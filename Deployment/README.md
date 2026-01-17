# Integratieproject J3 - DevOps Deployment

## 🎮 Bordspelplatform Multi-Team Deployment

Dit project bevat de complete DevOps infrastructuur voor drie bordspelplatform teams:
- **Team 4** - AI Platform (Chatbot, AI Player, Recommendation System)
- **Team 8** - Dampf Bordspelplatform (Blokus)
- **Team 12** - Stoom Bordspelplatform (Tic-Tac-Toe, Chess)

---

## 🚀 Quick Start

### Alle Teams Deployen
```bash
cd Scripts
bash main.sh
# Kies: 3 (Deploy) → selecteer team (4, 8, of 12)
```

### Specifiek Team Deployen
```bash
# Team 4 - AI Platform
cd Team4/Scripts && bash deploy-team4.sh

# Team 8 - Dampf (Blokus)
cd Team8/Scripts && bash deploy-team8.sh

# Team 12 - Stoom (Tic-Tac-Toe, Chess)
cd Team12/Scripts && bash deploy-team12.sh
```

---

## 📋 Team Overview

| Team | Platform | Domain | Games | Speciale Features |
|------|----------|--------|-------|-------------------|
| **Team 4** | AI Platform | `35.233.49.216` | - | Chatbot, AI Player, RAG |
| **Team 8** | Dampf | `dampf-app.com` | Blokus | Chatbot integratie |
| **Team 12** | Stoom | `stoom-app.com` | Tic-Tac-Toe, Chess | Volledige game suite |

---

## 📁 Project Structuur

```
Deployment/
├── README.md                     # Dit bestand
├── credentials.json              # GCP service account (gitignored)
├── Scripts/                      # Gedeelde orchestrator scripts
│   ├── main.sh                   # Interactief menu
│   ├── enable-gcp-apis.sh        # GCP API enablement
│   └── create-gcp-service-account.sh
│
├── Team4/                        # AI Platform
│   ├── README.md                 # Team 4 documentatie
│   ├── Kubernetes/               # K8s manifests (Ollama, Chatbot, RAG)
│   ├── Terraform/                # GKE cluster configuratie
│   └── Scripts/                  # Deployment scripts
│
├── Team8/                        # Dampf Platform
│   ├── README.md                 # Team 8 documentatie
│   ├── Kubernetes/               # K8s manifests (Blokus, Platform)
│   ├── Terraform/                # GKE cluster configuratie
│   └── Scripts/                  # Deployment scripts
│
└── Team12/                       # Stoom Platform
    ├── README.md                 # Team 12 documentatie
    ├── Kubernetes/               # K8s manifests (TTT, Chess, Platform)
    ├── Terraform/                # GKE cluster configuratie
    └── Scripts/                  # Deployment scripts
```

---

## 🔑 Prerequisites

