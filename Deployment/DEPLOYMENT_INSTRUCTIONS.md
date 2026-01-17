# Multi-Team Deployment Instructions

## 🚀 Quick Start

```bash
cd Deployment/Scripts
./main.sh
```

Dan volg het menu:
1. **Eerste keer setup:**
   - Optie 1: Enable GCP APIs
   - Optie 2: Create Service Account (plaats credentials.json in repo root)

2. **Deploy een team:**
   - Optie 3: Deploy → Selecteer Team (4, 8, of 12)

Klaar! ✅

---

## 📋 Team Overview

| Team | Platform | Namespace | Domain | Games |
|------|----------|-----------|--------|-------|
| **Team 4** | AI Platform | `ai-platform-team4` | `35.233.49.216` | - |
| **Team 8** | Dampf | `bordspelplatform-8` | `dampf-app.com` | Blokus |
| **Team 12** | Stoom | `bordspelplatform-12` | `stoom-app.com` | Tic-Tac-Toe, Chess |

---

## 🎯 Team 4 - AI Platform

**Wat wordt gedeployed:**
- **Ollama** - LLM Server met gpt-oss:20b-cloud model
- **Chatbot RAG** - AI chatbot met document context
- **AI Player** - Game AI voor Blokus en Tic-Tac-Toe
- **PostgreSQL** - Document storage met pgvector

**Endpoints:**
```
http://35.233.49.216/api/chat         → Chatbot API
http://35.233.49.216/api/docs         → Document upload
http://35.233.49.216/api/ai-player/   → Game AI endpoints
http://35.233.49.216/ollama/          → Ollama API
```

**Deploy:**
```bash
cd Team4/Scripts
bash deploy-team4.sh
```

---

## 🎯 Team 8 - Dampf Platform

**Wat wordt gedeployed:**
- **Platform Frontend/Backend** - Hoofdapplicatie
- **Blokus Game** - Strategisch bordspel met AI
- **Keycloak** - Authenticatie
- **ELK Stack** - Logging (Elasticsearch, Logstash, Kibana)
- **Infrastructure** - PostgreSQL, MySQL, Redis, RabbitMQ

**Architecture:**
```
External IP (NGINX Gateway LoadBalancer)
  ↓
  ├── /                  → Platform Frontend
  ├── /api/              → Platform Backend
  ├── /auth/             → Keycloak
  ├── /blokus/           → Blokus Frontend
  ├── /api/blokus/       → Blokus Backend
  ├── /kibana/           → Kibana Dashboard
  ├── /rabbitmq/         → RabbitMQ Management
  ├── /api/chat          → Chatbot (proxy naar Team 4)
  └── /api/ai-player/    → AI Player (proxy naar Team 4)
```

**Deploy:**
```bash
cd Team8/Scripts
bash deploy-team8.sh
```

---

## 🎯 Team 12 - Stoom Platform

**Wat wordt gedeployed:**
- **Platform Frontend/Backend** - Hoofdapplicatie
- **Tic-Tac-Toe Game** - Klassiek spel met AI
- **Chess Game** - Schaakspel met AI
- **Keycloak** - Authenticatie
- **ELK Stack** - Logging
- **Infrastructure** - PostgreSQL, Redis, RabbitMQ

**Architecture:**
```
External IP (NGINX Gateway LoadBalancer)
  ↓
  ├── /                    → Platform Frontend
  ├── /api/                → Platform Backend
  ├── /auth/               → Keycloak
  ├── /play/tictactoe/     → Tic-Tac-Toe Frontend
  ├── /api/tictactoe/      → Tic-Tac-Toe Backend
  ├── /play/blitz-chess/   → Chess Frontend
  ├── /api/blitz-chess/    → Chess Backend
  ├── /kibana/             → Kibana Dashboard
  └── /rabbitmq/           → RabbitMQ Management
```

**Deploy:**
```bash
cd Team12/Scripts
bash deploy-team12.sh
```

---

## 📋 Stap-voor-Stap Uitleg

### Stap 1: Prerequisites

