# Team12 Kubernetes Resources

## 🚀 Quick Start

**Deploy everything from root directory:**
```bash
cd /home/kali/Downloads/IntegrationProject2-Deployment-main
./Scripts/main.sh
# → Select: 3 (Deploy) → 3 (Team12)
```

That's it! The deployment script handles everything.

---

## 📋 Configuration

**Region:** `europe-west1-b` (Belgium)  
**Machine Type:** `e2-standard-4`  
**Namespace:** `bordspelplatform-12`

## 📁 Files & Folders

### Active Deployment Manifests
```
├── 00-namespace-configmap-secrets.yaml    # Namespace, ConfigMap, Secrets
├── 01-infrastructure.yaml                 # PostgreSQL, Redis, RabbitMQ
├── 02-elk-stack.yaml                      # Elasticsearch, Logstash, Kibana
├── 03-platform-frontend-backend.yaml      # Platform services
├── 04-game-tic-tac-toe.yaml              # Tic-Tac-Toe services
├── 05-gateway.yaml                        # NGINX LoadBalancer
├── 06-game-chess.yaml                     # Chess services
└── 07-ssl-certificate.yaml                # SSL/TLS certificates
```

**These files are automatically applied during deployment** via `Team12/Scripts/deploy-team12.sh`

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
├── 10-tictactoe-backend.yaml             # Tic-Tac-Toe Backend
├── 11-ai-service.yaml                    # AI Service
└── 12-api-gateway.yaml                   # API Gateway
```

Can be used as a reference for understanding individual services.

### Documentation
```
├── README.md (this file)                 # Overview
├── DEPLOYMENT_GUIDE.md                   # Detailed deployment info
└── QUICK_REFERENCE.md                    # Quick commands
```

## Component Architecture

### Infrastructure Components
- **PostgreSQL**: Main database for all applications
  - Databases: platform, tictactoe, keycloak
  - Storage: 20Gi PVC

- **Redis**: Caching layer
  - Storage: 5Gi PVC

- **RabbitMQ**: Message broker for async communication
  - Management UI: Port 15672

### Authentication & Authorization
- **Keycloak**: OpenID Connect identity provider
  - Realms: stoom
  - Clients: stoom-frontend

### Logging & Monitoring (ELK Stack)
- **Elasticsearch**: Log storage and search
  - Storage: 10Gi PVC

- **Logstash**: Log aggregation and processing
  - Inputs: TCP, UDP, RabbitMQ queue

- **Kibana**: Log visualization dashboard

### Application Services
- **Platform Frontend**: React-based UI
  - Image: registry.gitlab.com/kdg-ti/integratieproject-j3/teams-25-26/team12/platform/frontend:latest
  - Port: 80

- **Platform Backend**: Spring Boot API
  - Image: registry.gitlab.com/kdg-ti/integratieproject-j3/teams-25-26/team12/platform/backend:latest
  - Port: 8080

- **Tic-Tac-Toe Backend**: Game service
  - Image: registry.gitlab.com/kdg-ti/integratieproject-j3/teams-25-26/team12/tictactoe/backend:latest
  - Port: 8081

- **AI Service**: AI opponent for games
  - Image: registry.gitlab.com/kdg-ti/integratieproject-j3/teams-25-26/team12/ai/service:latest
  - Port: 8000

### API Gateway
- **NGINX**: Reverse proxy and load balancer
  - Port: 80 (HTTP)
  - Routes:
    - `/auth/` → Keycloak
    - `/api/platform/` → Platform Backend
    - `/api/tictactoe/` → Tic-Tac-Toe Backend
    - `/play/tictactoe/` → Tic-Tac-Toe UI
    - `/` → Platform Frontend

### Service Communication

### DNS Resolution
All services communicate using Kubernetes DNS:
- Format: `<service-name>.bordspelplatform-12.svc.cluster.local:<port>`
- Example: `postgres-service.bordspelplatform-12.svc.cluster.local:5432`

### Port Mapping
| Service | Internal Port | External Port |
|---------|--------------|---------------|
| PostgreSQL | 5432 | 5432 |
| Redis | 6379 | 6379 |
| RabbitMQ (AMQP) | 5672 | 5672 |
| RabbitMQ (Mgmt) | 15672 | 15672 |
| Keycloak | 8080 | 8080 |
| Elasticsearch | 9200 | 9200 |
| Logstash | 5000 | 5000 |
| Kibana | 5601 | 5601 |
| Platform Frontend | 80 | 80/443 via gateway |
| Platform Backend | 8080 | 80/443 via gateway |
| Tic-Tac-Toe Backend | 8081 | 80/443 via gateway |
| Chess Backend | 8082 | 80/443 via gateway |
| AI Service | 8000 | 80/443 via gateway |
| API Gateway | 80/443 | LoadBalancer |

## Deployment Instructions

### Prerequisites
1. GCP project with billing enabled
2. `gcloud`, `kubectl`, and `tofu` installed locally
3. GitLab token with `read_registry` scope for private images
4. Domain `stoom-app.com` (and `www`) pointing to the LoadBalancer IP

### Step 1: Provision and Deploy

From the repo root, run the orchestrator:
```bash
cd /home/kali/Downloads/IntegrationProject2-Deployment-main
./Scripts/main.sh
# Select: 3 (Deploy) → 3 (Team12)
```

This performs Terraform (GKE, networking), configures kubectl, sets up the GitLab registry secret, applies manifests in order, and waits for the gateway IP.

### Step 2: Registry Access (manual fallback)
If you need to re-create the pull secret manually:
```bash
kubectl create namespace bordspelplatform-12 --dry-run=client -o yaml | kubectl apply -f -
bash Team12/Scripts/setup-gitlab-registry.sh
```

### Step 3: Verify Deployment

```bash
cd Team12/Scripts
./status.sh
kubectl get svc nginx-gateway-service -n bordspelplatform-12
```

Access the platform at `https://stoom-app.com/` (or `https://<EXTERNAL-IP>/` if DNS is not set).

