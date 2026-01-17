variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region (Belgium)"
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "GCP Zone for single-zone cluster (to reduce SSD quota)"
  type        = string
  default     = "europe-west1-b"
}

variable "cluster_name" {
  description = "Kubernetes Cluster Name"
  type        = string
  default     = "bordspel-platform-team12"
}

variable "machine_type" {
  description = "Machine type for nodes"
  type        = string
  default     = "e2-standard-2"
}

variable "node_count" {
  description = "Number of nodes per zone in the cluster"
  type        = number
  default     = 1
}

variable "db_password" {
  description = "Password for Cloud SQL database user"
  type        = string
  default     = "password"
  sensitive   = true
}

variable "credentials_file" {
  description = "Path to GCP credentials JSON file"
  type        = string
  default     = "../../credentials.json"
}

variable "network_name" {
  description = "VPC Network Name"
  type        = string
  default     = "bordspel-network-team12"
}

variable "subnet_name" {
  description = "VPC Subnet Name"
  type        = string
  default     = "bordspel-subnet-team12"
}
