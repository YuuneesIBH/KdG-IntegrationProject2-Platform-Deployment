#!/bin/bash

# Team 12 Deployment Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GRAY='\033[0;37m'
NC='\033[0m'

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
TERRAFORM_DIR="$PROJECT_ROOT/Team12/Terraform"
KUBERNETES_DIR="$PROJECT_ROOT/Team12/Kubernetes"

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}   Deploying Team12${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# Step 0: Get GCP Project ID
echo -e "${YELLOW}Please enter your GCP Project ID:${NC}"
read -p "> " GCP_PROJECT_ID

if [ -z "$GCP_PROJECT_ID" ]; then
  echo -e "${RED}Error: GCP Project ID cannot be empty${NC}"
  exit 1
fi

echo -e "${GREEN}Using GCP Project: $GCP_PROJECT_ID${NC}"
echo ""

# Step 1: Validate configuration
echo -e "${YELLOW}✓ Validating Team12 configuration${NC}"
if [ ! -d "$TERRAFORM_DIR" ]; then
  echo -e "${RED}Error: Terraform directory not found: $TERRAFORM_DIR${NC}"
  exit 1
fi
if [ ! -d "$KUBERNETES_DIR" ]; then
  echo -e "${RED}Error: Kubernetes directory not found: $KUBERNETES_DIR${NC}"
  exit 1
fi

# Check if credentials.json exists
if [ ! -f "$PROJECT_ROOT/credentials.json" ]; then
  echo -e "${RED}Error: GCP credentials not found at $PROJECT_ROOT/credentials.json${NC}"
  echo -e "${YELLOW}Please create service account first using: ./Scripts/main.sh (option 1)${NC}"
  exit 1
fi

echo ""

# Step 2: Initialize and apply Terraform
echo -e "${YELLOW}✓ Initializing OpenTofu for Team12${NC}"
cd "$TERRAFORM_DIR"

# Update terraform.tfvars with the project ID
echo "project_id = \"$GCP_PROJECT_ID\"" > terraform.tfvars.tmp
tail -n +2 terraform.tfvars >> terraform.tfvars.tmp
mv terraform.tfvars.tmp terraform.tfvars

if [ ! -d ".terraform" ]; then
  echo -e "${YELLOW}  Running: tofu init${NC}"
  tofu init -upgrade || {
    echo -e "${RED}Failed to initialize OpenTofu${NC}"
    exit 1
  }
fi

echo -e "${YELLOW}✓ Validating OpenTofu configuration${NC}"
tofu validate || {
  echo -e "${RED}Failed to validate OpenTofu configuration${NC}"
  exit 1
}

echo -e "${YELLOW}✓ Planning OpenTofu infrastructure${NC}"
tofu plan -out=tfplan || {
  echo -e "${RED}Failed to plan OpenTofu${NC}"
  exit 1
}

echo -e "${YELLOW}✓ Creating GCP infrastructure for Team12${NC}"
tofu apply tfplan || {
  echo -e "${RED}Failed to apply OpenTofu${NC}"
  exit 1
}

echo ""

# Step 3: Configure kubectl context
echo -e "${YELLOW}✓ Configuring kubectl context${NC}"
CLUSTER_NAME=$(tofu output -raw kubernetes_cluster_name 2>/dev/null)
ZONE="europe-west1-b"
PROJECT_ID=$(tofu output -raw project_id 2>/dev/null)

if [ -z "$CLUSTER_NAME" ] || [ -z "$PROJECT_ID" ]; then
  echo -e "${YELLOW}  Waiting for Terraform outputs...${NC}"
  sleep 10
  CLUSTER_NAME=$(tofu output -raw kubernetes_cluster_name 2>/dev/null)
  PROJECT_ID=$(tofu output -raw project_id 2>/dev/null)
fi

if [ -z "$CLUSTER_NAME" ] || [ -z "$PROJECT_ID" ]; then
  echo -e "${RED}Failed to get cluster information from Terraform${NC}"
  exit 1
fi

echo -e "${YELLOW}  Cluster: $CLUSTER_NAME${NC}"
echo -e "${YELLOW}  Zone: $ZONE${NC}"
echo -e "${YELLOW}  Project: $PROJECT_ID${NC}"

gcloud container clusters get-credentials "$CLUSTER_NAME" --zone "$ZONE" --project "$PROJECT_ID" || {
  echo -e "${RED}Failed to configure kubectl context${NC}"
  exit 1
}

# Verify kubectl can connect to cluster
echo -e "${YELLOW}  Verifying cluster connection...${NC}"
kubectl cluster-info 2>/dev/null || {
  echo -e "${RED}Cannot connect to cluster. Cluster may still be initializing.${NC}"
  echo -e "${YELLOW}Waiting 30 seconds and retrying...${NC}"
  sleep 30
  kubectl cluster-info || {
    echo -e "${RED}Failed to connect to cluster${NC}"
    exit 1
  }
}

echo ""

# Step 3.5: Setup cert-manager for SSL certificates
echo -e "${YELLOW}✓ Setting up cert-manager for SSL certificates${NC}"
if [ -f "$SCRIPT_DIR/setup-ssl-certificate.sh" ]; then
  bash "$SCRIPT_DIR/setup-ssl-certificate.sh" || {
    echo -e "${YELLOW}Warning: cert-manager setup encountered issues (may already be installed)${NC}"
  }
else
  echo -e "${YELLOW}Note: setup-ssl-certificate.sh not found, skipping cert-manager setup${NC}"
fi

echo ""

# Step 4: Deploy Kubernetes manifests
echo -e "${YELLOW}✓ Deploying Kubernetes resources for Team12${NC}"
cd "$KUBERNETES_DIR"

# Apply manifests in order (concise output)
MANIFESTS=(
  00-namespace-configmap-secrets.yaml
  01-infrastructure.yaml
  02-elk-stack.yaml
  03-platform-frontend-backend.yaml
  04-game-tic-tac-toe.yaml
  05-gateway.yaml
  06-game-chess.yaml
  07-ssl-certificate.yaml
)

for manifest in "${MANIFESTS[@]}"; do
  [ -f "$manifest" ] || continue
  echo -e "${GRAY}→ ${manifest}${NC}"
  kubectl apply -f "$manifest" >/dev/null || {
    echo -e "${RED}  Error: Failed to apply $manifest${NC}"
    exit 1
  }
done

echo ""

# Step 4.4: Create temporary SSL certificate for NGINX
echo -e "${YELLOW}✓ Creating temporary SSL certificate${NC}"
if ! kubectl get secret stoom-app-tls -n bordspelplatform-12 >/dev/null 2>&1; then
  echo -e "${GRAY}→ Generating self-signed certificate for stoom-app.com${NC}"
  openssl req -x509 -newkey rsa:4096 -keyout /tmp/tls.key -out /tmp/tls.crt \
    -days 365 -nodes -subj "/CN=stoom-app.com/O=Stoom/C=NL" >/dev/null 2>&1 || {
    echo -e "${RED}Failed to generate SSL certificate${NC}"
    exit 1
  }
  kubectl create secret tls stoom-app-tls \
    --cert=/tmp/tls.crt --key=/tmp/tls.key -n bordspelplatform-12 >/dev/null 2>&1 || {
    echo -e "${RED}Failed to create stoom-app-tls secret${NC}"
    exit 1
  }
  rm -f /tmp/tls.key /tmp/tls.crt
  echo -e "${GREEN}✓ Self-signed certificate created (will be replaced by Let's Encrypt)${NC}"
else
  echo -e "${GREEN}✓ SSL certificate already exists${NC}"
fi

echo ""

# Step 4.5: Setup GitLab Registry Authentication
echo -e "${YELLOW}✓ Setting up GitLab registry authentication${NC}"
if [ -f "$SCRIPT_DIR/setup-gitlab-registry.sh" ]; then
  bash "$SCRIPT_DIR/setup-gitlab-registry.sh" || {
    echo -e "${RED}Failed to setup GitLab registry authentication${NC}"
    exit 1
  }
else
  echo -e "${RED}setup-gitlab-registry.sh not found${NC}"
  exit 1
fi

echo ""

# Step 4.6: Ensure platform-secrets exists (do not overwrite if present)
echo -e "${YELLOW}✓ Ensuring platform-secrets is present${NC}"
CREDENTIALS_FILE="$TERRAFORM_DIR/../credentials.json"
if ! kubectl get secret platform-secrets -n bordspelplatform-12 >/dev/null 2>&1; then
  if [ -f "$CREDENTIALS_FILE" ]; then
    kubectl create secret generic platform-secrets -n bordspelplatform-12 \
      --from-literal=DB_PASS=password \
      --from-literal=RABBIT_PASS=password \
      --from-literal=ELASTIC_PASSWORD=password \
      --from-literal=PLATFORM_CLIENT_SECRET=your-platform-client-secret \
      --from-literal=TICTACTOE_CLIENT_SECRET=your-tictactoe-client-secret \
      --from-literal=CHESS_CLIENT_SECRET=your-chess-client-secret \
      --from-literal=KEYCLOAK_ADMIN=admin \
      --from-literal=KEYCLOAK_ADMIN_PASSWORD=admin \
      --from-literal=KC_DB_PASSWORD=password \
      --from-file=GCP_CREDENTIALS="$CREDENTIALS_FILE" \
      --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1 || {
      echo -e "${YELLOW}  Warning: Could not create platform-secrets${NC}"
    }
    echo -e "${GREEN}✓ platform-secrets created with initial placeholders${NC}"
  else
    echo -e "${YELLOW}  Warning: credentials.json not found at $CREDENTIALS_FILE; creating without GCP credentials${NC}"
    kubectl create secret generic platform-secrets -n bordspelplatform-12 \
      --from-literal=DB_PASS=password \
      --from-literal=RABBIT_PASS=password \
      --from-literal=ELASTIC_PASSWORD=password \
      --from-literal=PLATFORM_CLIENT_SECRET=your-platform-client-secret \
      --from-literal=TICTACTOE_CLIENT_SECRET=your-tictactoe-client-secret \
      --from-literal=CHESS_CLIENT_SECRET=your-chess-client-secret \
      --from-literal=KEYCLOAK_ADMIN=admin \
      --from-literal=KEYCLOAK_ADMIN_PASSWORD=admin \
      --from-literal=KC_DB_PASSWORD=password \
      --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1 || {
      echo -e "${YELLOW}  Warning: Could not create platform-secrets without GCP credentials${NC}"
    }
    echo -e "${GREEN}✓ platform-secrets created without GCP credentials${NC}"
  fi
else
  echo -e "${GREEN}✓ platform-secrets already exists; skipping overwrite${NC}"
fi

echo ""

# Step 4.7: Setup Database Schemas
echo -e "${YELLOW}✓ Setting up database schemas${NC}"
echo -e "${YELLOW}  Waiting for PostgreSQL to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=postgres -n bordspelplatform-12 --timeout=120s >/dev/null 2>&1 || {
  echo -e "${YELLOW}  PostgreSQL still starting, waiting additional 30s...${NC}"
  sleep 30
}

