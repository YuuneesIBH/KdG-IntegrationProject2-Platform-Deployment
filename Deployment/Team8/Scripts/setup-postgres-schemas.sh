#!/bin/bash

# Setup PostgreSQL Schemas for Team 8
# Creates required schemas (backend_platform, backend_blokus) in PostgreSQL
# Usage: ./setup-postgres-schemas.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NAMESPACE="bordspelplatform-8"

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}   PostgreSQL Schema Setup for Team 8   ${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
  echo -e "${RED}Error: kubectl not found${NC}"
  echo -e "${YELLOW}Please install kubectl first${NC}"
  exit 1
fi

# Check if PostgreSQL pod is running
echo -e "${YELLOW}✓ Checking PostgreSQL pod status...${NC}"
POSTGRES_POD=$(kubectl get pods -n "$NAMESPACE" -l app=postgres -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$POSTGRES_POD" ]; then
  echo -e "${RED}Error: PostgreSQL pod not found in namespace '$NAMESPACE'${NC}"
  echo -e "${YELLOW}Available pods:${NC}"
  kubectl get pods -n "$NAMESPACE" | head -10
  exit 1
fi

echo -e "${GREEN}✓ Found PostgreSQL pod: $POSTGRES_POD${NC}"
echo ""

# Get database user and password from ConfigMap/Secret
echo -e "${YELLOW}✓ Retrieving database credentials...${NC}"
DB_USER=$(kubectl get configmap platform-config -n "$NAMESPACE" -o jsonpath='{.data.DB_USER}' 2>/dev/null || echo "user")
DB_PASS=$(kubectl get secret platform-secrets -n "$NAMESPACE" -o jsonpath='{.data.DB_PASS}' 2>/dev/null | base64 -d || echo "password")

echo -e "${GREEN}✓ Using database user: $DB_USER${NC}"
echo ""

# Create schemas
echo -e "${YELLOW}✓ Creating PostgreSQL schemas...${NC}"

# Platform schema
echo -e "${YELLOW}  Creating schema: backend_platform${NC}"
kubectl exec -n "$NAMESPACE" "$POSTGRES_POD" -- psql -U "$DB_USER" -d postgres \
  -c 'CREATE SCHEMA IF NOT EXISTS backend_platform; GRANT ALL ON SCHEMA backend_platform TO "'"$DB_USER"'";' 2>/dev/null && \
  echo -e "${GREEN}  ✓ backend_platform schema created${NC}" || \
  echo -e "${YELLOW}  ⚠ backend_platform schema already exists${NC}"

# Blokus schema  
echo -e "${YELLOW}  Creating schema: backend_blokus${NC}"
kubectl exec -n "$NAMESPACE" "$POSTGRES_POD" -- psql -U "$DB_USER" -d postgres \
  -c 'CREATE SCHEMA IF NOT EXISTS backend_blokus; GRANT ALL ON SCHEMA backend_blokus TO "'"$DB_USER"'";' 2>/dev/null && \
  echo -e "${GREEN}  ✓ backend_blokus schema created${NC}" || \
  echo -e "${YELLOW}  ⚠ backend_blokus schema already exists${NC}"

echo ""

# Verify schemas
echo -e "${YELLOW}✓ Verifying created schemas...${NC}"
echo ""

echo -e "${BLUE}Schemas in 'postgres' database:${NC}"
kubectl exec -n "$NAMESPACE" "$POSTGRES_POD" -- psql -U "$DB_USER" -d postgres -c "\dn" 2>/dev/null | grep -E "backend_platform|backend_blokus|public" || true

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ PostgreSQL schemas setup completed${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "${BLUE}1. Restart backend deployments:${NC}"
echo -e "   kubectl rollout restart deployment/platform-backend-deployment -n $NAMESPACE"
echo -e "   kubectl rollout restart deployment/blokus-backend-deployment -n $NAMESPACE"
echo ""
echo -e "${BLUE}2. Check pod status:${NC}"
echo -e "   kubectl get pods -n $NAMESPACE"
echo ""