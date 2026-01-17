#!/bin/bash

# GCP Service Account Creation Script
# Creates a service account with necessary permissions for Kubernetes cluster management and Cloud SQL

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ID="${1:-}"
SERVICE_ACCOUNT_NAME="${2:-integration-deployment}"
KEY_FILE_PATH="${3:-./credentials.json}"

# Validate inputs
if [ -z "$PROJECT_ID" ]; then
  echo -e "${RED}Error: PROJECT_ID is required${NC}"
  echo "Usage: $0 <PROJECT_ID> [SERVICE_ACCOUNT_NAME] [KEY_FILE_PATH]"
  echo "Example: $0 my-gcp-project integration-deployment ./credentials.json"
  exit 1
fi

echo -e "${BLUE}=== GCP Service Account Creation ===${NC}"
echo -e "${YELLOW}Project ID: ${GREEN}$PROJECT_ID${NC}"
echo -e "${YELLOW}Service Account: ${GREEN}$SERVICE_ACCOUNT_NAME${NC}"
echo -e "${YELLOW}Key File: ${GREEN}$KEY_FILE_PATH${NC}"
echo ""

# Set the project
echo -e "${YELLOW}Setting GCP project...${NC}"
gcloud config set project "$PROJECT_ID" &>/dev/null || {
  echo -e "${RED}Failed to set GCP project. Make sure you're authenticated with: gcloud auth login${NC}"
  exit 1
}

# Check if service account already exists
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
echo -e "${YELLOW}Checking if service account exists...${NC}"

if gcloud iam service-accounts describe "$SERVICE_ACCOUNT_EMAIL" &>/dev/null; then
  echo -e "${GREEN}✓ Service account already exists: $SERVICE_ACCOUNT_EMAIL${NC}"
else
  echo -e "${YELLOW}Creating service account: $SERVICE_ACCOUNT_NAME${NC}"
  gcloud iam service-accounts create "$SERVICE_ACCOUNT_NAME" \
    --display-name="Service Account for Integration Deployment" \
    --description="Used for deploying Kubernetes clusters and Cloud SQL resources" &>/dev/null || {
    echo -e "${RED}Failed to create service account${NC}"
    exit 1
  }
  echo -e "${GREEN}✓ Service account created successfully${NC}"
fi

# Grant necessary roles
echo -e "${YELLOW}Granting IAM roles...${NC}"

ROLES=(
  "roles/container.developer"              # Kubernetes cluster management
  "roles/cloudsql.client"                  # Cloud SQL access
  "roles/compute.networkViewer"            # Network viewing
  "roles/iam.serviceAccountUser"           # Service account usage
  "roles/storage.admin"                    # Storage access for state files
)

for role in "${ROLES[@]}"; do
  echo -e "${YELLOW}✓ Adding: $role${NC}"
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
    --role="$role" \
    --quiet &>/dev/null || echo -e "${YELLOW}  Role might already be assigned${NC}"
done

# Create or regenerate key
echo -e "${YELLOW}Creating service account key...${NC}"

if [ -f "$KEY_FILE_PATH" ]; then
  echo -e "${YELLOW}Key file already exists at $KEY_FILE_PATH${NC}"
  read -p "Do you want to regenerate it? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}✓ Using existing key file${NC}"
  else
    gcloud iam service-accounts keys create "$KEY_FILE_PATH" \
      --iam-account="$SERVICE_ACCOUNT_EMAIL" &>/dev/null || {
      echo -e "${RED}Failed to create service account key${NC}"
      exit 1
    }
    echo -e "${GREEN}✓ New key created${NC}"
  fi
else
  gcloud iam service-accounts keys create "$KEY_FILE_PATH" \
    --iam-account="$SERVICE_ACCOUNT_EMAIL" &>/dev/null || {
    echo -e "${RED}Failed to create service account key${NC}"
    exit 1
  }
  echo -e "${GREEN}✓ Service account key created${NC}"
fi

# Set permissions on key file
chmod 600 "$KEY_FILE_PATH"

echo ""
echo -e "${GREEN}=== Service Account Setup Complete ===${NC}"
echo -e "${YELLOW}Service Account Email: ${GREEN}$SERVICE_ACCOUNT_EMAIL${NC}"
echo -e "${YELLOW}Key File Location: ${GREEN}$(cd "$(dirname "$KEY_FILE_PATH")" && pwd)/$(basename "$KEY_FILE_PATH")${NC}"
