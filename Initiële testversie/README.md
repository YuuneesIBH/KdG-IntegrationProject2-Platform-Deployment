# Initiële Testversie - Bordspelplatform

🧪 **Dit is een proof-of-concept testversie** met simpele container images om de infrastructuur te testen.
❌ **Geen volledige applicatie** - alleen basis containers voor validatie.

## 🎯 Doel

Deze testversie valideert dat:

- ✅ Docker Compose correct werkt
- ✅ Kubernetes manifests deployen zonder errors
- ✅ CI/CD pipeline kan builden en deployen
- ✅ Netwerking tussen services werkt
- ✅ Database connectivity werkt
- ✅ Message queue operationeel is

## 📦 Wat Zit Erin?

### Test Services

| Service           | Image                     | Port        | Doel                  |
| ----------------- | ------------------------- | ----------- | --------------------- |
| Platform Frontend | `nginx:alpine`          | 8080        | Web UI test           |
| Game Service      | `httpd:alpine`          | 8081        | Spel container test   |
| Backend API       | `python:3.11-slim`      | 8082        | API endpoint test     |
| Database          | `postgres:15-alpine`    | 5432        | Database connectivity |
| Message Queue     | `rabbitmq:3-management` | 5672, 15672 | Event messaging test  |

## 🚀 Quick Start

### Optie 1: Docker Compose (Lokaal Testen)

1. **Start alle test containers**:

   ```bash
   cd "Initiële testversie"
   docker-compose up -d
   ```
2. **Check of alles draait**:

   ```bash
   docker-compose ps
   docker-compose logs -f
   ```
3. **Open in browser**:

   - Platform: http://localhost:8080
   - Game Service: http://localhost:8081
   - Backend API: http://localhost:8082
   - RabbitMQ UI: http://localhost:15672 (guest/guest)
4. **Stop alles**:

   ```bash
   docker-compose down
   ```
5. **⚠️ BELANGRIJK - Opruimen (om kosten te vermijden)**:

   ```bash
   # Stop en verwijder alle containers + volumes
   docker-compose down -v
   ```

### Optie 2: OpenTofu + Kubernetes (Cloud Deployment)

> **⚠️ Vereisten:**

- GCP project met billing enabled
- APIs enabled (zie hieronder)
- Voldoende quota (standaard free tier is meestal genoeg voor dev)

1. **Enable GCP APIs**:

   ```bash
   gcloud services enable \
     container.googleapis.com \
     artifactregistry.googleapis.com \
     servicenetworking.googleapis.com \
     sqladmin.googleapis.com \
     compute.googleapis.com
   ```
2. **Deploy infrastructure**:

   ```bash
   cd opentofu
   # Vul je GCP project details in in het opentofu.tvars bestandje (dit is al gedaan, maar kan aangepast worden)
   tofu init
   tofu apply
   ```
3. **Deploy applicaties**:

   ```bash
   cd ../kubernetes
   gcloud container clusters get-credentials dev-gke-cluster --region europe-west1-b
   kubectl apply -f .
   ```
4. **Check external IP**:

   ```bash
   kubectl get svc nginx-hello-service -n bordspelplatform
   ```
5. **🚨 INFRASTRUCTUUR AFSLUITEN (DIT IS EEN TEST - VERWIJDER ALLES OM KOSTEN TE VERMIJDEN)**:

   ```bash
   # Stap 1: Verwijder Kubernetes resources
   kubectl delete namespace bordspelplatform

   # Stap 2: Verwijder GCP infrastructuur (GKE cluster, Cloud SQL, VPC)
   cd opentofu
   tofu destroy
   # Type 'yes' om te bevestigen

   # Stap 3: Verifieer dat alles weg is
   gcloud container clusters list
   gcloud sql instances list
   ```

   **💡 Alternatief - Complete cleanup script:**

   ```bash
   #!/bin/bash
   echo "🗑️ Cleaning up GCP infrastructure..."

   # Delete Kubernetes namespace (includes all services, deployments, PVCs)
   kubectl delete namespace bordspelplatform --wait=true

   # Destroy infrastructure with OpenTofu
   cd opentofu
   tofu destroy -auto-approve

   echo "✅ Cleanup complete! Verify in GCP Console."
   ```

## 🧪 Testen

### Database Test

```bash
# Connect naar database
docker-compose exec postgres psql -U testuser -d testdb

# Run test query
SELECT * FROM test_status;

# Verwachte output: 5 services met status 'ready'
```

### RabbitMQ Test

```bash
# Open management UI
http://localhost:15672
# Login: guest/guest

# Ga naar Queues tab
# Verwacht: RabbitMQ is running, geen errors
```

### Network Test

```bash
# Test of containers elkaar kunnen bereiken
docker-compose exec nginx-platform ping -c 3 postgres
docker-compose exec python-backend ping -c 3 rabbitmq

# Verwacht: Successful pings
```

## 📊 CI/CD Pipeline Testen

De `.gitlab-ci.yml` is klaar om te gebruiken.

