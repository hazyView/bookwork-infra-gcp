# Bookwork Infrastructure - GCP

Terraform configuration for deploying the Bookwork application infrastructure on Google Cloud Platform (GCP). This setup provisions a containerized web application with API backend and frontend components using Cloud Run, Global Load Balancer, and Artifact Registry.

## Architecture Overview

This infrastructure deploys:
- **Cloud Run Services**: Containerized application deployment for API and frontend
- **Global Load Balancer**: HTTPS traffic routing with SSL/TLS termination
- **Artifact Registry**: Container image storage for API and frontend
- **Google-managed SSL Certificate**: SSL/TLS certificate for HTTPS
- **IAM Service Accounts**: Secure access control for Cloud Run services

## Infrastructure Components

### Container Services
- **API Service**: Runs on port 8080, handles `/api/*` routes
- **Frontend Service**: Runs on port 3000, serves the web application  
- Both services run on Cloud Run with auto-scaling (0-10 instances)
- Resource limits: 1 vCPU, 512MB memory per instance

### Load Balancing
- **Global Load Balancer**: Routes traffic based on path patterns
- **HTTPS listener**: Port 443 with Google-managed SSL certificate
- **HTTP to HTTPS redirect**: Automatic redirect from port 80 to 443
- **Path-based routing**: Frontend serves default traffic, API traffic routed via `/api/*`

### Container Registry
- **Artifact Registry repositories**: Separate repositories for API and frontend images
- **Regional storage**: Images stored in the same region as Cloud Run services

### Security
- **Service Accounts**: Dedicated service account for Cloud Run services
- **IAM bindings**: Minimal required permissions
- **HTTPS-only**: All traffic encrypted in transit

## Prerequisites

- Google Cloud CLI (`gcloud`) installed and authenticated
- Terraform >= 1.0 installed
- A GCP project with billing enabled
- Domain name for SSL certificate (configurable via variables)

## Configuration

### Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `project_id` | The GCP project ID | **(required)** |
| `region` | The GCP region | `us-central1` |
| `zone` | The GCP zone within the region | `us-central1-a` |
| `project` | Project name prefix for resources | `bookwork` |
| `domain_name` | Domain name for SSL certificate | `bookwork.demo.com` |
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
   docker build -t us-central1-docker.pkg.dev/$PROJECT_ID/bookwork-api/api:latest ./api
   docker push us-central1-docker.pkg.dev/$PROJECT_ID/bookwork-api/api:latest
   
   # For Frontend
   docker build -t us-central1-docker.pkg.dev/$PROJECT_ID/bookwork-frontend/frontend:latest ./frontend
   docker push us-central1-docker.pkg.dev/$PROJECT_ID/bookwork-frontend/frontend:latest
   ```

3. **Deploy new image versions**:
   ```bash
   terraform apply -var="api_image_tag=v1.2.3" -var="frontend_image_tag=v1.2.3"
   ```

## Outputs

After successful deployment, the following outputs are available:

- `load_balancer_ip`: IP address of the Global Load Balancer
- `domain_name`: The configured domain name
- `api_service_url`: Direct URL of the Cloud Run API service
- `frontend_service_url`: Direct URL of the Cloud Run frontend service
- `api_artifact_registry_url`: Artifact Registry URL for the API repository
- `frontend_artifact_registry_url`: Artifact Registry URL for the frontend repository
- `ssl_certificate_status`: Status of the managed SSL certificate
- `dns_instructions`: DNS configuration instructions

## DNS Configuration

After deployment, you need to configure DNS:

1. **Get the load balancer IP**:
   ```bash
   terraform output load_balancer_ip
   ```

2. **Create DNS A record**:
   - Create an A record for your domain pointing to the load balancer IP
   - Example: `bookwork.demo.com` → `34.102.136.180`

3. **Wait for SSL certificate provisioning**:
   - Google-managed certificates can take 10-60 minutes to provision
   - Check status: `terraform output ssl_certificate_status`

## Health Checks

- **API**: Health check endpoint at `/health` (expected 200 response)
- **Frontend**: Health check at root `/` (expected 200 response)
- **Probes**: Both startup and liveness probes configured for each service

## Auto-scaling

Cloud Run services are configured with:
- **Minimum instances**: 0 (scales to zero when no traffic)
- **Maximum instances**: 10 (can be adjusted based on needs)
- **CPU-based scaling**: Automatically scales based on CPU utilization and request volume

## Security Considerations

- **HTTPS-only**: All traffic automatically redirected to HTTPS
- **Google-managed SSL**: Certificates automatically renewed
- **Service accounts**: Minimal required permissions
- **Regional deployment**: Resources deployed in a single region for optimal performance
- **No VPC**: Uses Google's default networking (consider custom VPC for production)

## Cost Optimization

Current configuration uses:
- **Cloud Run**: Pay-per-use pricing, scales to zero
- **Global Load Balancer**: Pay for data processed
- **Artifact Registry**: Pay for storage used
- **Minimal resource allocation**: 1 vCPU, 512MB memory per instance

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

**Note**: This will delete all resources including container images in Artifact Registry.

This GCP infrastructure is equivalent to the AWS setup with these mappings:

| AWS Service | GCP Service | Notes |
|-------------|-------------|-------|
| ECS Fargate | Cloud Run | Serverless container platform |
| ECR | Artifact Registry | Container image storage |
| Application Load Balancer | Global Load Balancer | Layer 7 load balancing |
| ACM Certificate | Google-managed SSL | Automatic certificate management |
| Security Groups | IAM + Service networking | Access control |
| Route 53 | Cloud DNS (manual) | DNS management |


### Useful Commands

```bash
# Check Cloud Run services
gcloud run services list --region=us-central1

# View service logs
gcloud run services logs read bookwork-api --region=us-central1

# Check load balancer status
gcloud compute url-maps describe bookwork-urlmap --global

# List Artifact Registry repositories
gcloud artifacts repositories list --location=us-central1
```
