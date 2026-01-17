18-12-2024
IP3 DevOps
18-12-2024
Content
• Infrastructure as Code
• Kubernetes
• IP3 DevOps
Infrastructure as Code
```
• Infrastructure as Code (IaC)
```
– Deploy, maintain, destroy infrastructure
→ Version managed
– Triggered in CI/CD flow
– DevOps: make software delivery more efficient
– Categories of tools
```
• Scripts (bash, PowerShell, Python,…)
```
```
• Configuration Management tools (Puppet, Chef, Ansible, SaltStack,…)
```
```
• Templating tools (Docker, Packer, Vagrant,…)
```
```
• Provisioning tools (Terraform, Heat, CloudFormation,…)
```
```
• Orchestration tools (Kubernetes, Nomad, Mesos, Swarm,…)
```
- p.3
Configuration Mgmt
• Configuration Management
– Install and maintain software on existing servers
– Puppet, Chef, Ansible, SaltStack,…
```
– Declarative (what) vs. Procedural (how), Master
```
vs. Masterless, Agent vs. Agentless
- p.4
Templating tools
• Templating tools
– Alternative for configuration management
– Creating an image of the server with the installed software
• Virtual Machine images
• Container images
– Can be run in a CI/CD flow
– Immutable infrastructure philosophy
• no change, destroy and create new -> "cattle"
- p.5
Provisioning tools
• Provisioning
– Creates the infrastructure itself
– Terraform, Heat, CloudFormation
– Immutable infrastructure philosophy
- p.6
Orchestration tools
• Orchestration tools are giving operational facilities
to run your images
– Deploying images instances on hardware and
```
making efficient use of it (load balancing)
```
– Elasticity: scaling up/down, auto scaling
– Distributing traffic
– Monitoring health and auto healing
– Update deployment: blue-green update, rolling
update, …
– Service discovery: allow your VM's/Containers to
talk to each other
- p.7
Combinations
• Provisioning and Templating and Orchestration tool
```
– Terraform (for deploying infrastructure)
```
```
– Docker (for creating Container image)
```
```
– Kubernetes (for the operational facilities - Orchestration)
```
- p.8
18-12-2024
Content
• Infrastructure as Code
• Kubernetes
• IP3 DevOps
Cluster nodes
- p.10
•Cluster
– Nodes
– Physical / Virtual
• Nodes
– Master node: coordinates the
cluster
```
– (Worker) nodes run
```
applications
Pods
- p.11
•Pod
– Basic unit of deployment
– Pods run on Nodes
– At least one container
– Can have Storage
volumes
– Unique internal IP address
Deployment Controller
- p.12
•Deployment Controller
– horizontal scaling of pods
– self-healing
▪ Pod goes down → restarted
▪ Node goes down → Pods
started up on another node
Services
- p.13
•Services
– Expose the pods to
▪ other pods
▪ to the outside world
– Routes traffic to the right pod
– Different types
▪ ClusterIP
▪ NodePort
▪ LoadBalancer
Service Types
- p.14
• NodePort
```
– Service is exposed on a port on the (external) IP
```
address of the Node
– Makes a Service accessible from outside the
cluster
– However, nodes can be shut down and new nodes
can be started, so the IP addresses are not
always stable
Service Types
- p.15
```
• ClusterIP (default)
```
– Service is exposed with an internal IP address.
– The name of the ClusterIP service can be used
```
by the other application services (the K8s DNS
```
service will translate the name to the internal
```
IP address)
```
Service Types
- p.16
• LoadBalancer
– Creates an external load balancer and assigns an external IP to the
Service
– Internet DNS
Microservice application in K8s
EXAMPLE SETUP
- Votes are cast with voting app
- results are stored in redis db
- worker node reads memory from
redis app, processes data
- worker node stores data in
permanent storage
- results from the vote can be read
from the result app.
CLUSTERIP SERVICES
- redis
- postgres
NODEPORT SERVICES
- voting-app
- result-app
K8s Ingress
- p.18
• Ingress
– An Ingress is not a Service type, but
has a separate controller
– Can expose multiple Services to the
outside world using the same IP
address
– Uses rules to route paths or
subdomains to the correct
```
(ClusterIP or Nodeport) Service
```
– Different Ingress controllers are
available with different capabilities
▪ NGINX Ingress
▪ GKE Ingress
▪ …
kubectl
- p.19
• K8S command-line tool
• Get information
– kubectl get nodes
– kubectl get pods
– kubectl get deployments
– kubectl get services
• Help
– https://kubernetes.io/docs/reference/generated/kubectl/kubectl-comm
ands
– kubectl --help
• Deploy from command line
– kubectl create deployment DEPLOYMENT_NAME --image=IMAGE_NAME
– kubectl expose deployment/DEPLOYMENT_NAME --type=TYPE
--port=PORT --target-port=CONTAINER_PORT
YAML
- p.20
• Deploy from YAML file
– kubectl create -f file.yaml
• Reference
– https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18
18-12-2024
Content
• Infrastructure as Code
• Kubernetes
• IP3 DevOps
Deployment
- p.22
Docker Container Images
• Docker Container Images
– Docker Container Images are created via GitLab CD
– Stores images in a registry
• Who:
– Dev teams create the GitLab YAML files
– Dev teams and Ops teams agree on which container registry to
use
Kubernetes / Docker Compose
• Kubernetes on Google Cloud
– Production environment
• Docker Compose
– Test environment on laptop
• Who:
– Ops teams create the K8S YAML files
– Ops teams generate necessary documentation
– Dev and Ops teams agree on the requirements for the
```
application services (names, ports, protocols, env vars)
```
– Dev teams write the required compose yaml file for the
deployment on their system with Docker Compose
Terraform
• Terraform
– Creates the K8s cluster on Google Cloud
– Deploys cloud components which are not running in the K8s
```
cluster (e.g. database)
```
```
– Run manually (shutdown cluster when you stop working to save
```
```
Google Cloud credits)
```
• Who:
– Ops teams develop the Terraform tf files
– Ops teams document the deployment
Frontend -> backend communication
• From your frontend, always communicate with /api
• On the Kubernetes cluster, this will work as the Ingress
Controller will route the request
• On the local Docker Compose setup, there is no Ingress
Controller. A few solutions:
– For local development with Vite:
Set up
```
https://vite.dev/config/server-options#server-proxy
```
so the local dev server can route the /api call to
your local API.
– For running inside docker-compose:
Set up a reverse proxy container that behaves
similarly to the Ingress Controller.
```
Monitoring (TBD)
```
• Monitoring is set up for:
– Infrastructure: uptime, usage, logs…
– Application: uptime/logs app components
```
– Dashboard (timeseries,…)
```
• Who:
```
– Ops teams choose and install the tool(s) and create dashboards
```
– Ops teams define what to monitor for the infrastructure
```
– Dev teams provide application endpoints (e.g. Spring
```
```
Boot/Actuators ) for the monitoring
```
Next steps
• Ops and Dev team assign “deployment contact” person. Dev
```
team: 1 contact person, Ops team: 4 contact persons (1 for
```
```
each Dev team)
```
• Ops and Dev “deployment contacts” meet Friday W1 to discuss
the “deployment agreement”
• Ops and Dev teams finalize the “deployment agreement” Friday
W2
Deployment agreement
• In the “deployment agreement”, the Dev and Ops teams agree
```
on the work (and timing) to be done by the Ops “service
```
provider” for the Dev team
```
– Agree on what to be done (see previous slides)
```
– Agree on the specifications/requirements
```
– Agree on what input the Ops teams need (and by when), to be able to
```
```
execute the “deployment service” (e.g. delivery for test and final
```
```
versions of the containers images)
```
```
– Agree on timing of delivery deployment files and documentation (test
```
```
and final versions) and documentation
```
– Agree on “deployment contacts” and when they meet
– Agree on the availability of the teams and “deployment contacts”
Information
• Google Cloud credits: see Canvas
– 4/5 credits for DevOps teams
– Everybody is responsible for his own credits!
• More documentation of K8S and Terraform: see Canvas
• On-site session Terraform for ISB: next Friday
• https://cloud.google.com/sql/docs/postgres/connect-kuberne
tes-engine
• https://kubernetes.io/docs/concepts/configuration/secret/