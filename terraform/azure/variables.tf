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
variable "deploy_postgres_db" {
  type    = bool
  default = false
}
variable "postgres_db_account_name" {
  default = "mdcore-db"
}

variable "resource_group_name_prefix" {
  default       = "md"
  description   = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "resource_group_location" {
  default       = "eastus"
  description   = "Location of the resource group. Was centralus; moved to eastus after repeated AKSCapacityHeavyUsage errors there — override via -var if you need a different region."
}

variable "agent_count" {
    default = 3
}

variable "vm_size" {
  default     = "Standard_F8s_v2"
  description = "AKS node pool VM size. Compute-optimized F-series SKUs like this one tend to run into AKSCapacityHeavyUsage more often than general-purpose D-series — override via -var if the default is capacity-constrained in the target region."
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