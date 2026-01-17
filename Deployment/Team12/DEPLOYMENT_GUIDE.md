# Team12 Kubernetes Deployment Guide

## ⚡ Quick Start

**Deploy everything from the root directory:**
```bash
cd /home/kali/Downloads/IntegrationProject2-Deployment-main
./Scripts/main.sh
# Select: 3 (Deploy) → 3 (Team12)
```

That's it! The script handles:
- ✅ GCP Infrastructure (Terraform)
- ✅ kubectl configuration
- ✅ GitLab Registry authentication
- ✅ All Kubernetes deployments

---

## 📋 Complete Setup Guide

See **DEPLOYMENT_INSTRUCTIONS.md** in the root directory for:
- Prerequisites & tools setup
- GCP credentials configuration
- Full step-by-step walkthrough

---

## 🏗️ Team12-Specific Architecture

Active manifests applied by `Team12/Scripts/deploy-team12.sh` (in order):

```
00-namespace-configmap-secrets.yaml   # Namespace, config, secrets
01-infrastructure.yaml                # PostgreSQL, Redis, RabbitMQ, Keycloak
02-elk-stack.yaml                     # Elasticsearch, Logstash, Kibana
03-platform-frontend-backend.yaml     # Platform frontend + backend + AI
04-game-tic-tac-toe.yaml             # Tic-Tac-Toe services
05-gateway.yaml                       # NGINX LoadBalancer
06-game-chess.yaml                    # Chess frontend + backend
07-ssl-certificate.yaml               # TLS for stoom-app.com
```

Reference (not applied automatically): `pods/` contains per-service manifests for inspection.

**Deployment Region:** `europe-west1-b` (Belgium)  
**Machine Type:** `e2-standard-4`  
**Namespace:** `bordspelplatform-12`

### Step 1: Setup GCP Cluster

```bash
# Navigate to Terraform directory
cd ../Terraform

# Review the infrastructure plan
terraform plan

# Apply the configuration
# This will:
# - Create a GKE cluster in europe-west1-b
# - Setup VPC network
# - Configure Cloud SQL PostgreSQL instance
# - Setup service accounts and IAM
terraform apply

# Cluster name output: see terraform outputs (e.g., bordspel-platform-team12)
```

**Terraform Configuration Details:**
```
Region: europe-west1-b (Belgium)
Machine Type: e2-standard-4
Node Count: 1
Cluster: bordspel-platform-team12
```

### Step 2: Configure kubectl Access

After Terraform completes, configure local kubectl:

```bash
# Get credentials from GCP
gcloud container clusters get-credentials bordspel-platform-team12 \
  --zone europe-west1-b \
  --project ip2-devops4-480317

# Verify connection
kubectl cluster-info
kubectl get nodes
```

### Step 3: Setup GitLab Registry Secret

Before deploying, pods need credentials to pull images from GitLab:

```bash
# Run the setup script
bash Team12/Scripts/setup-gitlab-registry.sh
```

