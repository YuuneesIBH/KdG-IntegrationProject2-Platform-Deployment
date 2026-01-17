#!/bin/bash

# Setup GitLab Registry Pull Secret for Team 8 Kubernetes

set -e

NAMESPACE="bordspelplatform-8"
REGISTRY_URL="registry.gitlab.com"
GITLAB_USERNAME="${GITLAB_USERNAME:-}"
GITLAB_TOKEN="${GITLAB_TOKEN:-}"
GITLAB_EMAIL="${GITLAB_EMAIL:-}"

echo "========================================="
echo "Team 8 GitLab Registry Setup"
echo "========================================="
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "ERROR: kubectl is not installed or not in PATH"
    exit 1
fi

# Check if namespace exists
if ! kubectl get namespace $NAMESPACE &>/dev/null; then
    echo "Creating namespace $NAMESPACE..."
    kubectl create namespace $NAMESPACE
fi

# Prompt for credentials if not set
if [ -z "$GITLAB_USERNAME" ]; then
    read -p "GitLab Username: " GITLAB_USERNAME
fi

if [ -z "$GITLAB_TOKEN" ]; then
    read -sp "GitLab Personal Access Token (with read_registry scope): " GITLAB_TOKEN
    echo ""
fi

if [ -z "$GITLAB_EMAIL" ]; then
    read -p "Email: " GITLAB_EMAIL
fi

echo ""
echo "Creating docker registry secret..."
kubectl create secret docker-registry gitlab-registry \
  --docker-server=$REGISTRY_URL \
  --docker-username=$GITLAB_USERNAME \
  --docker-password=$GITLAB_TOKEN \
  --docker-email=$GITLAB_EMAIL \
  -n $NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "✅ GitLab registry secret created/updated successfully!"
echo ""
echo "The following secret is now available in namespace '$NAMESPACE':"
kubectl get secret gitlab-registry -n $NAMESPACE

echo ""
echo "This secret will be used by pods to pull images from GitLab Container Registry."
echo ""