**Configureer in GitLab: Settings → CI/CD → Variables**

```yaml
GCP_PROJECT_ID: your-project-id
GCP_SERVICE_KEY: {...}
GKE_CLUSTER_NAME: dev-gke-cluster
```

**Push naar repository**:

```bash
git add .
git commit -m "Test initial deployment"
git push origin main
```

**Pipeline stages**:

1. ✅ **Build** - Bouwt nginx hello world image
2. ✅ **Test** - Placeholder tests
3. ✅ **Push** - Push naar Artifact Registry
4. ✅ **Deploy** - Deploy naar GKE

## 🔍 Verificatie Checklist

### Docker Compose (Lokaal)

Na `docker-compose up -d`, verifieer:

- [ ] Alle containers zijn running: `docker-compose ps`
- [ ] Web UI toegankelijk: http://localhost:8080
- [ ] Game service toegankelijk: http://localhost:8081
- [ ] Backend API toegankelijk: http://localhost:8082
- [ ] Database heeft test data: `docker-compose exec postgres psql -U testuser -d testdb -c "SELECT * FROM test_status;"`
- [ ] RabbitMQ management UI: http://localhost:15672 (guest/guest)
- [ ] Containers kunnen communiceren: `docker-compose exec nginx-platform ping -c 3 postgres`

### Kubernetes + GKE (Cloud)

Na deployment, verifieer:

#### 1. Cluster & Resources

```bash
# Cluster info
kubectl cluster-info

# Nodes (verwacht: 1 node)
kubectl get nodes

# Alle resources in namespace
kubectl get all -n bordspelplatform

# Pod status (alles moet RUNNING zijn)
kubectl get pods -n bordspelplatform
```

#### 2. External Access

```bash
# Check LoadBalancer IP (wacht tot niet meer <pending>)
kubectl get svc nginx-hello-service -n bordspelplatform

# Test external IP in browser of met curl
curl http://<EXTERNAL-IP>
```

#### 3. Database Test

```bash
# Connect naar postgres pod
kubectl exec -it -n bordspelplatform deployment/postgres -- psql -U dbadmin -d platform_db

# In psql:
\l              # List databases
\dt             # List tables
SELECT version();
\q              # Quit
```

#### 4. RabbitMQ Test

```bash
# Port forward management UI
kubectl port-forward -n bordspelplatform svc/rabbitmq-service 15672:15672

# Open browser: http://localhost:15672
# Login: guest/guest
```

#### 5. Logs & Debugging

```bash
# Nginx logs
kubectl logs -n bordspelplatform deployment/nginx-hello --tail=50

# Postgres logs
kubectl logs -n bordspelplatform deployment/postgres --tail=50

# RabbitMQ logs
kubectl logs -n bordspelplatform deployment/rabbitmq --tail=50
```

#### 6. Autoscaling Test

```bash
# Check HorizontalPodAutoscaler
kubectl get hpa -n bordspelplatform

# Generate load om scaling te testen
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -n bordspelplatform -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://nginx-hello-service; done"

# In andere terminal, watch HPA scaling
kubectl get hpa -n bordspelplatform -w
```

#### 7. Complete Verificatie Script

run de commando's apart om te verifieren dat de deployment werkt:

```bash
#!/bin/bash
echo "=== Bordspelplatform Deployment Verificatie ==="
echo ""

echo "1. Cluster Info:"
kubectl cluster-info

echo ""
echo "2. Nodes:"
kubectl get nodes

echo ""
echo "3. All Resources:"
kubectl get all -n bordspelplatform

echo ""
echo "4. Services with IPs:"
kubectl get svc -n bordspelplatform

echo ""
echo "5. Pod Status:"
kubectl get pods -n bordspelplatform -o wide

echo ""
echo "6. HPA Status:"
kubectl get hpa -n bordspelplatform

echo ""
echo "7. External IP Test:"
EXTERNAL_IP=$(kubectl get svc nginx-hello-service -n bordspelplatform -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "External IP: $EXTERNAL_IP"
if [ ! -z "$EXTERNAL_IP" ]; then
    echo "Testing HTTP endpoint..."
    curl -I http://$EXTERNAL_IP
fi

echo ""
echo "✅ Deployment Verification Complete!"
```

Run met:

```bash
chmod +x verify-deployment.sh
./verify-deployment.sh
```

#### 8. Screenshots voor Demonstratie

Maak screenshots van:

