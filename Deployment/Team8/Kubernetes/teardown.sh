#!/bin/bash

# Team 8 Kubernetes Teardown Script
# Removes all deployed components

set -e

NAMESPACE="bordspelplatform-8"

echo "========================================="
echo "Team 8 Kubernetes Teardown Script"
echo "========================================="
echo ""
echo "WARNING: This will delete all resources in namespace: $NAMESPACE"
read -p "Are you sure? (yes/no): " confirmation

if [ "$confirmation" != "yes" ]; then
    echo "Teardown cancelled."
    exit 0
fi

echo ""
echo "Deleting namespace $NAMESPACE and all its resources..."
kubectl delete namespace $NAMESPACE --ignore-not-found=true

echo ""
echo "========================================="
echo "Teardown Complete!"
echo "========================================="
echo ""
