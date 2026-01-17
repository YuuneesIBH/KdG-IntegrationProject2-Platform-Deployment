#!/bin/bash

# Team 8 (Blokus) Deployment Script
# Deploys ONLY to namespace bordspelplatform-8
# Does NOT touch Terraform or any other team's resources

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$SCRIPT_DIR/../Kubernetes"
NAMESPACE="bordspelplatform-8"

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}   Deploying Team 8 - Blokus Platform   ${NC}"
echo -e "${BLUE}   Namespace: ${NAMESPACE}              ${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

# Check cluster connection
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
    echo -e "${YELLOW}Make sure you have run: gcloud container clusters get-credentials <cluster-name> --zone <zone> --project <project>${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Connected to Kubernetes cluster${NC}"

# Safety check: verify we're not accidentally deploying to Team 12's namespace
CURRENT_NAMESPACES=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
if echo "$CURRENT_NAMESPACES" | grep -q "bordspelplatform-12"; then
    echo -e "${YELLOW}⚠️  Team 12 namespace detected. Team 8 will deploy to separate namespace: ${NAMESPACE}${NC}"
fi

echo ""

# Deploy in order
echo -e "${YELLOW}Step 1: Creating namespace, configmaps, and secrets...${NC}"
kubectl apply -f "$K8S_DIR/00-namespace-configmap-secrets.yaml"
sleep 2

# Ensure GitLab registry pull secret exists
if ! kubectl get secret gitlab-registry -n "$NAMESPACE" &>/dev/null; then
    echo -e "${YELLOW}GitLab registry secret not found. Running setup...${NC}"
    if [ -f "$K8S_DIR/setup-gitlab-registry.sh" ]; then
        bash "$K8S_DIR/setup-gitlab-registry.sh" || {
            echo -e "${RED}Failed to set up GitLab registry secret. Pods may fail to pull images.${NC}"
            echo -e "${YELLOW}You can set it up manually later with: ${K8S_DIR}/setup-gitlab-registry.sh${NC}"
        }
    fi
fi

echo -e "${YELLOW}Step 2: Deploying infrastructure (PostgreSQL, MySQL, Redis, RabbitMQ, Keycloak)...${NC}"
kubectl apply -f "$K8S_DIR/01-infrastructure.yaml"
echo -e "${BLUE}Waiting for infrastructure to be ready...${NC}"
sleep 30

# Wait for postgres
echo -e "${YELLOW}Waiting for PostgreSQL...${NC}"
kubectl wait --for=condition=ready pod -l app=postgres -n "$NAMESPACE" --timeout=300s || true

# Wait for MySQL (for Keycloak)
echo -e "${YELLOW}Waiting for MySQL...${NC}"
kubectl wait --for=condition=ready pod -l app=mysql -n "$NAMESPACE" --timeout=300s || true

# Wait for RabbitMQ
echo -e "${YELLOW}Waiting for RabbitMQ...${NC}"
kubectl wait --for=condition=ready pod -l app=rabbitmq -n "$NAMESPACE" --timeout=300s || true

# Wait for Keycloak
echo -e "${YELLOW}Waiting for Keycloak...${NC}"
kubectl wait --for=condition=ready pod -l app=keycloak -n "$NAMESPACE" --timeout=300s || true

echo -e "${YELLOW}Step 3: Deploying ELK Stack (optional)...${NC}"
if [ -f "$K8S_DIR/02-elk-stack.yaml" ]; then
    kubectl apply -f "$K8S_DIR/02-elk-stack.yaml" || echo -e "${YELLOW}ELK stack deployment skipped${NC}"
fi
sleep 5

echo -e "${YELLOW}Step 4: Deploying Platform Frontend and Backend...${NC}"
kubectl apply -f "$K8S_DIR/02-platform-frontend-backend.yaml"
sleep 5

echo -e "${YELLOW}Step 5: Deploying Blokus Game...${NC}"
kubectl apply -f "$K8S_DIR/03-game-blokus.yaml"
sleep 5

echo -e "${YELLOW}Step 6: Deploying API Gateway...${NC}"
kubectl apply -f "$K8S_DIR/04-gateway.yaml"

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}   Deployment Complete!                 ${NC}"
echo -e "${GREEN}   Namespace: ${NAMESPACE}              ${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""

# Get external IP
echo -e "${YELLOW}Waiting for external IP...${NC}"
sleep 10
EXTERNAL_IP=$(kubectl get svc nginx-gateway-service -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")

if [ "$EXTERNAL_IP" != "pending" ] && [ -n "$EXTERNAL_IP" ]; then
    echo -e "${GREEN}External IP: ${EXTERNAL_IP}${NC}"
    echo ""
    echo -e "${BLUE}Access the platform at: http://${EXTERNAL_IP}/${NC}"
    echo -e "${BLUE}Access Blokus at: http://${EXTERNAL_IP}/blokus/${NC}"
    echo -e "${BLUE}Access Keycloak at: http://${EXTERNAL_IP}:8180/ (or via /auth/)${NC}"
else
    echo -e "${YELLOW}External IP is still pending. Run this command to check:${NC}"
    echo "kubectl get svc nginx-gateway-service -n $NAMESPACE"
fi

echo ""
echo -e "${BLUE}Check deployment status with:${NC}"
echo "kubectl get pods -n $NAMESPACE"
echo ""
