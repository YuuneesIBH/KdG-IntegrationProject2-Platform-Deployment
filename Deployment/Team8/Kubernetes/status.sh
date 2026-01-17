#!/bin/bash

# Team 8 Kubernetes Status Check Script
# Monitors deployment status

NAMESPACE="bordspelplatform-8"

echo "========================================="
echo "Team 8 Kubernetes Status"
echo "========================================="
echo ""

echo "Namespace Status:"
kubectl get namespace $NAMESPACE

echo ""
echo "Pod Status:"
kubectl get pods -n $NAMESPACE -o wide

echo ""
echo "Services:"
kubectl get svc -n $NAMESPACE

echo ""
echo "Persistent Volumes:"
kubectl get pvc -n $NAMESPACE

echo ""
echo "ConfigMap and Secrets:"
kubectl get configmap,secret -n $NAMESPACE

echo ""
echo "Detailed Pod Events (last 10 lines):"
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -10

echo ""
echo "Checking Pod Logs (sample from platform-backend):"
echo "===================="
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=platform-backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD_NAME" ]; then
    echo "Recent logs from $POD_NAME:"
    kubectl logs -n $NAMESPACE "$POD_NAME" --tail=20 2>/dev/null || echo "No logs available yet"
else
    echo "Platform backend pod not found yet"
fi

echo ""
