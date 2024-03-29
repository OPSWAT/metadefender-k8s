variable "resource_group_name" {
  description = "The name of the resource group in which the function app will be created."
  type        = string
}

variable "service_plan_name" {
  description = "The name of the app service plan"
  type        = string
}

variable "storage_account_name" {
    description = "The name of the storage account to be created"
    type        = string
}

variable "fn_name_prefix" {
  description = "String value prepended to the name of each function app"
  type        = string
}

variable "resource_tags" {
  description = "Map of tags to apply to taggable resources in this module. By default the taggable resources are tagged with the name defined above and this map is merged in"
  type        = map(string)
  default     = {}
}

variable "fn_app_settings" {
  description = "Map of app settings that will be applied across all provisioned function apps"
  type        = map(string)
  default     = {}
}

variable "runtime_version" {
  description = "Functions runtime version"
  type = string
  default = "~4"
}

variable "worker_runtime" {
  description = "Functions worker runtime"
  type = string
  default = "python"
}

variable "fn_app_config" {
  description = "Metadata about the app services to be created"
  type = map(object({
    image = string,
    zip = string,
    hash = string
  }))
  default = {}
}

variable "app_insights_instrumentation_key" {
  description = "The Instrumentation Key for the Application Insights component"
  type        = string
  default     = ""
}

variable "site_config_always_on" {
  description = "Should the app be loaded at all times? Defaults to true."
  type        = string
  default     = true
}

variable "docker_registry_server_url" {
  description = "The docker registry server URL for app service to be created"
  type        = string
  default     = "docker.io"
}
variable "docker_image_name" {
  description = "The docker image name for app service to be created"
  type        = string
  default     = ""
}
variable "docker_image_tag" {
  description = "The docker image tag for app service to be created"
  type        = string
  default     = ""
}
variable "docker_registry_server_username" {
  description = "The docker registry server username for app service to be created"
  type        = string
  default     = ""
}

variable "docker_registry_server_password" {
  description = "The docker registry server password for app service to be created"
  type        = string
  default     = ""
}

variable "AzureWebJobsBlobTrigger" {
  description = "The storage account connection string that triggers the function"
  type        = string
  default     = ""
}

variable "CONTAINERNAME" {
  description = "The blob container that needs to be scanned"
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = ""
}

variable "STORAGECLIENTID" {
  description = "StorageClientId env variable"
  type        = string
  default     = ""
}

variable "APIKEY" {
  description = "ApiKey env variable"
  type        = string
  default     = ""
}

variable "APIENDPOINT" {
  description = "ApiEndpoint env variable"
  type        = string
  default     = ""
}