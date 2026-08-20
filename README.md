# ShopFlow

An end-to-end DevOps project demonstrating how to containerize, secure, continuously integrate, and automatically deploy a Node.js API to Kubernetes on AWS using Terraform and GitHub Actions.

## Project Overview

ShopFlow is a small Node.js-based e-commerce API created to demonstrate a production-oriented DevOps workflow.

The project covers:

* Infrastructure as Code with Terraform
* AWS VPC and EC2 provisioning
* Docker containerization
* Docker image security scanning with Trivy
* GitHub Actions CI/CD
* Docker Hub image publishing
* Kubernetes deployment using K3s
* Traefik Ingress
* Kubernetes resource requests and limits
* Readiness and liveness probes
* Kubernetes self-healing
* Rolling updates
* Application request logging
* Kubernetes CPU and memory monitoring

## Architecture

```text
Developer
    |
    v
GitHub Repository
    |
    v
Pull Request
    |
    v
GitHub Actions
    |
    +---- ESLint
    |
    +---- Jest Tests
    |
    +---- Docker Build
    |
    +---- Trivy Security Scan
    |
    v
Docker Hub
    |
    | Immutable image tagged with Git SHA
    v
SSH Deployment
    |
    v
AWS EC2
    |
    v
K3s Kubernetes
    |
    +--------------------+
    |                    |
    v                    v
Traefik Ingress      Kubernetes Service
                         |
                         v
                  ShopFlow Deployment
                         |
                         v
                    Node.js API
                      Port 3000
                         |
              +----------+----------+
              |                     |
              v                     v
          /health              Application
                               request logs

Terraform
    |
    v
AWS Infrastructure
    |
    +---- VPC
    +---- Subnets
    +---- Route tables
    +---- Internet Gateway
    +---- Security Group
    +---- EC2
```

## Technology Stack

| Category               | Technology                |
| ---------------------- | ------------------------- |
| Application            | Node.js, Express          |
| Version Control        | Git, GitHub               |
| Infrastructure as Code | Terraform                 |
| Cloud                  | AWS                       |
| Compute                | EC2                       |
| Containerization       | Docker                    |
| Container Registry     | Docker Hub                |
| Container Security     | Trivy                     |
| CI/CD                  | GitHub Actions            |
| Orchestration          | Kubernetes / K3s          |
| Ingress                | Traefik                   |
| Monitoring             | Kubernetes Metrics Server |
| Testing                | Jest                      |
| Linting                | ESLint                    |

## Repository Structure

```text
shopflow/
├── .github/
│   └── workflows/
│       └── ci.yml
│
├── api/
│   ├── app.js
│   ├── app.test.js
│   ├── index.js
│   ├── package.json
│   ├── package-lock.json
│   ├── Dockerfile
│   └── .trivyignore
│
├── k8s/
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
│
├── terraform/
│   ├── provider.tf
│   ├── variables.tf
│   ├── vpc.tf
│   ├── security_group.tf
│   ├── ec2.tf
│   ├── outputs.tf
│   └── .terraform.lock.hcl
│
└── README.md
```

## Infrastructure with Terraform

The AWS infrastructure is provisioned using Terraform.

The Terraform configuration manages the infrastructure required to host the Kubernetes cluster, including:

* VPC
* Networking components
* Subnets
* Route configuration
* Internet Gateway
* Security Group
* EC2 instance
* Required provider configuration

The EC2 instance is used as the K3s Kubernetes control-plane node.

### Terraform workflow

```bash
cd terraform

terraform init
terraform plan
terraform apply
```

To inspect the infrastructure before making changes:

```bash
terraform plan
```

Terraform state should be handled carefully and should not be committed to the repository.

## Docker

The Node.js API is packaged as a Docker image.

The image is built using the application's Dockerfile:

```bash
docker build -t shopflow-api:latest ./api
```

The CI pipeline builds the image using the Git commit SHA as the image tag:

```text
shopflow-api:<git-sha>
```

Using the Git SHA instead of relying only on `latest` makes deployments traceable to a specific source-code revision.

## Container Security

The Docker image is scanned using Trivy during CI.

The pipeline scans for:

* CRITICAL vulnerabilities
* HIGH vulnerabilities

A failed security scan causes the CI pipeline to fail, preventing the image from progressing through the deployment pipeline.

## CI/CD Pipeline

GitHub Actions automates the build, security scanning, publishing, and deployment process.

### CI

For pushes and pull requests targeting `main`, the pipeline performs:

```text
Checkout
   |
   v
Node.js setup
   |
   v
npm ci
   |
   v
ESLint
   |
   v
Jest tests
   |
   v
Docker build
   |
   v
Trivy scan
```

### CD

For pushes to `main`, the pipeline continues with:

```text
Docker Hub authentication
        |
        v
Push image tagged with Git SHA
        |
        v
SSH into EC2
        |
        v
Synchronize repository with origin/main
        |
        v
Apply Kubernetes manifests
        |
        v
Update Deployment image
        |
        v
Wait for successful rollout
```

The deployment uses GitHub repository secrets for sensitive credentials such as:

* Docker Hub username
* Docker Hub access token
* EC2 host
* EC2 username
* EC2 SSH private key

Secrets are not stored directly in the repository.

## Kubernetes

The application runs on a K3s Kubernetes cluster hosted on AWS EC2.

### Namespace

The application is isolated in the `shopflow` namespace.

```bash
kubectl get namespace shopflow
```

### Deployment

The Kubernetes Deployment manages the ShopFlow API pod.

The Deployment currently uses one replica and performs rolling updates.

```yaml
replicas: 1
```

