output "resource_group_name" {
  value = azurerm_resource_group.k8s.name
}

output "client_key" {
    value = azurerm_kubernetes_cluster.k8s.kube_config.0.client_key
    sensitive = true
}

output "client_certificate" {
    value = azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate
    sensitive = true
}

output "cluster_ca_certificate" {
    value = azurerm_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate
    sensitive = true
}

output "cluster_name" {
    value = azurerm_kubernetes_cluster.k8s.name
}
output "cluster_username" {
    value = azurerm_kubernetes_cluster.k8s.kube_config.0.username
    sensitive = true
}

output "cluster_password" {
    value = azurerm_kubernetes_cluster.k8s.kube_config.0.password
    sensitive = true
}

output "kube_config" {
    value = azurerm_kubernetes_cluster.k8s.kube_config_raw
    sensitive = true
}

output "db_server_fqdn_postgres" {
    value =  var.deploy_postgres_db ? azurerm_postgresql_flexible_server.postgredb.*.fqdn[0] : null
    sensitive = true
}
output "db_server_name_postgres" {
    value = var.deploy_postgres_db ? azurerm_postgresql_flexible_server.postgredb.*.name[0] : null
    sensitive = true
}
output "db_server_username_postgres" {
    value = var.deploy_postgres_db ? azurerm_postgresql_flexible_server.postgredb.*.administrator_login[0] : null
    sensitive = true
}