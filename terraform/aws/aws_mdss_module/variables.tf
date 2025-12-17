variable "MD_CLUSTER_NAME" {
  type    = string
  default = "md-k8s"
}

variable "VPC_ID" {
  type = string
}

variable "VPC_CIDR" {
  type = string
}

variable "SUBNET_GROUP_ID" {
  type = string
}
variable "PRIVATE_SUBNETS" {
  type = list(string)
}
variable "DEPLOY_REDIS" {
  type    = bool
  default = false
}
variable "DEPLOY_RABBITMQ" {
  type    = bool
  default = false
}
variable "MQ_USERNAME" {
  type = string
}

variable "MQ_PASSWORD" {
  type = string
}