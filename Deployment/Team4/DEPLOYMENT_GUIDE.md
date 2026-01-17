# Team 4 - AI Platform Deployment Guide

## ⚡ Quick Start

**Deploy alles met één commando:**
```bash
cd Deployment/Team4/Scripts
bash deploy-team4.sh
```

Dat is alles! Het script handelt af:
- ✅ GCP Infrastructure (Terraform)
- ✅ kubectl configuratie
- ✅ GitLab Registry authenticatie
- ✅ Alle Kubernetes deployments
- ✅ Ollama model downloads

---

## 📋 Volledige Setup Guide

Zie **DEPLOYMENT_INSTRUCTIONS.md** in de Deployment folder voor:
- Prerequisites & tools setup
- GCP credentials configuratie
- Volledige stap-voor-stap uitleg

---

## 🏗️ Team4-Specifieke Architectuur

Active manifests toegepast door `Team4/Scripts/deploy-team4.sh` (in volgorde):

```
00-namespace-configmap-secrets.yaml   # Namespace, config, secrets
01-infrastructure.yaml                # PostgreSQL met pgvector
02-ollama.yaml                        # Ollama LLM server
03-ai-services.yaml                   # Chatbot RAG, AI Player
04-gateway.yaml                       # NGINX LoadBalancer
```

**Deployment Region:** `europe-west1-b` (Belgium)  
**Machine Type:** `e2-standard-4` (minimaal 8GB RAM voor Ollama)  
**Namespace:** `ai-platform-team4`

---

## 🔧 Stap-voor-Stap Setup

### Stap 1: Setup GCP Cluster

```bash
# Navigeer naar Terraform directory
cd Team4/Terraform

# Review de infrastructure plan
tofu plan

# Apply de configuratie
tofu apply

# Cluster naam: ai-platform-team4
```

**Terraform Configuratie:**
```
Region: europe-west1-b (Belgium)
Machine Type: e2-standard-4
Node Count: 1-2 (autoscaling)
Cluster: ai-platform-team4
```

### Stap 2: Configureer kubectl Access

Na Terraform, configureer lokale kubectl:

```bash
# Haal credentials op van GCP
gcloud container clusters get-credentials ai-platform-team4 \
  --zone europe-west1-b \
  --project <PROJECT_ID>

# Verifieer connectie
kubectl cluster-info
kubectl get nodes

# Sla context op voor later
kubectl config rename-context \
  gke_<PROJECT_ID>_europe-west1-b_ai-platform-team4 \
  team4
```

### Stap 3: Setup GitLab Registry Secret

Pods hebben credentials nodig om images te pullen van GitLab:

```bash
# Run het setup script
bash Team4/Scripts/setup-gitlab-registry.sh
```

**Of handmatig:**
```bash
kubectl create namespace ai-platform-team4

kubectl create secret docker-registry gitlab-registry \
  -n ai-platform-team4 \
  --docker-server=registry.gitlab.com \
  --docker-username=oauth2 \
  --docker-password=<YOUR_GITLAB_TOKEN>
```

**Personal Access Token aanmaken:**
1. Ga naar https://gitlab.com/-/profile/personal_access_tokens
2. Maak nieuwe token met naam "Team4-Kubernetes"
3. Selecteer scope: `read_registry`
4. Kopieer de token (je ziet hem maar één keer!)

### Stap 4: Deploy Alle Componenten

Run de volledige deployment:

```bash
bash Team4/Scripts/deploy-team4.sh
```

**Wat gebeurt er:**
1. Maakt namespace `ai-platform-team4`
2. Maakt ConfigMap en Secrets
3. Deployt PostgreSQL met pgvector (wacht op readiness)
4. Deployt Ollama LLM server
5. Wacht tot Ollama ready is
6. Deployt Chatbot RAG service
7. Deployt AI Player service
8. Deployt NGINX Gateway
9. Pullt Ollama modellen (gpt-oss:20b-cloud, bge-m3)

**Progress Indicators:**
```
[1/5] Deploying Namespace, ConfigMap and Secrets...
[2/5] Deploying Infrastructure (PostgreSQL)...
[3/5] Deploying Ollama LLM Server...
[4/5] Deploying AI Services (Chatbot, AI Player)...
[5/5] Deploying Gateway...
[POST] Pulling Ollama models...
```

### Stap 5: Monitor Deployment

```bash
# Check alle pods draaien
kubectl get pods -n ai-platform-team4 -w

# Check service status
kubectl get svc -n ai-platform-team4

# Haal external IP op
kubectl get svc nginx-gateway-service -n ai-platform-team4
```

