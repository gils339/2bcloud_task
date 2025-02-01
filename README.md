2BCloud Task
Infrastructure Overview

EKS cluster with t3.small node
ECR repository for container images
FastAPI application with health check
GitHub Actions CI/CD pipeline

Project Structure
Copy.
├── .github/workflows/    # CI/CD pipeline
│   └── ci-cd.yml
├── app/                  # Application code
│   ├── app.py
│   └── requirements.txt
├── kubernetes/          # Kubernetes manifests
│   └── deployment.yaml
├── terraform/          # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── Dockerfile          # Container build file
Setup Instructions
1. Infrastructure Provisioning
bashCopycd terraform
terraform init
terraform plan
terraform apply
2. Application Deployment
The application is a simple FastAPI service with:

Root endpoint ("/") returning "Hello World"
Health check endpoint ("/healthz")

3. Container Registry
ECR repository: 2bcloud-repo-dev
bashCopyaws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 114885604022.dkr.ecr.eu-central-1.amazonaws.com
4. CI/CD Pipeline
The GitHub Actions pipeline automates:

Building Docker image
Pushing to ECR
Deploying to EKS

Required GitHub Secrets:

AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY

5. Kubernetes Deployment
bashCopykubectl apply -f kubernetes/deployment.yaml
6. Verification Steps

Check pod status:

bashCopykubectl get pods

Check service and LoadBalancer:

bashCopykubectl get svc hello-app

Access application:


Hello World: http://<LOAD_BALANCER_URL>
Health Check: http://<LOAD_BALANCER_URL>/healthz

Troubleshooting

Check node status: kubectl get nodes
Check pod logs: kubectl logs <pod-name>
Check service status: kubectl describe svc hello-app

Security Notes

Cluster access is managed through AWS IAM
Application is exposed via AWS LoadBalancer
Container registry requires AWS authentication

Maintenance

Monitor node resources
Update dependencies regularly
Check CloudWatch logs for issues
Rotate AWS credentials as needed
