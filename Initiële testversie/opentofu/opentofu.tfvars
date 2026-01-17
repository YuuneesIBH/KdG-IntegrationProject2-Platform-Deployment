project_id  = "ip2-devops4-479310"
region      = "europe-west1"
environment = "dev"

# Network configuratie
subnet_cidr    = "10.0.0.0/24"
pods_cidr      = "10.1.0.0/16"
services_cidr  = "10.2.0.0/16"

# GKE Cluster configuratie
node_count           = 1
min_node_count       = 1
max_node_count       = 5
machine_type         = "e2-micro"
use_preemptible_nodes = true

# Database configuratie
db_tier              = "db-f1-micro"
db_availability_type = "ZONAL"
db_disk_size         = 10
db_username          = "postgres"
db_password          = "postgres"  # ⚠️ Verander voor productie
db_deletion_protection = false  # false voor dev (makkelijk cleanup)