---

## 🌐 Platform Toegang

### External IP
Na deployment, haal het external IP op:

```bash
kubectl get svc nginx-gateway-service -n ai-platform-team4
```

**Huidige IP:** `35.233.49.216`

### API Endpoints

| Endpoint | URL | Methode | Beschrijving |
|----------|-----|---------|--------------|
| Chatbot | `/api/chat` | POST | AI chat met context |
| Chat History | `/api/chat/history/{sessionId}` | GET | Chat geschiedenis |
| Document Upload | `/api/docs/upload` | POST | Upload documenten |
| Document List | `/api/docs` | GET | Lijst documenten |
| AI Best Move | `/api/ai-player/games/best-move` | POST | Beste zet (generiek) |
| Blokus AI | `/api/ai-player/games/blokus/best-move` | POST | Blokus AI |
| TTT AI | `/api/ai-player/games/tic-tac-toe/best-move` | POST | Tic-Tac-Toe AI |
| Ollama API | `/ollama/api/tags` | GET | Beschikbare modellen |

### Test Commands

```bash
# Test chatbot
curl -X POST "http://35.233.49.216/api/chat" \
  -H "Content-Type: application/json" \
  -d '{"message": "Welke bordspellen zijn er?"}'

# Test AI player
curl -X POST "http://35.233.49.216/api/ai-player/games/tic-tac-toe/best-move" \
  -H "Content-Type: application/json" \
  -d '{"board": [[null,null,null],[null,"X",null],[null,null,null]], "player": "O"}'

# Check Ollama modellen
curl "http://35.233.49.216/ollama/api/tags"

# Upload document
curl -X POST "http://35.233.49.216/api/docs/upload" \
  -F "file=@document.txt"
```

---

## 🤖 Ollama Model Management

### Beschikbare Modellen
```bash
# Lijst huidige modellen
curl "http://35.233.49.216/ollama/api/tags"
```

**Vereiste modellen:**
- `gpt-oss:20b-cloud` - Chat model
- `bge-m3:latest` - Embedding model

### Model Pullen
```bash
# Pull een nieuw model
curl -X POST "http://35.233.49.216/ollama/api/pull" \
  -H "Content-Type: application/json" \
  -d '{"name": "gpt-oss:20b-cloud"}'

# Via kubectl
kubectl exec -n ai-platform-team4 deployment/ollama-deployment -- \
  ollama pull gpt-oss:20b-cloud
```

### Model Verwijderen
```bash
curl -X DELETE "http://35.233.49.216/ollama/api/delete" \
  -H "Content-Type: application/json" \
  -d '{"name": "model-name"}'
```

---

## 🗄️ Database Management

### PostgreSQL met pgvector
De database bevat:
- `documents` - Geüploade documenten
- `document_chunks` - Gesplitste document chunks met embeddings

### Database Toegang
```bash
# Exec in postgres pod
kubectl exec -it -n ai-platform-team4 deployment/postgres-deployment -- \
  psql -U raguser -d ragdb

# Bekijk tabellen
\dt

# Bekijk documenten
SELECT id, filename, file_type FROM documents;

# Bekijk chunks
SELECT id, document_id, LEFT(content, 100) FROM document_chunks LIMIT 10;
```

### Database Reset
```bash
# Drop en recreate tabellen
kubectl exec -n ai-platform-team4 deployment/postgres-deployment -- \
  psql -U raguser -d ragdb -c "
    DROP TABLE IF EXISTS document_chunks;
    DROP TABLE IF EXISTS documents;
  "

# Restart chatbot om tabellen te recreëren
kubectl rollout restart deployment/chatbot-rag-deployment -n ai-platform-team4
```

---

## ❌ Troubleshooting

### 1. Pods Starten Niet

```bash
# Check pod status
kubectl get pods -n ai-platform-team4

# Describe pod voor events
kubectl describe pod <pod-name> -n ai-platform-team4

# Bekijk logs
kubectl logs <pod-name> -n ai-platform-team4
```

### 2. ImagePullBackOff Error

```bash
# Check het secret
kubectl get secret gitlab-registry -n ai-platform-team4

# Recreate het secret
kubectl create secret docker-registry gitlab-registry \
  -n ai-platform-team4 \
  --docker-server=registry.gitlab.com \
  --docker-username=oauth2 \
  --docker-password=<TOKEN> \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart deployment
kubectl rollout restart deployment/<name> -n ai-platform-team4
```

