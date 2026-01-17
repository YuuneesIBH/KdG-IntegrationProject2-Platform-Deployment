# Team8 Kubernetes Deployment - Index & Start Here

## 🎯 Where to Start?

Choose your path based on what you need to do:

### 🚀 **I want to deploy now**
→ Read: `QUICK_REFERENCE.md` (2 min read)  
→ Run: `./setup-gitlab-registry.sh` then `./deploy.sh`

### 📚 **I want to understand the setup**
→ Read: `DEPLOYMENT_GUIDE.md` (full walkthrough)  
→ Read: `README.md` (technical deep dive)

### 🔍 **I want to review the configuration**
→ Check: `pods/` directory (12 individual service files)  
→ Check: `00-namespace-configmap-secrets.yaml` (configuration)

### 🐛 **Something is broken**
→ Run: `./status.sh` (shows current state)  
→ Run: `./verify.sh` (validates configuration)  
→ Check: `README.md` → Troubleshooting section

### 📋 **I want to understand what was built**
→ Read: `IMPLEMENTATION_SUMMARY.md` (overview of changes)

---

## 📁 Directory Structure

```
Team8/Kubernetes/
│
├─── Configuration
│    ├── 00-namespace-configmap-secrets.yaml  ← Namespace, ConfigMap, Secrets, PVCs
│    └── pods/  ← 12 individual service deployments
│        ├── 01-postgres.yaml                 ← Database
│        ├── 02-redis.yaml                    ← Cache
│        ├── 03-rabbitmq.yaml                 ← Message Broker
│        ├── 04-keycloak.yaml                 ← Auth Service
│        ├── 05-elasticsearch.yaml            ← Log Storage
│        ├── 06-logstash.yaml                 ← Log Processor
│        ├── 07-kibana.yaml                   ← Log Viewer
│        ├── 08-platform-frontend.yaml        ← UI
│        ├── 09-platform-backend.yaml         ← API
│        ├── 10-blokus-backend.yaml          ← Game
│        ├── 11-ai-service.yaml               ← AI
│        └── 12-api-gateway.yaml              ← Router
│
├─── Scripts
│    ├── deploy.sh                    ← Deploy everything
│    ├── teardown.sh                  ← Remove everything
│    ├── status.sh                    ← Check status
│    ├── verify.sh                    ← Validate config
│    └── setup-gitlab-registry.sh     ← Setup credentials
│
├─── Documentation
│    ├── QUICK_REFERENCE.md           ← START HERE (5 min)
│    ├── DEPLOYMENT_GUIDE.md          ← Step-by-step guide
│    ├── README.md                    ← Full documentation
│    ├── IMPLEMENTATION_SUMMARY.md    ← What was built
│    └── INDEX.md                     ← This file
│
└─── Reference (Old Files - kept as backup)
     ├── 01-infrastructure.yaml
     ├── 02-elk-stack.yaml
     ├── 02-platform-frontend-backend.yaml
     ├── 03-game-blokus.yaml
     └── 04-gateway.yaml
```

---

## ⚡ 5-Step Quick Start

```bash
# 1. Setup cluster credentials (from GCP)
gcloud container clusters get-credentials bordspel-platform-team8 --zone europe-west1-b

# 2. Navigate to Kubernetes directory
cd Team8/Kubernetes

# 3. Setup GitLab registry access
./setup-gitlab-registry.sh

# 4. Verify everything is configured
./verify.sh

# 5. Deploy!
./deploy.sh

# Monitor deployment
./status.sh
```

---

## 📚 Documentation Guide

| File | Length | Content | Read When |
|------|--------|---------|-----------|
| **QUICK_REFERENCE.md** | 2 min | Commands, URLs, troubleshooting | Before first deployment |
| **DEPLOYMENT_GUIDE.md** | 15 min | Full step-by-step walkthrough | Planning a deployment |
| **README.md** | 20 min | Complete technical documentation | Understanding the architecture |
| **IMPLEMENTATION_SUMMARY.md** | 10 min | What was built and why | Understanding the changes |
| **INDEX.md** | 3 min | This file - navigation guide | Getting oriented |

---

## 🔧 Scripts Reference

### Main Deployment
```bash
./deploy.sh          # Deploy all 12 services in correct order
./teardown.sh        # Remove entire deployment
./status.sh          # Check current pod status
./verify.sh          # Validate YAML before deployment
```

### Setup & Configuration
```bash
./setup-gitlab-registry.sh  # Configure GitLab image pull credentials
```

---

## 🎯 What Each Pod Does

| # | Pod | Purpose | Port | Storage |
|---|-----|---------|------|---------|
| 1 | PostgreSQL | Main database | 5432 | 20Gi |
| 2 | Redis | Caching layer | 6379 | 5Gi |
| 3 | RabbitMQ | Message broker | 5672 | 5Gi |
| 4 | Keycloak | Authentication | 8080 | - |
| 5 | Elasticsearch | Log storage | 9200 | 10Gi |
| 6 | Logstash | Log processing | 5000 | - |
| 7 | Kibana | Log viewer | 5601 | - |
| 8 | Platform Frontend | Web UI | 80 | - |
| 9 | Platform Backend | REST API | 8080 | - |
| 10 | Blokus | Game service | 8080 | - |
| 11 | AI Service | Game AI | 8000 | - |
| 12 | API Gateway | Router/LB | 80 | - |

---

