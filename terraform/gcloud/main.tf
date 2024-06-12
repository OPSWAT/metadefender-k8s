terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.19.0"
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
  name = "mdk8s-${var.cluster_name}-vpc"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "mdk8s-${var.cluster_name}-subnet"
  region        = var.region
  network       = google_compute_network.vpc_network.name
  ip_cidr_range = "10.10.0.0/24"
}

# GKE cluster AutoPilot
resource "google_container_cluster" "primary-autopilot" {
  count    = var.AUTOPILOT_GKE ? 1 : 0
  name     = "mdk8s-${var.cluster_name}-gke"
  location = var.cluster_location

  network    = google_compute_network.vpc_network.name
  subnetwork = google_compute_subnetwork.subnet.name

  enable_autopilot = true
}

# GKE cluster
resource "google_container_cluster" "primary" {
  count    = var.AUTOPILOT_GKE ? 0 : 1
  name     = "mdk8s-${var.cluster_name}-gke"
  location = var.cluster_location
  
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc_network.name
  subnetwork = google_compute_subnetwork.subnet.name
}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  count      = var.AUTOPILOT_GKE ? 0 : 1
  name       = "${google_container_cluster.primary[0].name}-node-pool"
  location   = var.cluster_location
  cluster    = google_container_cluster.primary[0].name
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
    tags         = ["gke-node", "${var.cluster_name}-gke"]
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
  deletion_protection = var.deletion_protection
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
  deletion_policy = "ABANDON"
}