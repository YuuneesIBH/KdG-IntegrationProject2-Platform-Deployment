# Team 8 Kubernetes Resources - Blokus Game Platform

## 🚀 Quick Start

**Deploy everything:**
```bash
cd Deployment/Team8/Scripts
./deploy-team8.sh
```

That's it! The deployment script handles everything.

---

## 📋 Configuration

**Region:** `europe-west1-b` (Belgium)  
**Machine Type:** `e2-standard-4`  
**Namespace:** `bordspelplatform`

## 📁 Files & Folders

### Active Deployment Manifests
```
├── 00-namespace-configmap-secrets.yaml    # Namespace, ConfigMap, Secrets
├── 01-infrastructure.yaml                 # PostgreSQL, MySQL, Redis, RabbitMQ, Keycloak
├── 02-elk-stack.yaml                     # Elasticsearch, Logstash, Kibana
├── 02-platform-frontend-backend.yaml     # Platform services
├── 03-game-blokus.yaml                   # Blokus game services
└── 04-gateway.yaml                       # NGINX LoadBalancer
```

**These files are automatically applied during deployment** via `deploy-team8.sh`

### Reference Documentation (pods/ directory)
```
pods/                                      # Individual pod manifests (reference)
├── 01-postgres.yaml                      # PostgreSQL
├── 02-redis.yaml                         # Redis cache
├── 03-rabbitmq.yaml                      # RabbitMQ
├── 04-keycloak.yaml                      # Keycloak
├── 05-elasticsearch.yaml                 # Elasticsearch
├── 06-logstash.yaml                      # Logstash
├── 07-kibana.yaml                        # Kibana
├── 08-platform-frontend.yaml             # Platform Frontend
├── 09-platform-backend.yaml              # Platform Backend
├── 10-blokus-backend.yaml                # Blokus Game Backend
├── 11-ai-service.yaml                    # AI Service
└── 12-api-gateway.yaml                   # API Gateway
```

## Docker Images (Team 8)

| Component | Image |
|-----------|-------|
| Platform Frontend | `registry.gitlab.com/kdg-ti/integratieproject-j3/teams-25-26/team8/frontend/frontend-platform:latest` |
| Platform Backend | `registry.gitlab.com/kdg-ti/integratieproject-j3/teams-25-26/team8/backend-platform-service/app:latest` |
| Blokus Frontend | `registry.gitlab.com/kdg-ti/integratieproject-j3/teams-25-26/team8/frontend-blokus/frontend-blokus:latest` |
| Blokus Backend | `registry.gitlab.com/kdg-ti/integratieproject-j3/teams-25-26/team8/backend-game-service/app:latest` |
| AI Service | `matthiastruyzelaerekdg/integratieproject:ai-player` |

## Component Architecture

### Infrastructure Components
- **PostgreSQL**: Main database for applications
  - Schemas: backend_platform, backend_blokus
  - Storage: 20Gi PVC

- **MySQL**: Database for Keycloak
  - Database: keycloak
  - Storage: 10Gi PVC

- **Redis**: Caching layer
  - Storage: 5Gi PVC

- **RabbitMQ**: Message broker for async communication
  - Management UI: Port 15672

### Authentication & Authorization
- **Keycloak**: OpenID Connect identity provider
  - Realm: boardgame-platform
  - Client: react-client
  - Uses MySQL database

### Application Services
- **Platform Frontend**: React-based UI
  - Port: 80

- **Platform Backend**: Spring Boot API
  - Port: 8080

- **Blokus Frontend**: React-based game UI
  - Port: 80

- **Blokus Backend**: Spring Boot game service
  - Port: 8080

- **AI Service**: AI opponent for games
  - Port: 8000

### API Gateway
- **NGINX**: Reverse proxy and load balancer
  - Port: 80 (HTTP)
  - Routes:
    - `/` → Platform Frontend
    - `/api/` → Platform Backend
    - `/api/platform/` → Platform Backend (with rewrite)
    - `/blokus/` → Blokus Frontend
    - `/api/games/` → Blokus Backend
    - `/api/ai/` → AI Service
    - `/auth/` → Keycloak

