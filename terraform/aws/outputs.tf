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
