#!/bin/bash
# Team 4 AI Platform - Deployment Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../Terraform"
KUBERNETES_DIR="$SCRIPT_DIR/../Kubernetes"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}   Team 4 AI Platform - Deployment${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# Check prerequisites
command -v tofu >/dev/null 2>&1 || { echo -e "${RED}OpenTofu is required but not installed.${NC}"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}kubectl is required but not installed.${NC}"; exit 1; }
command -v gcloud >/dev/null 2>&1 || { echo -e "${RED}gcloud is required but not installed.${NC}"; exit 1; }

# Step 1: Deploy Infrastructure with OpenTofu
echo -e "${YELLOW}[1/5] Deploying GKE infrastructure with OpenTofu...${NC}"
cd "$TERRAFORM_DIR"

tofu init -upgrade
tofu plan -out=tfplan
tofu apply tfplan

# Get cluster info
CLUSTER_NAME=$(tofu output -raw kubernetes_cluster_name 2>/dev/null || echo "ai-platform-team4")
ZONE=$(grep 'zone' terraform.tfvars | cut -d'=' -f2 | tr -d ' "' || echo "europe-west1-b")
PROJECT_ID=$(tofu output -raw project_id 2>/dev/null || grep 'project_id' terraform.tfvars | cut -d'=' -f2 | tr -d ' "')

echo ""
echo -e "${YELLOW}[2/5] Configuring kubectl...${NC}"
gcloud container clusters get-credentials "$CLUSTER_NAME" --zone "$ZONE" --project "$PROJECT_ID"

# Step 2: Setup GitLab Registry Secret
echo ""
echo -e "${YELLOW}[3/5] Setting up GitLab registry credentials...${NC}"
echo "Please enter your GitLab credentials for pulling container images:"
read -p "GitLab Username: " GITLAB_USER
read -sp "GitLab Access Token (with read_registry scope): " GITLAB_TOKEN
echo ""

# Create namespace first
kubectl apply -f "$KUBERNETES_DIR/00-namespace-configmap-secrets.yaml"

# Create GitLab registry secret
kubectl create secret docker-registry gitlab-registry \
  --namespace=ai-platform-team4 \
  --docker-server=registry.gitlab.com \
  --docker-username="$GITLAB_USER" \
  --docker-password="$GITLAB_TOKEN" \
  --docker-email="$GITLAB_USER@gitlab.com" \
  --dry-run=client -o yaml | kubectl apply -f -

# Step 3: Deploy Kubernetes resources
echo ""
echo -e "${YELLOW}[4/5] Deploying Kubernetes resources...${NC}"
kubectl apply -f "$KUBERNETES_DIR/00-namespace-configmap-secrets.yaml"
kubectl apply -f "$KUBERNETES_DIR/01-infrastructure.yaml"

echo "Waiting for infrastructure to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/postgres-deployment -n ai-platform-team4 || true
kubectl wait --for=condition=available --timeout=300s deployment/ollama-deployment -n ai-platform-team4 || true

kubectl apply -f "$KUBERNETES_DIR/02-services.yaml"
kubectl apply -f "$KUBERNETES_DIR/03-gateway.yaml"

# Step 4: Pull Ollama models (optional, takes time)
echo ""
read -p "Do you want to pull Ollama models now? (y/n): " PULL_MODELS
if [[ "$PULL_MODELS" =~ ^[Yy]$ ]]; then
  echo "Pulling Ollama models (this may take a while)..."
  kubectl apply -f "$KUBERNETES_DIR/04-ollama-model-puller.yaml"
fi

# Step 5: Show status
echo ""
echo -e "${YELLOW}[5/5] Deployment complete! Checking status...${NC}"
echo ""
kubectl get pods -n ai-platform-team4
echo ""
kubectl get svc -n ai-platform-team4

# Get external IP
echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}External Access:${NC}"
EXTERNAL_IP=$(kubectl get svc api-gateway -n ai-platform-team4 -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
echo "API Gateway: http://$EXTERNAL_IP"
echo ""
echo "Endpoints:"
echo "  - Chatbot/RAG API: http://$EXTERNAL_IP/api/rag/"
echo "  - AI Player API:   http://$EXTERNAL_IP/api/ai-player/"
echo "  - Ollama:          http://$EXTERNAL_IP/ollama/"
echo "  - Health Check:    http://$EXTERNAL_IP/health"
echo -e "${GREEN}════════════════════════════════════════${NC}"
