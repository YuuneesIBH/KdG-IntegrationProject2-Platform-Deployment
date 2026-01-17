# Team8 Kubernetes - Quick Reference

## 🚀 Deploy from Scripts/main.sh

```bash
cd /home/kali/Downloads/IntegrationProject2-Deployment-main
./Scripts/main.sh
# → Select option 3 (Deploy)
# → Select option 4 (Team8)
```

**Done!** All infrastructure and Kubernetes resources deployed automatically.

---

## 📍 Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                  API Gateway (NGINX)                    │
│                  LoadBalancer Service                   │
└────────────────┬──────────────────────────────────────┘
                 │
    ┌────────────┼────────────┬─────────────────┐
    │            │            │                 │
┌───▼──┐    ┌───▼──────┐ ┌───▼──┐         ┌───▼──────┐
│Front │    │Platform  │ │Tic-  │         │  Auth    │
│ End  │    │Backend   │ │Tac-  │         │Keycloak  │
└──┬───┘    └──┬───────┘ │Toe   │         └──┬───────┘
   │           │         │Back  │            │
   └──────┬────┴────┬────┴──┬───┴──────┬─────┘
          │         │       │          │
     ┌────▼─┐   ┌───▼───┐ ┌─▼──┐  ┌───▼─────┐
     │Redis │   │Rabbit │ │ AI │  │Postgres │
     │Cache │   │  MQ   │ │Svc │  │Database │
     └──────┘   └───┬───┘ └────┘  └─────────┘
                    │
          ┌─────────┴──────────┐
          │                    │
       ┌──▼──┐          ┌──────▼──┐
       │  ELK Stack     │ Kibana  │
       │ Elasticsearch  │ Logs    │
       │ Logstash       │Dash     │
       └──────┘         └─────────┘
```

---

## 🔧 Manual kubectl Commands (after deployment)

```bash
# All pods
kubectl get pods -n bordspelplatform

# All services
kubectl get svc -n bordspelplatform

# Specific pod details
kubectl describe pod <pod-name> -n bordspelplatform

# Pod logs
kubectl logs -f pod/<pod-name> -n bordspelplatform

# All events
kubectl get events -n bordspelplatform --sort-by='.lastTimestamp'

# Restart deployments
kubectl rollout restart deployment -n bordspelplatform
```

---

## 🔗 Service URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| Platform | `http://<IP>/` | - |
| Keycloak | `http://<IP>/auth` | admin/admin |
| RabbitMQ | `http://<IP>:15672` | user/password |
| Kibana | `http://<IP>:5601` | - |

---

## 🐛 Quick Troubleshooting

```bash
# Check what went wrong
kubectl describe pod <pod-name> -n bordspelplatform

# View pod logs
kubectl logs <pod-name> -n bordspelplatform

# Test database connection
kubectl run -it --rm debug --image=postgres:latest --restart=Never -n bordspelplatform -- \
  psql -h postgres-service -U user -d postgres

# Test service DNS
kubectl run -it --rm debug --image=busybox --restart=Never -n bordspelplatform -- \
  nslookup postgres-service

# Full deployment status
./status.sh
```

---

## 🔧 Common Commands

```bash
# Restart a deployment
kubectl rollout restart deployment/<name> -n bordspelplatform

# Scale deployment
kubectl scale deployment/<name> --replicas=3 -n bordspelplatform

# View all resources
kubectl get all -n bordspelplatform

# Delete everything
./teardown.sh

# Update image
kubectl set image deployment/<name> <container>=<new-image> -n bordspelplatform
```

---

## 📝 Pod Deployment Order

1. **PostgreSQL** - Database (needs to be up first)
2. **Redis** - Cache
3. **RabbitMQ** - Message broker
4. **Keycloak** - Auth service
5. **Elasticsearch** - Log storage
6. **Logstash** - Log processor
7. **Kibana** - Log viewer
8. **Platform Frontend** - UI
9. **Platform Backend** - API
10. **Blokus Backend** - Game service
11. **AI Service** - Game AI
12. **API Gateway** - Reverse proxy/LB

---

## 📂 File Structure

```
Team8/Kubernetes/
├── 00-namespace-configmap-secrets.yaml  # Namespace + Config
├── pods/
│   ├── 01-postgres.yaml
│   ├── 02-redis.yaml
│   ├── 03-rabbitmq.yaml
│   ├── 04-keycloak.yaml
│   ├── 05-elasticsearch.yaml
│   ├── 06-logstash.yaml
│   ├── 07-kibana.yaml
│   ├── 08-platform-frontend.yaml
│   ├── 09-platform-backend.yaml
│   ├── 10-blokus-backend.yaml
│   ├── 11-ai-service.yaml
│   └── 12-api-gateway.yaml
├── deploy.sh                    # Deploy all
├── teardown.sh                  # Remove all
├── status.sh                    # Check status
├── verify.sh                    # Validate config
├── setup-gitlab-registry.sh     # Setup credentials
├── README.md                    # Full documentation
├── DEPLOYMENT_GUIDE.md          # Step-by-step guide
└── QUICK_REFERENCE.md           # This file
```

---

## 🔑 Key Information

- **Namespace**: `bordspelplatform`
- **Region**: `europe-west1-b` (Belgium)
- **Machine Type**: `e2-standard-2`
- **Cluster Name**: `bordspel-platform-team8`
- **Project ID**: `ip2-devops4-480317`

---

## 🆘 Emergency Cleanup

If something goes wrong and you need to start fresh:

```bash
# Remove everything
./teardown.sh

# Destroy infrastructure
cd ../Terraform
terraform destroy

# Recreate
terraform apply
cd ../Kubernetes
./setup-gitlab-registry.sh
./deploy.sh
```

---

## 📞 Support Resources

- **Kubernetes Docs**: https://kubernetes.io/
- **GKE Docs**: https://cloud.google.com/kubernetes-engine/docs
- **Check Logs**: `./status.sh` or `kubectl logs <pod> -n bordspelplatform`
- **Check Events**: `kubectl get events -n bordspelplatform`

---

**Pro Tip**: Bookmark this quick reference and the DEPLOYMENT_GUIDE.md for easy access!
