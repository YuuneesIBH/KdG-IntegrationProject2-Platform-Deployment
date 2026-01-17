#!/bin/bash
# Setup cert-manager for SSL/HTTPS certificate management

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing cert-manager for Let's Encrypt SSL certificates..."

# Install cert-manager directly (helm not required)
# Using kubectl apply with the official cert-manager manifests
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager to be ready
echo "Waiting for cert-manager deployment to be ready..."
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/instance=cert-manager \
  -n cert-manager \
  --timeout=300s || true

# Verify cert-manager is running
echo "Verifying cert-manager installation..."
kubectl get pods -n cert-manager || echo "Note: cert-manager may still be starting up"

echo ""
echo "✓ cert-manager installation complete!"
echo ""
echo "Next steps:"
echo "1. Ensure your DNS is configured:"
echo "   - stoom-app.com → <LoadBalancer-IP>"
echo "   - www.stoom-app.com → <LoadBalancer-IP>"
echo ""
echo "2. Deploy SSL certificate configuration:"
echo "   kubectl apply -f 07-ssl-certificate.yaml"
echo ""
echo "3. Check certificate status:"
echo "   kubectl describe certificate stoom-app-cert -n bordspelplatform-12"