## Service Communication

### DNS Resolution
All services communicate using Kubernetes DNS:
- Format: `<service-name>.bordspelplatform.svc.cluster.local:<port>`
- Example: `postgres-service.bordspelplatform.svc.cluster.local:5432`

### Port Mapping
| Service | Internal Port | External Port |
|---------|--------------|---------------|
| PostgreSQL | 5432 | 5432 |
| MySQL | 3306 | 3306 |
| Redis | 6379 | 6379 |
| RabbitMQ (AMQP) | 5672 | 5672 |
| RabbitMQ (Mgmt) | 15672 | 15672 |
| Keycloak | 8080 | 8180 |
| Platform Frontend | 80 | 80 |
| Platform Backend | 8080 | 8080 |
| Blokus Frontend | 80 | 80 |
| Blokus Backend | 8080 | 8080 |
| AI Service | 8000 | 8000 |
| API Gateway | 80 | LoadBalancer |

## Deployment Instructions

### Prerequisites
1. GCP Project configured
2. Kubernetes cluster running in europe-west1-b
3. kubectl configured and connected to cluster
4. GitLab credentials configured in cluster

### Step 1: Setup Kubernetes Cluster

Use the Terraform configuration:
```bash
cd ../Terraform
terraform init
terraform plan
terraform apply
```

### Step 2: Configure GitLab Registry Access

Create a secret for pulling images:
```bash
kubectl create namespace bordspelplatform

kubectl create secret docker-registry gitlab-registry \
  --docker-server=registry.gitlab.com \
  --docker-username=<gitlab-username> \
  --docker-password=<gitlab-token> \
  --docker-email=<email> \
  -n bordspelplatform
```

### Step 3: Deploy All Components

Run the deployment script:
```bash
./deploy-team8.sh
```

This will:
1. Create namespace and ConfigMaps/Secrets
2. Deploy infrastructure components (Postgres, MySQL, Redis, RabbitMQ, Keycloak)
3. Deploy logging stack (Elasticsearch, Logstash, Kibana)
4. Deploy application components (Frontend, Backends, AI Service)
5. Deploy API Gateway

### Step 4: Verify Deployment

Check deployment status:
```bash
kubectl get pods -n bordspelplatform
```

Get the external IP for accessing the platform:
```bash
kubectl get svc nginx-gateway-service -n bordspelplatform
```

Access the platform at: `http://<EXTERNAL-IP>/`
Access Blokus at: `http://<EXTERNAL-IP>/blokus/`

## Monitoring and Logs

### View Pod Logs
```bash
kubectl logs -f <pod-name> -n bordspelplatform
```

### Check Pod Events
```bash
kubectl get events -n bordspelplatform --sort-by='.lastTimestamp'
```

## Troubleshooting

### Pod Not Starting
```bash
kubectl describe pod <pod-name> -n bordspelplatform
kubectl logs <pod-name> -n bordspelplatform
```

### Database Connection Issues
```bash
# Test PostgreSQL connection
kubectl run -it --rm debug --image=postgres:latest --restart=Never -n bordspelplatform -- \
  psql -h postgres-service -U user -c "SELECT 1"
```

### Image Pull Errors
Make sure GitLab registry secret is configured:
```bash
kubectl get secret gitlab-registry -n bordspelplatform
```

## Cleanup

To remove all resources:
```bash
kubectl delete namespace bordspelplatform
```

## Updates and Scaling

### Scale a Deployment
```bash
kubectl scale deployment platform-backend-deployment -n bordspelplatform --replicas=3
```

### Update Image
```bash
kubectl set image deployment/blokus-backend-deployment \
  blokus-backend=registry.gitlab.com/kdg-ti/integratieproject-j3/teams-25-26/team8/backend-game-service/app:v2.0 \
  -n bordspelplatform
```

### Rolling Update
```bash
kubectl rollout status deployment/platform-backend-deployment -n bordspelplatform
kubectl rollout undo deployment/platform-backend-deployment -n bordspelplatform
```