### 3. Ollama Out of Memory

```bash
# Check node resources
kubectl top nodes

# Check Ollama logs
kubectl logs -n ai-platform-team4 deployment/ollama-deployment

# Verklein model of verhoog node resources
# Minimaal 8GB RAM voor gpt-oss:20b-cloud
```

### 4. Chatbot "thinking not supported" Error

```bash
# Check CHAT_MODEL environment variable
kubectl get deployment chatbot-rag-deployment -n ai-platform-team4 -o yaml | grep CHAT_MODEL

# Model moet gpt-oss:20b-cloud zijn (niet llama3.2:3b)
kubectl set env deployment/chatbot-rag-deployment \
  -n ai-platform-team4 \
  CHAT_MODEL=gpt-oss:20b-cloud

# Restart
kubectl rollout restart deployment/chatbot-rag-deployment -n ai-platform-team4
```

### 5. Database Connection Issues

```bash
# Test PostgreSQL
kubectl exec -n ai-platform-team4 deployment/postgres-deployment -- \
  psql -U raguser -d ragdb -c "SELECT 1"

# Check pgvector extension
kubectl exec -n ai-platform-team4 deployment/postgres-deployment -- \
  psql -U raguser -d ragdb -c "SELECT * FROM pg_extension WHERE extname='vector'"
```

### 6. Embedding Errors

```bash
# Check embedding model is geladen
curl "http://35.233.49.216/ollama/api/tags" | grep bge-m3

# Pull embedding model indien nodig
curl -X POST "http://35.233.49.216/ollama/api/pull" \
  -d '{"name": "bge-m3:latest"}'
```

---

## 📊 Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| **Pods stuck in Pending** | Onvoldoende resources. Check: `kubectl top nodes` |
| **CrashLoopBackOff** | Check logs: `kubectl logs <pod> -n ai-platform-team4` |
| **ImagePullBackOff** | GitLab credentials. Run setup-gitlab-registry.sh |
| **LoadBalancer pending** | Wacht 5-10 min. Check: `kubectl get svc -n ai-platform-team4 -w` |
| **Ollama OOMKilled** | Node heeft meer RAM nodig (min 8GB) |
| **Chat returns empty** | Model niet geladen. Pull gpt-oss:20b-cloud |
| **Embeddings fail** | bge-m3 niet geladen. Pull het model |

---

## 📈 Monitoring & Logging

### View Logs
```bash
# Chatbot logs
kubectl logs -f deployment/chatbot-rag-deployment -n ai-platform-team4

# AI Player logs
kubectl logs -f deployment/ai-player-deployment -n ai-platform-team4

# Ollama logs
kubectl logs -f deployment/ollama-deployment -n ai-platform-team4

# PostgreSQL logs
kubectl logs -f deployment/postgres-deployment -n ai-platform-team4
```

### Monitor Resources
```bash
# Pod resource usage
kubectl top pods -n ai-platform-team4

# Node resource usage
kubectl top nodes

# Continue monitoring
watch kubectl get pods -n ai-platform-team4
```

---

## 🔄 Scaling & Updates

### Scale een Deployment
```bash
# Scale chatbot naar 2 replicas
kubectl scale deployment chatbot-rag-deployment -n ai-platform-team4 --replicas=2
```

### Update Container Image
```bash
kubectl set image deployment/chatbot-rag-deployment \
  chatbot-rag=registry.gitlab.com/.../chatbot-and-recommendation-system:v2.0 \
  -n ai-platform-team4

kubectl rollout status deployment/chatbot-rag-deployment -n ai-platform-team4
```

### Rollback
```bash
kubectl rollout undo deployment/chatbot-rag-deployment -n ai-platform-team4
```

---

## 🧹 Cleanup & Teardown

### Verwijder Alle Resources
```bash
bash Team4/Scripts/teardown-team4.sh
```

### Cleanup GCP Infrastructure
```bash
cd Team4/Terraform
tofu destroy
```

---

## 📚 Aanvullende Scripts

| Script | Doel |
|--------|------|
| `Team4/Scripts/deploy-team4.sh` | Deploy alle componenten |
| `Team4/Scripts/teardown-team4.sh` | Verwijder alle resources |
| `Team4/Scripts/setup-gitlab-registry.sh` | GitLab registry access |
| `Team4/Scripts/pull-models.sh` | Download Ollama modellen |

---

**Last Updated:** 2026-01-04  
**Team:** Team 4  
**Project:** IntegrationProject J3 - AI Platform
