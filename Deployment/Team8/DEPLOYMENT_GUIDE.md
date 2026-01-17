# Team 8 - Dampf Platform Deployment Guide

## ⚡ Quick Start

**Deploy alles met één commando:**
```bash
cd Deployment/Team8/Scripts
bash deploy-team8.sh
```

Dat is alles! Het script handelt af:
- ✅ GCP Infrastructure (Terraform)
- ✅ kubectl configuratie
- ✅ GitLab Registry authenticatie
- ✅ Alle Kubernetes deployments
- ✅ SSL certificaten

---

## 📋 Volledige Setup Guide

Zie **DEPLOYMENT_INSTRUCTIONS.md** in de Deployment folder voor:
- Prerequisites & tools setup
- GCP credentials configuratie
- Volledige stap-voor-stap uitleg

---

## 🏗️ Team8-Specifieke Architectuur

Active manifests toegepast door `Team8/Scripts/deploy-team8.sh` (in volgorde):

```
00-namespace-configmap-secrets.yaml   # Namespace, config, secrets
01-infrastructure.yaml                # PostgreSQL, MySQL, Redis, RabbitMQ, Keycloak
02-elk-stack.yaml                     # Elasticsearch, Logstash, Kibana
02-platform-frontend-backend.yaml     # Platform frontend + backend
03-game-blokus.yaml                   # Blokus frontend + backend + AI
04-gateway.yaml                       # NGINX LoadBalancer met SSL
```

**Deployment Region:** `europe-west1-b` (Belgium)  
**Machine Type:** `e2-standard-4`  
**Namespace:** `bordspelplatform-8`  
**Domain:** `dampf-app.com` / `www.dampf-app.com`

### Routing Architectuur

```
External IP (NGINX Gateway LoadBalancer)
  ↓
  ├── /                    → Platform Frontend
  ├── /api/                → Platform Backend
  ├── /auth/               → Keycloak
  ├── /blokus/             → Blokus Frontend
  ├── /api/blokus/         → Blokus Backend
  ├── /kibana/             → Kibana Dashboard
  ├── /rabbitmq/           → RabbitMQ Management
  │
  └── Proxy naar Team 4:
      ├── /api/chat        → http://35.233.49.216/api/chat
      ├── /api/docs        → http://35.233.49.216/api/docs
      └── /api/ai-player/  → http://35.233.49.216/api/ai-player/
```

---

## 🔧 Stap-voor-Stap Setup

### Stap 1: Setup GCP Cluster

```bash
# Navigeer naar Terraform directory
cd Team8/Terraform

# Review de infrastructure plan
tofu plan

# Apply de configuratie
tofu apply

# Cluster naam: bordspel-platform-team8
```

**Terraform Configuratie:**
```
Region: europe-west1-b (Belgium)
Machine Type: e2-standard-4
Node Count: 1
Cluster: bordspel-platform-team8
```

### Stap 2: Configureer kubectl Access

Na Terraform, configureer lokale kubectl:

```bash
# Haal credentials op van GCP
gcloud container clusters get-credentials bordspel-platform-team8 \
  --zone europe-west1-b \
  --project <PROJECT_ID>

# Verifieer connectie
kubectl cluster-info
kubectl get nodes

# Sla context op voor later
kubectl config rename-context \
  gke_<PROJECT_ID>_europe-west1-b_bordspel-platform-team8 \
  team8
```

### Stap 3: Setup GitLab Registry Secret

Pods hebben credentials nodig om images te pullen van GitLab:

```bash
# Run het setup script
bash Team8/Scripts/setup-gitlab-registry.sh
```

**Of handmatig:**
```bash
kubectl create namespace bordspelplatform-8

kubectl create secret docker-registry gitlab-registry \
  -n bordspelplatform-8 \
  --docker-server=registry.gitlab.com \
  --docker-username=oauth2 \
  --docker-password=<YOUR_GITLAB_TOKEN>
```

**Personal Access Token aanmaken:**
1. Ga naar https://gitlab.com/-/profile/personal_access_tokens
2. Maak nieuwe token met naam "Team8-Kubernetes"
3. Selecteer scope: `read_registry`
4. Kopieer de token (je ziet hem maar één keer!)

