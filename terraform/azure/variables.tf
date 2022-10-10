variable "aks_service_principal_app_id" {
  
}

variable "aks_service_principal_client_secret" {
  
}

variable "aks_service_principal_object_id" {
  
}
variable "postgres_admin" {
  
}

variable "postgres_password" {
  
}

variable "deploy_cosmos_db" {
  type    = bool
  default = false
}
variable "deploy_postgres_db" {
  type    = bool
  default = false
}
variable "cosmos_db_account_name" {
  default = "mdss-db-account"
}
variable "postgres_db_account_name" {
  default = "mdcore-db"
}

variable "resource_group_name_prefix" {
  default       = "md"
  description   = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "resource_group_location" {
  default       = "centralus"
  description   = "Location of the resource group."
}

variable "failover_location" {
  default = "us-west-2"
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

variable location {
    default = "Central US"
}

variable log_analytics_workspace_name {
    default = "testLogAnalyticsWorkspaceName"
}

# refer https://azure.microsoft.com/global-infrastructure/services/?products=monitor for log analytics available regions
variable log_analytics_workspace_location {
    default = "centralus"
}

# refer https://azure.microsoft.com/pricing/details/monitor/ for log analytics pricing 
variable log_analytics_workspace_sku {
    default = "PerGB2018"
}