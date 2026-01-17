# OpenTofu Infrastructure as Code - Bordspelplatform

> **💰 KOSTENWAARSCHUWING:** Deze infrastructuur kost ~€75-100/maand op GCP. Dit is een TEST - verwijder alles zodra je klaar bent!
>
> ```bash
> # Quick cleanup om kosten te stoppen:
> kubectl delete namespace bordspelplatform
> tofu destroy
> ```

Deze directory bevat de Infrastructure as Code configuratie voor het opzetten van de infrastructuur op Google Cloud Platform met OpenTofu.

> 💡 **OpenTofu**: We gebruiken OpenTofu, een open-source alternatief voor Terraform. Alle `.tf` bestanden zijn volledig compatibel.

## Wat wordt er gecreëerd?

- **VPC Network**: Geïsoleerd netwerk voor de applicatie
- **GKE Cluster**: Kubernetes cluster voor het draaien van containers
- **Cloud SQL**: PostgreSQL database instances voor platform, AI services en analytics
- **Artifact Registry**: Docker image repository
- **Service Accounts**: Voor veilige toegang tot GCP resources
- **Networking**: Firewall regels en static IP voor load balancer

## Prerequisites

1. **Google Cloud SDK** geïnstalleerd en geconfigureerd

   ```bash
   gcloud auth login
   gcloud config set project <PROJECT_ID>
   ```
2. **OpenTofu** geïnstalleerd (versie >= 1.6)

   ```bash
   # Windows (Chocolatey)
   choco install opentofu

   # Linux
   curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
   chmod +x install-opentofu.sh
   ./install-opentofu.sh --install-method deb

   # Verificatie
   tofu --version
   ```
3. **GCP Project** aangemaakt met facturering ingeschakeld
4. **API's** ingeschakeld:

   ```bash
   gcloud services enable compute.googleapis.com
   gcloud services enable container.googleapis.com
   gcloud services enable sqladmin.googleapis.com
   gcloud services enable artifactregistry.googleapis.com
   gcloud services enable servicenetworking.googleapis.com
   ```

## Gebruik

### 1. Configuratie

Bekijk het configuratiebestand en pas het aan:

```bash
./opentofu.tfvars
```

Bewerk `opentofu.tfvars` en vul de juiste waarden in:

- `project_id`: Jouw GCP project ID
- `db_password`: Een sterk wachtwoord voor de database

### 2. Initialisatie

Initialiseer en download de benodigde providers:

```bash
tofu init
```

### 3. Plan

Bekijk welke resources er aangemaakt worden:

```bash
tofu plan
```

### 4. Apply

Creëer de infrastructuur:

```bash
tofu apply
```

Type `yes` om te bevestigen.

### 5. Outputs

Na succesvolle deployment, bekijk de outputs:

```bash
tofu output
```

### 6. Connecteren met GKE

Gebruik de output van `kubectl_connection_command`:

```bash
gcloud container clusters get-credentials <cluster-name> --region <region> --project <project-id>
```

Verifieer de connectie:

```bash
kubectl get nodes
```

## Belangrijke Outputs

- `cluster_endpoint`: Kubernetes API server endpoint
- `database_connection_name`: Voor Cloud SQL Proxy connectie
- `artifact_registry_url`: URL voor Docker images
- `load_balancer_ip`: Static IP voor de applicatie

## Omgevingen

Deze configuratie ondersteunt meerdere omgevingen (dev, test, prod):

```bash
# Development
tofu workspace new dev
tofu apply -var="environment=dev"

# Test
tofu workspace new test
tofu apply -var="environment=test"

# Production
tofu workspace new prod
tofu apply -var="environment=prod" -var="use_preemptible_nodes=false" -var="db_availability_type=REGIONAL"
```

## Security Best Practices

1. **Secrets Management**: Gebruik Google Secret Manager voor gevoelige data
2. **State File**: Configureer remote backend (GCS) voor team samenwerking
3. **IAM**: Volg het principe van least privilege
4. **Networking**: Gebruik private clusters en VPC-native routing
5. **Database**: SSL vereist, private IP, regelmatige backups

## Kosten Optimalisatie

Voor development/test omgevingen:

- Gebruik preemptible nodes (`use_preemptible_nodes = true`)
- Kleinere machine types (`e2-medium`)
- ZONAL database availability
- Minimale node counts

Voor productie:

- Reguliere nodes
- Grotere machine types (bijv. `e2-standard-4`)
- REGIONAL database availability
- Auto-scaling configuratie

## Cleanup

> **🚨 BELANGRIJK - DIT IS EEN TEST DEPLOYMENT**
> 
> Verwijder de infrastructuur zodra je klaar bent om kosten te voorkomen!

### Stap 1: Verwijder Kubernetes Resources Eerst

```bash
# Ga terug naar kubernetes directory
cd ../kubernetes

# Verwijder namespace (inclusief alle services, LoadBalancers, PVCs)
kubectl delete namespace bordspelplatform

# Verifieer dat alles weg is
kubectl get namespace bordspelplatform  # Moet "NotFound" geven
```

