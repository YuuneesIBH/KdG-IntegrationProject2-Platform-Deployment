#!/bin/bash

# Setup PostgreSQL Schemas for Team12
# Creates required schemas (platform, tictactoe, keycloak) in PostgreSQL
# Usage: ./setup-postgres-schemas.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NAMESPACE="bordspelplatform-12"

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}   PostgreSQL Schema Setup for Team12${NC}"
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
echo -e "${YELLOW}  Creating schema: platform${NC}"
kubectl exec -n "$NAMESPACE" "$POSTGRES_POD" -- psql -U "$DB_USER" -d postgres \
  -c 'CREATE SCHEMA IF NOT EXISTS platform; GRANT ALL ON SCHEMA platform TO "'"$DB_USER"'";' 2>/dev/null && \
  echo -e "${GREEN}  ✓ platform schema created${NC}" || \
  echo -e "${YELLOW}  ⚠ platform schema already exists${NC}"

# Tictactoe schema
echo -e "${YELLOW}  Creating schema: tictactoe${NC}"
kubectl exec -n "$NAMESPACE" "$POSTGRES_POD" -- psql -U "$DB_USER" -d postgres \
  -c 'CREATE SCHEMA IF NOT EXISTS tictactoe; GRANT ALL ON SCHEMA tictactoe TO "'"$DB_USER"'";' 2>/dev/null && \
  echo -e "${GREEN}  ✓ tictactoe schema created${NC}" || \
  echo -e "${YELLOW}  ⚠ tictactoe schema already exists${NC}"

# Keycloak schema
echo -e "${YELLOW}  Creating schema: keycloak_schema${NC}"
kubectl exec -n "$NAMESPACE" "$POSTGRES_POD" -- psql -U "$DB_USER" -d keycloak \
  -c 'CREATE SCHEMA IF NOT EXISTS keycloak_schema; GRANT ALL ON SCHEMA keycloak_schema TO "keycloak_user";' 2>/dev/null && \
  echo -e "${GREEN}  ✓ keycloak_schema created${NC}" || \
  echo -e "${YELLOW}  ⚠ keycloak_schema already exists${NC}"

echo ""

# Verify schemas
echo -e "${YELLOW}✓ Verifying created schemas...${NC}"
echo ""

echo -e "${BLUE}Schemas in 'postgres' database:${NC}"
kubectl exec -n "$NAMESPACE" "$POSTGRES_POD" -- psql -U "$DB_USER" -d postgres -c "\dn" 2>/dev/null | grep -E "platform|tictactoe|public" || true

echo ""
echo -e "${BLUE}Schemas in 'keycloak' database:${NC}"
kubectl exec -n "$NAMESPACE" "$POSTGRES_POD" -- psql -U "$DB_USER" -d keycloak -c "\dn" 2>/dev/null | grep -E "keycloak_schema|public" || true

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ PostgreSQL schemas setup completed${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "${BLUE}1. Restart backend deployments:${NC}"
echo -e "   kubectl rollout restart deployment/platform-backend-deployment -n $NAMESPACE"
echo -e "   kubectl rollout restart deployment/tic-tac-toe-backend-deployment -n $NAMESPACE"
echo ""
echo -e "${BLUE}2. Check pod status:${NC}"
echo -e "   kubectl get pods -n $NAMESPACE"
echo ""
