#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="bordspelplatform-8"
SERVICE_NAME="nginx-gateway-service"
CONFIGMAP_FILE="../Kubernetes/00-namespace-configmap-secrets.yaml"

echo "Getting external IP from service $SERVICE_NAME..."

# Wait for external IP to be assigned
for i in {1..30}; do
  EXTERNAL_IP=$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
  
  if [[ -n "$EXTERNAL_IP" ]]; then
    echo "✓ External IP found: $EXTERNAL_IP"
    break
  fi
  
  echo "Waiting for external IP... ($i/30)"
  sleep 5
done

if [[ -z "$EXTERNAL_IP" ]]; then
  echo "ERROR: Could not get external IP after 150 seconds"
  exit 1
fi

# Update ConfigMap YAML file with external IP
echo "Updating ConfigMap file with external IP..."
sed -i "s|http://[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+/|http://$EXTERNAL_IP/|g" "$CONFIGMAP_FILE"
sed -i "s|http://<EXTERNAL_IP>/|http://$EXTERNAL_IP/|g" "$CONFIGMAP_FILE"

echo "✓ ConfigMap file updated"

# Apply the updated ConfigMap
echo "Applying updated ConfigMap..."
kubectl apply -f "$CONFIGMAP_FILE"

# Update ConfigMap directly in cluster (for immediate effect)
echo "Patching ConfigMap in cluster..."
kubectl patch configmap platform-config -n "$NAMESPACE" --type merge -p "{\"data\":{
  \"KEYCLOAK_URL\":\"http://$EXTERNAL_IP/auth\",
  \"KEYCLOAK_REALM\":\"boardgame-platform\",
  \"KEYCLOAK_CLIENT_ID\":\"react-client\"
}}"

echo "✓ ConfigMap patched in cluster"

# Restart deployments that use these env vars
echo "Restarting deployments to pick up new configuration..."
kubectl rollout restart deployment \
  platform-frontend-deployment \
  platform-backend-deployment \
  blokus-frontend-deployment \
  blokus-backend-deployment \
  keycloak-deployment \
  -n "$NAMESPACE"

echo ""
echo "✓ Done! External IP $EXTERNAL_IP is now configured everywhere."
echo ""
echo "Access URLs:"
echo "  Platform Frontend:    http://$EXTERNAL_IP/"
echo "  Keycloak Admin:       http://$EXTERNAL_IP/auth/admin"
echo "  Blokus Game:          http://$EXTERNAL_IP/blokus/"
echo "  Platform Backend API: http://$EXTERNAL_IP/api/"
echo "  Game Backend API:     http://$EXTERNAL_IP/api/games/"
echo "  RabbitMQ Management:  http://$EXTERNAL_IP/rabbitmq/"
echo "  Kibana:              http://$EXTERNAL_IP/kibana/"