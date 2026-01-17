#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load .env file
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
else
    echo "Error: .env file not found"
    echo "Create $SCRIPT_DIR/.env with:"
    echo "  GITLAB_DEPLOY_TOKEN_USERNAME=your-username"
    echo "  GITLAB_DEPLOY_TOKEN_PASSWORD=your-token"
    exit 1
fi

# Kubernetes settings
NAMESPACE="bordspelplatform-12"
SECRET_NAME="gitlab-registry"

echo "Creating GitLab registry pull secret in namespace: $NAMESPACE"

# Ensure namespace exists
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo "Creating namespace $NAMESPACE..."
    kubectl create namespace "$NAMESPACE"
fi

# Delete existing secret if present
kubectl delete secret "$SECRET_NAME" -n "$NAMESPACE" --ignore-not-found=true

# Create new docker-registry secret
kubectl create secret docker-registry "$SECRET_NAME" \
    --namespace="$NAMESPACE" \
    --docker-server=registry.gitlab.com \
    --docker-username="$GITLAB_DEPLOY_TOKEN_USERNAME" \
    --docker-password="$GITLAB_DEPLOY_TOKEN_PASSWORD"

echo "✓ Secret '$SECRET_NAME' created successfully"

# Patch default service account to use this secret
echo "Patching default service account to use pull secret..."
kubectl patch serviceaccount default \
    -n "$NAMESPACE" \
    -p '{"imagePullSecrets": [{"name": "'"$SECRET_NAME"'"}]}'

echo "✓ Default service account patched"
echo ""
echo "Done! All pods in namespace '$NAMESPACE' can now pull from GitLab registry."
echo "Existing pods need to be restarted to pick up the new secret."
