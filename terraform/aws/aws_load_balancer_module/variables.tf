variable "MD_CLUSTER_NAME" {
  type    = string
  default = "md-k8s"
}

variable "MD_CLUSTER_REGION" {
  type    = string
  default = "eu-central-1"
}

variable "ACCESS_KEY_ID" {
  type    = string
  default = ""
}

variable "SECRET_ACCESS_KEY" {
  type    = string
  default = ""
}

variable "VPC_ID" {
  type = string
}

variable "VPC_CIDR" {
  type = string
}

variable "PUBLIC_SUBNETS" {
  type = list(string)
}

variable "PRIVATE_SUBNETS" {
  type = list(string)
}

variable "EKS_CLUSTER_OICD_URL" {
  type = string
}

variable "SERVICE_ACCOUNT_NAME" {
  type    = string
  default = "md-k8s-load-balancer-controller"
}

variable "SERVICE_ACCOUNT_NAMESPACE" {
  type    = string
  default = "default"
}

variable "DEPLOY_MDSS_INGRESS" {
  type    = bool
  default = false
}

variable "DEPLOY_MDCORE_INGRESS" {
  type    = bool
  default = false
}

variable "EXTERNAL_ACCESS" {
  type    = bool
  default = false
}