### Stap 2: Disable Deletion Protection (indien nodig)

Als `tofu destroy` faalt met deletion protection errors:

```bash
# Update main.tf om deletion_protection uit te schakelen
# (Dit is al gedaan in de huidige configuratie)

# Of handmatig via gcloud:
gcloud container clusters update dev-gke-cluster \
  --zone=europe-west1-b \
  --no-enable-deletion-protection

gcloud sql instances patch <instance-name> \
  --no-deletion-protection
```

### Stap 3: Destroy Infrastructure

```bash
# Verwijder ALLE GCP resources
tofu destroy

# Type 'yes' om te bevestigen
```

**Dit verwijdert:**
- ✅ GKE Cluster (~€70/maand)
- ✅ Cloud SQL Instance (~€7/maand)
- ✅ VPC Network
- ✅ Artifact Registry
- ✅ Service Accounts
- ✅ Static IP
- ✅ Firewall Rules

### Stap 4: Verifieer Cleanup

```bash
# Check of cluster weg is
gcloud container clusters list

# Check of SQL instances weg zijn
gcloud sql instances list

# Check of VPC netwerk weg is (alleen 'default' moet over blijven)
gcloud compute networks list

# Check Artifact Registry
gcloud artifacts repositories list
```

### Complete Cleanup Script

```bash
#!/bin/bash
echo "🗑️ Complete Infrastructure Cleanup"
echo "=================================="

# Step 1: Delete Kubernetes namespace
echo "Step 1: Deleting Kubernetes resources..."
kubectl delete namespace bordspelplatform --wait=true

# Step 2: Destroy OpenTofu infrastructure
echo "Step 2: Destroying GCP infrastructure..."
cd opentofu
tofu destroy -auto-approve

# Step 3: Verify cleanup
echo ""
echo "Step 3: Verifying cleanup..."
echo ""
echo "GKE Clusters:"
gcloud container clusters list
echo ""
echo "Cloud SQL Instances:"
gcloud sql instances list
echo ""
echo "VPC Networks (only 'default' should remain):"
gcloud compute networks list
echo ""
echo "✅ Cleanup complete! Check GCP Console to verify."
echo "💰 Cost savings: ~€95/month"
```

Save als `cleanup-all.sh` en run met `bash cleanup-all.sh`.

### ⚠️ Wat gebeurt er met je data?

- **Database**: PERMANENT VERWIJDERD (tenzij `db_deletion_protection = true`)
- **Logs**: Verwijderd na retention period
- **Container Images**: Blijven in Artifact Registry (verwijder handmatig indien gewenst)
- **OpenTofu State**: Blijft lokaal in `terraform.tfstate` (backup aanbevolen)

### 💡 Kosten na Cleanup

Na succesvolle cleanup:
- GKE Cluster: €0 (verwijderd)
- Cloud SQL: €0 (verwijderd)
- LoadBalancer: €0 (verwijderd met services)
- Persistent Disks: €0 (verwijderd met PVCs)

**Total: €0/maand** 🎉

**Let op**: Dit verwijdert alle resources inclusief databases (als `db_deletion_protection = false`).

## Troubleshooting

### Quota Issues

Als je quota errors krijgt:

**SSD Quota Error:**
```
Insufficient regional quota: resource "SSD_TOTAL_GB"
```

**Oplossing voor Development:**
De configuratie is aangepast om binnen free tier quota te blijven:
- GKE nodes: 30GB standard disk (i.p.v. 100GB SSD)
- Cloud SQL: 10GB disk minimum
- Max 5 nodes autoscaling

**Voor productie:** Vraag quota verhogingen aan:
```bash
gcloud compute project-info describe --project=<PROJECT_ID>
# Ga naar GCP Console > IAM & Admin > Quotas
```

### Cloud SQL Private IP Issues

**Error:**
```
network doesn't have at least 1 private services connection
```

**Oplossing:**
Voor development gebruiken we publieke IP (met SSL encryption).
Voor productie, enable private networking:

1. Uncomment in `main.tf`:
```hcl
ip_configuration {
  private_network = google_compute_network.vpc.id
  ipv4_enabled    = false  # Alleen private IP
}
```

2. Add VPC peering:
```bash
gcloud services vpc-peerings connect \
  --service=servicenetworking.googleapis.com \
  --ranges=google-managed-services \
  --network=dev-vpc
```

### API niet ingeschakeld

Zorg dat alle benodigde APIs zijn ingeschakeld:

```bash
# Enable alle APIs tegelijk
gcloud services enable \
  container.googleapis.com \
  artifactregistry.googleapis.com \
  servicenetworking.googleapis.com \
  sqladmin.googleapis.com \
  compute.googleapis.com

# Check enabled APIs
gcloud services list --enabled
```

## Volgende Stappen

1. Deploy Kubernetes manifests (zie `../kubernetes/`)
2. Configureer CI/CD pipelines (zie `../.gitlab-ci.yml`)
3. Setup monitoring en logging
4. Configureer DNS en SSL certificaten

## Support

Voor vragen of problemen, contacteer het ISB team.
