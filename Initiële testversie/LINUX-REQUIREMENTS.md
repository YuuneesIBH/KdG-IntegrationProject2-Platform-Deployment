# Linux Requirements - Bordspelplatform Setup

## 📋 Vereiste Software

### 1. Docker & Docker Compose

**⚠️ BELANGRIJK: Kali Linux Gebruikers**

Kali Linux heeft Docker.io in de officiële repositories. Gebruik NIET de Ubuntu instructies!

**Installatie (Kali Linux - AANBEVOLEN):**

```bash
# Update package index
sudo apt update

# Installeer Docker.io (Kali's versie)
sudo apt install -y docker.io docker-compose

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group (no sudo needed)
sudo usermod -aG docker $USER

# BELANGRIJK: Logout en login opnieuw, of run:
newgrp docker

# Verify installation
docker --version
docker compose version
```

**Installatie (Ubuntu/Debian):**

```bash
# Update package index
sudo apt update

# Installeer dependencies
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Setup repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group (no sudo needed)
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker compose version
```

**Installatie (Fedora/RHEL):**

```bash
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

**Test:**

```bash
docker run hello-world
docker compose version
```

### 2. kubectl (Kubernetes CLI)

**Installatie:**

```bash
# Download latest version
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify
kubectl version --client
```

**Alternatief (via package manager):**

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y kubectl

# Verify
kubectl version --client
```

### 3. Google Cloud SDK (gcloud)

**Installatie (via installer):**

```bash
# Download en installeer
curl https://sdk.cloud.google.com | bash

# Restart shell
exec -l $SHELL
```

**Configuratie:**

```bash
# Login
gcloud auth login

# Set project
gcloud config set project YOUR_PROJECT_ID

# Configure docker authentication
gcloud auth configure-docker

# Configure kubectl for GKE
gcloud components install gke-gcloud-auth-plugin

# Run ook deze, handig voor opentofu
gcloud auth application-default login
```

**Test:**

```bash
gcloud version
gcloud auth list
```

### 4. OpenTofu

**Installatie (manual):**

```bash
# Download latest release
wget https://github.com/opentofu/opentofu/releases/download/v1.6.0/tofu_1.6.0_linux_amd64.zip

# Unzip
unzip tofu_1.6.0_linux_amd64.zip

# Move to bin
sudo mv tofu /usr/local/bin/

# Verify
tofu --version
```

**Installatie (Snap):**

```bash
sudo snap install opentofu --classic
tofu --version
```

### 5. Git

**Installatie:**

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y git

# Configure
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Verify
git --version
```

### 6. Utilities (Optioneel maar handig)

**Installatie:**

```bash
# Essential tools
sudo apt install -y curl wget jq unzip

# Network tools
sudo apt install -y net-tools iputils-ping dnsutils

# Editor (kies wat je wilt)
sudo apt install -y vim nano

# PostgreSQL client (voor database testing)
sudo apt install -y postgresql-client

# Verify
curl --version
jq --version
psql --version
```

## 🔍 Verificatie Script

Save als `check-requirements.sh`:

```bash
#!/bin/bash

echo "=== Checking Requirements for Bordspelplatform ==="
echo ""

# Function to check command
check_cmd() {
    if command -v $1 &> /dev/null; then
        echo "✅ $1: $(command -v $1)"
        $1 --version 2>&1 | head -n 1
    else
        echo "❌ $1: NOT FOUND"
        return 1
    fi
    echo ""
}

# Check all requirements
check_cmd docker
check_cmd "docker compose" || check_cmd docker-compose
check_cmd kubectl
check_cmd gcloud
check_cmd tofu
check_cmd git
check_cmd curl
check_cmd jq

echo "=== Docker Group Check ==="
if groups | grep -q docker; then
    echo "✅ User is in docker group"
else
    echo "⚠️  User NOT in docker group - run: sudo usermod -aG docker \$USER && newgrp docker"
fi

echo ""
echo "=== Docker Service Check ==="
if systemctl is-active --quiet docker; then
    echo "✅ Docker service is running"
