# Integratieproject J3 - DevOps Overzicht

Deze repository bevat de volledige infrastructuur en deployment tooling voor het bordspelplatform, inclusief AI services, applicatieplatforms en een initiele testversie. Beheer en ondersteuning gebeuren door het Ops team.

## Inhoud

- `Deployment/` - Volledige infra en deployment per platformonderdeel
- `Initiële testversie/` - Proof-of-concept omgeving voor snelle validatie
- `Contracten/` - Project- en teamcontracten
- `Hulpmiddelen/` - Referentiedocumenten en visuals

## Quick start (Deployment)

Gebruik het centrale script om een onderdeel te deployen:

```bash
cd Deployment/Scripts
bash main.sh
```

Volg het menu om een deployment uit te voeren. Details per onderdeel staan in de specifieke README's onder `Deployment/`.

## Map-voor-map uitleg

Let op: mapnamen weerspiegelen de oorspronkelijke projectindeling. In de uitleg hieronder verwijzen we functioneel naar de inhoud, niet naar dev teams.

### `Deployment/`

De productie-achtige deployment omgeving met scripts, Terraform en Kubernetes manifests.

- `Deployment/README.md` - Overkoepelende deploymenthandleiding en entrypoints
- `Deployment/credentials.json` - GCP service account key (gitignored)
- `Deployment/Scripts/` - Centrale opscripts
  - `main.sh` - Interactief menu om een onderdeel te deployen
  - `enable-gcp-apis.sh` - Activeert de benodigde GCP APIs
  - `create-gcp-service-account.sh` - Maakt service account + keys

#### `Deployment/Team4/` (AI platform)

Infra en services voor chatbot/RAG, AI player, LLM en database.

- `Deployment/Team4/README.md` - Praktische usage en endpoints
- `Deployment/Team4/DEPLOYMENT_GUIDE.md` - Stapsgewijze deploymentgids
- `Deployment/Team4/Scripts/`
  - `deploy-team4.sh` - End-to-end deployment (infra + K8s)
  - `teardown-team4.sh` - Opruimen van resources
  - `setup-gitlab-registry.sh` - Registry secret in namespace
  - `status.sh` - Snelle status van pods/services
- `Deployment/Team4/Terraform/` - GKE cluster en netwerk
  - `main.tf` - Provider en algemene config
  - `kubernetes-cluster.tf` - GKE cluster definitie
  - `variables.tf` / `terraform.tfvars` - Input en waarden
  - `outputs.tf` - Belangrijke outputwaarden
  - `tfplan` / `terraform.tfstate*` - Gegenereerde plan/state files
- `Deployment/Team4/Kubernetes/` - Manifests in vaste volgorde
  - `00-namespace-configmap-secrets.yaml` - Namespace + config + secrets
  - `01-infrastructure.yaml` - PostgreSQL (pgvector)
  - `02-services.yaml` - Chatbot, AI player, LLM deployments/services
  - `03-gateway.yaml` - NGINX gateway + routing
  - `04-ollama-model-puller.yaml` - Job om LLM modellen te laden

#### `Deployment/Team8/` (Bordspelplatform A)

Platform met frontend/backend, game, auth en logging stack.

- `Deployment/Team8/README.md` - Gebruik en endpoints
- `Deployment/Team8/DEPLOYMENT_GUIDE.md` - Stapsgewijze deploymentgids
- `Deployment/Team8/agent.txt` - Ops-notities of agent context
- `Deployment/Team8/Scripts/`
  - `deploy-team8.sh` / `teardown-team8.sh` - Deploy en cleanup
  - `setup-gitlab-registry.sh` - Registry secret
  - `setup-postgres-schemas.sh` - Database schema init
  - `update-external-ip.sh` - Public IP refresh in configs
  - `monitor-deployment.sh` / `verify-fixes.sh` - Validatie en checks
  - `player-*.ndjson` / `revenue-*.ndjson` - Kibana dashboards
  - `realm-*.json` - Keycloak realm exports
- `Deployment/Team8/Terraform/`
  - `main.tf` / `kubernetes-cluster.tf` - GKE cluster
  - `google-cloud-sql.tf` - Cloud SQL provisioning
  - `variables.tf` / `terraform.tfvars` / `outputs.tf` - Config en outputs
  - `terraform.tfstate*` - Gegenereerde state backups
- `Deployment/Team8/Kubernetes/` - Manifests + helpers
  - `00-namespace-configmap-secrets.yaml` - Namespace + config + secrets
  - `01-infrastructure.yaml` - Databases/queues
  - `02-platform-frontend-backend.yaml` - Platform services
  - `02-elk-stack.yaml` - Logging stack (ELK)
  - `03-game-blokus.yaml` - Game service
  - `04-gateway.yaml` - Gateway + ingress
  - `deploy.sh` / `teardown.sh` / `verify.sh` / `status.sh` - Helpers
  - `proxy/` / `pods/` - Extra manifests en tooling
  - `README.md`, `QUICK_REFERENCE.md`, `INDEX.md` - Doc bundel
