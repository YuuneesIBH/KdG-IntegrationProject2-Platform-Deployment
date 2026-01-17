#!/bin/bash

# Team 12 Teardown Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
TERRAFORM_DIR="$PROJECT_ROOT/Team12/Terraform"
KUBERNETES_DIR="$PROJECT_ROOT/Team12/Kubernetes"

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}   Destroying Team12${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# Confirmation
echo -e "${YELLOW}⚠️  This will destroy all Team12 resources!${NC}"
read -p "Type 'yes' to confirm destruction: " confirmation
if [ "$confirmation" != "yes" ]; then
  echo -e "${YELLOW}Destruction cancelled${NC}"
  exit 0
fi

echo ""

# Step 1: Remove Kubernetes resources
echo -e "${YELLOW}✓ Removing Team12 Kubernetes resources${NC}"
cd "$KUBERNETES_DIR"

for manifest in 07-ssl-certificate.yaml 06-game-chess.yaml 05-gateway.yaml 04-game-tic-tac-toe.yaml 03-platform-frontend-backend.yaml 02-elk-stack.yaml 01-infrastructure.yaml 00-namespace-configmap-secrets.yaml; do
  if [ -f "$manifest" ]; then
    echo -e "${YELLOW}  Removing: $manifest${NC}"
    kubectl delete -f "$manifest" --ignore-not-found=true 2>/dev/null || true
  fi
done

echo -e "${YELLOW}✓ Waiting for resources to be deleted${NC}"
sleep 10

echo ""

# Step 2: Destroy Terraform infrastructure
echo -e "${YELLOW}✓ Destroying Team12 GCP infrastructure via OpenTofu${NC}"
cd "$TERRAFORM_DIR"

if [ -f "tfplan" ]; then
  rm -f tfplan
fi

if [ ! -d ".terraform" ]; then
  echo -e "${YELLOW}  Initializing OpenTofu first${NC}"
  tofu init -upgrade || {
    echo -e "${YELLOW}  Warning: Could not initialize OpenTofu${NC}"
  }
fi

echo -e "${YELLOW}  Running: tofu destroy${NC}"
tofu destroy -auto-approve || {
  echo -e "${YELLOW}  Warning: Some resources may not have been destroyed${NC}"
}

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Team12 destruction completed${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
