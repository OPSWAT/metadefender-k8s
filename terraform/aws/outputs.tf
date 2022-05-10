output "MD_CLUSTER_NAME" {
  value = var.MD_CLUSTER_NAME
}

output "VPC_ID" {
  value = module.aws_eks_cluster.vpc_id
}

output "MD_CLUSTER_REGION" {
  value = var.MD_CLUSTER_REGION
}

output "LOAD_BALANCER_SERVICE_ACCOUNT_NAME" {
  value = module.aws_load_balancer.0.load_balancer_service_account_name
}

output "LOAD_BALANCER_SERVICE_ACCOUNT_ROLE_ARN" {
  value = module.aws_load_balancer.0.load_balancer_service_account_role_arn
}

output "WEBCLIENT_TARGET_GROUP_ARN" {
  value = module.aws_load_balancer.0.webclient_target_group_arn
}

output "SYSTEMCHECKS_TARGET_GROUP_ARN" {
  value = module.aws_load_balancer.0.systemchecks_target_group_arn
}

output "MDCORE_TARGET_GROUP_ARN" {
  value = module.aws_load_balancer.0.mdcore_target_group_arn
}

output "POSTGRES_ENDPOINT" {
  value =  var.DEPLOY_RDS_POSTGRES_DB ? module.aws_rds_postgres.0.postgres_endpoint : null
}
