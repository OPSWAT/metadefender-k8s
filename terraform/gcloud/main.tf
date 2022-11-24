terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {
  credentials = file(var.gcloud_json_key_path)

  project = var.project_id
  region  = var.region
}

# MDK8S VPC
resource "google_compute_network" "vpc_network" {
  name = "mdk8s-${var.project_id}-vpc"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "mdk8s-${var.project_id}-subnet"
  region        = var.region
  network       = google_compute_network.vpc_network.name
  ip_cidr_range = "10.10.0.0/24"
}

# GKE cluster
resource "google_container_cluster" "primary" {
  name     = "mdk8s-${var.project_id}-gke"
  location = var.cluster_location
  
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc_network.name
  subnetwork = google_compute_subnetwork.subnet.name
}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${google_container_cluster.primary.name}-node-pool"
  location   = var.cluster_location
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      env = var.project_id
    }

    preemptible  = true
    machine_type = var.machine_type
    tags         = ["gke-node", "${var.project_id}-gke"]
  }
}

resource "google_compute_global_address" "private_ip_address" {
  count  = var.deploy_cloud_sql && var.private_ip_cloud_sql ? 1 : 0
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  network       = google_compute_network.vpc_network.id
}

resource "google_service_networking_connection" "vpc_connection" {
  count  = var.deploy_cloud_sql && var.private_ip_cloud_sql ? 1 : 0
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address[0].name]
}

resource "google_sql_database_instance" "metadefender-db" {
  count  = var.deploy_cloud_sql ? 1 : 0
  name             = "metadefender-db"
  database_version = "POSTGRES_14"
  region           = var.region

  depends_on = [google_service_networking_connection.vpc_connection]

  settings {
    tier = "db-f1-micro"
    dynamic "ip_configuration" {
      for_each = var.private_ip_cloud_sql ? [1] : []
      content {
        ipv4_enabled    = false
        private_network = google_compute_network.vpc_network.id
      }
    }
  }
}

resource "google_sql_user" "users" {
  count  = var.deploy_cloud_sql ? 1 : 0
  name     = var.cloud_sql_user
  instance = google_sql_database_instance.metadefender-db[0].name
  password = var.cloud_sql_password != null ? var.cloud_sql_password : random_password.random_pass.result
}