- ✅ `kubectl get all -n bordspelplatform` (toont alle resources)
- ✅ `kubectl get nodes` (toont GKE node)
- ✅ External IP in browser (nginx hello page)
- ✅ RabbitMQ management UI (http://localhost:15672)
- ✅ `kubectl get hpa` (toont autoscaling)
- ✅ GCP Console > Kubernetes Engine > Clusters
- ✅ GCP Console > Cloud SQL

### CI/CD Pipeline

- [ ] GitLab variables geconfigureerd (GCP_PROJECT_ID, GCP_SERVICE_KEY, GKE_CLUSTER_NAME)
- [ ] Pipeline succesvol na git push
- [ ] Build stage completed
- [ ] Test stage passed
- [ ] Push to Artifact Registry successful
- [ ] Deploy to GKE successful

## 🐛 Troubleshooting

### Containers starten niet

```bash
# Check logs
docker-compose logs <service-name>

# Restart specifieke service
docker-compose restart <service-name>

# Rebuild en restart alles
docker-compose down
docker-compose up -d --build
```

### Port al in gebruik

```bash
# Check welk proces de port gebruikt (Windows)
netstat -ano | findstr :8080

# Stop conflicterende services of wijzig ports in docker-compose.yml
```

### Database errors

```bash
# Reset database (verliest data!)
docker-compose down -v
docker-compose up -d

# Check database logs
docker-compose logs postgres
```

### Kubernetes pods blijven Pending

```bash
# Check events
kubectl describe pod <pod-name> -n bordspelplatform

# Check node resources
kubectl top nodes
kubectl describe nodes
```

## ➡️ Volgende Stappen

> **⚠️ VERGEET NIET OM INFRASTRUCTUUR AF TE SLUITEN NA TESTEN!**
>
> ```bash
> # Quick cleanup commando's:
> kubectl delete namespace bordspelplatform
> cd opentofu && tofu destroy
> ```

Deze testversie is een **foundation**. Volgende stappen:

1. ✅ **Valideer** dat deze test setup werkt
2. 🔄 **Vervang** nginx/apache/python containers met echte applicaties:
   - Spring Boot backend
   - React frontend
   - Python AI services
3. 🔐 **Voeg toe** Keycloak voor authenticatie (in "Initiële versies" folder)
4. 📊 **Implementeer** ELK stack voor analytics (in "Initiële versies" folder)
5. 🧪 **Schrijf** unit en integration tests
6. 🚀 **Deploy** naar staging en productie omgevingen

## 📁 Directory Structuur

```
Initiële testversie/
├── docker-compose.yml       # Test containers setup (5 services)
├── .gitlab-ci.yml           # CI/CD pipeline
├── README.md                # Deze file
├── nginx/
│   └── html/
│       ├── index.html       # Platform UI test
│       └── game.html        # Game service test
├── init-scripts/
│   └── init.sql             # Database test data
├── kubernetes/              # K8s manifests
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── nginx-hello.yaml     # Test deployment
│   └── ...
└── opentofu/                # OpenTofu Infrastructure as Code
    ├── main.tf
    ├── variables.tf
    └── ...
```

## 🤝 Support

Dit is een **initiële test**. Voor de volledige applicatie setup, zie de "Initiële versies" folder met:

- Keycloak, ELK Stack, en andere production-ready services
- Uitgebreide OpenTofu configuratie
- Complete Kubernetes manifests
- Geavanceerde CI/CD pipeline

## ✨ Success Criteria

Je testversie werkt als:

- ✅ Alle 5 containers draaien zonder errors
- ✅ Web UI toont de test pagina
- ✅ Database bevat test data
- ✅ Services kunnen met elkaar communiceren
- ✅ CI/CD pipeline kan deployen (als geconfigureerd)

**🎉 Als dit werkt, ben je klaar om echte applicaties toe te voegen!**

```bash
git checkout -b test-pipeline
git add .
git commit -m "Test CI/CD pipeline"
git push origin test-pipeline
```

## 🐛 Troubleshooting

### Service start niet

```bash
# Check logs
docker-compose logs service-name

# Check resource usage
docker stats

# Restart service
docker-compose restart service-name
```

### Database connectie problemen

```bash
# Check of postgres running is
docker-compose ps postgres

# Check database logs
docker-compose logs postgres

# Test connectie
docker-compose exec postgres pg_isready -U dbadmin
```

### Elasticsearch yellow/red status

```bash
# Check cluster health
curl http://localhost:9200/_cluster/health?pretty

# Voor single-node, yellow is OK (geen replicas mogelijk)
# Set replicas to 0 voor development
curl -X PUT "localhost:9200/_settings" -H 'Content-Type: application/json' -d'
{
  "index": {
    "number_of_replicas": 0
  }
}'
```

### RabbitMQ queue problemen

```bash
# List queues
docker-compose exec rabbitmq rabbitmqctl list_queues

# Check bindings
docker-compose exec rabbitmq rabbitmqctl list_bindings
```

## 📚 Volgende Stappen

1. ✅ Pas de pipeline aan voor je eigen applicaties
2. ✅ Configureer Keycloak realms en clients
3. ✅ Implementeer health endpoints in je applicaties
4. ✅ Setup monitoring met Prometheus/Grafana
5. ✅ Configureer DNS en SSL certificaten voor productie
6. ✅ Implementeer blue-green of canary deployment strategie

## 🤝 Support

Voor vragen of problemen:

- Check de logs: `docker-compose logs` of `kubectl logs`
- Review de documentatie in elke subdirectory
- Contact het DevOps/ISB team

## 📝 License

Dit is een educatief project voor het Integratieproject J3.
