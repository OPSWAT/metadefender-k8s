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

variable "DEPLOY_RDS_POSTGRES_DB" {
  type    = bool
  default = false
}
variable "DEPLOY_MONGO_DB" {
  type    = bool
  default = false
}
variable "DEPLOY_REDIS" {
  type    = bool
  default = false
}
variable "DEPLOY_RABBITMQ" {
  type    = bool
  default = false
}

variable "POSTGRES_USERNAME" {
  type = string
}

variable "POSTGRES_PASSWORD" {
  type = string
}

variable "MONGO_USERNAME" {
  type = string
}

variable "MONGO_PASSWORD" {
  type = string
}
variable "TLS_MONGO_ENABLED" {
  type = string
  default = "disabled"
}
variable "MQ_USERNAME" {
  type = string
}

variable "MQ_PASSWORD" {
  type = string
}
