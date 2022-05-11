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

module "aws_load_balancer" {
  source = "./aws_load_balancer_module"
  count  = var.DEPLOY_MDSS_INGRESS || var.DEPLOY_MDCORE_INGRESS ? 1 : 0

  MD_CLUSTER_NAME           = var.MD_CLUSTER_NAME
  MD_CLUSTER_REGION         = var.MD_CLUSTER_REGION
  ACCESS_KEY_ID             = var.ACCESS_KEY_ID
  SECRET_ACCESS_KEY         = var.SECRET_ACCESS_KEY
  VPC_ID                    = module.aws_eks_cluster.vpc_id
  VPC_CIDR                  = module.aws_eks_cluster.vpc_cidr
  PUBLIC_SUBNETS            = module.aws_eks_cluster.public_subnets
  PRIVATE_SUBNETS           = module.aws_eks_cluster.private_subnets
  EKS_CLUSTER_OICD_URL      = module.aws_eks_cluster.eks_cluster_oicd_url
  SERVICE_ACCOUNT_NAME      = var.LOAD_BALANCER_SERVICE_ACCOUNT_NAME
  SERVICE_ACCOUNT_NAMESPACE = var.LOAD_BALANCER_SERVICE_ACCOUNT_NAMESPACE
  DEPLOY_MDSS_INGRESS       = var.DEPLOY_MDSS_INGRESS
  DEPLOY_MDCORE_INGRESS     = var.DEPLOY_MDCORE_INGRESS
  EXTERNAL_ACCESS           = var.EXTERNAL_ACCESS

  depends_on = [
    module.aws_eks_cluster
  ]
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