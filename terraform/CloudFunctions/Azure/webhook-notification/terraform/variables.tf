variable "fn_resource_group_name" {
  description = "The name of the resource group in which the function app will be created."
  type        = string
}

variable "fn_service_plan_name" {
  description = "The name of the app service plan"
  type        = string
}

variable "fn_storage_account_name" {
    description = "The name of the storage account to be created for the function"
    type        = string
}

variable "fn_name" {
  description = "String value prepended to the name of each function app"
  type        = string
}

variable "fn_site_config_always_on" {
  description = "Should the app be loaded at all times? Defaults to true."
  type        = bool
  default     = true
}

variable "fn_location" {
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

variable "STORAGE_RG" {
  description = "The resource group where the storage account that triggers the function is"
  type        = string
  default     = ""
}

variable "STORAGE_ACCOUNT" {
  description = "The storage account name where the container that triggers the function is"
  type        = string
  default     = ""
}

variable "STORAGE_CONTAINERNAME" {
  description = "The container name that triggers the function"
  type        = string
  default     = ""
}