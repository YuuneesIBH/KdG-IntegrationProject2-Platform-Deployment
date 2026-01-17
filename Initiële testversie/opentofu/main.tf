# OpenTofu configuration for Bordspelplatform
# Infrastructure as Code voor Google Cloud Platform
# OpenTofu >= 1.6

terraform {
  required_version = ">= 1.6"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
  
  # Backend configuration voor state management
  # Uncomment en configureer wanneer je klaar bent voor productie
  # backend "gcs" {
  #   bucket = "bordspelplatform-opentofu-state"
  #   prefix = "opentofu/state"
  # }
}

# Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "${var.environment}-vpc"
  auto_create_subnetworks = false
  description             = "VPC voor ${var.environment} omgeving"
}

# Subnet voor GKE cluster
resource "google_compute_subnetwork" "gke_subnet" {
  name          = "${var.environment}-gke-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }
  
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }
}

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = "${var.environment}-gke-cluster"
  location = "${var.region}-b"  # Single zone voor dev (minder quota)
  
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.gke_subnet.name
  
  # IP allocation policy voor VPC-native cluster
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }
  
  # Workload Identity voor veilige toegang tot GCP services
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  # Monitoring en logging
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = true
    }
  }
  
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }
  
  # Security settings
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
  
  # Netwerkbeleid inschakelen
  network_policy {
    enabled = true
  }
  
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }
  
  deletion_protection = false
}

# Node Pool voor applicatie workloads
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.environment}-node-pool"
  location   = "${var.region}-b"  # Single zone voor dev
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count
  
  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }
  
  node_config {
    preemptible  = var.use_preemptible_nodes
    machine_type = var.machine_type
    disk_size_gb = 30  # Verlaagd voor dev quota (standaard is 100GB)
    disk_type    = "pd-standard"  # Standard disk i.p.v. SSD voor dev
    
    # Google recommends custom service accounts with minimal permissions
    service_account = google_service_account.gke_service_account.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    labels = {
      environment = var.environment
      managed-by  = "opentofu"
    }
    
    tags = ["gke-node", "${var.environment}-gke"]
    
    metadata = {
      disable-legacy-endpoints = "true"
    }
    
    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
  
  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# Service Account voor GKE nodes
resource "google_service_account" "gke_service_account" {
  account_id   = "${var.environment}-gke-sa"
  display_name = "GKE Service Account voor ${var.environment}"
  description  = "Service account gebruikt door GKE nodes"
}

# IAM binding voor service account
resource "google_project_iam_member" "gke_service_account_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/artifactregistry.reader"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
}

# Random suffix voor database instance naam (voorkomt conflicts)
resource "random_id" "db_name_suffix" {
  byte_length = 4
}

# Cloud SQL PostgreSQL Instance voor databases
resource "google_sql_database_instance" "postgres" {
  name             = "${var.environment}-postgres-${random_id.db_name_suffix.hex}"
  database_version = "POSTGRES_15"
  region           = var.region
  
  settings {
    tier              = var.db_tier
    availability_type = var.db_availability_type
    disk_size         = var.db_disk_size
    disk_type         = "PD_SSD"
    
    backup_configuration {
      enabled            = true
      start_time         = "03:00"
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 7
      }
    }
    
    ip_configuration {
      ipv4_enabled    = true
      # Private network disabled voor dev - enable voor productie
      # private_network = google_compute_network.vpc.id
      ssl_mode        = "ENCRYPTED_ONLY"
    }
    
    maintenance_window {
      day          = 7  # Sunday
      hour         = 3
      update_track = "stable"
    }
    
    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
    }
  }
  
  deletion_protection = false
}

# Database voor Platform
resource "google_sql_database" "platform_db" {
  name     = "platform_db"
  instance = google_sql_database_instance.postgres.name
}

# Database voor AI Services
resource "google_sql_database" "ai_db" {
  name     = "ai_services_db"
  instance = google_sql_database_instance.postgres.name
}

# Database voor Analytics (Elastic kan ook gebruikt worden)
resource "google_sql_database" "analytics_db" {
  name     = "analytics_db"
  instance = google_sql_database_instance.postgres.name
}

# Database gebruiker
resource "google_sql_user" "db_user" {
  name     = var.db_username
  instance = google_sql_database_instance.postgres.name
  password = var.db_password  # In productie: gebruik Secret Manager
}

# Artifact Registry voor Docker images
resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.region
  repository_id = "${var.environment}-docker-repo"
  description   = "Docker repository voor bordspelplatform containers"
  format        = "DOCKER"
  
  labels = {
    environment = var.environment
    managed-by  = "opentofu"
  }
}

# Firewall regel voor health checks
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.environment}-allow-health-checks"
  network = google_compute_network.vpc.name
  
  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080"]
  }
  
  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22"
  ]
  
  target_tags = ["gke-node"]
}

# Static IP voor Load Balancer
resource "google_compute_global_address" "lb_ip" {
  name = "${var.environment}-lb-ip"
}