else
    echo "❌ Docker service is NOT running - run: sudo systemctl start docker"
fi

echo ""
echo "=== Docker Test ==="
if docker ps &> /dev/null; then
    echo "✅ Docker is accessible"
else
    echo "❌ Cannot access Docker - check permissions"
fi

echo ""
echo "=== GCloud Authentication ==="
if gcloud auth list 2>&1 | grep -q ACTIVE; then
    echo "✅ GCloud authenticated"
    gcloud config list
else
    echo "⚠️  Not authenticated - run: gcloud auth login"
fi

echo ""
echo "=== Summary ==="
echo "If all checks pass, you're ready to start! 🚀"
```

**Run:**

```bash
chmod +x check-requirements.sh
./check-requirements.sh
```

## 📦 Minimale Requirements

### Voor Docker Compose Test (Lokaal):

- ✅ Docker Engine (20.10+)
- ✅ Docker Compose (v2.0+)
- ✅ Git

### Voor Kubernetes Test (Lokaal met Minikube):

- ✅ Docker
- ✅ kubectl
- ✅ Minikube

```bash
# Installeer Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start cluster
minikube start --driver=docker
```

### Voor Cloud Deployment (GCP):

- ✅ Docker
- ✅ kubectl
- ✅ Google Cloud SDK (gcloud)
- ✅ OpenTofu
- ✅ Git

## 🎯 Complete Setup Script

Save als `setup-environment.sh`:

```bash
#!/bin/bash
set -e

echo "🚀 Setting up Bordspelplatform Development Environment"
echo ""

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker
if ! command -v docker &> /dev/null; then
    echo "🐳 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    sudo systemctl start docker
    sudo systemctl enable docker
fi

# Install Docker Compose
if ! docker compose version &> /dev/null; then
    echo "🔧 Installing Docker Compose..."
    sudo apt install -y docker-compose-plugin
fi

# Install kubectl
if ! command -v kubectl &> /dev/null; then
    echo "☸️  Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
fi

# Install Google Cloud SDK
if ! command -v gcloud &> /dev/null; then
    echo "☁️  Installing Google Cloud SDK..."
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    sudo apt update
    sudo apt install -y google-cloud-cli google-cloud-sdk-gke-gcloud-auth-plugin
fi

# Install OpenTofu (aanbevolen)
if ! command -v tofu &> /dev/null; then
    echo "🔱 Installing OpenTofu..."
    curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
    chmod +x install-opentofu.sh
    ./install-opentofu.sh --install-method deb
    rm install-opentofu.sh
fi

# Install utilities
echo "🛠️  Installing utilities..."
sudo apt install -y git curl wget jq unzip postgresql-client

echo ""
echo "✅ Installation complete!"
echo ""
echo "⚠️  IMPORTANT: Logout and login again for Docker group changes to take effect"
echo "Then run: ./check-requirements.sh"
```

**Run:**

```bash
chmod +x setup-environment.sh
./setup-environment.sh

# Logout en login opnieuw
logout
```

## 🧪 Test de Setup

### 1. Docker Compose Test

```bash
cd "Initiële testversie"

# Start services
docker compose up -d

# Check
docker compose ps
curl http://localhost:8080

# Stop
docker compose down
```

### 2. Kubernetes Test (Lokaal met Minikube)

```bash
# Start Minikube
minikube start

# Deploy
cd kubernetes
kubectl apply -f namespace.yaml
kubectl apply -f nginx-hello.yaml

# Check
kubectl get pods -n bordspelplatform

# Test
minikube service nginx-hello-service -n bordspelplatform

# Cleanup
minikube delete
```

### 3. Cloud Deployment Test

```bash
# Authenticate
gcloud auth login

# Set project
gcloud config set project YOUR_PROJECT_ID

# Enable APIs
gcloud services enable compute.googleapis.com container.googleapis.com

# Deploy with OpenTofu
cd opentofu
tofu init
tofu plan
tofu apply

# Note: Enable alle GCP APIs eerst!
# gcloud services enable container.googleapis.com artifactregistry.googleapis.com servicenetworking.googleapis.com sqladmin.googleapis.com

