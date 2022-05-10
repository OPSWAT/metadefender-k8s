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

variable "PUBLIC_SUBNETS" {
  type = list(string)
}

variable "POSTGRES_USERNAME" {
  type = string
}

variable "POSTGRES_PASSWORD" {
  type = string
}
