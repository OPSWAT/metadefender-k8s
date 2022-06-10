variable "aks_service_principal_app_id" {
  
}

variable "aks_service_principal_client_secret" {
  
}

variable "aks_service_principal_object_id" {
  
}

variable "deploy_cosmos_db" {
  type    = bool
  default = false
}
variable "cosmos_db_account_name" {
  default = "md-db-account"
}

variable "resource_group_name_prefix" {
  default       = "md"
  description   = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "resource_group_location" {
  default       = "eastus"
  description   = "Location of the resource group."
}

variable "failover_location" {
  default = "swedencentral"
}



variable "agent_count" {
    default = 3
}

variable "ssh_public_key" {
    default = "~/.ssh/id_rsa.pub"
}

variable "dns_prefix" {
    default = "k8md"
}

variable cluster_name {
    default = "k8md"
}

variable resource_group_name {
    default = "azure-k8md"
}

variable location {
    default = "Central US"
}

variable log_analytics_workspace_name {
    default = "testLogAnalyticsWorkspaceName"
}

# refer https://azure.microsoft.com/global-infrastructure/services/?products=monitor for log analytics available regions
variable log_analytics_workspace_location {
    default = "eastus"
}

# refer https://azure.microsoft.com/pricing/details/monitor/ for log analytics pricing 
variable log_analytics_workspace_sku {
    default = "PerGB2018"
}