## Configuration

### Environment Variables
All application configuration is stored in:
- **ConfigMap**: `platform-config` - Non-sensitive configuration
- **Secret**: `platform-secrets` - Sensitive credentials

See `00-namespace-configmap-secrets.yaml` for all available variables.

### Persistent Storage
All stateful components use PersistentVolumeClaims (PVC):
- `postgres-pvc`: 20Gi
- `redis-pvc`: 5Gi
- `rabbitmq-pvc`: 5Gi
- `elasticsearch-pvc`: 10Gi

## Monitoring and Logs

### View Pod Logs
```bash
kubectl logs -f <pod-name> -n bordspelplatform-12
```

### Access Kibana Dashboard
Once deployed, access Kibana at: `https://stoom-app.com/kibana/` (or `https://<EXTERNAL-IP>/kibana/`).

### Check Pod Events
```bash
kubectl get events -n bordspelplatform-12 --sort-by='.lastTimestamp'
```

## Resource Requirements

### CPU & Memory Per Node
- **Total Requested**: ~3.6 CPU cores, 8GB RAM
- **Recommended Node Size**: e2-standard-4 or higher

### Node Configuration
- **Machine Type**: e2-standard-2
- **Node Count**: 1 (configurable in Terraform)
- **Disk**: 100GB per node

## Troubleshooting

### Pod Not Starting
```bash
kubectl describe pod <pod-name> -n bordspelplatform-12
kubectl logs <pod-name> -n bordspelplatform-12
```

### Database Connection Issues
```bash
# Test PostgreSQL connection
kubectl run -it --rm debug --image=postgres:latest --restart=Never -n bordspelplatform-12 -- \
  psql -h postgres-service -U user -c "SELECT 1"
```

### RabbitMQ Management UI
Access at: `https://stoom-app.com/rabbitmq/` (or `https://<EXTERNAL-IP>/rabbitmq/`) with credentials from `platform-secrets`.

### Service Communication Issues
```bash
# Test DNS resolution from a pod
kubectl run -it --rm debug --image=busybox --restart=Never -n bordspelplatform-12 -- \
  nslookup postgres-service.bordspelplatform-12.svc.cluster.local
```

## Cleanup

To remove all resources:
```bash
bash Team12/Scripts/teardown-team12.sh
```

## Updates and Scaling

### Scale a Deployment
```bash
kubectl scale deployment platform-backend-deployment -n bordspelplatform-12 --replicas=3
```

### Update Image
```bash
kubectl set image deployment/platform-backend-deployment \
  platform-backend=registry.gitlab.com/kdg-ti/integratieproject-j3/teams-25-26/team12/platform/backend:v2.0 \
  -n bordspelplatform-12
```

### Rolling Update
```bash
kubectl rollout status deployment/platform-backend-deployment -n bordspelplatform-12
kubectl rollout undo deployment/platform-backend-deployment -n bordspelplatform-12
```

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Elasticsearch Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)

## Support

For issues or questions about the Team12 deployment:
1. Check the logs using `bash Team12/Scripts/status.sh`
2. Review pod descriptions
3. Verify network connectivity between services
4. Check Terraform state in `../Terraform/`
