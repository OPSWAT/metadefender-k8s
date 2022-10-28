provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "fnapp" {
  name = var.resource_group_name
  location = var.location
}

resource "azurerm_service_plan" "fnapp" {
  name                = var.service_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "EP1"
  depends_on = [
   azurerm_resource_group.fnapp
  ]

}

resource "azurerm_storage_account" "fnapp" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  depends_on = [
   azurerm_resource_group.fnapp
  ]
}
resource "azurerm_application_insights" "fnapp" {
  name                = format("%s-%s",var.fn_name_prefix,"appinsight")
  location            = azurerm_resource_group.fnapp.location
  resource_group_name = azurerm_resource_group.fnapp.name
  application_type    = "other"
  depends_on = [
   azurerm_resource_group.fnapp
  ]
}
resource "azurerm_linux_function_app" "fnapp" {
  name                = var.fn_name_prefix
  resource_group_name = azurerm_resource_group.fnapp.name
  location            = azurerm_resource_group.fnapp.location

  storage_account_name       = azurerm_storage_account.fnapp.name
  storage_account_access_key = azurerm_storage_account.fnapp.primary_access_key
  service_plan_id            = azurerm_service_plan.fnapp.id
  functions_extension_version = "~3"
  depends_on = [
   azurerm_resource_group.fnapp,
   azurerm_service_plan.fnapp,
   azurerm_storage_account.fnapp
  ]
   site_config {
    application_stack {
      docker {
    registry_url = var.docker_registry_server_url
    image_name = var.docker_image_name
    image_tag = var.docker_image_tag
#    registry_username = var.docker_registry_server_username
#    registry_password = var.docker_registry_server_password
    }
  }
    application_insights_connection_string = azurerm_application_insights.fnapp.connection_string
    application_insights_key = azurerm_application_insights.fnapp.instrumentation_key
}
app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
    AzureWebJobsBlobTrigger             = var.AzureWebJobsBlobTrigger
    CONTAINERNAME                       = var.CONTAINERNAME
    STORAGECLIENTID                     = var.STORAGECLIENTID
    APIKEY                              = var.APIKEY
    APIENDPOINT                         = var.APIENDPOINT
  }
  }