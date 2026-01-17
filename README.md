# Integration Project J3 - DevOps Overview

This repository contains the full infrastructure and deployment tooling for the board game platform, including AI services, application platforms, and an initial test version. Operations and support are owned by the Ops team.

## Contents

- `Deployment/` - Full infra and deployment per platform component
- `Initiële testversie/` - Proof-of-concept environment for quick validation
- `Contracten/` - Project and team contracts
- `Hulpmiddelen/` - Reference documents and visuals

## Quick start (Deployment)

Use the central script to deploy a component:

```bash
cd Deployment/Scripts
bash main.sh
```

Follow the menu to run a deployment. Details per component are in the specific README files under `Deployment/`.

## Map-by-map explanation

Note: folder names reflect the original project structure. The explanation below is functional and avoids dev team names.

### `Deployment/`

The production-like deployment environment with scripts, Terraform, and Kubernetes manifests.

- `Deployment/README.md` - Overall deployment guide and entry points
- `Deployment/credentials.json` - GCP service account key (gitignored)
- `Deployment/Scripts/` - Central ops scripts
  - `main.sh` - Interactive menu to deploy a component
  - `enable-gcp-apis.sh` - Enables required GCP APIs
  - `create-gcp-service-account.sh` - Creates a service account and keys

#### `Deployment/Team4/` (AI platform)

Infrastructure and services for chatbot/RAG, AI player, LLM, and database.

- `Deployment/Team4/README.md` - Practical usage and endpoints
- `Deployment/Team4/DEPLOYMENT_GUIDE.md` - Step-by-step deployment guide
- `Deployment/Team4/Scripts/`
  - `deploy-team4.sh` - End-to-end deployment (infra + K8s)
  - `teardown-team4.sh` - Cleanup resources
  - `setup-gitlab-registry.sh` - Registry secret in namespace
  - `status.sh` - Quick status of pods/services
- `Deployment/Team4/Terraform/` - GKE cluster and networking
  - `main.tf` - Provider and shared config
  - `kubernetes-cluster.tf` - GKE cluster definition
  - `variables.tf` / `terraform.tfvars` - Inputs and values
  - `outputs.tf` - Key output values
  - `tfplan` / `terraform.tfstate*` - Generated plan/state files
- `Deployment/Team4/Kubernetes/` - Manifests in a fixed order
  - `00-namespace-configmap-secrets.yaml` - Namespace + config + secrets
  - `01-infrastructure.yaml` - PostgreSQL (pgvector)
  - `02-services.yaml` - Chatbot, AI player, LLM deployments/services
  - `03-gateway.yaml` - NGINX gateway + routing
  - `04-ollama-model-puller.yaml` - Job to pull LLM models

#### `Deployment/Team8/` (Board game platform A)

Platform with frontend/backend, game service, auth, and logging stack.

- `Deployment/Team8/README.md` - Usage and endpoints
- `Deployment/Team8/DEPLOYMENT_GUIDE.md` - Step-by-step deployment guide
- `Deployment/Team8/agent.txt` - Ops notes or agent context
- `Deployment/Team8/Scripts/`
  - `deploy-team8.sh` / `teardown-team8.sh` - Deploy and cleanup
  - `setup-gitlab-registry.sh` - Registry secret
  - `setup-postgres-schemas.sh` - Database schema init
  - `update-external-ip.sh` - Refresh public IP in configs
  - `monitor-deployment.sh` / `verify-fixes.sh` - Validation and checks
  - `player-*.ndjson` / `revenue-*.ndjson` - Kibana dashboards
  - `realm-*.json` - Keycloak realm exports
- `Deployment/Team8/Terraform/`
  - `main.tf` / `kubernetes-cluster.tf` - GKE cluster
  - `google-cloud-sql.tf` - Cloud SQL provisioning
  - `variables.tf` / `terraform.tfvars` / `outputs.tf` - Config and outputs
  - `terraform.tfstate*` - Generated state backups
- `Deployment/Team8/Kubernetes/` - Manifests + helpers
  - `00-namespace-configmap-secrets.yaml` - Namespace + config + secrets
  - `01-infrastructure.yaml` - Databases/queues
  - `02-platform-frontend-backend.yaml` - Platform services
  - `02-elk-stack.yaml` - Logging stack (ELK)
  - `03-game-blokus.yaml` - Game service
  - `04-gateway.yaml` - Gateway + ingress
  - `deploy.sh` / `teardown.sh` / `verify.sh` / `status.sh` - Helpers
  - `proxy/` / `pods/` - Extra manifests and tooling
  - `README.md`, `QUICK_REFERENCE.md`, `INDEX.md` - Doc bundle
