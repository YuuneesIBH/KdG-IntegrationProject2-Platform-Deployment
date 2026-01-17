# Team 8 - Bordspelplatform "Dampf"

## 🚀 Quick Start

```bash
cd Deployment/Team8/Scripts
./deploy-team8.sh
```

De deployment script handelt alles automatisch af.

---

## 📋 Project Overview

**Team 8** bouwt het **Dampf Bordspelplatform** met:
- **Platform Frontend/Backend** - Hoofdapplicatie met store, library, gebruikersbeheer
- **Blokus Game** - Strategisch bordspel met AI tegenstander
- **Keycloak** - Authenticatie en autorisatie
- **ELK Stack** - Logging en monitoring

**Cluster:** `bordspel-platform-team8`  
**Region:** `europe-west1-b` (Belgium)  
**Namespace:** `bordspelplatform-8`  
**Domain:** `dampf-app.com` / `www.dampf-app.com`

---

## 🌐 Live Endpoints

| Service | URL | Beschrijving |
|---------|-----|--------------|
| Platform | `https://www.dampf-app.com` | Hoofdplatform |
| Blokus Game | `https://www.dampf-app.com/blokus/` | Blokus spel |
| Keycloak | `https://www.dampf-app.com/auth/` | Login/registratie |
| Kibana | `https://www.dampf-app.com/kibana/` | Log dashboard |
| RabbitMQ | `https://www.dampf-app.com/rabbitmq/` | Message queue UI |
| Chatbot API | `https://www.dampf-app.com/api/chat` | AI chatbot (via Team 4) |

---

## 📁 Project Structuur

```
Team8/
├── Kubernetes/
│   ├── 00-namespace-configmap-secrets.yaml   # Namespace, ConfigMap, Secrets
│   ├── 01-infrastructure.yaml                # PostgreSQL, MySQL, Redis, RabbitMQ
│   ├── 02-elk-stack.yaml                     # Elasticsearch, Logstash, Kibana
│   ├── 02-platform-frontend-backend.yaml     # Platform services
│   ├── 03-game-blokus.yaml                   # Blokus game services
│   ├── 04-gateway.yaml                       # NGINX Gateway met SSL
│   └── pods/                                 # Individuele pod referenties
├── Scripts/
│   ├── deploy-team8.sh                       # Hoofddeployment script
│   ├── teardown-team8.sh                     # Cleanup script
│   ├── setup-gitlab-registry.sh              # Registry credentials
│   ├── setup-postgres-schemas.sh             # Database schemas
│   ├── update-external-ip.sh                 # DNS configuratie
│   ├── monitor-deployment.sh                 # Real-time monitoring
│   └── *.ndjson                              # Kibana dashboards
├── Terraform/
│   ├── main.tf                               # GCP provider
│   ├── kubernetes-cluster.tf                 # GKE cluster
│   ├── google-cloud-sql.tf                   # Cloud SQL (optioneel)
│   └── variables.tf                          # Configuratie
└── infrastructure-main/                      # Docker Compose (lokaal)
```

---

## 🔧 Componenten

### Infrastructure
| Component | Image | Port | Storage |
|-----------|-------|------|---------|
| PostgreSQL | `postgres:17` | 5432 | 20Gi PVC |
| MySQL | `mysql:8.0` | 3306 | 10Gi PVC |
| Redis | `redis:7-alpine` | 6379 | 5Gi PVC |
| RabbitMQ | `rabbitmq:3-management` | 5672, 15672 | - |
| Keycloak | Custom image | 8180 | MySQL backend |

### ELK Stack
| Component | Image | Port | Beschrijving |
|-----------|-------|------|--------------|
| Elasticsearch | `elasticsearch:8.11.0` | 9200 | Log storage |
| Logstash | `logstash:8.11.0` | 5044, 50000 | Log processing |
| Kibana | `kibana:8.11.0` | 5601 | Visualisatie |

### Application Services
| Component | Image | Port |
|-----------|-------|------|
| Platform Frontend | `registry.gitlab.com/.../frontend-platform:latest` | 80 |
| Platform Backend | `registry.gitlab.com/.../backend-platform-service:latest` | 8080 |
| Blokus Frontend | `registry.gitlab.com/.../frontend-blokus:latest` | 80 |
| Blokus Backend | `registry.gitlab.com/.../backend-game-service:latest` | 8080 |
| AI Service | `registry.gitlab.com/.../team4/ai-player:latest` | 8000 |

---

## 📦 Deployment

### Prerequisites
1. GCP Project met billing enabled
2. `gcloud` CLI geïnstalleerd
3. `kubectl` geïnstalleerd  
4. `tofu` (OpenTofu) geïnstalleerd
5. GitLab access token
6. DNS configuratie voor `dampf-app.com`

### Volledige Deployment

```bash
# 1. Infrastructure
cd Team8/Terraform
tofu init && tofu apply

# 2. Kubernetes resources
cd ../Scripts
./deploy-team8.sh

# 3. Verify
kubectl get pods -n bordspelplatform-8
```

### Individuele Componenten

```bash
# Alleen infrastructure
kubectl apply -f Kubernetes/01-infrastructure.yaml

# Alleen platform
kubectl apply -f Kubernetes/02-platform-frontend-backend.yaml

# Alleen Blokus
kubectl apply -f Kubernetes/03-game-blokus.yaml
```

