variable "project_id" {
  description = "GCloud project id"
  default = "metadefender-k8s"
}

variable "region" {
  description = "Region where to deploy"
  default = "europe-central2"
}

variable "cluster_location" {
  description = "GKE cluster location that can be either a region or a specific zone"
  default = "europe-central2-a"
}

variable "gcloud_json_key_path" {
  description = "JSON key with the credentials for the service account to use"
  default = "/path/to/json"
  type    = string
}

variable "node_count" {
  description = "The initial number of nodes per zone in the cluster"
  default = "1"
}

variable "machine_type" {
  description = "GCloud machine type to use for backend nodes"
  default = "e2-standard-8"
}

variable "deploy_cloud_sql" {
  description = "Enable the deployment of a Cloud SQL instance for MD Core"
  default = false
}

variable "private_ip_cloud_sql" {
  description = "Create a private IP address for the Cloud SQL instance (requires the servicenetworking.services.addPeering permission)"
  default = false
}

variable "cloud_sql_user" {
  description = "Username for the Cloud SQL instance"
  default = "postgres"
}

resource "random_password" "random_pass" {
  length           = 16
  special          = false
}

variable "cloud_sql_password" {
  description = "Password for the Cloud SQL instance"
  default = null
}