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

variable "PERSISTENT_DEPLOYMENT" {
  type    = bool
  default = false
}

variable "DEPLOY_FARGATE_NODES" {
  type    = bool
  default = false
}

variable "DEPLOY_MDSS_INGRESS" {
  type    = bool
  default = true
}

variable "DEPLOY_MDCORE_INGRESS" {
  type    = bool
  default = false
}

variable "LOAD_BALANCER_SERVICE_ACCOUNT_NAME" {
  type    = string
  default = "md-k8s-load-balancer-controller"
}

variable "LOAD_BALANCER_SERVICE_ACCOUNT_NAMESPACE" {
  type    = string
  default = "default"
}

variable "DEPLOY_RDS_POSTGRES_DB" {
  type    = bool
  default = false
}

variable "POSTGRES_USERNAME" {
  type = string
}

variable "POSTGRES_PASSWORD" {
  type = string
}

variable "EXTERNAL_ACCESS" {
  type    = bool
  default = false
}