**Vereiste Tools:**
| Tool | Installatie |
|------|-------------|
| gcloud CLI | `sudo apt install google-cloud-cli` |
| kubectl | `sudo apt install kubectl` |
| OpenTofu | [opentofu.org/docs/intro/install](https://opentofu.org/docs/intro/install/) |

**Vereiste Accounts:**
- GCP Project (maak aan op https://console.cloud.google.com)
- GitLab account met toegang tot team repositories

### Stap 2: Eerste Keer Setup

```bash
# Navigeer naar Deployment folder
cd Deployment

# Run main menu
./Scripts/main.sh

# Optie 1: Enable GCP APIs
# - Voer je GCP Project ID in
# - Enabled vereiste services (Compute, SQL, Kubernetes, etc.)

# Optie 2: Create GCP Service Account
# - Voer zelfde Project ID in
# - Maakt service account met juiste permissions
# - Download credentials.json → plaats in Deployment folder
```

### Stap 3: Deploy Team

```bash
./Scripts/main.sh
# Selecteer optie 3 (Deploy)
# Selecteer team (4, 8, of 12)

# Script zal:
# ✅ OpenTofu initialiseren
# ✅ GCP infrastructure aanmaken
# ✅ kubectl configureren
# ✅ Alle Kubernetes resources deployen
# ✅ Wachten op external LoadBalancer IP
```

### Stap 4: Verkrijg External IP

```bash
# Team 4
kubectl get svc -n ai-platform-team4 | grep LoadBalancer

# Team 8
kubectl get svc nginx-gateway-service -n bordspelplatform-8

# Team 12
kubectl get svc nginx-gateway-service -n bordspelplatform-12
```

### Stap 5: DNS Configureren (optioneel)

```
# Team 8
dampf-app.com     → <EXTERNAL_IP>
www.dampf-app.com → <EXTERNAL_IP>

# Team 12
stoom-app.com     → <EXTERNAL_IP>
www.stoom-app.com → <EXTERNAL_IP>
```

---

## 🔧 Veelgebruikte Commands

### Context Switchen
```bash
kubectl config use-context team4   # Team 4
kubectl config use-context team8   # Team 8
kubectl config use-context team12  # Team 12
```

### Pods Monitoren
```bash
kubectl get pods -n <namespace> -w
```

### Logs Bekijken
```bash
kubectl logs -f deployment/<name> -n <namespace>
```

### Service Herstarten
```bash
kubectl rollout restart deployment/<name> -n <namespace>

# Of alle deployments in een namespace
kubectl rollout restart deployment -n <namespace>
```

### Teardown
```bash
./Scripts/main.sh
# Selecteer optie 4 (Destroy) → selecteer team
```

---

## 📁 Repository Structuur

```
Deployment/
├── credentials.json              # GCP service account (gitignored)
├── Scripts/                      # Gedeelde scripts
│   ├── main.sh                   # Interactief menu
│   ├── enable-gcp-apis.sh        # GCP API enablement
│   └── create-gcp-service-account.sh
│
├── Team4/                        # AI Platform
│   ├── Kubernetes/               # K8s manifests
│   ├── Terraform/                # GKE cluster
│   └── Scripts/                  # Deploy scripts
│
├── Team8/                        # Dampf Platform
│   ├── Kubernetes/               # K8s manifests
│   ├── Terraform/                # GKE cluster
│   └── Scripts/                  # Deploy scripts
│
└── Team12/                       # Stoom Platform
    ├── Kubernetes/               # K8s manifests
    ├── Terraform/                # GKE cluster
    └── Scripts/                  # Deploy scripts
```

### Kubernetes Manifests (per team)
```
00-namespace-configmap-secrets.yaml   # Namespace, ConfigMap, Secrets
01-infrastructure.yaml                # PostgreSQL, Redis, RabbitMQ
02-elk-stack.yaml                     # Elasticsearch, Logstash, Kibana
02-platform-frontend-backend.yaml     # Platform services
03-game-*.yaml                        # Game services
04-gateway.yaml                       # NGINX Gateway
```

---

## 🔐 Security & Credentials

### GCP Credentials (credentials.json)
- **Locatie:** Deployment folder root
- **Bewaar veilig:** Dit bestand staat in .gitignore en geeft volledige GCP toegang
- **Hoe te verkrijgen:** Maak via Scripts/main.sh optie 2

### GitLab Registry Credentials
- **Automatisch:** Geconfigureerd tijdens deployment
- **Handmatig:** `<Team>/Scripts/setup-gitlab-registry.sh`
- **Vereiste scope:** `read_registry` permission

```bash
# Handmatig GitLab registry secret aanmaken
kubectl create secret docker-registry gitlab-registry \
  -n <namespace> \
  --docker-server=registry.gitlab.com \
  --docker-username=oauth2 \
  --docker-password=<YOUR_TOKEN>
```

---

## ❌ Troubleshooting

### Pod Start Niet
```bash
# Check events en logs
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous  # Vorige crash
```

### ImagePullBackOff
```bash
# Update GitLab registry secret
kubectl create secret docker-registry gitlab-registry \
  -n <namespace> \
  --docker-server=registry.gitlab.com \
  --docker-username=oauth2 \
  --docker-password=<TOKEN> \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart deployment
kubectl rollout restart deployment/<name> -n <namespace>
```

### External IP in `<pending>`
```bash
# Wacht 5-10 minuten voor GCP LoadBalancer provisioning
kubectl describe svc nginx-gateway-service -n <namespace>

# Check quota in GCP Console
# Compute Engine → Quotas → In-use IP addresses
```

### Database Connection Issues
```bash
# Test PostgreSQL
kubectl exec -n <namespace> deployment/postgres-deployment -- \
  psql -U user -d postgres -c "\l"

# Check logs
kubectl logs -n <namespace> deployment/postgres-deployment
```

### Keycloak Niet Bereikbaar
```bash
# Check pod status
kubectl get pods -n <namespace> -l app=keycloak

# Check logs
kubectl logs -n <namespace> deployment/keycloak-deployment

# Verify NGINX config
kubectl get configmap nginx-config -n <namespace> -o yaml
```

### Service Communicatie Issues
```bash
# Test DNS resolutie
kubectl run -it --rm debug --image=busybox --restart=Never -n <namespace> -- \
  nslookup postgres-service.<namespace>.svc.cluster.local

# Test service bereikbaarheid
kubectl run -it --rm curl --image=curlimages/curl --restart=Never -n <namespace> -- \
  curl -s http://<service>:<port>/health
```

---

## 🌐 Toegang Na Deployment

### Team 4 - AI Platform
| Service | URL |
|---------|-----|
| Chatbot API | `http://35.233.49.216/api/chat` |
| Document Upload | `http://35.233.49.216/api/docs/upload` |
| AI Player | `http://35.233.49.216/api/ai-player/games/best-move` |
| Ollama API | `http://35.233.49.216/ollama/api/tags` |

### Team 8 - Dampf Platform
| Service | URL |
|---------|-----|
| Platform | `https://www.dampf-app.com` |
| Blokus Game | `https://www.dampf-app.com/blokus/` |
| Keycloak | `https://www.dampf-app.com/auth/` |
| Kibana | `https://www.dampf-app.com/kibana/` |
| RabbitMQ | `https://www.dampf-app.com/rabbitmq/` |
| Chatbot | `https://www.dampf-app.com/api/chat` |

### Team 12 - Stoom Platform
| Service | URL |
|---------|-----|
| Platform | `https://stoom-app.com` |
| Tic-Tac-Toe | `https://stoom-app.com/play/tictactoe/` |
| Chess | `https://stoom-app.com/play/blitz-chess/` |
| Keycloak | `https://stoom-app.com/auth/` |
| Kibana | `https://stoom-app.com/kibana/` |
| RabbitMQ | `https://stoom-app.com/rabbitmq/` |

---

## 🔄 Cross-Team Integratie

Team 4 host gecentraliseerde AI services die door Team 8 en 12 gebruikt worden:

```
Team 8 (dampf-app.com)        Team 12 (stoom-app.com)
         │                              │
         ▼                              ▼
    NGINX Gateway                 NGINX Gateway
         │                              │
         └──────────┬───────────────────┘
                    │
                    ▼
            Team 4 AI Platform
            (35.233.49.216)
                    │
        ┌───────────┴───────────┐
        │                       │
        ▼                       ▼
    AI Player               Chatbot RAG
   (game moves)            (recommendations)
```

### Proxy Routes (Team 8 → Team 4)
```nginx
location /api/chat { proxy_pass http://35.233.49.216/api/chat; }
location /api/docs { proxy_pass http://35.233.49.216/api/docs; }
location /api/ai-player/ { proxy_pass http://35.233.49.216/api/ai-player/; }
```

---

## 📊 Kubernetes Resources

### Manifests Volgorde (apply order)
1. `00-namespace-configmap-secrets.yaml` - Namespace, ConfigMap, secrets, PVCs
2. `01-infrastructure.yaml` - PostgreSQL, Redis, RabbitMQ, Keycloak
3. `02-elk-stack.yaml` - Elasticsearch, Logstash, Kibana
4. `02-platform-frontend-backend.yaml` - Platform frontend, backend
5. `03-game-*.yaml` - Game services (Blokus/TTT/Chess)
6. `04-gateway.yaml` - NGINX gateway (LoadBalancer)

### Services Controleren
```bash
# Alle services
kubectl get svc -n <namespace>

# Pods status
kubectl get pods -n <namespace>

# Events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

---

## ⚙️ Environment Variables

Alle services gebruiken ConfigMaps en Secrets per namespace.

### Database Connection
| Variable | Waarde |
|----------|--------|
| `DB_HOST` | postgres-service |
| `DB_PORT` | 5432 |
| `DB_USER` | user |
| `DB_PASS` | (from Secret) |

### Message Queue
| Variable | Waarde |
|----------|--------|
| `RABBIT_HOST` | rabbitmq-service |
| `RABBIT_PORT` | 5672 |
| `RABBIT_USER` | user |
| `RABBIT_PASS` | (from Secret) |

### Cache
| Variable | Waarde |
|----------|--------|
| `REDIS_HOST` | redis-service |
| `REDIS_PORT` | 6379 |

### AI Services (Team 4)
| Variable | Waarde |
|----------|--------|
| `OLLAMA_HOST` | ollama-service |
| `CHAT_MODEL` | gpt-oss:20b-cloud |
| `EMBEDDING_MODEL` | bge-m3:latest |

---

## 🔍 Logs & Monitoring

### Pod Logs Bekijken
```bash
# Platform backend
kubectl logs -n <namespace> deployment/platform-backend-deployment -f

# Keycloak
kubectl logs -n <namespace> deployment/keycloak-deployment

# Database
kubectl logs -n <namespace> deployment/postgres-deployment

# Alle containers in pod
kubectl logs -n <namespace> <pod-name> --all-containers
```

### Kibana Dashboard
Na deployment bereikbaar op:
- Team 8: `https://www.dampf-app.com/kibana/`
- Team 12: `https://stoom-app.com/kibana/`

Setup:
1. Ga naar Management → Index Patterns
2. Maak pattern `logstash-*`
3. Selecteer `@timestamp` als time field

### RabbitMQ Management
- Team 8: `https://www.dampf-app.com/rabbitmq/`
- Team 12: `https://stoom-app.com/rabbitmq/`
- Credentials: user/password (uit platform-secrets)

---

## 🧹 Cleanup

### Per Team Teardown
```bash
# Team 4
cd Team4/Scripts && bash teardown-team4.sh

# Team 8
cd Team8/Scripts && bash teardown-team8.sh

# Team 12
cd Team12/Scripts && bash teardown-team12.sh
```

### Via Main Menu
```bash
./Scripts/main.sh
# Selecteer optie 4: Destroy → selecteer team
# Type 'yes' om te bevestigen
```

Dit verwijdert:
1. Alle Kubernetes resources
2. GKE cluster
3. VPC network
4. Alle GCP infrastructure

---

## 📊 Resource Requirements

### GCP Quotas (per team)
| Resource | Hoeveelheid |
|----------|-------------|
| SSD Persistent Disk | ~100GB |
| In-use IP addresses | 1 external IP |
| CPUs | 4 vCPUs (e2-standard-4) |

### Kubernetes Resources (indicatief)
| Component | RAM | Storage |
|-----------|-----|---------|
| PostgreSQL | 512Mi | 20Gi |
| Elasticsearch | 2Gi | 10Gi |
| Keycloak | 1Gi | - |
| RabbitMQ | 512Mi | 5Gi |
| Redis | 256Mi | 5Gi |
| Platform Backend | 512Mi | - |
| Ollama (Team 4) | 8Gi | 50Gi |
| **Totaal** | ~12-14Gi | ~90Gi |

### Geschatte Kosten
| Resource | Per Team/Maand |
|----------|----------------|
| GKE Cluster | ~€50 |
| Load Balancer | ~€20 |
| Persistent Disks | ~€10 |
| **Totaal** | ~€80/team |

---

## 📝 Belangrijke Notities

### Default Credentials
| Service | Username | Password |
|---------|----------|----------|
| Keycloak Admin | admin | admin |
| RabbitMQ | user | password |
| PostgreSQL | user | password |

⚠️ **Wijzig deze voor productie!**

### Database Setup
- **DDL_AUTO:** `create` - schema wordt automatisch aangemaakt
- **SQL_INIT_MODE:** `always` - init scripts draaien bij elke start
- **Databases:** platform, tictactoe, chess, keycloak (auto-created)

### AI Models (Team 4)
- **Chat Model:** gpt-oss:20b-cloud
- **Embedding Model:** bge-m3:latest
- **Pull commando:** `curl -X POST http://35.233.49.216/ollama/api/pull -d '{"name":"model"}'`

---

## 🔒 Security Aanbevelingen

⚠️ **Voor Productie:**
- [ ] Wijzig alle default wachtwoorden
- [ ] Enable HTTPS met echte TLS certificaten
- [ ] Gebruik Cloud SQL ipv in-cluster PostgreSQL
- [ ] Enable Keycloak security features
- [ ] Configureer proper IAM roles
- [ ] Enable Kubernetes Secrets encryption
- [ ] Configureer network policies
- [ ] Stel resource quotas in
- [ ] Enable audit logging

---

## 📚 Aanvullende Documentatie

| Document | Beschrijving |
|----------|--------------|
| [README.md](README.md) | Project overview |
| [GCP_CREDENTIALS_SETUP.md](GCP_CREDENTIALS_SETUP.md) | GCP credentials guide |
| [GITLAB_REGISTRY_SETUP.md](GITLAB_REGISTRY_SETUP.md) | GitLab registry setup |
| [Team4/README.md](Team4/README.md) | Team 4 documentatie |
| [Team8/README.md](Team8/README.md) | Team 8 documentatie |
| [Team12/README.md](Team12/README.md) | Team 12 documentatie |

---

**KdG - Integratieproject J3 DevOps 2025-2026**
