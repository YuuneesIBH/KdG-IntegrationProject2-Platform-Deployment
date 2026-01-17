#!/bin/bash
# Setup GitLab Registry Credentials for Team 4

NAMESPACE="ai-platform-team4"

echo "======================================"
echo "GitLab Registry Setup - Team 4"
echo "======================================"

# Check if namespace exists
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  echo "Creating namespace $NAMESPACE..."
  kubectl create namespace "$NAMESPACE"
fi

echo "Please enter your GitLab credentials:"
read -p "GitLab Username: " GITLAB_USER
read -sp "GitLab Access Token (with read_registry scope): " GITLAB_TOKEN
echo ""

# Create or update the secret
kubectl create secret docker-registry gitlab-registry \
  --namespace="$NAMESPACE" \
  --docker-server=registry.gitlab.com \
  --docker-username="$GITLAB_USER" \
  --docker-password="$GITLAB_TOKEN" \
  --docker-email="$GITLAB_USER@gitlab.com" \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "GitLab registry secret created/updated successfully!"
echo "You can now pull images from registry.gitlab.com"
