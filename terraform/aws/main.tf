provider "aws" {
  region     = var.MD_CLUSTER_REGION
  access_key = var.ACCESS_KEY_ID
  secret_key = var.SECRET_ACCESS_KEY
}

module "aws_eks_cluster" {
  source = "./eks_cluster_module"

  MD_CLUSTER_NAME       = var.MD_CLUSTER_NAME
  MD_CLUSTER_REGION     = var.MD_CLUSTER_REGION
  ACCESS_KEY_ID         = var.ACCESS_KEY_ID
  SECRET_ACCESS_KEY     = var.SECRET_ACCESS_KEY
  PERSISTENT_DEPLOYMENT = var.PERSISTENT_DEPLOYMENT
  DEPLOY_FARGATE_NODES  = var.DEPLOY_FARGATE_NODES
}

module "aws_rds_postgres" {
  source = "./aws_rds_postgres_module"
  count  = var.DEPLOY_RDS_POSTGRES_DB ? 1 : 0

  MD_CLUSTER_NAME   = var.MD_CLUSTER_NAME
  VPC_ID            = module.aws_eks_cluster.vpc_id
  VPC_CIDR          = module.aws_eks_cluster.vpc_cidr
  PUBLIC_SUBNETS    = module.aws_eks_cluster.public_subnets
  POSTGRES_USERNAME = var.POSTGRES_USERNAME
  POSTGRES_PASSWORD = var.POSTGRES_PASSWORD

  depends_on = [
    module.aws_eks_cluster
  ]
}