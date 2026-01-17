# OpenTofu variabelen voor Bordspelplatform Infrastructure

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP regio voor resources"
  type        = string
  default     = "europe-west1"
}

variable "environment" {
  description = "Omgeving naam (dev, test, prod)"
  type        = string
  default     = "dev"
}

# Network variabelen
variable "subnet_cidr" {
  description = "CIDR range voor GKE subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "pods_cidr" {
  description = "CIDR range voor Kubernetes pods"
  type        = string
  default     = "10.1.0.0/16"
}

variable "services_cidr" {
  description = "CIDR range voor Kubernetes services"
  type        = string
  default     = "10.2.0.0/16"
}

# GKE Cluster variabelen
variable "node_count" {
  description = "Initieel aantal nodes per zone"
  type        = number
  default     = 1
}

variable "min_node_count" {
  description = "Minimum aantal nodes voor autoscaling"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum aantal nodes voor autoscaling"
  type        = number
  default     = 5
}

variable "machine_type" {
  description = "Machine type voor GKE nodes"
  type        = string
  default     = "e2-medium"  # 2 vCPU, 4GB RAM
}

variable "use_preemptible_nodes" {
  description = "Gebruik preemptible nodes voor kostenbesparing"
  type        = bool
  default     = true  # Voor dev/test, zet op false voor productie
}

# Database variabelen
variable "db_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"  # Voor dev, upgrade naar db-custom-2-4096 voor prod
}

variable "db_availability_type" {
  description = "Database availability type (ZONAL of REGIONAL)"
  type        = string
  default     = "ZONAL"  # Voor dev, gebruik REGIONAL voor prod
}

variable "db_disk_size" {
  description = "Database disk grootte in GB (minimum 10GB voor Cloud SQL)"
  type        = number
  default     = 10
}

variable "db_username" {
  description = "Database gebruikersnaam"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "db_password" {
  description = "Database wachtwoord"
  type        = string
  sensitive   = true
}

variable "db_deletion_protection" {
  description = "Bescherm database tegen onbedoelde verwijdering"
  type        = bool
  default     = false
}
