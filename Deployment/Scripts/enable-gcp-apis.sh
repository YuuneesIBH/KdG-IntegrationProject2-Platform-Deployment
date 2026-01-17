#!/bin/bash

# Enable Required GCP APIs for Team 12 Deployment

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}   Enabling GCP APIs${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# Get project ID
echo -e "${YELLOW}Please enter your GCP Project ID:${NC}"
read -p "> " PROJECT_ID

if [ -z "$PROJECT_ID" ]; then
  echo -e "${RED}Error: Project ID cannot be empty${NC}"
  exit 1
fi

echo -e "${GREEN}Using GCP Project: $PROJECT_ID${NC}"
echo ""

# Set the project
echo -e "${YELLOW}Setting GCP project...${NC}"
gcloud config set project "$PROJECT_ID" &>/dev/null || {
  echo -e "${RED}Failed to set GCP project${NC}"
  exit 1
}

echo ""

# List of required APIs
APIS=(
  "compute.googleapis.com"              # Google Compute Engine (VPC, Firewall, etc.)
  "container.googleapis.com"            # Google Kubernetes Engine
  "sqladmin.googleapis.com"             # Cloud SQL Admin
  "storage-api.googleapis.com"          # Cloud Storage
  "cloudresourcemanager.googleapis.com" # Cloud Resource Manager
  "servicenetworking.googleapis.com"    # Service Networking
  "cloudkms.googleapis.com"             # Cloud KMS
  "iam.googleapis.com"                  # Identity and Access Management
  "serviceusage.googleapis.com"         # Service Usage
)

echo -e "${YELLOW}Enabling required APIs...${NC}"
echo ""

for api in "${APIS[@]}"; do
  echo -e "${YELLOW}✓ Enabling: $api${NC}"
  gcloud services enable "$api" --quiet 2>/dev/null || {
    echo -e "${YELLOW}  Warning: Could not enable $api (may already be enabled)${NC}"
  }
done

echo ""

# Grant necessary IAM roles to service account
echo -e "${YELLOW}Granting IAM roles to service account...${NC}"
echo ""

SA_EMAIL="integration-deployment@${PROJECT_ID}.iam.gserviceaccount.com"

ROLES=(
  "roles/container.admin"              # GKE cluster management
  "roles/compute.admin"                # Compute resources
  "roles/cloudsql.admin"               # Cloud SQL
  "roles/storage.admin"                # Cloud Storage
  "roles/iam.securityAdmin"            # IAM management
  "roles/servicenetworking.networksAdmin" # Service networking for VPC peering
  "roles/compute.networkAdmin"         # Network admin for VPC peering
  "roles/resourcemanager.projectIamAdmin" # Project IAM management
)

for role in "${ROLES[@]}"; do
  echo -e "${YELLOW}✓ Granting: $role${NC}"
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="$role" \
    --quiet 2>/dev/null || {
    echo -e "${YELLOW}  Warning: Could not grant $role (may already be assigned)${NC}"
  }
done

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ All required APIs and IAM roles configured${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}You can now proceed with deployment:${NC}"
echo -e "${GREEN}./Scripts/main.sh${NC}"
