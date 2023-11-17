output "mongo_endpoint" {
  value = var.DEPLOY_MONGO_DB ? aws_docdb_cluster.docdb[0].endpoint : null
}
output "redis_endpoint" {
  value = var.DEPLOY_REDIS ? aws_elasticache_replication_group.redis_cache[0].configuration_endpoint_address : null
}
output "rabbitmq_id" {
  value = var.DEPLOY_RABBITMQ ? aws_mq_broker.rabbitmq_broker[0].id : null
}
output "rabbitmq_endpoint" {
  value = var.DEPLOY_RABBITMQ ? aws_mq_broker.rabbitmq_broker[0].instances.0.endpoints.0 : null
}