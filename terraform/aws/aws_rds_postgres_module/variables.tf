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

variable "POSTGRES_USERNAME" {
  type = string
}

variable "POSTGRES_PASSWORD" {
  type = string
}