# Get PostgreSQL pod name
POSTGRES_POD=$(kubectl get pods -n bordspelplatform-12 -l app=postgres -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -n "$POSTGRES_POD" ]; then
  echo -e "${YELLOW}  Creating application schemas in postgres database...${NC}"
  
  # Get database user from ConfigMap
  DB_USER=$(kubectl get configmap platform-config -n bordspelplatform-12 -o jsonpath='{.data.DB_USER}' 2>/dev/null || echo "user")
  
  # Create schemas in the postgres database (backends use currentSchema parameter)
  kubectl exec -n bordspelplatform-12 "$POSTGRES_POD" -- sh -c "psql -U $DB_USER -d postgres -c 'CREATE SCHEMA IF NOT EXISTS platform; CREATE SCHEMA IF NOT EXISTS tictactoe; CREATE SCHEMA IF NOT EXISTS chess;'" 2>/dev/null || true
  
  # Verify schemas were created
  SCHEMAS=$(kubectl exec -n bordspelplatform-12 "$POSTGRES_POD" -- sh -c "psql -U $DB_USER -d postgres -c '\\dn'" 2>/dev/null | grep -E "platform|tictactoe|chess" | wc -l)
  
  if [ "$SCHEMAS" -ge 3 ]; then
    echo -e "${GREEN}✓ Database schemas created successfully${NC}"
  else
    echo -e "${YELLOW}  Warning: Could not verify schema creation${NC}"
  fi