- `Deployment/Team8/infrastructure-main/`
  - `docker-compose.yml` - Local infra test stack
  - `nginx/` - Reverse proxy config
  - `postgres-init/` - DB init scripts
  - `themes/` - UI theming resources
  - `README.md` - Notes for the local stack

#### `Deployment/Team12/` (Board game platform B)

Platform with games, auth, logging, and SSL.

- `Deployment/Team12/README.md` - Usage and endpoints
- `Deployment/Team12/DEPLOYMENT_GUIDE.md` - Step-by-step deployment guide
- `Deployment/Team12/Scripts/`
  - `deploy-team12.sh` / `teardown-team12.sh` - Deploy and cleanup
  - `setup-gitlab-registry.sh` - Registry secret
  - `setup-postgres-schemas.sh` - Database schema init
  - `setup-cloud-dns.sh` - DNS records
  - `setup-ssl-certificate.sh` / `watch-certificate.sh` - SSL provisioning
  - `configure-keycloak.sh` - Auth configuration
  - `update-external-ip.sh` / `verify-fixes.sh` / `status.sh` - Checks
- `Deployment/Team12/Terraform/`
  - `main.tf` / `kubernetes-cluster.tf` - GKE cluster
  - `google-cloud-sql.tf` - Cloud SQL provisioning
  - `variables.tf` / `terraform.tfvars` / `outputs.tf` - Config and outputs
  - `tfplan` / `terraform.tfstate*` - Generated plan/state files
- `Deployment/Team12/Kubernetes/` - Manifests in order
  - `00-namespace-configmap-secrets.example.yaml` - Example secrets/config
  - `01-infrastructure.yaml` - Databases/queues
  - `02-elk-stack.yaml` - Logging stack (ELK)
  - `03-platform-frontend-backend.yaml` - Platform services
  - `04-game-tic-tac-toe.yaml` - Game service
  - `05-gateway.yaml` - Gateway + ingress
  - `06-game-chess.yaml` - Game service
  - `07-ssl-certificate.yaml` - Managed certificate
  - `pods/` - Extra manifests/snippets

### `Initiële testversie/`

A proof-of-concept environment with simple containers to test CI/CD, networking, and infra.

- `Initiële testversie/README.md` - Explanation and quick start
- `Initiële testversie/LINUX-REQUIREMENTS.md` - Linux requirements and setup
- `Initiële testversie/docker-compose.yml` - Local test stack
- `Initiële testversie/init-scripts/init.sql` - DB init data
- `Initiële testversie/kubernetes/` - K8s manifests for test services
  - `namespace.yaml`, `configmap.yaml`, `secrets.yaml` - Base config
  - `nginx-hello.yaml`, `postgres.yaml`, `rabbitmq.yaml` - Core services
  - `elasticsearch.yaml`, `kibana.yaml`, `logstash.yaml` - Logging stack
  - `keycloak.yaml` - Auth service
  - `README.md` - Notes per manifest
- `Initiële testversie/opentofu/` - Infra provisioning with OpenTofu
  - `main.tf`, `variables.tf`, `opentofu.tfvars`, `outputs.tf`
  - `README.md` - Setup and apply steps
- `Initiële testversie/logstash/pipeline/logstash.conf` - Logstash pipeline
- `Initiële testversie/nginx/html/` - Simple test pages

### `Contracten/`

Project agreements and contracts.

- `Groepscontract.md` / `Groepscontract_-_Template.pdf` - Base contracts
- Subfolders per platform team (folders named `Team 4`, `Team 8`, `Team 12`)

### `Hulpmiddelen/`

Reference and context documents.

- `3 - DevOps.md` - DevOps guidelines
- `Integratieproject J3 - Bordspelplatform.md` - Overview document
- `Integratieproject J3 - Kick-off.md` - Kick-off notes
- `deploymentarchitectuur.png` - Architecture diagram

## Componenten (functioneel)

- AI platform: chatbot/RAG, AI player, LLM runtime, vector database
- Bordspelplatforms: webplatforms met games, auth, logging, messaging
- Shared tooling: Terraform/OpenTofu, Kubernetes manifests, deployment scripts

## Vereisten

- GCP project met billing enabled
- `gcloud`, `kubectl`, `tofu` (OpenTofu)
- Toegang tot container registry (GitLab token met `read_registry`)

Zie `Deployment/README.md` voor volledige setup en enablement scripts.

## Deployment paths

- AI platform: `Deployment/Team4/README.md`
- Board game platform A: `Deployment/Team8/README.md`
- Board game platform B: `Deployment/Team12/README.md`
- Ops orchestration: `Deployment/README.md`

## Initial test version (POC)

For quick validation and CI/CD proofing:

- `Initiële testversie/README.md`
- Docker Compose locally or GKE via OpenTofu

## Ops and support

For questions or incidents: the Ops team owns infrastructure and deployments. Document changes in the relevant `README.md` under `Deployment/`.