---

## 🔄 Updates Deployen

### Nieuwe Images Pullen
```bash
# Alle services herstarten voor nieuwe images
kubectl rollout restart deployment/platform-frontend-deployment \
  deployment/platform-backend-deployment \
  deployment/blokus-frontend-deployment \
  deployment/blokus-backend-deployment \
  -n bordspelplatform-8

# Status checken
kubectl rollout status deployment/platform-frontend-deployment -n bordspelplatform-8
```

### Specifieke Service Updaten
```bash
kubectl rollout restart deployment/<service>-deployment -n bordspelplatform-8
```

---

## 🔗 Service Communicatie

### Interne DNS
```
<service>-service.bordspelplatform-8.svc.cluster.local:<port>
```

### Port Mapping
| Service | Internal | External |
|---------|----------|----------|
| PostgreSQL | 5432 | ClusterIP |
| MySQL | 3306 | ClusterIP |
| Redis | 6379 | ClusterIP |
| RabbitMQ | 5672/15672 | LoadBalancer |
| Keycloak | 8180 | via Gateway |
| Platform Backend | 8080 | via Gateway |
| Blokus Backend | 8080 | via Gateway |
| NGINX Gateway | 80/443 | LoadBalancer |

---

## 📊 Monitoring & Logging

### Kibana Dashboards
Beschikbaar op `https://www.dampf-app.com/kibana/`:
- **Player Behaviour** - Gebruikersactiviteit
- **Revenue Dashboard** - Transacties en coins
- **System Health** - Infrastructure metrics

### Pod Logs
```bash
# Platform backend
kubectl logs -n bordspelplatform-8 deployment/platform-backend-deployment -f

# Blokus AI errors
kubectl logs -n bordspelplatform-8 deployment/blokus-backend-deployment | grep -i error

# Alle pods status
kubectl get pods -n bordspelplatform-8 -o wide
```

### Real-time Monitoring
```bash
cd Team8/Scripts
./monitor-deployment.sh
```

---

## 🤖 AI Integratie

### Blokus AI (Game Moves)
De AI service voor game moves draait lokaal:
```bash
# AI service status
kubectl get pods -n bordspelplatform-8 -l app=ai-service

# Check AI endpoints
kubectl run curl-test --image=curlimages/curl --rm -it -n bordspelplatform-8 \
  -- curl -s http://ai-service:8000/openapi.json
```

### Chatbot (via Team 4)
Chatbot requests worden geproxied naar Team 4:
```bash
# Test chatbot
curl -X POST "https://www.dampf-app.com/api/chat" \
  -H "Content-Type: application/json" \
  -d '{"message": "Welke games kan ik spelen?"}'
```

---

## 🛠️ Troubleshooting

### Pods Starten Niet
```bash
# Check events
kubectl describe pod <pod-name> -n bordspelplatform-8

# Check resources
kubectl top nodes
kubectl top pods -n bordspelplatform-8
```

### ImagePullBackOff
```bash
# Update GitLab registry secret
kubectl create secret docker-registry gitlab-registry \
  -n bordspelplatform-8 \
  --docker-server=registry.gitlab.com \
  --docker-username=oauth2 \
  --docker-password=YOUR_TOKEN \
  --dry-run=client -o yaml | kubectl apply -f -
```

### Database Connectie Errors
```bash
# Check PostgreSQL
kubectl logs -n bordspelplatform-8 deployment/postgres-deployment

# Test connectie
kubectl exec -it -n bordspelplatform-8 deployment/postgres-deployment -- \
  psql -U user -d postgres -c "\l"
```

### Keycloak Login Faalt
```bash
# Check Keycloak logs
kubectl logs -n bordspelplatform-8 deployment/keycloak-deployment

# Verify realm config
# Login: https://www.dampf-app.com/auth/admin
# Credentials: Check platform-secrets
```

### Blokus AI Werkt Niet
```bash
# Check AI service logs
kubectl logs -n bordspelplatform-8 deployment/ai-service-deployment

# Verify AI endpoints
kubectl exec -n bordspelplatform-8 deployment/blokus-backend-deployment -- \
  env | grep AI_SERVICE
```

---

## 🔒 Security

### Secrets
- `platform-secrets` - Database passwords, Keycloak credentials
- `gitlab-registry` - Container registry access
- `nginx-ssl-secret` - TLS certificaten

### Network Policies
- Database services: ClusterIP only (geen externe toegang)
- Gateway: LoadBalancer met SSL termination
- Inter-service: Kubernetes DNS

---

## 📝 Configuratie

### Environment Variables
Geconfigureerd in `00-namespace-configmap-secrets.yaml`:
- Database URLs en credentials
- Keycloak endpoints
- RabbitMQ connection
- JWT configuratie

### Keycloak Setup
- **Realm:** `boardgame-platform`
- **Client:** `react-client`
- **Admin URL:** `https://dampf-app.com/auth/admin`

---

## 🧹 Cleanup

### Volledige Teardown
```bash
cd Team8/Scripts
./teardown-team8.sh
```

### Alleen Kubernetes Resources
```bash
kubectl delete namespace bordspelplatform-8
```

### Alleen Terraform Infrastructure
```bash
cd Team8/Terraform
tofu destroy
```

---

## 📞 Contact

**Team 8 - Bordspelplatform Dampf**  
Domain: dampf-app.com