- `Deployment/Team8/infrastructure-main/`
  - `docker-compose.yml` - Lokale infra teststack
  - `nginx/` - Reverse proxy config
  - `postgres-init/` - DB init scripts
  - `themes/` - UI theming resources
  - `README.md` - Uitleg voor de lokale stack

#### `Deployment/Team12/` (Bordspelplatform B)

Platform met games, auth, logging en SSL.

- `Deployment/Team12/README.md` - Gebruik en endpoints
- `Deployment/Team12/DEPLOYMENT_GUIDE.md` - Stapsgewijze deploymentgids
- `Deployment/Team12/Scripts/`
  - `deploy-team12.sh` / `teardown-team12.sh` - Deploy en cleanup
  - `setup-gitlab-registry.sh` - Registry secret
  - `setup-postgres-schemas.sh` - Database schema init
  - `setup-cloud-dns.sh` - DNS records
  - `setup-ssl-certificate.sh` / `watch-certificate.sh` - SSL provisioning
  - `configure-keycloak.sh` - Auth configuratie
  - `update-external-ip.sh` / `verify-fixes.sh` / `status.sh` - Checks
- `Deployment/Team12/Terraform/`
  - `main.tf` / `kubernetes-cluster.tf` - GKE cluster
  - `google-cloud-sql.tf` - Cloud SQL provisioning
  - `variables.tf` / `terraform.tfvars` / `outputs.tf` - Config en outputs
  - `tfplan` / `terraform.tfstate*` - Gegenereerde plan/state files
- `Deployment/Team12/Kubernetes/` - Manifests in volgorde
  - `00-namespace-configmap-secrets.example.yaml` - Voorbeeld secrets/config
  - `01-infrastructure.yaml` - Databases/queues
  - `02-elk-stack.yaml` - Logging stack (ELK)
  - `03-platform-frontend-backend.yaml` - Platform services
  - `04-game-tic-tac-toe.yaml` - Game service
  - `05-gateway.yaml` - Gateway + ingress
  - `06-game-chess.yaml` - Game service
  - `07-ssl-certificate.yaml` - Managed certificate
  - `pods/` - Extra manifests/snippets

### `Initiële testversie/`

Een proof-of-concept omgeving met eenvoudige containers om CI/CD, networking en infra te testen.

- `Initiële testversie/README.md` - Uitleg en quick start
- `Initiële testversie/LINUX-REQUIREMENTS.md` - Linux vereisten en setup
- `Initiële testversie/docker-compose.yml` - Lokale teststack
- `Initiële testversie/init-scripts/init.sql` - DB init data
- `Initiële testversie/kubernetes/` - K8s manifests voor testservices
  - `namespace.yaml`, `configmap.yaml`, `secrets.yaml` - Basis config
  - `nginx-hello.yaml`, `postgres.yaml`, `rabbitmq.yaml` - Core services
  - `elasticsearch.yaml`, `kibana.yaml`, `logstash.yaml` - Logging stack
  - `keycloak.yaml` - Auth service
  - `README.md` - Uitleg per manifest
- `Initiële testversie/opentofu/` - Infra provisioning met OpenTofu
  - `main.tf`, `variables.tf`, `opentofu.tfvars`, `outputs.tf`
  - `README.md` - Setup en apply stappen
- `Initiële testversie/logstash/pipeline/logstash.conf` - Logstash pipeline
- `Initiële testversie/nginx/html/` - Simpele testpagina's

### `Contracten/`

Projectafspraken en contracten.

- `Groepscontract.md` / `Groepscontract_-_Template.pdf` - Basis contracten
- Submappen per platformteam (mapnamen met `Team 4`, `Team 8`, `Team 12`)

### `Hulpmiddelen/`

Referentie- en contextdocumenten.

- `3 - DevOps.md` - DevOps richtlijnen
- `Integratieproject J3 - Bordspelplatform.md` - Overzichtsdocument
- `Integratieproject J3 - Kick-off.md` - Kick-off notities
- `deploymentarchitectuur.png` - Architectuurdiagram

## Componenten (functioneel)

- AI platform: chatbot/RAG, AI player, LLM runtime, vector database
- Bordspelplatforms: webplatforms met games, auth, logging, messaging
- Shared tooling: Terraform/OpenTofu, Kubernetes manifests, deployment scripts

## Vereisten

- GCP project met billing enabled
- `gcloud`, `kubectl`, `tofu` (OpenTofu)
- Toegang tot container registry (GitLab token met `read_registry`)

Zie `Deployment/README.md` voor volledige setup en enablement scripts.

## Deployment paden

- AI platform: `Deployment/Team4/README.md`
- Bordspelplatform A: `Deployment/Team8/README.md`
- Bordspelplatform B: `Deployment/Team12/README.md`
- Ops orchestratie: `Deployment/README.md`

## Initiele testversie (POC)

Voor snelle validatie en CI/CD proofing:

- `Initiële testversie/README.md`
- Docker Compose lokaal of GKE via OpenTofu

## Ops en ondersteuning

Bij vragen of incidenten: Ops team is eigenaar van de infrastructuur en deployments. Documenteer wijzigingen in de relevante `README.md` onder `Deployment/`.
