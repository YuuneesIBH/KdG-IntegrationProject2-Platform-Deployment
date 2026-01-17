#!/bin/bash

# Team 8 (Blokus) Teardown Script
# Removes ONLY namespace bordspelplatform-8
# Does NOT touch any other team's resources

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NAMESPACE="bordspelplatform-8"

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}   Destroying Team 8 - Blokus Platform  ${NC}"
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
    exit 1
fi

# Safety check: only delete Team 8 namespace
echo -e "${YELLOW}⚠️  WARNING: This will delete ALL resources in namespace: ${NAMESPACE}${NC}"
echo -e "${YELLOW}This will NOT affect any other namespaces (like bordspelplatform or bordspelplatform-12)${NC}"
echo ""
read -p "Are you sure? Type 'yes' to confirm: " confirmation

if [ "$confirmation" != "yes" ]; then
    echo -e "${YELLOW}Teardown cancelled${NC}"
    exit 0
fi

# Check if namespace exists
if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
    echo -e "${YELLOW}Namespace ${NAMESPACE} does not exist. Nothing to delete.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Deleting namespace ${NAMESPACE}...${NC}"
kubectl delete namespace "$NAMESPACE" --timeout=120s || {
    echo -e "${YELLOW}Timeout reached. Forcing deletion...${NC}"
    kubectl delete namespace "$NAMESPACE" --force --grace-period=0 2>/dev/null || true
}

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}   Team 8 Teardown Complete!            ${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
