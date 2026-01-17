#!/bin/bash
# Team 4 AI Platform - Teardown Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../Terraform"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}   Team 4 AI Platform - Teardown${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

read -p "Are you sure you want to destroy all Team 4 resources? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  echo -e "${YELLOW}Aborted.${NC}"
  exit 0
fi

# Delete Kubernetes resources first
echo ""
echo -e "${YELLOW}[1/2] Deleting Kubernetes resources...${NC}"
kubectl delete namespace ai-platform-team4 --ignore-not-found=true || true

# Destroy infrastructure
echo ""
echo -e "${YELLOW}[2/2] Destroying GKE infrastructure with OpenTofu...${NC}"
cd "$TERRAFORM_DIR"

if [[ -f "terraform.tfstate" ]]; then
  tofu destroy -auto-approve
else
  echo -e "${YELLOW}No Terraform state found. Skipping infrastructure destruction.${NC}"
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}Team 4 teardown complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
