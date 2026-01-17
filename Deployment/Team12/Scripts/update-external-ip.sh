#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

NAMESPACE="bordspelplatform-12"
SERVICE_NAME="nginx-gateway-service"
CONFIGMAP_FILE="/home/kali/Downloads/IntegrationProject2-Deployment-main/Team12/Kubernetes/00-namespace-configmap-secrets.yaml"

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

# NOTE: ConfigMap already has correct domain URLs (https://stoom-app.com)
# We only need to store the external IP for reference/logging purposes
# Do NOT patch ConfigMap - it would overwrite domain with IP!
echo "✓ External IP detected: $EXTERNAL_IP (ConfigMap already has correct domain URLs)"
echo "  ConfigMap uses: https://stoom-app.com (no patching needed)"

# Also refresh Cloud DNS A records (if script exists)
if [[ -f "$SCRIPT_DIR/setup-cloud-dns.sh" ]]; then
  echo "Updating Cloud DNS A records for stoom-app.com..."
  "$SCRIPT_DIR/setup-cloud-dns.sh" --domain stoom-app.com --ip "$EXTERNAL_IP" || echo "Warning: DNS update failed (continuing)"
fi

# NOTE: During initial deployment, pods are still starting and will pick up ConfigMap automatically.
# Skip restart when caller sets FIRST_DEPLOY=1; otherwise only restart if pods are already running
if [[ "${FIRST_DEPLOY:-0}" == "1" ]]; then
  echo "Initial deployment detected, skipping restart (pods will pick up config on first start)"
else
  RUNNING_PODS=$(kubectl get pods -n "$NAMESPACE" -l app=platform-backend --field-selector=status.phase=Running 2>/dev/null | grep -c "Running" || echo "0")

  if [ "$RUNNING_PODS" -gt "0" ]; then
    echo "Deployments already running, restarting to pick up new IP..."
    kubectl rollout restart deployment \
      platform-frontend-deployment \
      platform-backend-deployment \
      tic-tac-toe-backend-deployment \
      keycloak-deployment \
      -n "$NAMESPACE"
  else
    echo "Initial deployment: pods are starting and will use correct config automatically (no restart needed)"
  fi
fi

echo ""
echo "✓ Done! External IP $EXTERNAL_IP is now configured everywhere."
echo ""
echo "Access URLs:"
echo "  Platform Frontend:    http://$EXTERNAL_IP/"
echo "  Keycloak Admin:       http://$EXTERNAL_IP/auth/admin"
echo "  Tic-Tac-Toe:         http://$EXTERNAL_IP/play/tictactoe/"
echo "  Chess (Blitz):        http://$EXTERNAL_IP/play/blitz-chess"
echo "  Platform Backend API: http://$EXTERNAL_IP/api/"
echo "  RabbitMQ Management:  http://$EXTERNAL_IP/rabbitmq/"
echo "  Kibana:              http://$EXTERNAL_IP/kibana/"
echo ""
echo "With SSL/HTTPS (stoom-app.com):"
echo "  ✓ DNS Configuration Needed:"
echo "    - Add A record: stoom-app.com → $EXTERNAL_IP"
echo "    - Add A record: www.stoom-app.com → $EXTERNAL_IP"
echo ""
echo "  Then access via: https://stoom-app.com"
echo "  Certificate status: kubectl describe certificate stoom-app-cert -n bordspelplatform-12"