## 💾 Storage

All data is persisted:
- PostgreSQL: 20GB (platform, blokus databases)
- MySQL: 10GB (keycloak database)
- Redis: 5GB (cache)
- RabbitMQ: 5GB (message queue)
- Elasticsearch: 10GB (logs)

**Total: 40GB storage** on e2-standard-2 machines

---

## 🌍 Regional Configuration

- **Region**: europe-west1-b (Belgium)
- **Machine Type**: e2-standard-2
- **Cluster Name**: bordspel-platform-team8
- **Project**: ip2-devops4-480317

---

## 🚦 Deployment Status Indicators

After running `./deploy.sh`, check status:

```bash
✅ Pod Status
✅ Services (should see api-gateway with EXTERNAL-IP)
✅ Storage (PVCs should be Bound)
✅ Events (should show successful deployments)
✅ Logs (sample logs from platform-backend)
```

---

## 🔐 Default Credentials

**⚠️ IMPORTANT: Change these in production!**

| Service | User | Password |
|---------|------|----------|
| Keycloak | admin | admin |
| RabbitMQ | user | password |
| PostgreSQL | user | password |

Database connections from components use environment variables from Secrets.

---

## 📞 Getting Help

### If deployment fails:
1. Run `./status.sh` to see what's wrong
2. Check specific pod: `kubectl describe pod <pod-name> -n bordspelplatform`
3. View logs: `kubectl logs <pod-name> -n bordspelplatform`
4. See the **Troubleshooting** section in `README.md`

### If you need to understand something:
1. Check `QUICK_REFERENCE.md` for commands
2. Read `DEPLOYMENT_GUIDE.md` for procedures
3. Review `README.md` for technical details

### If you need to customize:
1. Edit `00-namespace-configmap-secrets.yaml` for ConfigMap/Secrets
2. Edit specific `pods/*.yaml` files for service configuration
3. Run `./verify.sh` to validate changes
4. Re-run `./deploy.sh` to apply changes

---

## ✅ Checklist Before Deployment

- [ ] Terraform infrastructure created (GKE cluster running)
- [ ] kubectl configured and connected to cluster
- [ ] GitLab personal access token generated (read_registry scope)
- [ ] `./verify.sh` passes all checks
- [ ] GitLab registry secret created with `./setup-gitlab-registry.sh`
- [ ] Ready to run `./deploy.sh`

---

## 🔄 Common Tasks

### Deploy
```bash
./deploy.sh
```

### Check Status
```bash
./status.sh
```

### View Logs
```bash
kubectl logs -f pod/<pod-name> -n bordspelplatform
```

### Access Services
```bash
# Get external IP
kubectl get svc api-gateway -n bordspelplatform

# Copy the EXTERNAL-IP and access at http://<IP>/
```

### Scale a Service
```bash
kubectl scale deployment <deployment-name> --replicas=3 -n bordspelplatform
```

### Update an Image
```bash
kubectl set image deployment/<name> <container>=<new-image>:tag -n bordspelplatform
```

### Restart a Service
```bash
kubectl rollout restart deployment/<name> -n bordspelplatform
```

### Remove Everything
```bash
./teardown.sh
```

---

## 📊 Architecture at a Glance

```
┌─ External Users ─────────────────────────┐
│                                           │
│        API Gateway (NGINX Router)        │
│              (LoadBalancer)              │
│                                           │
│  ┌──────────────────────────────────┐    │
│  │  Routes: /auth, /api, /, etc     │    │
│  └──────────────────────────────────┘    │
│                                           │
│  ┌──────────────────────────────────┐    │
└→ │ Frontend │ Backend │ Auth Service│    │
   │  Game    │ Game AI │ RabbitMQ    │    │
   └──────────────────────────────────┘    │
           │              │                 │
           v              v                 │
   ┌─────────────────────────────┐          │
   │  PostgreSQL    │  Redis    │          │
   │  Cache         │ Broker     │          │
   └─────────────────────────────┘          │
                                             │
   ┌─────────────────────────────┐          │
   │  Elasticsearch │ Logstash   │          │
   │  Kibana Dashboard           │          │
   └─────────────────────────────┘          │
```

---

## 🎓 Learning Resources

- **Kubernetes**: https://kubernetes.io/docs/
- **GKE**: https://cloud.google.com/kubernetes-engine/docs
- **kubectl**: https://kubernetes.io/docs/reference/kubectl/
- **Keycloak**: https://www.keycloak.org/documentation

---

## 📝 File Summary

- **27 files total** in this directory
- **12 pod configuration files** in pods/ subdirectory
- **5 automation scripts** (deploy, teardown, status, verify, setup-gitlab)
- **5 documentation files** (README, guides, this index)
- **5 reference files** (old configurations, kept as backup)

---

## ✨ Key Features

✅ Pod-based architecture (each service in own file)
✅ Automated deployment in correct order
✅ Health checks on all services
✅ Persistent storage for stateful services
✅ Service discovery via Kubernetes DNS
✅ Complete ELK logging stack
✅ API gateway with routing
✅ GitLab registry integration
✅ Full documentation and guides
✅ Validation and verification scripts

---

**Next Step**: Open `QUICK_REFERENCE.md` and follow the 5-step deployment!

---

**Status**: ✅ Ready to Deploy
**Last Updated**: 2025-12-12
**Team**: Team8 Only
**Region**: europe-west1-b (Belgium)
