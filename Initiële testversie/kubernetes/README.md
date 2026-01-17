# Kubernetes Manifests - Bordspelplatform

> **💰 KOSTENWAARSCHUWING:** Als je dit op GKE draait, VERGEET NIET om alles te verwijderen na testen! Zie [Cleanup sectie](#-cleanup---infrastructuur-verwijderen) onderaan.

Deze directory bevat de Kubernetes manifest bestanden voor het deployen van de bordspelplatform applicatie en ondersteunende services.

## Overzicht van Componenten

### Core Infrastructure

- **namespace.yaml**: Namespace voor alle platform resources
- **configmap.yaml**: Algemene configuratie (non-sensitive)
- **secrets.yaml**: Gevoelige configuratie (credentials)

### Databases & Messaging

- **postgres.yaml**: PostgreSQL database voor platform data
- **rabbitmq.yaml**: RabbitMQ message broker voor event-driven architectuur

### Authentication & Authorization

- **keycloak.yaml**: Keycloak voor SSO en gebruikersbeheer

### Analytics (ELK Stack)

- **elasticsearch.yaml**: Elasticsearch voor data opslag
- **logstash.yaml**: Logstash voor event processing
- **kibana.yaml**: Kibana voor data visualisatie en dashboards

### Example Deployment

- **nginx-hello.yaml**: Nginx "Hello World" deployment voor CI/CD testing

## Prerequisites

1. **Kubernetes cluster** (GKE, lokaal met Minikube, of Docker Desktop)
2. **kubectl** CLI tool geïnstalleerd en geconfigureerd
3. **Toegang** tot cluster:
   ```bash
   kubectl cluster-info
   kubectl get nodes
   ```

## Deployment Volgorde

Deploy de manifests in de volgende volgorde:

### 1. Basis Setup

```bash
# Namespace
kubectl apply -f namespace.yaml

# Configuratie
kubectl apply -f configmap.yaml
kubectl apply -f secrets.yaml
```

### 2. Infrastructure Services

```bash
# Database
kubectl apply -f postgres.yaml

# Message Queue
kubectl apply -f rabbitmq.yaml

# Authentication
kubectl apply -f keycloak.yaml
```

### 3. Analytics Stack (ELK)

```bash
kubectl apply -f elasticsearch.yaml
kubectl apply -f logstash.yaml
kubectl apply -f kibana.yaml
```

### 4. Example Application

```bash
kubectl apply -f nginx-hello.yaml
```

### Deploy Alles Tegelijk

```bash
kubectl apply -f .
```

## Verificatie

### Check alle resources

```bash
kubectl get all -n bordspelplatform
```

### Check pods status

```bash
kubectl get pods -n bordspelplatform
kubectl get pods -n bordspelplatform -w  # Watch mode
```

### Check services en endpoints

```bash
kubectl get services -n bordspelplatform
kubectl get endpoints -n bordspelplatform
```

### Check persistent volumes

```bash
kubectl get pvc -n bordspelplatform
kubectl get pv
```

## Toegang tot Services

### Port Forwarding voor lokale toegang

```bash
# Nginx Hello World
kubectl port-forward -n bordspelplatform svc/nginx-hello-service 8080:80

# Kibana Dashboard
kubectl port-forward -n bordspelplatform svc/kibana-service 5601:5601

# RabbitMQ Management
kubectl port-forward -n bordspelplatform svc/rabbitmq-service 15672:15672

# Keycloak
kubectl port-forward -n bordspelplatform svc/keycloak-service 8080:8080

# PostgreSQL (voor debugging)
kubectl port-forward -n bordspelplatform svc/postgres-service 5432:5432
```

Open in browser:

- Nginx Hello: http://localhost:8080
- Kibana: http://localhost:5601
- RabbitMQ: http://localhost:15672 (guest/guest)
- Keycloak: http://localhost:8080

### LoadBalancer External IP (GKE)

```bash
# Check external IP
kubectl get svc -n bordspelplatform

# Voor nginx-hello-service
kubectl get svc nginx-hello-service -n bordspelplatform -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

## Logs Bekijken

```bash
# Logs van specifieke pod
kubectl logs -n bordspelplatform <pod-name>

# Logs met follow
kubectl logs -n bordspelplatform <pod-name> -f

# Logs van alle containers in een pod
kubectl logs -n bordspelplatform <pod-name> --all-containers=true

# Previous logs (bij crashes)
kubectl logs -n bordspelplatform <pod-name> --previous
```

## Troubleshooting

### Pod start niet

```bash
# Beschrijving van pod (events onderaan)
kubectl describe pod -n bordspelplatform <pod-name>

# Check resource constraints
kubectl top pods -n bordspelplatform
kubectl top nodes
```

### Service niet bereikbaar

```bash
# Check endpoints
kubectl get endpoints -n bordspelplatform <service-name>

# Test connectiviteit vanuit cluster
kubectl run -n bordspelplatform test-pod --image=busybox -it --rm -- sh
# Binnen pod: wget -O- http://service-name:port
```

### PVC blijft Pending

```bash
kubectl describe pvc -n bordspelplatform <pvc-name>

# Check beschikbare storage classes
kubectl get storageclass
```

### Database connectie problemen

```bash
# Check of postgres pod running is
kubectl get pods -n bordspelplatform -l app=postgres

# Test connectie
kubectl exec -it -n bordspelplatform <postgres-pod> -- psql -U dbadmin -d platform_db
```

## Secrets Management

⚠️ **BELANGRIJK**: De `secrets.yaml` bevat voorbeeld credentials die **NIET** veilig zijn!

### Voor Productie:

1. **Google Secret Manager** (aanbevolen voor GKE):

```bash
# Maak secret in GCP
gcloud secrets create db-password --data-file=-

# Gebruik External Secrets Operator
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/crds/bundle.yaml
```

2. **Sealed Secrets**:

```bash
# Installeer sealed-secrets controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Encrypt secret
kubeseal -f secrets.yaml -w sealed-secrets.yaml
```

3. **Manual secrets** (voor dev):

```bash
# Creëer secret vanaf command line
kubectl create secret generic platform-secrets \
  --from-literal=DB_PASSWORD='your-secure-password' \
  --namespace=bordspelplatform
```

## Resource Limits Aanpassen

Voor productie of grotere workloads, pas resource limits aan:

```yaml
resources:
  requests:
    memory: "1Gi"
    cpu: "1000m"
  limits:
    memory: "2Gi"
    cpu: "2000m"
```

## Cleanup

### Verwijder specifieke resources

```bash
kubectl delete -f nginx-hello.yaml
```

### Verwijder alles

```bash
kubectl delete namespace bordspelplatform
```

Dit verwijdert alle resources in de namespace, maar **NIET** de PersistentVolumes!

### Verwijder ook PVs

```bash
kubectl delete pv -l namespace=bordspelplatform
```

## High Availability Setup

Voor productie, verhoog replicas:

```yaml
spec:
  replicas: 3  # Of meer
```

En gebruik:

- **StatefulSets** voor databases (i.p.v. Deployments)
- **PodDisruptionBudgets** voor availability tijdens updates
- **Affinity rules** om pods te spreiden over nodes

## Monitoring

### Metrics Server

```bash
# Installeer metrics-server (als nog niet aanwezig)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Check resource usage
kubectl top nodes
kubectl top pods -n bordspelplatform
```

### Prometheus & Grafana (optioneel)

Voor uitgebreide monitoring, installeer Prometheus stack:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
```

## 🔍 Deployment Verificatie

### Quick Check

```bash
# Alle resources
kubectl get all -n bordspelplatform

# Pod status (moet allemaal Running zijn)
kubectl get pods -n bordspelplatform

# Services met IPs
kubectl get svc -n bordspelplatform
```

### External Access Test

```bash
# Check LoadBalancer IP (wacht tot niet meer <pending>)
kubectl get svc nginx-hello-service -n bordspelplatform

# Test in browser of met curl
curl http://<EXTERNAL-IP>
```

### Database Connectivity

```bash
# Connect naar PostgreSQL
kubectl exec -it -n bordspelplatform deployment/postgres -- psql -U dbadmin -d platform_db

# Test queries
\l                  # List databases
\dt                 # List tables
SELECT version();
\q                  # Quit
```

### RabbitMQ Management UI

```bash
# Port forward
kubectl port-forward -n bordspelplatform svc/rabbitmq-service 15672:15672

# Open browser: http://localhost:15672
# Login: guest/guest
```

### Logs Troubleshooting

```bash
# Nginx logs
kubectl logs -n bordspelplatform deployment/nginx-hello --tail=100

# Postgres logs
kubectl logs -n bordspelplatform deployment/postgres --tail=100

# RabbitMQ logs
kubectl logs -n bordspelplatform deployment/rabbitmq --tail=100

# Alle logs van een pod
kubectl logs -n bordspelplatform <pod-name> --all-containers
```

### Scaling Verificatie

```bash
# Check HPA status
kubectl get hpa -n bordspelplatform

# Generate load voor autoscaling test
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -n bordspelplatform -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://nginx-hello-service; done"

# Watch autoscaling (in andere terminal)
kubectl get hpa -n bordspelplatform -w
kubectl get pods -n bordspelplatform -w
```

### Verificatie Commando's

```bash
#!/bin/bash
echo "=== Kubernetes Deployment Verification ==="
echo ""

# Cluster health
echo "1. Cluster Info:"
kubectl cluster-info
echo ""

# Nodes
echo "2. Nodes:"
kubectl get nodes -o wide
echo ""

# Namespace resources
echo "3. All Resources in bordspelplatform:"
kubectl get all -n bordspelplatform
echo ""

# Services and IPs
echo "4. Services:"
kubectl get svc -n bordspelplatform -o wide
echo ""

# Pod details
echo "5. Pod Status:"
kubectl get pods -n bordspelplatform -o wide
echo ""

# Storage
echo "6. Persistent Volumes:"
kubectl get pvc -n bordspelplatform
echo ""

# HPA
echo "7. Autoscaling:"
kubectl get hpa -n bordspelplatform
echo ""

# External IP test
echo "8. External Access Test:"
EXTERNAL_IP=$(kubectl get svc nginx-hello-service -n bordspelplatform -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ ! -z "$EXTERNAL_IP" ]; then
    echo "External IP: $EXTERNAL_IP"
    echo "HTTP Test:"
    curl -I http://$EXTERNAL_IP
else
    echo "LoadBalancer IP not ready yet (still <pending>)"
fi

echo ""
echo "✅ Verification Complete!"
```

Save als `verify-k8s.sh` en run:

```bash
chmod +x verify-k8s.sh
./verify-k8s.sh
```

### Common Issues

**Pods in Pending state:**

```bash
# Check events
kubectl describe pod <pod-name> -n bordspelplatform
kubectl get events -n bordspelplatform --sort-by='.lastTimestamp'
```

**LoadBalancer stuck on `<pending>`:**

```bash
# Check service
kubectl describe svc nginx-hello-service -n bordspelplatform

# GKE might need time (wait 1-2 minutes)
# Check GCP Console > Network Services > Load Balancing
```

**Database connection errors:**

```bash
# Check if postgres is running
kubectl get pods -n bordspelplatform | grep postgres

# Check logs
kubectl logs -n bordspelplatform deployment/postgres

# Test connectivity from another pod
kubectl run -it --rm debug --image=postgres:15-alpine --restart=Never -n bordspelplatform -- psql -h postgres-service -U dbadmin -d platform_db
```

## 🗑️ Cleanup - Infrastructuur Verwijderen

> **💰 BELANGRIJK:** Dit is een test deployment. Verwijder ALLES om kosten te voorkomen!

### Optie 1: Quick Cleanup (Aanbevolen voor Tests)

```bash
# Verwijder de hele namespace (dit verwijdert ALLES in bordspelplatform)
kubectl delete namespace bordspelplatform

# Wacht tot alles verwijderd is
kubectl get namespace bordspelplatform --watch
```

### Optie 2: Per Resource Type

```bash
# Verwijder alle deployments
kubectl delete deployments --all -n bordspelplatform

# Verwijder alle services (inclusief LoadBalancers)
kubectl delete services --all -n bordspelplatform

# Verwijder alle PVCs (persistent volumes)
kubectl delete pvc --all -n bordspelplatform

# Verwijder ConfigMaps en Secrets
kubectl delete configmaps --all -n bordspelplatform
kubectl delete secrets --all -n bordspelplatform

# Verwijder namespace
kubectl delete namespace bordspelplatform
```

### Optie 3: Alles in één keer (gebruik manifests)

```bash
# Verwijder alles dat met apply was deployed
kubectl delete -f .

# Verwijder namespace
kubectl delete -f namespace.yaml
```

### Verifieer dat alles weg is

```bash
# Check namespace (moet "NotFound" geven)
kubectl get namespace bordspelplatform

# Check of LoadBalancers weg zijn in GCP Console
# Network Services > Load Balancing (moet leeg zijn)

# Check Persistent Disks in GCP Console
# Compute Engine > Disks (moet leeg zijn)
```

### 🚨 Complete Cleanup Script

```bash
#!/bin/bash
echo "🗑️ Cleaning up Kubernetes resources..."

# Delete namespace (this deletes everything inside it)
kubectl delete namespace bordspelplatform --wait=true

# Verify cleanup
echo ""
echo "Verifying cleanup..."
kubectl get namespace bordspelplatform 2>/dev/null || echo "✅ Namespace deleted"
kubectl get pv | grep bordspelplatform || echo "✅ Persistent Volumes cleaned"

echo ""
echo "✅ Kubernetes cleanup complete!"
echo "⚠️  Don't forget to also run: cd ../opentofu && tofu destroy"
```

### Na Kubernetes Cleanup - Verwijder GCP Infrastructuur

```bash
# Ga naar opentofu directory
cd ../opentofu

# Verwijder ALLE GCP resources (GKE, Cloud SQL, VPC, etc.)
tofu destroy

# Type 'yes' om te bevestigen

# Verifieer in GCP Console:
# - Kubernetes Engine > Clusters (leeg)
# - SQL > Instances (leeg)  
# - VPC Networks (alleen default over)
# - Artifact Registry > Repositories (leeg of alleen wat je wil houden)
```

### 💡 Kosten Besparen

- **GKE Cluster**: ~€70/maand → Verwijder zodra je klaar bent met testen
- **Cloud SQL**: ~€7/maand → Verwijder of stop instance
- **LoadBalancer**: ~€18/maand → Wordt verwijderd met services
- **Persistent Disks**: ~€0.17/GB/maand → Wordt verwijderd met PVCs

**Total besparing na cleanup: ~€95/maand** 🎉

## Volgende Stappen

1. Deploy je eigen applicatie containers (platform, games, AI services)
2. Configureer Ingress voor routing
3. Setup SSL/TLS certificaten
4. Configureer horizontal pod autoscaling
5. Implementeer CI/CD pipelines

## Support

Voor vragen, check:

- Kubernetes logs: `kubectl logs`
- Events: `kubectl get events -n bordspelplatform`
- Resource status: `kubectl describe`

Contact het ISB team voor infrastructuur support.
