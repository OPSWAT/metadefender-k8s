terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.99.0"
    }
  }
}

provider "azurerm" {
  features {}
}
# Generate random resource group name
resource "random_pet" "rg-name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "k8s" {
  name     = random_pet.rg-name.id
  location = var.resource_group_location
}

resource "random_id" "log_analytics_workspace_name_suffix" {
  byte_length = 8
}

resource "azurerm_log_analytics_workspace" "md" {
  # The WorkSpace name has to be unique across the whole of azure, not just the current subscription/tenant.
  name                = "${var.log_analytics_workspace_name}-${random_id.log_analytics_workspace_name_suffix.dec}"
  location            = var.log_analytics_workspace_location
  resource_group_name = azurerm_resource_group.k8s.name
  sku                 = var.log_analytics_workspace_sku
}

resource "azurerm_log_analytics_solution" "md" {
  solution_name         = "ContainerInsights"
  location              = azurerm_log_analytics_workspace.md.location
  resource_group_name   = azurerm_resource_group.k8s.name
  workspace_resource_id = azurerm_log_analytics_workspace.md.id
  workspace_name        = azurerm_log_analytics_workspace.md.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_group_name_prefix}-vnet"
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  address_space       = ["192.168.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.resource_group_name_prefix}-aks-subnet"
  resource_group_name  = azurerm_resource_group.k8s.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.2.0/23"]
}
resource "azurerm_subnet" "subnet_db" {
  name                 = "${var.resource_group_name_prefix}-db-subnet"
  resource_group_name  = azurerm_resource_group.k8s.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.4.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}
resource "azurerm_private_dns_zone" "priv_zone" {
  name                = "${var.postgres_db_account_name}.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.k8s.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "priv_zone_link" {
  name                  = "${var.postgres_db_account_name}.com"
  private_dns_zone_name = azurerm_private_dns_zone.priv_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  resource_group_name   = azurerm_resource_group.k8s.name
}

resource "azurerm_kubernetes_cluster" "k8s" {
  name                = var.cluster_name
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  dns_prefix          = var.dns_prefix

  linux_profile {
    admin_username = "ubuntu"

    ssh_key {
      key_data = file(var.ssh_public_key)
    }
  }

  default_node_pool {
    name       = "agentpool"
    node_count = var.agent_count
    vm_size    = "Standard_F8s_v2"
    vnet_subnet_id = "${azurerm_subnet.subnet.id}"
  }

  service_principal {
    client_id     = var.aks_service_principal_app_id
    client_secret = var.aks_service_principal_client_secret
  }

  network_profile {
    load_balancer_sku = "Standard"
    network_plugin    = "kubenet"
  }
  

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.md.id
    }
  }

  tags = {
    Environment = "Development"
  }
}

resource "azurerm_cosmosdb_account" "mdcs" {
  count  = var.deploy_cosmos_db ? 1 : 0
  name                      = var.cosmos_db_account_name
  location                  = azurerm_resource_group.k8s.location
  resource_group_name       = azurerm_resource_group.k8s.name
  offer_type                = "Standard"
  kind                      = "MongoDB"
  enable_automatic_failover = true
  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 400
    max_staleness_prefix    = 200000
  }

  geo_location {
    location          = var.failover_location
    failover_priority = 1
  }

  geo_location {
    location          = var.resource_group_location
    failover_priority = 0
  }

}

resource "azurerm_cosmosdb_mongo_database" "mongodb" {
  count  = var.deploy_cosmos_db ? 1 : 0
  name                = "MDCS"
  resource_group_name = azurerm_cosmosdb_account.mdcs[0].resource_group_name
  account_name        = azurerm_cosmosdb_account.mdcs[0].name
  throughput          = 400
}

resource "azurerm_postgresql_flexible_server" "postgredb" {
  count  = var.deploy_postgres_db ? 1 : 0
  name                = "postgresql-${var.postgres_db_account_name}"
  location            = azurerm_resource_group.k8s.location
  resource_group_name = random_pet.rg-name.id
  version             = "12"
  delegated_subnet_id    = azurerm_subnet.subnet_db.id
  private_dns_zone_id    = azurerm_private_dns_zone.priv_zone.id

  administrator_login          = var.postgres_admin
  administrator_password = var.postgres_password

  sku_name   = "GP_Standard_D4s_v3"
  storage_mb = 65536

  geo_redundant_backup_enabled = false
  depends_on = [azurerm_private_dns_zone_virtual_network_link.priv_zone_link]

}

resource "azurerm_postgresql_flexible_server_configuration" "postgredbconfig" {
  count  = var.deploy_postgres_db ? 1 : 0
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.postgredb[0].id
  value     = "PG_TRGM,DBLINK,BTREE_GIN"
}   