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
  description = "GCP Zone for single-zone cluster"
  type        = string
  default     = "europe-west1-b"
}

variable "cluster_name" {
  description = "Kubernetes Cluster Name"
  type        = string
  default     = "ai-platform-team4"
}

variable "machine_type" {
  description = "Machine type for nodes (needs GPU-capable for Ollama)"
  type        = string
  default     = "e2-standard-4"
}

variable "node_count" {
  description = "Number of nodes in the cluster"
  type        = number
  default     = 1
}

variable "db_password" {
  description = "Password for PostgreSQL database"
  type        = string
  default     = "team4SecurePass123"
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
  default     = "ai-network-team4"
}

variable "subnet_name" {
  description = "VPC Subnet Name"
  type        = string
  default     = "ai-subnet-team4"
}
