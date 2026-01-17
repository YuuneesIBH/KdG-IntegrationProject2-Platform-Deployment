#!/usr/bin/env bash
set -euo pipefail

# GitLab Deploy Token credentials (supply via env or prompt)
GITLAB_DEPLOY_TOKEN_USERNAME="${GITLAB_DEPLOY_TOKEN_USERNAME:-}"
GITLAB_DEPLOY_TOKEN_PASSWORD="${GITLAB_DEPLOY_TOKEN_PASSWORD:-}"

# Kubernetes settings
NAMESPACE="bordspelplatform-8"
SECRET_NAME="gitlab-registry"

echo "Creating GitLab registry pull secret in namespace: $NAMESPACE"

# Prompt for credentials if not provided by environment
if [[ -z "$GITLAB_DEPLOY_TOKEN_USERNAME" ]]; then
    read -r -p "Enter GitLab deploy token username: " GITLAB_DEPLOY_TOKEN_USERNAME
fi

if [[ -z "$GITLAB_DEPLOY_TOKEN_PASSWORD" ]]; then
    read -r -s -p "Enter GitLab deploy token password (hidden): " GITLAB_DEPLOY_TOKEN_PASSWORD
    echo ""
fi

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