# Get cluster credentials
gcloud container clusters get-credentials dev-gke-cluster --region europe-west1

# Deploy to K8s
cd ../kubernetes
kubectl apply -f .

# Check
kubectl get all -n bordspelplatform
```

## 💾 System Requirements

### Minimaal:

- **RAM**: 8GB (16GB aanbevolen)
- **Disk**: 20GB vrije ruimte
- **CPU**: 2 cores (4 aanbevolen)
- **OS**: Ubuntu 20.04+ / Debian 11+ / Fedora 38+

### Voor Docker Compose met alle services:

- **RAM**: 8GB minimum (Elasticsearch + Kibana zijn memory-intensive)
- **Disk**: 30GB vrije ruimte

### Voor Minikube:

```bash
# Start met meer resources
minikube start --memory=4096 --cpus=2 --disk-size=20g
```

## 🔧 Troubleshooting

### Docker permission denied

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Apply changes (logout/login of:)
newgrp docker

# Test
docker ps
```

### Docker service not running

```bash
# Start Docker
sudo systemctl start docker

# Check status
sudo systemctl status docker

# Enable on boot
sudo systemctl enable docker
```

### kubectl connection refused

```bash
# Check if cluster is running
minikube status

# Or for GKE
gcloud container clusters list

# Get credentials again
gcloud container clusters get-credentials <cluster-name> --region <region>
```

### OpenTofu command not found

```bash
# Check if installed
which tofu

# Add to PATH if needed
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
source ~/.bashrc
```

### Port already in use

```bash
# Find process using port
sudo lsof -i :8080

# Kill process
sudo kill -9 <PID>

# Or change port in docker-compose.yml
```

## 📝 Quick Reference

### Essential Commands

```bash
# Docker
docker ps                          # List running containers
docker compose up -d              # Start services
docker compose down               # Stop services
docker compose logs -f            # View logs
docker system prune -a            # Clean up

# Kubernetes
kubectl get pods -n bordspelplatform        # List pods
kubectl logs <pod> -n bordspelplatform      # View logs
kubectl describe pod <pod> -n bordspelplatform  # Debug
kubectl port-forward svc/<service> 8080:80  # Port forward

# OpenTofu
tofu init                         # Initialize
tofu plan                         # Preview changes
tofu apply                        # Apply changes
tofu destroy                      # Destroy infrastructure

# GCloud
gcloud auth login                 # Authenticate
gcloud config set project <ID>    # Set project
gcloud container clusters list    # List clusters
```

## ✅ Complete Setup Checklist

- [ ] Docker Engine installed and running
- [ ] Docker Compose installed (v2+)
- [ ] User added to docker group (no sudo needed)
- [ ] kubectl installed
- [ ] Google Cloud SDK installed
- [ ] OpenTofu installed
- [ ] Git installed
- [ ] GCloud authenticated (`gcloud auth login`)
- [ ] GCP Project configured (`gcloud config set project`)
- [ ] Required GCP APIs enabled
- [ ] At least 8GB RAM available
- [ ] At least 20GB disk space available

## 🚀 All-in-One Test

```bash
# Clone repo (if not done)
git clone <your-repo-url>
cd integratieproject-j3-devops-team-4

# Navigate to test version
cd "Initiële testversie"

# Start Docker Compose test
docker compose up -d

# Wait 30 seconds
sleep 30

# Test all endpoints
curl http://localhost:8080  # Platform
curl http://localhost:8081  # Game
curl http://localhost:8082  # Backend
curl http://localhost:15672 # RabbitMQ

# Check database
docker compose exec postgres psql -U testuser -d testdb -c "SELECT * FROM test_status;"

# View logs
docker compose logs

# Stop
docker compose down

echo "✅ If no errors, your setup is complete!"
```

## 📚 Volgende Stappen

Na installatie:

1. Run `./check-requirements.sh` om alles te verifiëren
2. Test Docker Compose: `docker compose up -d`
3. Test Kubernetes lokaal met Minikube
4. Deploy naar GCP met OpenTofu

Voor vragen, zie de README.md in elke directory! 🎯
