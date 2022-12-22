provider "azurerm" {
  features {}
}
provider "random" {}
provider "archive" {}
resource "random_id" "random" { 
  keepers = {
    first = "${timestamp()}"
  }     
  byte_length = 8
}

locals {
  test = pathexpand("~/${path.module}/main.tf")
        command_map = substr(local.test,0,1) == "/"? {
        command = "bash ../scripts/prepare_env.sh"
      }:{
        command = "powershell ../scripts/prepare_env.ps1", 
      }
}

resource "null_resource" "localexec" {
  provisioner "local-exec" {
    command = local.command_map.command
    #interpreter = [local.command_map.intrepreter]
  }
  triggers = {
      trigger = random_id.random.hex
  }
}

resource "azurerm_resource_group" "fnapp" {
  name = var.fn_resource_group_name
  location = var.fn_location
}

resource "azurerm_storage_account" "fnapp" {
  name                     = var.fn_storage_account_name
  resource_group_name      = var.fn_resource_group_name
  location                 = var.fn_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
      }
    depends_on = [
   azurerm_resource_group.fnapp
  ]
}

resource "azurerm_service_plan" "fnapp" {
  name                = var.fn_service_plan_name
  resource_group_name = var.fn_resource_group_name
  location            = var.fn_location
  os_type             = "Linux"
  sku_name            = "B1"
  depends_on = [
   azurerm_resource_group.fnapp
  ]
}

resource "azurerm_storage_container" "fnapp" {
  name                  = "function-releases"
  storage_account_name  = azurerm_storage_account.fnapp.name
  container_access_type = "private"
}

data "archive_file" "zip_function_app" {
  type        = "zip"
  source_dir  = "../src"
  output_path = "${random_id.random.hex}_function.zip"
  excludes  = ["terraform",".git",".venv", "local.settings.json",".vscode","__pycache__",".funcignore",".gitignore","scripts"]
  depends_on = [
    null_resource.localexec
  ]
}


resource "azurerm_storage_blob" "fnapp" {
  name = "${random_id.random.hex}_function.zip"
  storage_account_name   = azurerm_storage_account.fnapp.name
  storage_container_name = azurerm_storage_container.fnapp.name
  type   = "Block"
  source = "${random_id.random.hex}_function.zip"
  depends_on = [
    data.archive_file.zip_function_app
  ]
}

data "azurerm_storage_account_sas" "sas-fnapp" {
  connection_string = azurerm_storage_account.fnapp.primary_connection_string
  https_only        = false

  resource_types {
    service   = false
    container = false
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  start  = "2022-01-01"
  expiry = "2032-01-01"

  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}

resource "azurerm_application_insights" "fnapp" {
  name                = format("%s-%s",var.fn_name,"appinsight")
  location            = azurerm_resource_group.fnapp.location
  resource_group_name = azurerm_resource_group.fnapp.name
  application_type    = "other"
  depends_on = [
   azurerm_resource_group.fnapp
  ]
}

resource "azurerm_linux_function_app" "fnapp" {
  name                = var.fn_name
  resource_group_name = azurerm_resource_group.fnapp.name
  location            = azurerm_resource_group.fnapp.location
  storage_account_name       = azurerm_storage_account.fnapp.name
  storage_account_access_key = azurerm_storage_account.fnapp.primary_access_key
  service_plan_id            = azurerm_service_plan.fnapp.id
  depends_on = [
    azurerm_storage_blob.fnapp
  ]
  site_config {
    application_insights_connection_string = azurerm_application_insights.fnapp.connection_string
    application_insights_key = azurerm_application_insights.fnapp.instrumentation_key
    always_on = var.fn_site_config_always_on

    app_service_logs {
      disk_quota_mb = 25
    }
    application_stack {
      python_version = 3.9

  }
}
 app_settings = {
    WEBSITE_RUN_FROM_PACKAGE            = "https://${azurerm_storage_account.fnapp.name}.blob.core.windows.net/${azurerm_storage_container.fnapp.name}/${azurerm_storage_blob.fnapp.name}${data.azurerm_storage_account_sas.sas-fnapp.sas}"
    STORAGECLIENTID                     = var.STORAGECLIENTID
    APIKEY                              = var.APIKEY
    APIENDPOINT                         = var.APIENDPOINT
    FUNCTIONS_WORKER_RUNTIME            = "python"
  }
}

data "azurerm_storage_account" "storage" {
  name                = var.STORAGE_ACCOUNT
  resource_group_name = var.STORAGE_RG
}

resource "azurerm_eventgrid_system_topic" "topic" {
    name                = "${var.fn_name}-systemtopic"
    location            = data.azurerm_storage_account.storage.location
    resource_group_name = var.STORAGE_RG
    source_arm_resource_id = data.azurerm_storage_account.storage.id
    topic_type             = "Microsoft.Storage.StorageAccounts"
    depends_on = [
      data.azurerm_storage_account.storage
    ]
}

resource "azurerm_eventgrid_system_topic_event_subscription" "eventgrid" {
  name  = "${azurerm_linux_function_app.fnapp.name}-evtfilecreated"
  system_topic = azurerm_eventgrid_system_topic.topic.name
  resource_group_name = var.STORAGE_RG
  event_delivery_schema = "EventGridSchema"
  subject_filter {
    subject_begins_with = "/blobServices/default/containers/${var.STORAGE_CONTAINERNAME}"
  }
      depends_on = [
    azurerm_linux_function_app.fnapp,
    azurerm_eventgrid_system_topic.topic
  ]
  azure_function_endpoint {
    function_id = "${azurerm_linux_function_app.fnapp.id}/functions/webhook-notification"
  }
}