#!/bin/bash

# Team 8 Kubernetes Verification Script
# Validates deployment configuration

NAMESPACE="bordspelplatform-8"
PODS_DIR="./pods"
ERRORS=0
WARNINGS=0

echo "========================================="
echo "Team 8 Kubernetes Configuration Verification"
echo "========================================="
echo ""

# Function to print error
error() {
    echo "❌ ERROR: $1"
    ((ERRORS++))
}

# Function to print warning
warning() {
    echo "⚠️  WARNING: $1"
    ((WARNINGS++))
}

# Function to print success
success() {
    echo "✅ OK: $1"
}

echo "[1/5] Checking YAML File Syntax..."
for file in 00-namespace-configmap-secrets.yaml $PODS_DIR/*.yaml; do
    if [ -f "$file" ]; then
        if kubectl apply -f "$file" --dry-run=client &>/dev/null; then
            success "$(basename $file) has valid syntax"
        else
            error "$(basename $file) has invalid YAML syntax"
        fi
    fi
done

echo ""
echo "[2/5] Checking Namespace and ConfigMap..."
if grep -q "kind: Namespace" 00-namespace-configmap-secrets.yaml; then
    success "Namespace definition found"
else
    error "Namespace definition missing"
fi

if grep -q "name: bordspelplatform-8" 00-namespace-configmap-secrets.yaml; then
    success "Namespace 'bordspelplatform-8' correctly named"
else
    error "Namespace not named 'bordspelplatform-8'"
fi

if grep -q "kind: ConfigMap" 00-namespace-configmap-secrets.yaml; then
    success "ConfigMap definition found"
else
    error "ConfigMap definition missing"
fi

echo ""
echo "[3/5] Checking Pod Definitions..."

# Check required pods
required_pods=(
    "01-postgres.yaml|postgres-deployment"
    "02-redis.yaml|redis-deployment"
    "03-rabbitmq.yaml|rabbitmq-deployment"
    "04-keycloak.yaml|keycloak-deployment"
    "05-elasticsearch.yaml|elasticsearch-deployment"
    "06-logstash.yaml|logstash-deployment"
    "07-kibana.yaml|kibana-deployment"
    "08-platform-frontend.yaml|platform-frontend-deployment"
    "09-platform-backend.yaml|platform-backend-deployment"
    "10-blokus-backend.yaml|blokus-backend-deployment"
    "11-ai-service.yaml|ai-service-deployment"
    "12-api-gateway.yaml|api-gateway-deployment"
)

for entry in "${required_pods[@]}"; do
    IFS='|' read -r file deployment <<< "$entry"
    if [ -f "$PODS_DIR/$file" ]; then
        if grep -q "name: $deployment" "$PODS_DIR/$file"; then
            success "$file contains '$deployment'"
        else
            error "$file missing deployment '$deployment'"
        fi
    else
        error "Pod file missing: $PODS_DIR/$file"
    fi
done

echo ""
echo "[4/5] Checking Service Definitions..."

# Check required services
required_services=(
    "postgres-service|01-postgres.yaml"
    "redis-service|02-redis.yaml"
    "rabbitmq-service|03-rabbitmq.yaml"
    "keycloak-service|04-keycloak.yaml"
    "elasticsearch-service|05-elasticsearch.yaml"
    "logstash-service|06-logstash.yaml"
    "kibana-service|07-kibana.yaml"
    "platform-frontend-service|08-platform-frontend.yaml"
    "platform-backend-service|09-platform-backend.yaml"
    "blokus-backend-service|10-blokus-backend.yaml"
    "ai-service|11-ai-service.yaml"
    "api-gateway|12-api-gateway.yaml"
)

for entry in "${required_services[@]}"; do
    IFS='|' read -r service file <<< "$entry"
    if [ -f "$PODS_DIR/$file" ]; then
        if grep -q "name: $service" "$PODS_DIR/$file"; then
            success "Service '$service' defined in $file"
        else
            error "Service '$service' not defined in $file"
        fi
    fi
done

echo ""
echo "[5/5] Checking Service Connectivity Configuration..."

# Check ConfigMap for proper DNS names
config_file="00-namespace-configmap-secrets.yaml"

if grep -q "postgres-service.bordspelplatform-8.svc.cluster.local" "$config_file"; then
    success "PostgreSQL service DNS configured correctly"
else
    error "PostgreSQL service DNS not properly configured in ConfigMap"
fi

if grep -q "redis-service.bordspelplatform-8.svc.cluster.local" "$config_file"; then
    success "Redis service DNS configured correctly"
else
    error "Redis service DNS not properly configured in ConfigMap"
fi

if grep -q "rabbitmq-service.bordspelplatform-8.svc.cluster.local" "$config_file"; then
    success "RabbitMQ service DNS configured correctly"
else
    error "RabbitMQ service DNS not properly configured in ConfigMap"
fi

if grep -q "keycloak-service.bordspelplatform-8.svc.cluster.local" "$config_file"; then
    success "Keycloak service DNS configured correctly"
else
    error "Keycloak service DNS not properly configured in ConfigMap"
fi

if grep -q "elasticsearch-service:9200" "$PODS_DIR/06-logstash.yaml"; then
    success "Logstash Elasticsearch connection configured"
else
    error "Logstash Elasticsearch connection not configured"
fi

echo ""
echo "========================================="
echo "Verification Summary"
echo "========================================="
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"

if [ $ERRORS -eq 0 ]; then
    echo ""
    echo "✅ All checks passed! Ready for deployment."
    exit 0
else
    echo ""
    echo "❌ Found $ERRORS error(s). Please fix before deployment."
    exit 1
fi