### Vereiste Tools
| Tool | Versie | Installatie |
|------|--------|-------------|
| gcloud CLI | Latest | `sudo apt install google-cloud-cli` |
| kubectl | Latest | `sudo apt install kubectl` |
| OpenTofu | >= 1.6 | [Install Guide](https://opentofu.org/docs/intro/install/) |

### GCP Setup
1. **GCP Project** met billing enabled
2. **APIs Enablen:**
   ```bash
   cd Scripts
   bash enable-gcp-apis.sh
   ```
3. **Service Account Credentials:**
   ```bash
   bash main.sh
   # Kies: 2 (Create GCP Service Account)
   ```

### GitLab Registry Access
Alle teams gebruiken private GitLab container images. Configureer een access token:
```bash
# Per team namespace
kubectl create secret docker-registry gitlab-registry \
  -n <namespace> \
  --docker-server=registry.gitlab.com \
  --docker-username=oauth2 \
  --docker-password=<YOUR_GITLAB_TOKEN>
```

---

## 🌐 Team 4 - AI Platform

**Namespace:** `ai-platform-team4`  
**Cluster:** `ai-platform-team4`  
**IP:** `35.233.49.216`

### Services
| Service | Beschrijving | Port |
|---------|--------------|------|
| Ollama | LLM Server (gpt-oss:20b-cloud) | 11434 |
| Chatbot RAG | Chat met document context | 8080 |
| AI Player | Game AI (Blokus, Tic-Tac-Toe) | 8000 |
| PostgreSQL | Document storage (pgvector) | 5432 |

### API Endpoints
```bash
# Chatbot
POST http://35.233.49.216/api/chat
POST http://35.233.49.216/api/docs/upload

# AI Player
POST http://35.233.49.216/api/ai-player/games/best-move
POST http://35.233.49.216/api/ai-player/games/tic-tac-toe/best-move
POST http://35.233.49.216/api/ai-player/games/blokus/best-move
```

### Deploy
```bash
cd Team4/Scripts
bash deploy-team4.sh
```

**Volledige documentatie:** [Team4/README.md](Team4/README.md)

---

## 🌐 Team 8 - Dampf Platform

**Namespace:** `bordspelplatform-8`  
**Cluster:** `bordspel-platform-team8`  
**Domain:** `dampf-app.com` / `www.dampf-app.com`

### Services
| Service | URL | Beschrijving |
|---------|-----|--------------|
| Platform | `https://www.dampf-app.com` | Hoofdplatform |
| Blokus | `https://www.dampf-app.com/blokus/` | Blokus game |
| Keycloak | `https://www.dampf-app.com/auth/` | Authenticatie |
| Kibana | `https://www.dampf-app.com/kibana/` | Logging |
| Chatbot | `https://www.dampf-app.com/api/chat` | AI Chatbot (via Team 4) |

### Architecture
- Frontend/Backend Platform (React + Spring Boot)
- Blokus Game met AI tegenstander
- PostgreSQL, MySQL, Redis, RabbitMQ
- ELK Stack voor logging
- NGINX Gateway met SSL

### Deploy
```bash
cd Team8/Scripts
bash deploy-team8.sh
```

**Volledige documentatie:** [Team8/README.md](Team8/README.md)

---

## 🌐 Team 12 - Stoom Platform

**Namespace:** `bordspelplatform-12`  
**Cluster:** `team12-cluster`  
**Domain:** `stoom-app.com` / `www.stoom-app.com`

### Services
| Service | URL | Beschrijving |
|---------|-----|--------------|
| Platform | `https://stoom-app.com` | Hoofdplatform |
| Tic-Tac-Toe | `https://stoom-app.com/play/tictactoe/` | TTT game |
| Chess | `https://stoom-app.com/play/blitz-chess` | Chess game |
| Keycloak | `https://stoom-app.com/auth/` | Authenticatie |
| Kibana | `https://stoom-app.com/kibana/` | Logging |
| RabbitMQ | `https://stoom-app.com/rabbitmq/` | Message queue UI |

### Architecture
- Frontend/Backend Platform (React + Spring Boot)
- Tic-Tac-Toe en Chess games met AI
- PostgreSQL, Redis, RabbitMQ
- ELK Stack voor logging
- NGINX Gateway met SSL

### Deploy
```bash
cd Team12/Scripts
bash deploy-team12.sh
```

**Volledige documentatie:** [Team12/README.md](Team12/README.md)

---

## 🔄 Cross-Team Integratie

### AI Services (Team 4 → Team 8 & 12)
Team 4 host gecentraliseerde AI services die door andere teams gebruikt worden:

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

### Proxy Configuratie
Team 8's NGINX routeert AI requests naar Team 4:
```nginx
location /api/chat { proxy_pass http://35.233.49.216/api/chat; }
location /api/docs { proxy_pass http://35.233.49.216/api/docs; }
location /api/ai-player/ { proxy_pass http://35.233.49.216/api/ai-player/; }
```

---

## 🛠️ Common Operations

### Context Switchen
```bash
# Team 4
kubectl config use-context team4

# Team 8
kubectl config use-context team8

# Team 12
kubectl config use-context team12
```

### Pods Bekijken
```bash
# Team 4
kubectl get pods -n ai-platform-team4

# Team 8
kubectl get pods -n bordspelplatform-8

# Team 12
kubectl get pods -n bordspelplatform-12
```

### Service Herstarten
```bash
kubectl rollout restart deployment/<name> -n <namespace>
```

### Logs Bekijken
```bash
kubectl logs -n <namespace> deployment/<name> -f
```

---

## 🧹 Cleanup

### Per Team
```bash
# Team 4
cd Team4/Scripts && bash teardown-team4.sh

# Team 8
cd Team8/Scripts && bash teardown-team8.sh

# Team 12
cd Team12/Scripts && bash teardown-team12.sh
```

### Volledige Teardown
```bash
cd Scripts
bash main.sh
# Kies: 4 (Teardown) → All
```

---

## 🔒 Security

### Secrets Management
- `credentials.json` - GCP service account (gitignored)
- `.env` files - Environment config (gitignored)
- `gitlab-registry` - Container registry credentials (per namespace)
- `platform-secrets` - Application secrets (in K8s)

### Network Security
- Alle externe toegang via NGINX Gateway
- SSL/TLS certificaten per domain
- Internal services via ClusterIP
- Database alleen intern bereikbaar

---

## 📊 Infrastructure Costs

| Resource | Per Team | Totaal |
|----------|----------|--------|
| GKE Cluster | ~€50/maand | ~€150/maand |
| Load Balancer | ~€20/maand | ~€60/maand |
| Persistent Disks | ~€10/maand | ~€30/maand |
| **Totaal** | ~€80/maand | ~€240/maand |

*Prijzen zijn schattingen voor e2-standard-4 nodes in europe-west1.*

---

## 🐛 Troubleshooting

### Pod Start Niet
```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous
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
```

### External IP Niet Toegewezen
```bash
# Check LoadBalancer status
kubectl get svc -n <namespace> | grep LoadBalancer

# Wacht 5-10 minuten voor GCP provisioning
```

### Database Connection Failed
```bash
# Test PostgreSQL
kubectl exec -n <namespace> deployment/postgres-deployment -- \
  psql -U user -d postgres -c "SELECT 1"
```

---

## 📚 Aanvullende Documentatie

| Document | Beschrijving |
|----------|--------------|
| [DEPLOYMENT_INSTRUCTIONS.md](DEPLOYMENT_INSTRUCTIONS.md) | Stap-voor-stap deployment guide |
| [GCP_CREDENTIALS_SETUP.md](GCP_CREDENTIALS_SETUP.md) | GCP credentials configuratie |
| [GITLAB_REGISTRY_SETUP.md](GITLAB_REGISTRY_SETUP.md) | GitLab container registry setup |
| [Team4/README.md](Team4/README.md) | Team 4 specifieke documentatie |
| [Team8/README.md](Team8/README.md) | Team 8 specifieke documentatie |
| [Team12/README.md](Team12/README.md) | Team 12 specifieke documentatie |

---

## 📄 License

See [LICENSE.md](LICENSE.md)

---

**KdG - Integratieproject J3 DevOps 2025-2026**
