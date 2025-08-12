
# Bookwork Infrastructure - GCP

Terraform configuration for deploying the Bookwork application infrastructure on Google Cloud Platform (GCP). This setup provisions a containerized web application with API backend and frontend components using **Google Kubernetes Engine (GKE)**, a VPC, Artifact Registry, and a Global Load Balancer.


## Project Overview


This repository contains:
- **Terraform modules** for GCP infrastructure (GKE, VPC, Load Balancer, Artifact Registry, IAM)
- **Makefile** for streamlined Terraform workflows
- **Implementation guide**: See `impl_bk.md` for a step-by-step, free-tier-focused deployment guide
- **.gitignore** for security of sensitive files (e.g., `.tfvars`, state, and plan files)
- **Note**: `graph.png` is present but currently empty/not provided



### Main Infrastructure Components
- **Google Kubernetes Engine (GKE) Cluster**: Runs the API and frontend workloads as Kubernetes deployments
- **VPC and Subnet**: Custom network and subnet for GKE and related resources
- **Artifact Registry**: Container image storage for API and frontend
- **Global Load Balancer**: HTTPS traffic routing with SSL/TLS termination
- **Google-managed SSL Certificate**: SSL/TLS certificate for HTTPS
- **IAM Service Accounts**: Secure access control for GKE nodes and workloads

## Infrastructure Components


### Application Services
- **API Service**: Runs on GKE, typically on port 8080, handles `/api/*` routes
- **Frontend Service**: Runs on GKE, typically on port 3000, serves the web application
- Both services are deployed as Kubernetes Deployments and Services


### Load Balancing
- **Global Load Balancer**: Routes traffic to GKE services based on path patterns
- **HTTPS listener**: Port 443 with Google-managed SSL certificate
- **HTTP to HTTPS redirect**: Automatic redirect from port 80 to 443
- **Path-based routing**: Frontend serves default traffic, API traffic routed via `/api/*`


### Container Registry
- **Artifact Registry repositories**: Separate repositories for API and frontend images
- **Regional storage**: Images stored in the same region as GKE cluster


### Security
- **Service Accounts**: Dedicated service account for GKE nodes
- **IAM bindings**: Minimal required permissions
- **HTTPS-only**: All traffic encrypted in transit


## Prerequisites

- Google Cloud CLI (`gcloud`) installed and authenticated
- Terraform >= 1.0 installed
- A GCP project with billing enabled
- Domain name for SSL certificate (configurable via variables)
- Docker (for building and pushing images)

## Configuration



### Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `project_id` | The GCP project ID | **(required)** |
| `region` | The GCP region | `us-central1` |
| `zone` | The GCP zone within the region | `us-central1-c` |
| `project` | Project name prefix for resources | `bookwork` |
| `domain_name` | Domain name for SSL certificate | `bookwork-demo.com` |
| `api_image_tag` | Docker image tag for API | `latest` |
| `frontend_image_tag` | Docker image tag for frontend | `latest` |

### Initial Setup

1. **Set up GCP authentication**:
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

2. **Create a terraform.tfvars file**:
   ```hcl
   project_id  = "your-gcp-project-id"
   region      = "us-central1"
   domain_name = "your-domain.com"
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Plan the deployment**:
   ```bash
   terraform plan
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply
   ```


### Container Deployment

After infrastructure is provisioned:

1. **Configure Docker authentication**:
   ```bash
   gcloud auth configure-docker us-central1-docker.pkg.dev
   ```

2. **Build and push your container images**:
   ```bash
   # For API
   docker build -t us-central1-docker.pkg.dev/$PROJECT_ID/bookwork-registry/api:latest ./api
   docker push us-central1-docker.pkg.dev/$PROJECT_ID/bookwork-registry/api:latest

   # For Frontend
   docker build -t us-central1-docker.pkg.dev/$PROJECT_ID/bookwork-registry/frontend:latest ./frontend
   docker push us-central1-docker.pkg.dev/$PROJECT_ID/bookwork-registry/frontend:latest
   ```

3. **Deploy to GKE**:
   - Use `kubectl` to apply your Kubernetes manifests for API and frontend deployments/services, referencing the pushed images.
   - Example:
     ```bash
     kubectl apply -f k8s/api-deployment.yaml
     kubectl apply -f k8s/frontend-deployment.yaml
     ```



## Outputs

After successful deployment, the following outputs are available (see `outputs.tf` for details):

- `gke_cluster_name`: Name of the GKE cluster
- `gke_cluster_endpint`: Endpoint for GKE cluster's master
- `gke_node_service_account`: Email of the service account used by GKE nodes
- `artifact_registry_name`: Name of the Artifact Registry
- `network_name`: Name of the VPC network
- `load_balancer_ip`: IP address of the Global Load Balancer (if enabled)
- `domain_name`: The configured domain name



## DNS Configuration

After deployment, you need to configure DNS:

1. **Get the load balancer IP**:
   ```bash
   terraform output load_balancer_ip
   ```

2. **Create DNS A record**:
   - Create an A record for your domain pointing to the load balancer IP
   - Example: `bookwork-demo.com` → `34.102.136.180`

3. **Wait for SSL certificate provisioning**:
   - Google-managed certificates can take 10-60 minutes to provision



## Health Checks

- **API**: Health check endpoint at `/health` (expected 200 response)
- **Frontend**: Health check at root `/` (expected 200 response)
- **Probes**: Both startup and liveness probes should be configured in your Kubernetes manifests



## Auto-scaling

GKE supports auto-scaling via Kubernetes Horizontal Pod Autoscaler (HPA). Configure HPA in your manifests as needed.



## Security Considerations

- **HTTPS-only**: All traffic automatically redirected to HTTPS
- **Google-managed SSL**: Certificates automatically renewed
- **Service accounts**: Minimal required permissions
- **Regional deployment**: Resources deployed in a single region for optimal performance
- **Custom VPC**: Used for GKE and related resources



## Cost Optimization

Current configuration uses:
- **GKE**: Pay for node hours and resources used
- **Global Load Balancer**: Pay for data processed
- **Artifact Registry**: Pay for storage used
- **Minimal resource allocation**: 1 node (e2-medium) by default



## Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

**Note**: This will delete all resources including container images in Artifact Registry.



## Additional Notes

- See `impl_bk.md` for a detailed, step-by-step implementation guide (including free-tier and local development options)
- Sensitive files (e.g., `.tfvars`, state, and plan files) are excluded from version control via `.gitignore` for security
- The file `graph.png` is present but currently empty or not provided

---


This GCP infrastructure is equivalent to the AWS setup with these mappings:

| AWS Service | GCP Service | Notes |
|-------------|-------------|-------|
| EKS | GKE | Managed Kubernetes |
| ECR | Artifact Registry | Container image storage |
| Application Load Balancer | Global Load Balancer | Layer 7 load balancing |
| ACM Certificate | Google-managed SSL | Automatic certificate management |
| Security Groups | IAM + VPC | Access control |
| Route 53 | Cloud DNS (manual) | DNS management |

### Useful Commands

```bash
# Get GKE credentials
gcloud container clusters get-credentials <cluster-name> --region=<region>

# List GKE clusters
gcloud container clusters list

# Check load balancer status
gcloud compute url-maps describe <urlmap-name> --global

# List Artifact Registry repositories
gcloud artifacts repositories list --location=us-central1
```