### Stap 4: Deploy Alle Componenten

Run de volledige deployment:

```bash
bash Team8/Scripts/deploy-team8.sh
```

**Wat gebeurt er:**
1. Maakt namespace `bordspelplatform-8`
2. Maakt ConfigMap en Secrets
3. Deployt PostgreSQL (wacht op readiness)
4. Deployt MySQL, Redis, RabbitMQ
5. Deployt Keycloak
6. Deployt ELK Stack (Elasticsearch, Logstash, Kibana)
7. Deployt Platform Frontend + Backend
8. Deployt Blokus Frontend + Backend + AI Service
9. Deployt NGINX Gateway met SSL

**Progress Indicators:**
```
[1/6] Deploying Namespace, ConfigMap and Secrets...
[2/6] Deploying Infrastructure (PostgreSQL, MySQL, Redis, RabbitMQ)...
[3/6] Deploying Keycloak...
[4/6] Deploying ELK Stack...
[5/6] Deploying Platform & Blokus Services...
[6/6] Deploying Gateway...
```

### Stap 5: Monitor Deployment

```bash
# Check alle pods draaien
bash Team8/Scripts/status.sh

# Watch real-time pod status
kubectl get pods -n bordspelplatform-8 -w

# Check service status
kubectl get svc -n bordspelplatform-8

# Haal external IP op
kubectl get svc nginx-gateway-service -n bordspelplatform-8
```

### Stap 6: DNS Configureren

Map je domein naar het external IP:
```
dampf-app.com     → 34.76.92.71
www.dampf-app.com → 34.76.92.71
```

---

## 🌐 Platform Toegang

### URLs

| Service | URL | Beschrijving |
|---------|-----|--------------|
| Platform | `https://www.dampf-app.com` | Hoofdplatform |
| Blokus | `https://www.dampf-app.com/blokus/` | Blokus game |
| Keycloak | `https://www.dampf-app.com/auth/` | Login/registratie |
| Kibana | `https://www.dampf-app.com/kibana/` | Log dashboard |
| RabbitMQ | `https://www.dampf-app.com/rabbitmq/` | Message queue UI |
| Chatbot API | `https://www.dampf-app.com/api/chat` | AI chatbot |

### Default Credentials

**Keycloak:**
- Admin Console: `https://www.dampf-app.com/auth/admin`
- Username: `admin`
- Password: `admin`
- Realm: `boardgame-platform`

**RabbitMQ:**
- Username: `user`
- Password: `password`

**Database (PostgreSQL):**
- User: `user`
- Password: `password`

**Database (MySQL - Keycloak):**
- User: `keycloak`
- Password: `keycloak`

⚠️ **BELANGRIJK:** Wijzig deze voor productie!

---

## 🎮 Blokus Game

### Blokus Spelen
1. Ga naar `https://www.dampf-app.com`
2. Login via Keycloak
3. Ga naar Games → Blokus
4. Start nieuw spel met AI tegenstander

### Blokus AI
De AI service draait lokaal in het cluster:
```bash
# Check AI service status
kubectl get pods -n bordspelplatform-8 -l app=ai-service

# Test AI endpoint
kubectl exec -n bordspelplatform-8 deployment/blokus-backend-deployment -- \
  curl -s http://ai-service:8000/openapi.json
```

**AI Endpoints (intern):**
- `http://ai-service:8000/games/best-move` - Generieke beste zet
- `http://ai-service:8000/games/blokus/best-move` - Blokus specifiek

---

## 🤖 Chatbot Integratie

De chatbot draait op Team 4's cluster en wordt geproxied via NGINX:

### Test Chatbot
```bash
curl -X POST "https://www.dampf-app.com/api/chat" \
  -H "Content-Type: application/json" \
  -d '{"message": "Welke games kan ik spelen?"}'
```

### Proxy Configuratie
In `04-gateway.yaml`:
```nginx
location /api/chat {
    proxy_pass http://35.233.49.216/api/chat;
}
location /api/docs {
    proxy_pass http://35.233.49.216/api/docs;
}
location /api/ai-player/ {
    proxy_pass http://35.233.49.216/api/ai-player/;
}
```

