output "MD_CLUSTER_NAME" {
  value = var.MD_CLUSTER_NAME
}

output "VPC_ID" {
  value = module.aws_eks_cluster.vpc_id
}

output "MD_CLUSTER_REGION" {
  value = var.MD_CLUSTER_REGION
}

output "POSTGRES_ENDPOINT" {
  value =  var.DEPLOY_RDS_POSTGRES_DB ? module.aws_rds_postgres.0.postgres_endpoint : null
}

output "MONGO_ENDPOINT" {
  value = var.DEPLOY_MONGO_DB ? module.aws_mdss.mongo_endpoint : null
}
output "TLS_MONGO_ENABLED" {
  value = var.TLS_MONGO_ENABLED
}
output "REDIS_ENDPOINT" {
  value = var.DEPLOY_REDIS ? module.aws_mdss.redis_endpoint : null
}
output "RABBITMQ_ID" {
  value = var.DEPLOY_RABBITMQ ? module.aws_mdss.rabbitmq_id : null
}
output "RABBITMQ_ENDPOINT" {
  value = var.DEPLOY_RABBITMQ ? module.aws_mdss.rabbitmq_endpoint : null
}