**What you'll need:**
- GitLab Username
- GitLab Personal Access Token (generate at: https://gitlab.com/-/profile/personal_access_tokens)
  - Required scopes: `read_registry`
- Your email address

**To create a Personal Access Token:**
1. Go to https://gitlab.com/-/profile/personal_access_tokens
2. Create new token with name "Team12-Kubernetes"
3. Select scope: `read_registry`
4. Copy the token (you won't see it again!)

### Step 4: Verify Configuration

Before deployment, verify all configurations are correct:

```bash
bash Team12/Scripts/verify-fixes.sh
```

**Expected Output:**
```
✅ OK: 00-namespace-configmap-secrets.yaml has valid syntax
✅ OK: postgres-deployment found
✅ OK: postgres-service DNS configured correctly
...
✅ All checks passed! Ready for deployment.
```

### Step 5: Deploy All Components

Run the complete deployment:

```bash
bash Team12/Scripts/deploy-team12.sh
```

**What happens:**
1. Creates namespace `bordspelplatform-12`
2. Creates ConfigMap and Secrets
3. Deploys PostgreSQL (waits for readiness)
4. Deploys Redis
5. Deploys RabbitMQ
6. Deploys Keycloak
7. Deploys Elasticsearch, Logstash, Kibana
8. Deploys all application services
9. Deploys API Gateway

**Progress Indicators:**
```
[1/3] Deploying Namespace, ConfigMap and Secrets...
[2/3] Deploying Infrastructure Pods (in order)...
[3/3] Deploying Logging Stack (ELK) and Application Pods...
```

### Step 6: Monitor Deployment

```bash
# Check all pods are running
bash Team12/Scripts/status.sh

# Watch real-time pod status
kubectl get pods -n bordspelplatform-12 -w

# Check service status
kubectl get svc -n bordspelplatform-12

# Get external IP for accessing the platform
kubectl get svc nginx-gateway-service -n bordspelplatform-12
```

---

## Accessing the Platform

### Platform URL
Once deployment is complete, get the external IP:

```bash
kubectl get svc nginx-gateway-service -n bordspelplatform-12
```

Map DNS:
```
stoom-app.com     → <EXTERNAL_IP>
www.stoom-app.com → <EXTERNAL_IP>
```

**Access URLs (gateway routes):**
- **Platform**: `https://stoom-app.com/`
- **Keycloak**: `https://stoom-app.com/auth`
- **Tic-Tac-Toe**: `https://stoom-app.com/play/tictactoe/`
- **Chess**: `https://stoom-app.com/play/blitz-chess/`
- **RabbitMQ Management**: `https://stoom-app.com/rabbitmq/`
- **Kibana Logs**: `https://stoom-app.com/kibana/`

Use `https://<EXTERNAL-IP>/...` if DNS is not configured yet.

### Default Credentials

**Keycloak:**
- Username: `admin`
- Password: `admin`

**RabbitMQ:**
- Username: `user`
- Password: `password`

**Database:**
- User: `user`
- Password: `password`

⚠️ **IMPORTANT:** Change these in production!

---

## Troubleshooting

### 1. Pods Not Starting

```bash
# Check pod status
kubectl get pods -n bordspelplatform-12

# Describe pod to see events
kubectl describe pod <pod-name> -n bordspelplatform-12

# View logs
kubectl logs <pod-name> -n bordspelplatform-12
```

### 2. ImagePullBackOff Error

This usually means GitLab registry credentials issue:

```bash
# Check the secret
kubectl get secret gitlab-registry -n bordspelplatform-12 -o yaml

# Re-create the secret
bash Team12/Scripts/setup-gitlab-registry.sh

# Check if pods can access registry
kubectl describe pod <pod-name> -n bordspelplatform-12 | grep -A 10 Events
```

### 3. Database Connection Issues

```bash
# Test PostgreSQL connection from a pod
kubectl run -it --rm debug --image=postgres:latest --restart=Never \
  -n bordspelplatform-12 -- \
  psql -h postgres-service.bordspelplatform-12.svc.cluster.local -U user -d postgres

# Try: SELECT 1;
```

### 4. Service Discovery Issues

```bash
# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never \
  -n bordspelplatform-12 -- \
  nslookup postgres-service.bordspelplatform-12.svc.cluster.local

# Test service connectivity
kubectl run -it --rm debug --image=busybox --restart=Never \
  -n bordspelplatform-12 -- \
  wget -O- http://nginx-gateway-service/
```

### 5. Storage Issues

```bash
# Check persistent volumes
kubectl get pvc -n bordspelplatform-12

# Check persistent volume status
kubectl get pv

# Describe a PVC
kubectl describe pvc <pvc-name> -n bordspelplatform-12
```

### 6. API Gateway Not Routing Correctly

```bash
# Check nginx configuration
kubectl get configmap nginx-config -n bordspelplatform-12 -o yaml

# Check gateway pod logs
kubectl logs -f deployment/nginx-gateway-deployment -n bordspelplatform-12

# Test from gateway pod
kubectl exec -it deployment/nginx-gateway-deployment -n bordspelplatform-12 -- \
  curl -v http://platform-frontend-service/
```

---

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| **Pods stuck in Pending** | Insufficient resources. Check node capacity: `kubectl top nodes` |
| **CrashLoopBackOff** | Check pod logs: `kubectl logs <pod>` |
| **ImagePullBackOff** | GitLab credentials issue. Run `bash Team12/Scripts/setup-gitlab-registry.sh` |
| **LoadBalancer pending** | GCP might take 5-10 minutes. Check with: `kubectl get svc nginx-gateway-service -n bordspelplatform-12 -w` |
| **Database pod not ready** | Allow more time for initialization. Check: `kubectl logs postgres-deployment...` |
| **Services can't connect** | Check DNS: `kubectl run -it --rm debug --image=busybox --restart=Never -n bordspelplatform-12 -- nslookup <service>` |

---

## Monitoring & Logging

### View Logs
```bash
# Tail logs from specific deployment
kubectl logs -f deployment/platform-backend-deployment -n bordspelplatform-12

# View logs from specific pod
kubectl logs <pod-name> -n bordspelplatform-12

# View previous crashed logs
kubectl logs <pod-name> -n bordspelplatform-12 --previous
```

### Monitor Resources
```bash
# Pod resource usage
kubectl top pods -n bordspelplatform-12

# Node resource usage
kubectl top nodes

# Continuous monitoring
watch kubectl get pods -n bordspelplatform-12
```

### View Events
```bash
# Recent cluster events
kubectl get events -n bordspelplatform-12 --sort-by='.lastTimestamp'

# Follow events
kubectl get events -n bordspelplatform-12 -w
```

---

## Scaling & Updates

### Scale a Deployment
```bash
# Scale platform backend to 3 replicas
kubectl scale deployment platform-backend-deployment -n bordspelplatform-12 --replicas=3

# Monitor scaling
kubectl get pods -l app=platform-backend -n bordspelplatform-12 -w
```

### Update Container Image
```bash
# Update image for platform backend
kubectl set image deployment/platform-backend-deployment \
  platform-backend=registry.gitlab.com/kdg-ti/integratieproject-j3/teams-25-26/team12/platform/backend:v2.0 \
  -n bordspelplatform-12

# Monitor rollout
kubectl rollout status deployment/platform-backend-deployment -n bordspelplatform-12
```

### Rollback
```bash
# View rollout history
kubectl rollout history deployment/platform-backend-deployment -n bordspelplatform-12

# Rollback to previous version
kubectl rollout undo deployment/platform-backend-deployment -n bordspelplatform-12

# Rollback to specific revision
kubectl rollout undo deployment/platform-backend-deployment -n bordspelplatform-12 --to-revision=2
```

---

## Configuration Management

### Update Configuration
Configurations are stored in ConfigMap (`platform-config`) and Secret (`platform-secrets`).

To update:

```bash
# Edit ConfigMap
kubectl edit configmap platform-config -n bordspelplatform-12

# Edit Secret
kubectl edit secret platform-secrets -n bordspelplatform-12

# Pods will need restart to pick up changes
kubectl rollout restart deployment/<deployment-name> -n bordspelplatform-12
```

---

## Cleanup & Teardown

### Remove All Resources
```bash
bash Team12/Scripts/teardown-team12.sh
```

This will delete the entire `bordspelplatform-12` namespace and all its resources.

### Cleanup GCP Infrastructure
```bash
cd ../Terraform
tofu destroy
```

---

## Next Steps

1. **Configure DNS**: Point your domain to the LoadBalancer IP
2. **Setup HTTPS**: Add SSL certificates (Google Cloud Load Balancer)
3. **Configure Backup**: Setup Cloud SQL backups in GCP console
4. **Setup Monitoring**: Enable Cloud Monitoring for the cluster
5. **Configure Alerts**: Set up alerting for pod failures

---

## Support & Documentation

- **Kubernetes Docs**: https://kubernetes.io/docs/
- **GKE Docs**: https://cloud.google.com/kubernetes-engine/docs
- **Keycloak Docs**: https://www.keycloak.org/documentation
- **Terraform Docs**: https://www.terraform.io/docs/

## Additional Scripts

| Script | Purpose |
|--------|---------|
| `Team12/Scripts/deploy-team12.sh` | Deploy all components |
| `Team12/Scripts/teardown-team12.sh` | Remove all resources |
| `Team12/Scripts/status.sh` | Check deployment status |
| `Team12/Scripts/verify-fixes.sh` | Verify configurations |
| `Team12/Scripts/setup-gitlab-registry.sh` | Configure GitLab registry access |

---

**Last Updated:** 2025-12-12  
**Team:** Team12  
**Project:** IntegrationProject2 - Deployment  