---

## 📊 Monitoring & Logging

### Kibana Dashboard
Toegang: `https://www.dampf-app.com/kibana/`

**Setup Index Pattern:**
1. Ga naar Management → Index Patterns
2. Maak pattern `logstash-*`
3. Selecteer `@timestamp` als time field

**Beschikbare Dashboards:**
- Player Behaviour - Gebruikersactiviteit
- Revenue Dashboard - Transacties
- System Health - Infrastructure metrics

### View Logs
```bash
# Platform backend
kubectl logs -f deployment/platform-backend-deployment -n bordspelplatform-8

# Blokus backend
kubectl logs -f deployment/blokus-backend-deployment -n bordspelplatform-8

# Keycloak
kubectl logs -f deployment/keycloak-deployment -n bordspelplatform-8

# NGINX Gateway
kubectl logs -f deployment/nginx-gateway-deployment -n bordspelplatform-8
```

### Monitor Resources
```bash
# Pod resource usage
kubectl top pods -n bordspelplatform-8

# Node resource usage
kubectl top nodes

# Continue monitoring
watch kubectl get pods -n bordspelplatform-8
```

### View Events
```bash
kubectl get events -n bordspelplatform-8 --sort-by='.lastTimestamp'
```

---

## ❌ Troubleshooting

### 1. Pods Starten Niet

```bash
# Check pod status
kubectl get pods -n bordspelplatform-8

# Describe pod voor events
kubectl describe pod <pod-name> -n bordspelplatform-8

# Bekijk logs
kubectl logs <pod-name> -n bordspelplatform-8
kubectl logs <pod-name> -n bordspelplatform-8 --previous
```

### 2. ImagePullBackOff Error

```bash
# Check het secret
kubectl get secret gitlab-registry -n bordspelplatform-8

# Recreate het secret
kubectl create secret docker-registry gitlab-registry \
  -n bordspelplatform-8 \
  --docker-server=registry.gitlab.com \
  --docker-username=oauth2 \
  --docker-password=<TOKEN> \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart deployment
kubectl rollout restart deployment/<name> -n bordspelplatform-8
```

### 3. Keycloak Login Faalt

```bash
# Check Keycloak logs
kubectl logs -n bordspelplatform-8 deployment/keycloak-deployment

# Verify MySQL connectie
kubectl exec -n bordspelplatform-8 deployment/mysql-deployment -- \
  mysql -ukeycloak -pkeycloak -e "SHOW DATABASES;"

# Check realm configuratie
# Login op https://www.dampf-app.com/auth/admin
```

### 4. Blokus AI Werkt Niet

```bash
# Check AI service logs
kubectl logs -n bordspelplatform-8 deployment/ai-service-deployment

# Test AI endpoint intern
kubectl exec -n bordspelplatform-8 deployment/blokus-backend-deployment -- \
  curl -s http://ai-service:8000/games/best-move

# Check environment variable
kubectl get deployment blokus-backend-deployment -n bordspelplatform-8 -o yaml | grep AI_SERVICE
```

### 5. Database Connection Issues

```bash
# Test PostgreSQL
kubectl exec -n bordspelplatform-8 deployment/postgres-deployment -- \
  psql -U user -d postgres -c "\l"

# Test MySQL
kubectl exec -n bordspelplatform-8 deployment/mysql-deployment -- \
  mysql -uroot -proot -e "SHOW DATABASES;"

# Check Redis
kubectl exec -n bordspelplatform-8 deployment/redis-deployment -- redis-cli PING
```

### 6. Gateway Routing Issues

```bash
# Check NGINX config
kubectl get configmap nginx-config -n bordspelplatform-8 -o yaml

# Bekijk gateway logs
kubectl logs -f deployment/nginx-gateway-deployment -n bordspelplatform-8

# Test routing intern
kubectl exec -n bordspelplatform-8 deployment/nginx-gateway-deployment -- \
  curl -s http://platform-frontend-service/
```

### 7. SSL Certificate Issues

```bash
# Check certificate secret
kubectl get secret nginx-ssl-secret -n bordspelplatform-8

# Verify certificate expiry
kubectl get secret nginx-ssl-secret -n bordspelplatform-8 -o jsonpath='{.data.tls\.crt}' | \
  base64 -d | openssl x509 -noout -dates
```

