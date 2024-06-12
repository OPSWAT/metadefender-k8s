output "region" {
  value       = var.region
  description = "GCloud region"
}

output "cluster_location" {
  value       = var.region
  description = "Cluster region or zone"
}

output "project_id" {
  value       = var.project_id
  description = "GCloud Project ID"
}

output "kubernetes_cluster_name" {
  value       = var.AUTOPILOT_GKE ? google_container_cluster.primary-autopilot[0].name : google_container_cluster.primary[0].name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = var.AUTOPILOT_GKE ? null : google_container_cluster.primary[0].endpoint
  description = "GKE Cluster Host"
}


output "cloud_sql_db_name" {
  value       = var.deploy_cloud_sql ? google_sql_database_instance.metadefender-db[0].name : null
  description = "Cloud SQL database name"
}

output "cloud_sql_connection_name" {
  value       = var.deploy_cloud_sql ? google_sql_database_instance.metadefender-db[0].connection_name : null
  description = "Cloud SQL connection name"
}
output "cloud_sql_private_ip_address" {
  value       = var.deploy_cloud_sql ? google_sql_database_instance.metadefender-db[0].private_ip_address : null
  description = "Cloud SQL Private IP Address"
}

output "cloud_sql_user" {
  value       = var.deploy_cloud_sql ? var.cloud_sql_user : null
  description = "Cloud SQL username"
}

output "cloud_sql_password" {
  value       = var.deploy_cloud_sql ? var.cloud_sql_password != null ? var.cloud_sql_password : random_password.random_pass.result : null
  description = "Cloud SQL user parssword"
  sensitive = true
}