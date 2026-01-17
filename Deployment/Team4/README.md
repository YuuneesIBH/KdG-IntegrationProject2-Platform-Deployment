# Team 4 - AI Platform Deployment

## Quick Start

```bash
cd Deployment/Team4/Scripts
./deploy-team4.sh
```

De deployment script handelt alles automatisch af.

---

## Project Overview

**Team 4** levert de **AI Platform** services voor alle teams:
- **Chatbot RAG API** - Vraag-antwoord systeem voor game hulp
- **AI Player API** - AI tegenstanders voor bordspellen  
- **Ollama LLM** - Large Language Model backend

**Cluster:** `ai-platform-team4`  
**Region:** `europe-west1-b` (Belgium)  
**Namespace:** `ai-platform-team4`

---

## Endpoints

| Service | URL | Beschrijving |
|---------|-----|--------------|
| Chatbot API | `http://35.233.49.216/api/chat` | POST requests voor chat |
| Chatbot Docs | `http://35.233.49.216/api/docs` | Swagger UI documentatie |
| AI Player API | `http://35.233.49.216/api/ai-player/` | Game AI endpoints |
| Ollama LLM | `http://35.233.49.216/ollama/api/tags` | Model management |
| Health Check | `http://35.233.49.216/health` | Service status |

---

## 📁 Project Structuur

```
Team4/
├── Kubernetes/
│   ├── 00-namespace-configmap-secrets.yaml   # Namespace & configuratie
│   ├── 01-infrastructure.yaml                # PostgreSQL database
│   ├── 02-services.yaml                      # Chatbot, AI Player, Ollama
│   ├── 03-gateway.yaml                       # NGINX API Gateway
│   └── 04-ollama-model-puller.yaml           # Model download job
├── Scripts/
│   ├── deploy-team4.sh                       # Hoofddeployment script
│   ├── teardown-team4.sh                     # Cleanup script
│   ├── setup-gitlab-registry.sh              # Registry credentials
│   └── status.sh                             # Pod monitoring
└── Terraform/
    ├── main.tf                               # GCP provider config
    ├── kubernetes-cluster.tf                 # GKE cluster definitie
    ├── variables.tf                          # Input variabelen
    ├── outputs.tf                            # Output waarden
    └── terraform.tfvars                      # Configuratie waarden
```

---

## Componenten

### Infrastructure
| Component | Image | Port | Beschrijving |
|-----------|-------|------|--------------|
| PostgreSQL | `pgvector/pgvector:pg17` | 5432 | Database met vector support |

### Services
| Component | Image | Port | Beschrijving |
|-----------|-------|------|--------------|
| Chatbot RAG | `registry.gitlab.com/.../chatbot-and-recommendation-system` | 8000 | RAG chatbot API |
| AI Player | `registry.gitlab.com/.../ai-player` | 8000 | Game AI service |
| Ollama | `ollama/ollama:latest` | 11434 | LLM runtime |
| API Gateway | `nginx:latest` | 80 | Reverse proxy |

### Ollama Modellen
| Model | Grootte | Gebruik |
|-------|---------|---------|
| `gpt-oss:20b-cloud` | ~40GB | Chat completions |
| `bge-m3:latest` | ~1.1GB | Embeddings |
| `llama3.2:3b` | ~2GB | Fallback chat |
| `nomic-embed-text:latest` | ~274MB | Text embeddings |

---

## 📦 Deployment

### Prerequisites
1. GCP Project met billing enabled
2. `gcloud` CLI geïnstalleerd en geconfigureerd
3. `kubectl` geïnstalleerd
4. `tofu` (OpenTofu) geïnstalleerd
5. GitLab access token met `read_registry` scope

### Stap 1: Infrastructure Deployment
```bash
cd Team4/Terraform
tofu init
tofu plan -out=tfplan
tofu apply tfplan
```

### Stap 2: Kubernetes Deployment
```bash
cd Team4/Scripts
./deploy-team4.sh
```

### Stap 3: Ollama Models Laden
```bash
# Models worden automatisch gepulled, of handmatig:
curl -X POST "http://35.233.49.216/ollama/api/pull" \
  -H "Content-Type: application/json" \
  -d '{"name": "gpt-oss:20b-cloud"}'
```

---

## 🔗 Integratie met Andere Teams

Team 4's services zijn beschikbaar voor alle teams via proxy routes:

### Team 8 (dampf-app.com)
```
https://www.dampf-app.com/api/chat     → Team 4 Chatbot
https://www.dampf-app.com/ollama/      → Team 4 Ollama
```

### Team 12 (stoom-app.com)
```
https://stoom-app.com/api/chat         → Team 4 Chatbot
```

---

## 📊 Monitoring

### Pod Status
```bash
kubectl get pods -n ai-platform-team4
```

### Logs Bekijken
```bash
# Chatbot logs
kubectl logs -n ai-platform-team4 deployment/chatbot-rag-deployment -f

# Ollama logs
kubectl logs -n ai-platform-team4 deployment/ollama-deployment -f
```

### Health Check
```bash
curl http://35.233.49.216/api/health
```

---

## 🛠️ Troubleshooting

### Chatbot geeft "connection error"
```bash
# Check of Ollama draait
kubectl get pods -n ai-platform-team4 | grep ollama

# Check model beschikbaarheid
curl http://35.233.49.216/ollama/api/tags
```

### Model niet gevonden
```bash
# Pull het benodigde model
curl -X POST "http://35.233.49.216/ollama/api/pull" \
  -d '{"name": "gpt-oss:20b-cloud"}'
```

### Database errors
```bash
# Check PostgreSQL
kubectl logs -n ai-platform-team4 deployment/postgres-deployment

# Connect naar database
kubectl exec -it -n ai-platform-team4 deployment/postgres-deployment -- \
  psql -U raguser -d ragdb
```

---

## 🔒 Security

- GitLab registry credentials in Kubernetes Secret
- Database credentials in platform-secrets
- Geen externe database toegang (ClusterIP only)
- API Gateway rate limiting enabled

---

## 📞 Contact

**Team 4 - DevOps**  
Verantwoordelijk voor AI Platform infrastructure
