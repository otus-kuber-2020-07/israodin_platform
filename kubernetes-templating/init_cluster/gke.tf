variable "gke_username" {
  default     = ""
  description = "gke username"
}
variable "gke_password" {
  default     = ""
  description = "gke password"
}
variable "gke_num_nodes" {
  default     = 1
  description = "number of gke nodes"
}
variable "autoscaling_min_node_count" {
  default = 1
}
variable "autoscaling_max_node_count" {
  default = 2
}
# GKE cluster
data "google_container_engine_versions" "uscentral1" {
  provider       = "google"
  location       = "us-central1"
  version_prefix = "1.16.9"
}
resource "google_container_cluster" "primary" {
  name     = "${var.project_id}-gke"
  location = var.region
  node_version  = data.google_container_engine_versions.uscentral1.version_prefix
  min_master_version = data.google_container_engine_versions.uscentral1.version_prefix
  remove_default_node_pool = true
  initial_node_count       = 1
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name
  master_auth {
    username = var.gke_username
    password = var.gke_password
    client_certificate_config {
      issue_client_certificate = false
    }
  }
}
# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${google_container_cluster.primary.name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.gke_num_nodes
  autoscaling {
      min_node_count = "${var.autoscaling_min_node_count}"
      max_node_count = "${var.autoscaling_max_node_count}"
    }

  # node_config {
  #   oauth_scopes = [
  #     "https://www.googleapis.com/auth/logging.write",
  #     "https://www.googleapis.com/auth/monitoring",
  #   ]

  #   labels = {
  #     env = var.project_id
  #   }

  #   # preemptible  = true
  #   machine_type = "n1-standard-1"
  #   tags         = ["gke-node", "${var.project_id}-gke"]
  #   metadata = {
  #     disable-legacy-endpoints = "true"
  #   }
  # }
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}