else
  echo -e "${YELLOW}  Warning: Could not find PostgreSQL pod, skipping schema setup${NC}"
fi

echo ""

# Step 5: Wait for LoadBalancer to get external IP
echo -e "${YELLOW}✓ Waiting for LoadBalancer external IP${NC}"
echo -e "${YELLOW}  This may take 2-5 minutes...${NC}"

# First verify the service exists
kubectl get svc nginx-gateway-service -n bordspelplatform-12 >/dev/null 2>&1 || {
  echo -e "${RED}nginx-gateway-service not found. Check if manifests were applied correctly.${NC}"
  kubectl get svc -n bordspelplatform-12
  exit 1
}

EXTERNAL_IP=""
MAX_WAIT=300
WAIT_COUNT=0

while [ -z "$EXTERNAL_IP" ] && [ $WAIT_COUNT -lt $MAX_WAIT ]; do
  EXTERNAL_IP=$(kubectl get svc nginx-gateway-service -n bordspelplatform-12 -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
  
  if [ -z "$EXTERNAL_IP" ]; then
    # Check if kubectl is still working
    kubectl get ns >/dev/null 2>&1 || {
      echo -e "${RED}Lost connection to cluster${NC}"
      exit 1
    }
    
    echo -e "${YELLOW}  Waiting for external IP... (${WAIT_COUNT}s/${MAX_WAIT}s)${NC}"
    sleep 10
    WAIT_COUNT=$((WAIT_COUNT + 10))
  fi
done

if [ -z "$EXTERNAL_IP" ]; then
  echo -e "${RED}Failed to get external IP after ${MAX_WAIT} seconds${NC}"
  echo -e "${YELLOW}Service status:${NC}"
  kubectl describe svc nginx-gateway-service -n bordspelplatform-12
  echo ""
  echo -e "${YELLOW}You can check manually later with:${NC}"
  echo -e "${BLUE}  kubectl get svc -n bordspelplatform-12 nginx-gateway-service${NC}"
  echo -e "${YELLOW}Then update configuration manually:${NC}"
  echo -e "${BLUE}  kubectl patch configmap platform-config -n bordspelplatform-12 --type json -p='[{\"op\":\"replace\",\"path\":\"/data/VITE_KC_URL\",\"value\":\"http://<EXTERNAL_IP>/auth\"}]'${NC}"
  exit 1
fi

echo -e "${GREEN}✓ External IP obtained: $EXTERNAL_IP${NC}"
echo ""

# Step 5.5: Configure Cloud DNS A records (domain → External IP)
echo -e "${YELLOW}✓ Configuring Cloud DNS A records${NC}"
if [ -f "$SCRIPT_DIR/setup-cloud-dns.sh" ]; then
  # Use explicit IP to avoid k8s lookup race
  bash "$SCRIPT_DIR/setup-cloud-dns.sh" --domain stoom-app.com --ip "$EXTERNAL_IP" || {
    echo -e "${YELLOW}  Warning: Could not configure Cloud DNS A records (continuing)${NC}"
  }
else
  echo -e "${YELLOW}  Note: setup-cloud-dns.sh not found, skipping DNS setup${NC}"
fi

echo ""

# Step 6: Wait for critical services to be ready FIRST
echo -e "${YELLOW}✓ Waiting for critical services to be ready...${NC}"
echo -e "${YELLOW}  This may take 5-10 minutes (first time startup)...${NC}"
echo ""

# Wait for critical services
CRITICAL_WAIT_TIME=600  # 10 minutes
CRITICAL_APPS=("nginx-gateway" "postgres" "redis" "rabbitmq")

for app in "${CRITICAL_APPS[@]}"; do
  echo -e "${YELLOW}  Waiting for $app...${NC}"
  if kubectl wait --for=condition=ready pod -l app=$app -n bordspelplatform-12 --timeout=${CRITICAL_WAIT_TIME}s 2>/dev/null; then
    echo -e "    ${GREEN}✓${NC} $app ready"
  else
    echo -e "    ${YELLOW}⚠${NC} $app still starting (will continue...)"
  fi
done

echo ""

# Step 9.5: Background watcher to restart NGINX when Let's Encrypt certificate becomes Ready
if [ -f "$SCRIPT_DIR/watch-certificate.sh" ]; then
  echo -e "${YELLOW}✓ Starting certificate watcher (nginx auto-restart on Ready)${NC}"
  nohup "$SCRIPT_DIR/watch-certificate.sh" \
    --namespace bordspelplatform-12 \
    --certificate stoom-app-cert \
    --deployment nginx-gateway-deployment \
    --timeout 7200 \
    --interval 20 \
    >/tmp/watch-certificate.log 2>&1 &
else
  echo -e "${YELLOW}Note: watch-certificate.sh not found, skipping auto-restart setup${NC}"
fi

# Step 8: Wait for backend services (may depend on other services)
echo -e "${YELLOW}✓ Waiting for backend services...${NC}"
BACKEND_WAIT_TIME=900  # 15 minutes (includes Keycloak dependency time)
BACKEND_APPS=("platform-frontend" "platform-backend")

for app in "${BACKEND_APPS[@]}"; do
  echo -e "${YELLOW}  Waiting for $app...${NC}"
  if kubectl wait --for=condition=ready pod -l app=$app -n bordspelplatform-12 --timeout=${BACKEND_WAIT_TIME}s 2>/dev/null; then
    echo -e "    ${GREEN}✓${NC} $app ready"
  else
    echo -e "    ${YELLOW}⚠${NC} $app still starting (may depend on external services)"
  fi
done

echo ""

# Step 7: Update ConfigMap with external IP (NOW after services are ready)
echo -e "${YELLOW}✓ Updating ConfigMap with external IP${NC}"

# Run the external IP update script (flag to avoid restarts during first deploy)
if [ -f "$SCRIPT_DIR/update-external-ip.sh" ]; then
  FIRST_DEPLOY=1 bash "$SCRIPT_DIR/update-external-ip.sh" || {
    echo -e "${RED}Failed to update external IP configuration${NC}"
    exit 1
  }
else
  echo -e "${RED}update-external-ip.sh script not found in $SCRIPT_DIR${NC}"
  exit 1
fi

echo ""

# Step 7.5: Configure Keycloak Realm & Clients (AUTOMATIC)
echo -e "${YELLOW}✓ Configuring Keycloak realm and clients (automatic)${NC}"
if [ -f "$SCRIPT_DIR/configure-keycloak.sh" ]; then
  # Check if Keycloak pod is ready first
  if kubectl wait --for=condition=ready pod -l app=keycloak -n bordspelplatform-12 --timeout=300s 2>/dev/null; then
    # Give Keycloak a few more seconds to initialize fully
    sleep 5
    echo -e "${YELLOW}  Running Keycloak configuration...${NC}"
    if bash "$SCRIPT_DIR/configure-keycloak.sh"; then
      echo -e "${GREEN}✓ Keycloak configuration completed successfully${NC}"
    else
      echo -e "${RED}✗ Keycloak configuration failed${NC}"
      echo -e "${YELLOW}  You can run manually later with: bash $SCRIPT_DIR/configure-keycloak.sh${NC}"
    fi
  else
    echo -e "${YELLOW}  ⚠ Keycloak not ready yet; will need manual configuration${NC}"
    echo -e "${YELLOW}  Run later: bash $SCRIPT_DIR/configure-keycloak.sh${NC}"
  fi
else
  echo -e "${YELLOW}  ✗ configure-keycloak.sh not found${NC}"
fi

echo ""

# Step 8: Auto-recovery for tic-tac-toe backend if Keycloak is ready
echo -e "${YELLOW}✓ Checking optional services and auto-recovery...${NC}"

# Check if Keycloak is ready
KEYCLOAK_READY=$(kubectl get pods -n bordspelplatform-12 -l app=keycloak -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)

if [ "$KEYCLOAK_READY" = "true" ]; then
  echo -e "    ${GREEN}✓${NC} Keycloak is ready"
  
  # Check if tic-tac-toe backend is already ready (no restart needed)
  TTT_READY=$(kubectl get pods -n bordspelplatform-12 -l app=tictactoe-backend -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
  
  if [ "$TTT_READY" = "true" ]; then
    echo -e "    ${GREEN}✓${NC} Tic-tac-toe backend already ready"
  else
    echo -e "${YELLOW}  Waiting for tic-tac-toe backend to auto-connect...${NC}"
    # Don't restart, just wait - pods will connect when ready
    if kubectl wait --for=condition=ready pod -l app=tictactoe-backend -n bordspelplatform-12 --timeout=300s 2>/dev/null; then
      echo -e "    ${GREEN}✓${NC} Tic-tac-toe backend ready"
    else
      echo -e "    ${YELLOW}⚠${NC} Tic-tac-toe backend still initializing (will auto-recover)"
    fi
  fi
else
  echo -e "    ${YELLOW}⚠${NC} Keycloak not ready yet (tic-tac-toe will auto-recover later)"
fi

echo ""

# Step 10: Final deployment status
echo -e "${YELLOW}✓ Deployment Status Summary${NC}"
echo ""

# Check critical pods
echo -e "${YELLOW}  Critical Services:${NC}"
for app in nginx-gateway platform-frontend platform-backend postgres redis rabbitmq; do
  READY=$(kubectl get pods -n bordspelplatform-12 -l app=$app -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
  POD_NAME=$(kubectl get pods -n bordspelplatform-12 -l app=$app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  
  if [ "$READY" = "true" ]; then
    echo -e "    ${GREEN}✓${NC} $app (1/1 Ready)"
  elif [ -n "$POD_NAME" ]; then
    RESTARTS=$(kubectl get pod -n bordspelplatform-12 "$POD_NAME" -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null)
    STATUS=$(kubectl get pod -n bordspelplatform-12 "$POD_NAME" -o jsonpath='{.status.phase}' 2>/dev/null)
    echo -e "    ${YELLOW}⚠${NC} $app (status: $STATUS, restarts: $RESTARTS)"
  else
    echo -e "    ${RED}✗${NC} $app (not found)"
  fi
done

echo ""
echo -e "${YELLOW}  Optional Services:${NC}"
for app in keycloak tictactoe-backend elasticsearch kibana chess-backend; do
  READY=$(kubectl get pods -n bordspelplatform-12 -l app=$app -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
  POD_NAME=$(kubectl get pods -n bordspelplatform-12 -l app=$app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  
  if [ "$READY" = "true" ]; then
    echo -e "    ${GREEN}✓${NC} $app (1/1 Ready)"
  elif [ -n "$POD_NAME" ]; then
    RESTARTS=$(kubectl get pod -n bordspelplatform-12 "$POD_NAME" -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null)
    STATUS=$(kubectl get pod -n bordspelplatform-12 "$POD_NAME" -o jsonpath='{.status.phase}' 2>/dev/null)
    echo -e "    ${YELLOW}⚠${NC} $app (status: $STATUS, restarts: $RESTARTS)"
  else
    echo -e "    ${GRAY}○${NC} $app (not created)"
  fi
done

echo ""
echo -e "${YELLOW}Note: Some services may still be initializing. This is normal.${NC}"
echo -e "${YELLOW}Database backends take 3-5 minutes on first startup.${NC}"

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Team12 deployment completed successfully${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}External IP: ${EXTERNAL_IP}${NC}"
echo ""
echo -e "${YELLOW}Access the application at:${NC}"
echo -e "${BLUE}  http://${EXTERNAL_IP}${NC} - Platform Frontend"
echo -e "${BLUE}  https://stoom-app.com${NC} - Platform Frontend (with SSL)"
echo -e "${BLUE}  https://stoom-app.com/auth${NC} - Keycloak (admin/admin)"
echo -e "${BLUE}  https://stoom-app.com/play/tictactoe/${NC} - Tic-Tac-Toe Game"
echo -e "${BLUE}  https://stoom-app.com/play/blitz-chess${NC} - Chess (Blitz)"
echo -e "${BLUE}  https://stoom-app.com/kibana/${NC} - Kibana Dashboard"
echo -e "${BLUE}  https://stoom-app.com/rabbitmq/${NC} - RabbitMQ Management (user/password)"
echo ""
echo -e "${YELLOW}Important: To use the domain stoom-app.com, ensure DNS is configured:${NC}"
echo -e "${BLUE}  stoom-app.com → ${EXTERNAL_IP}${NC}"
echo -e "${BLUE}  www.stoom-app.com → ${EXTERNAL_IP}${NC}"
echo ""
echo -e "${YELLOW}Certificate status:${NC}"
echo -e "${BLUE}  kubectl describe certificate stoom-app-cert -n bordspelplatform-12${NC}"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo -e "${BLUE}  kubectl get pods -n bordspelplatform-12${NC} - Check pod status"
echo -e "${BLUE}  kubectl logs -n bordspelplatform-12 <pod-name>${NC} - View logs"
echo -e "${BLUE}  kubectl get svc -n bordspelplatform-12${NC} - List services"
