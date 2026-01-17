# GCS Bucket
resource "google_storage_bucket" "stoom_images" {
  name          = "stoom-images-team12-${data.google_client_config.default.project}"
  location      = var.region
  force_destroy = false

  versioning {
    enabled = true
  }

  uniform_bucket_level_access = true
}