---

## 📊 Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| **Pods stuck in Pending** | Onvoldoende resources. Check: `kubectl top nodes` |
| **CrashLoopBackOff** | Check logs: `kubectl logs <pod> -n bordspelplatform-8` |
| **ImagePullBackOff** | GitLab credentials. Run setup-gitlab-registry.sh |
| **LoadBalancer pending** | Wacht 5-10 min. Check: `kubectl get svc -n bordspelplatform-8 -w` |
| **Keycloak 503** | MySQL niet ready. Check MySQL pod |
| **Blokus AI timeout** | AI service overbelast of niet running |
| **Chatbot fails** | Team 4 cluster niet bereikbaar |
| **SSL errors** | Certificate secret ontbreekt of verlopen |

---

## 🔄 Scaling & Updates

### Scale een Deployment
```bash
# Scale platform backend naar 3 replicas
kubectl scale deployment platform-backend-deployment -n bordspelplatform-8 --replicas=3

# Monitor scaling
kubectl get pods -l app=platform-backend -n bordspelplatform-8 -w
```

### Update Container Image
```bash
# Update platform backend
kubectl set image deployment/platform-backend-deployment \
  platform-backend=registry.gitlab.com/.../backend-platform-service:v2.0 \
  -n bordspelplatform-8

# Monitor rollout
kubectl rollout status deployment/platform-backend-deployment -n bordspelplatform-8
```

### Rollback
```bash
# View history
kubectl rollout history deployment/platform-backend-deployment -n bordspelplatform-8

# Rollback
kubectl rollout undo deployment/platform-backend-deployment -n bordspelplatform-8
```

### Restart Alle Services
```bash
kubectl rollout restart deployment/platform-frontend-deployment \
  deployment/platform-backend-deployment \
  deployment/blokus-frontend-deployment \
  deployment/blokus-backend-deployment \
  -n bordspelplatform-8
```

---

## ⚙️ Configuratie Aanpassen

### Update ConfigMap
```bash
# Edit ConfigMap
kubectl edit configmap platform-config -n bordspelplatform-8

# Pods herstarten om changes op te pikken
kubectl rollout restart deployment -n bordspelplatform-8
```

### Update Secrets
```bash
# Edit Secret (base64 encoded)
kubectl edit secret platform-secrets -n bordspelplatform-8

# Pods herstarten
kubectl rollout restart deployment -n bordspelplatform-8
```

---

## 🧹 Cleanup & Teardown

### Verwijder Alle Resources
```bash
bash Team8/Scripts/teardown-team8.sh
```

Dit verwijdert de namespace `bordspelplatform-8` en alle resources.

### Cleanup GCP Infrastructure
```bash
cd Team8/Terraform
tofu destroy
```

---

## 📚 Aanvullende Scripts

| Script | Doel |
|--------|------|
| `Team8/Scripts/deploy-team8.sh` | Deploy alle componenten |
| `Team8/Scripts/teardown-team8.sh` | Verwijder alle resources |
| `Team8/Scripts/status.sh` | Check deployment status |
| `Team8/Scripts/setup-gitlab-registry.sh` | GitLab registry access |
| `Team8/Scripts/setup-postgres-schemas.sh` | Database schema setup |
| `Team8/Scripts/update-external-ip.sh` | Update DNS config |
| `Team8/Scripts/monitor-deployment.sh` | Real-time monitoring |

---

## 🔗 Cross-Team Dependencies

Team 8 is afhankelijk van Team 4 voor:
- **Chatbot API** - `/api/chat` → Team 4
- **Document API** - `/api/docs` → Team 4
- **AI Player API** - `/api/ai-player/` → Team 4

**Team 4 IP:** `35.233.49.216`

Als Team 4 niet beschikbaar is:
- Chatbot features werken niet
- AI player proxy endpoints falen
- Lokale Blokus AI werkt nog wel (ai-service in eigen cluster)

---

**Last Updated:** 2026-01-04  
**Team:** Team 8  
**Project:** IntegrationProject J3 - Dampf Platform