The container exposes port `3000`.

### Service

The application is exposed internally through a ClusterIP service:

```text
Service port: 80
Container port: 3000
```

### Ingress

Traefik handles HTTP ingress traffic.

The Ingress routes requests from `/` to the `shopflow-api` service.

## Kubernetes Resource Management

The deployment defines resource requests and limits.

```text
CPU request:       100m
Memory request:    128Mi

CPU limit:         500m
Memory limit:      256Mi
```

This prevents the application from consuming unlimited cluster resources.

The resulting Kubernetes QoS class is:

```text
Burstable
```

Resource usage can be inspected using:

```bash
kubectl top nodes
kubectl top pods -n shopflow
```

## Health Checks

The application exposes:

```text
GET /health
```

which returns:

```json
{
  "status": "ok"
}
```

Kubernetes uses this endpoint for both readiness and liveness checks.

### Readiness probe

The readiness probe determines whether the pod is ready to receive traffic.

### Liveness probe

The liveness probe allows Kubernetes to detect an unhealthy application container.

This provides automated health detection during deployment and runtime.

## Application Logging

The Express application includes HTTP request logging.

Example:

```text
2026-08-16T13:54:09.648Z GET /health 200 1ms
2026-08-16T13:55:10.123Z GET / 200 2ms
```

Logs can be inspected using:

```bash
kubectl logs -n shopflow -l app=shopflow-api
```

This provides basic application-level observability without requiring an additional logging platform.

## Self-Healing

The Kubernetes Deployment maintains the desired replica count.

Self-healing was tested by manually deleting the running application pod:

```bash
kubectl delete pod -n shopflow -l app=shopflow-api
```

Kubernetes automatically created a replacement pod.

The replacement pod successfully reached:

```text
1/1 Running
```

This demonstrates Kubernetes reconciliation and self-healing behavior.

## Rolling Updates

The Deployment uses Kubernetes' rolling update strategy.

Application changes follow this flow:

```text
Git change
    |
    v
GitHub Actions
    |
    v
New Docker image
    |
    v
Docker Hub
    |
    v
Kubernetes Deployment update
    |
    v
Rolling update
    |
    v
New application pod
```

The deployment rollout is verified using:

```bash
kubectl rollout status deployment/shopflow-api -n shopflow
```

The deployed image can be checked using:

```bash
kubectl get deployment shopflow-api -n shopflow \
  -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

Git SHA image tags allow each running version to be traced back to a specific commit.

## Useful Kubernetes Commands

Check nodes:

```bash
kubectl get nodes -o wide
```

Check application pods:

```bash
kubectl get pods -n shopflow
```

Check deployment:

```bash
kubectl get deployment shopflow-api -n shopflow
```

Check service:

```bash
kubectl get service shopflow-api -n shopflow
```

Check ingress:

```bash
kubectl get ingress -n shopflow
```

Check logs:

```bash
kubectl logs -n shopflow -l app=shopflow-api
```

Check resource usage:

```bash
kubectl top pods -n shopflow
kubectl top nodes
```

Check rollout:

```bash
kubectl rollout status deployment/shopflow-api -n shopflow
```

Check deployed image:

```bash
kubectl get deployment shopflow-api -n shopflow \
  -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

## Deployment Verification

After a deployment, the following checks can be performed:

```bash
kubectl get pods -n shopflow
kubectl get deployment shopflow-api -n shopflow
kubectl get ingress -n shopflow
kubectl rollout status deployment/shopflow-api -n shopflow
```

Application health can also be verified from inside the pod:

```bash
kubectl exec -n shopflow deploy/shopflow-api -- \
  wget -qO- http://localhost:3000/health
```

Expected response:

```json
{
  "status": "ok"
}
```

## Security Practices

The project implements several security controls:

* Docker image vulnerability scanning using Trivy
* CI failure on HIGH and CRITICAL vulnerabilities
* Docker Hub authentication using GitHub Secrets
* EC2 SSH authentication using an SSH key
* No credentials committed to source control
* Immutable Docker image tags based on Git SHA
* Restricted Kubernetes resource consumption

## DevOps Practices Demonstrated

This project demonstrates practical experience with:

* Infrastructure as Code
* Cloud infrastructure provisioning
* Linux administration
* Docker containerization
* Container security
* Git branching and pull requests
* Automated testing
* CI/CD
* Container registry management
* Kubernetes deployments
* Kubernetes networking
* Health checks
* Resource management
* Application logging
* Kubernetes monitoring
* Self-healing
* Rolling deployments
* Production troubleshooting

## Future Improvements

Potential future improvements include:

* Centralized log aggregation
* Prometheus metrics
* Grafana dashboards
* Horizontal Pod Autoscaler
* Kubernetes Secrets management
* Remote Terraform state
* Infrastructure monitoring and alerting
* HTTPS/TLS configuration
* Multi-node Kubernetes cluster
* Managed Kubernetes using Amazon EKS

These are intentionally listed as future improvements and are not currently part of the implementation.

## Project Goal

The goal of ShopFlow is to demonstrate an end-to-end DevOps workflow where infrastructure, application packaging, testing, security scanning, deployment, monitoring, and operational recovery are automated and reproducible.

<img width="1235" height="1057" alt="Screenshot 2026-08-20 at 12 01 07 AM" src="https://github.com/user-attachments/assets/da1a43b4-8d01-42db-93db-1e4c292d46b3" />
<img width="1716" height="970" alt="Screenshot 2026-08-20 at 12 01 28 AM" src="https://github.com/user-attachments/assets/7d5b1d49-f60b-4e26-a922-e2642656942f" />

