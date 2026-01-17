#!/bin/bash

# Team8 Kubernetes Deployment Script
# Deploys all components in the correct order

set -e

NAMESPACE="bordspelplatform-8"
PODS_DIR="./pods"

echo "========================================="
echo "Team8 Kubernetes Deployment Script"
echo "Region: europe-west1-b (Belgium)"
echo "Machine Type: e2-standard-2"
echo "========================================="
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "ERROR: kubectl is not installed or not in PATH"
    exit 1
fi

# Check if kubectl can connect to cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "ERROR: Cannot connect to Kubernetes cluster"
    exit 1
fi

echo "[1/3] Deploying Namespace, ConfigMap and Secrets..."
kubectl apply -f 00-namespace-configmap-secrets.yaml

echo ""
echo "[2/3] Deploying Infrastructure Pods (in order)..."

# Deploy infrastructure components in order
for pod_file in $PODS_DIR/01-postgres.yaml \
                $PODS_DIR/02-redis.yaml \
                $PODS_DIR/03-rabbitmq.yaml \
                $PODS_DIR/04-keycloak.yaml; do
    if [ -f "$pod_file" ]; then
        echo "  - Deploying $(basename $pod_file)..."
        kubectl apply -f "$pod_file"
        echo "    Waiting for pods to be ready..."
        sleep 5
    fi
done

echo ""
echo "[3/3] Deploying Logging Stack (ELK) and Application Pods..."

# Deploy logging and application components
for pod_file in $PODS_DIR/05-elasticsearch.yaml \
                $PODS_DIR/06-logstash.yaml \
                $PODS_DIR/07-kibana.yaml \
                $PODS_DIR/08-platform-frontend.yaml \
                $PODS_DIR/09-platform-backend.yaml \
                $PODS_DIR/10-blokus-backend.yaml \
                $PODS_DIR/11-ai-service.yaml \
                $PODS_DIR/12-api-gateway.yaml; do
    if [ -f "$pod_file" ]; then
        echo "  - Deploying $(basename $pod_file)..."
        kubectl apply -f "$pod_file"
    fi
done

echo ""
echo "========================================="
echo "Deployment Complete!"
echo "========================================="
echo ""
echo "Waiting for all pods to be running..."
kubectl wait --for=condition=ready pod --all -n $NAMESPACE --timeout=300s 2>/dev/null || echo "Some pods are still starting..."

echo ""
echo "Pod Status:"
kubectl get pods -n $NAMESPACE

echo ""
echo "Services:"
kubectl get svc -n $NAMESPACE

echo ""
echo "Getting LoadBalancer External IP (might take a few minutes)..."
echo "Keycloak/Gateway URL: http://<EXTERNAL-IP>/"
echo "Kibana Logs: http://<EXTERNAL-IP>:5601 (if exposed)"
echo ""

echo "Use: kubectl get svc api-gateway -n $NAMESPACE to get the external IP"
echo ""
