#!/bin/bash

# Quick Deployment Fixes Summary Script
# Run this after deploying to verify all fixes are applied

echo "════════════════════════════════════════"
echo "   Team12 Deployment Fixes Verification"
echo "════════════════════════════════════════"
echo ""

# Check if connected to cluster
if ! kubectl cluster-info &>/dev/null; then
  echo "❌ Not connected to Kubernetes cluster"
  exit 1
fi

echo "✓ Connected to cluster"
echo ""

# 1. Check Backend Memory Limits
echo "1. Backend Memory Configuration:"
PLATFORM_MEM=$(kubectl get deployment platform-backend-deployment -n bordspelplatform-12 -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null)
TICTACTOE_MEM=$(kubectl get deployment tic-tac-toe-backend-deployment -n bordspelplatform-12 -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null)

if [ "$PLATFORM_MEM" = "4Gi" ]; then
  echo "   ✓ Platform backend: $PLATFORM_MEM (correct)"
else
  echo "   ✗ Platform backend: $PLATFORM_MEM (should be 4Gi)"
fi

if [ "$TICTACTOE_MEM" = "4Gi" ]; then
  echo "   ✓ Tic-tac-toe backend: $TICTACTOE_MEM (correct)"
else
  echo "   ✗ Tic-tac-toe backend: $TICTACTOE_MEM (should be 4Gi)"
fi

echo ""

# 2. Check RabbitMQ Probe Timeout
echo "2. RabbitMQ Probe Configuration:"
RABBITMQ_TIMEOUT=$(kubectl get deployment rabbitmq-deployment -n bordspelplatform-12 -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.timeoutSeconds}' 2>/dev/null)

if [ "$RABBITMQ_TIMEOUT" = "5" ]; then
  echo "   ✓ RabbitMQ probe timeout: ${RABBITMQ_TIMEOUT}s (correct)"
else
  echo "   ✗ RabbitMQ probe timeout: ${RABBITMQ_TIMEOUT}s (should be 5s)"
fi

echo ""

# 3. Check Keycloak Memory
echo "3. Keycloak Resource Configuration:"
KEYCLOAK_MEM=$(kubectl get deployment keycloak-deployment -n bordspelplatform-12 -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null)

if [ "$KEYCLOAK_MEM" = "2Gi" ]; then
  echo "   ✓ Keycloak memory: $KEYCLOAK_MEM (correct)"
else
  echo "   ✗ Keycloak memory: $KEYCLOAK_MEM (should be 2Gi)"
fi

echo ""

# 4. Check Database Schemas
echo "4. Database Schema Verification:"
POSTGRES_POD=$(kubectl get pods -n bordspelplatform-12 -l app=postgres -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -n "$POSTGRES_POD" ]; then
  DB_USER=$(kubectl get configmap platform-config -n bordspelplatform-12 -o jsonpath='{.data.DB_USER}' 2>/dev/null || echo "user")
  SCHEMAS=$(kubectl exec -n bordspelplatform-12 "$POSTGRES_POD" -- sh -c "psql -U $DB_USER -d postgres -c '\dn'" 2>/dev/null | grep -E "platform|tictactoe" | wc -l)
  
  if [ "$SCHEMAS" -ge 2 ]; then
    echo "   ✓ Database schemas exist (platform + tictactoe)"
  else
    echo "   ✗ Database schemas missing (run Step 4.7 from deploy script)"
  fi
else
  echo "   ✗ PostgreSQL pod not found"
fi

echo ""

# 5. Check GitLab Registry Secret
echo "5. GitLab Registry Authentication:"
GITLAB_SECRET=$(kubectl get secret gitlab-registry -n bordspelplatform-12 2>/dev/null | grep gitlab-registry | wc -l)

if [ "$GITLAB_SECRET" -eq 1 ]; then
  echo "   ✓ GitLab registry secret exists"
else
  echo "   ✗ GitLab registry secret missing (run setup-gitlab-registry.sh)"
fi

echo ""

# 6. Check GCP Credentials in Secret
echo "6. GCP Credentials Configuration:"
GCP_CREDS=$(kubectl get secret platform-secrets -n bordspelplatform-12 -o jsonpath='{.data.GCP_CREDENTIALS}' 2>/dev/null | wc -c)

if [ "$GCP_CREDS" -gt 100 ]; then
  echo "   ✓ GCP credentials exist in platform-secrets"
else
  echo "   ✗ GCP credentials missing (run Step 4.6 from deploy script)"
fi

echo ""

# 7. Check External IP
echo "7. External IP Configuration:"
EXTERNAL_IP=$(kubectl get svc nginx-gateway-service -n bordspelplatform-12 -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

if [ -n "$EXTERNAL_IP" ]; then
  echo "   ✓ External IP assigned: $EXTERNAL_IP"
  
  # Check if ConfigMap has correct IP
  CONFIGMAP_IP=$(kubectl get configmap platform-config -n bordspelplatform-12 -o jsonpath='{.data.VITE_KC_URL}' 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
  
  if [ "$CONFIGMAP_IP" = "$EXTERNAL_IP" ]; then
    echo "   ✓ ConfigMap updated with correct IP"
  else
    echo "   ✗ ConfigMap has wrong IP: $CONFIGMAP_IP (run update-external-ip.sh)"
  fi
else
  echo "   ✗ External IP not assigned yet (LoadBalancer still provisioning)"
fi

echo ""

# 8. Pod Status Summary
echo "8. Critical Services Status:"
for app in nginx-gateway platform-frontend platform-backend postgres redis rabbitmq; do
  READY=$(kubectl get pods -n bordspelplatform-12 -l app=$app -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
  
  if [ "$READY" = "true" ]; then
    echo "   ✓ $app"
  else
    echo "   ✗ $app (not ready)"
  fi
done

echo ""
echo "9. Optional Services Status:"
for app in keycloak tictactoe-backend elasticsearch kibana; do
  READY=$(kubectl get pods -n bordspelplatform-12 -l app=$app -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
  POD_NAME=$(kubectl get pods -n bordspelplatform-12 -l app=$app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  
  if [ "$READY" = "true" ]; then
    echo "   ✓ $app"
  elif [ -n "$POD_NAME" ]; then
    RESTARTS=$(kubectl get pod -n bordspelplatform-12 "$POD_NAME" -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null)
    echo "   ⚠ $app (restarts: $RESTARTS)"
  else
    echo "   ✗ $app (not found)"
  fi
done

echo ""
echo "════════════════════════════════════════"
echo "For detailed status: kubectl get pods -n bordspelplatform-12"
echo "For logs: kubectl logs -n bordspelplatform-12 <pod-name>"
echo "════════════════════════════════════════"
