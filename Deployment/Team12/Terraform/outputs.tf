output "region" {
  value       = var.region
  description = "GCP region"
}

output "project_id" {
  value       = var.project_id
  description = "GCP project ID"
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_endpoint" {
  value       = google_container_cluster.primary.endpoint
  description = "GKE Cluster endpoint"
  sensitive   = true
}

output "cluster_ca_certificate" {
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  description = "Cluster ca certificate (base64 encoded)"
  sensitive   = true
}

output "ingress_ip" {
  value       = google_compute_address.ingress.address
  description = "External IP for ingress"
}

output "gcs_bucket" {
  value       = google_storage_bucket.stoom_images.name
  description = "GCS bucket name for images"
}
