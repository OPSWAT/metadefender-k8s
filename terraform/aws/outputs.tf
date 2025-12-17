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

output "POSTGRES_USERNAME" {
  value = var.DEPLOY_RDS_POSTGRES_DB ? module.aws_rds_postgres.0.postgres_username : null
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