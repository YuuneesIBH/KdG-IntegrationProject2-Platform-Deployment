# OpenTofu outputs voor Bordspelplatform

output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "region" {
  description = "GCP Region"
  value       = var.region
}

output "cluster_name" {
  description = "GKE Cluster naam"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "GKE Cluster endpoint"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "GKE Cluster CA certificate"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "vpc_name" {
  description = "VPC network naam"
  value       = google_compute_network.vpc.name
}

output "subnet_name" {
  description = "GKE subnet naam"
  value       = google_compute_subnetwork.gke_subnet.name
}

output "database_instance_name" {
  description = "Cloud SQL instance naam"
  value       = google_sql_database_instance.postgres.name
}

output "database_connection_name" {
  description = "Cloud SQL connection naam"
  value       = google_sql_database_instance.postgres.connection_name
}

output "database_private_ip" {
  description = "Cloud SQL private IP"
  value       = google_sql_database_instance.postgres.private_ip_address
}

output "database_public_ip" {
  description = "Cloud SQL public IP"
  value       = google_sql_database_instance.postgres.public_ip_address
  sensitive   = true
}

output "artifact_registry_url" {
  description = "Artifact Registry repository URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.repository_id}"
}

output "load_balancer_ip" {
  description = "Static IP voor Load Balancer"
  value       = google_compute_global_address.lb_ip.address
}

output "gke_service_account_email" {
  description = "GKE Service Account email"
  value       = google_service_account.gke_service_account.email
}

# Kubectl commando om te connecteren met cluster
output "kubectl_connection_command" {
  description = "Command om kubectl te configureren voor deze cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${google_container_cluster.primary.location} --project ${var.project_id}"
}
