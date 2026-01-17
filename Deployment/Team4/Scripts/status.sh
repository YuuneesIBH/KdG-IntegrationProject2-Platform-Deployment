#!/bin/bash
# Status check script for Team 4

NAMESPACE="ai-platform-team4"

echo "======================================"
echo "Team 4 AI Platform - Status"
echo "======================================"

echo ""
echo "=== Pods ==="
kubectl get pods -n "$NAMESPACE" -o wide

echo ""
echo "=== Services ==="
kubectl get svc -n "$NAMESPACE"

echo ""
echo "=== Deployments ==="
kubectl get deployments -n "$NAMESPACE"

echo ""
echo "=== Jobs ==="
kubectl get jobs -n "$NAMESPACE"

# Get external IP
echo ""
echo "=== External Access ==="
EXTERNAL_IP=$(kubectl get svc api-gateway -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
echo "API Gateway IP: $EXTERNAL_IP"

if [[ "$EXTERNAL_IP" != "pending" && -n "$EXTERNAL_IP" ]]; then
  echo ""
  echo "Testing endpoints..."
  echo -n "  Health: "
  curl -s -o /dev/null -w "%{http_code}" "http://$EXTERNAL_IP/health" 2>/dev/null || echo "error"
  echo ""
  echo -n "  RAG API: "
  curl -s -o /dev/null -w "%{http_code}" "http://$EXTERNAL_IP/api/rag/health" 2>/dev/null || echo "error"
  echo ""
  echo -n "  AI Player: "
  curl -s -o /dev/null -w "%{http_code}" "http://$EXTERNAL_IP/api/ai-player/health" 2>/dev/null || echo "error"
  echo ""
fi

echo ""
echo "======================================"
