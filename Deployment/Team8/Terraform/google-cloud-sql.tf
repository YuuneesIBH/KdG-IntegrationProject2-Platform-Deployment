// GCS bucket for game assets/uploads (fixed name)

resource "google_storage_bucket" "team8_game_bucket" {
	name                        = "dampf-app-team8-game-bucket"
	location                    = var.region
	storage_class               = "STANDARD"
	uniform_bucket_level_access = true

	versioning {
		enabled = false
	}

	lifecycle_rule {
		condition {
			age = 30
		}
		action {
			type = "Delete"
		}
	}

	force_destroy = true
}
