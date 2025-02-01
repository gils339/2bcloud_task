2BCloud Assignment
This repository contains a complete CI/CD pipeline deploying a containerized web application to AWS EKS with Horizontal Pod Autoscaling.
Project Components
1. Infrastructure (AWS)

EKS Cluster with t3.small node type
ECR Repository: 2bcloud-repo-dev
AWS Load Balancer for external access

2. Web Application
A Python FastAPI application providing:

"/" endpoint returning Hello World message
"/healthz" endpoint for health checks

3. Docker Container

Base image: python:3.12-slim
Application runs on port 8000
Container image stored in AWS ECR

4. Kubernetes Deployment

Single replica deployment with HPA support
LoadBalancer service type
Health check configuration
Resource management
Horizontal Pod Autoscaler (1-5 pods, 50% CPU target)

5. CI/CD Pipeline
GitHub Actions workflow automating:

Docker image build
ECR push
EKS deployment

Setup Instructions
Prerequisites

AWS CLI configured
kubectl installed
Terraform installed
Docker installed
metrics-server installed in EKS cluster

Infrastructure Provisioning
cd terraform
terraform init
terraform plan
terraform apply
Application Deployment
# Deploy application
kubectl apply -f kubernetes/deployment.yaml

# Deploy HPA
kubectl apply -f kubernetes/hpa.yaml

# Verify HPA
kubectl get hpa
Horizontal Pod Autoscaler (HPA)
The application includes HPA configuration for automatic scaling:

Configuration:


Minimum pods: 1
Maximum pods: 5
Target CPU utilization: 50%


Testing HPA:

# Install Apache Bench
sudo apt-get install apache2-utils

# Get service URL
export SERVICE_URL=$(kubectl get svc hello-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Run load test
ab -n 10000 -c 100 http://$SERVICE_URL/

# Monitor scaling
kubectl get hpa -w
kubectl get pods -w

Expected Behavior:


High load triggers automatic scaling
System scales up to handle increased load
After load decreases, system automatically scales down

Verification

Check deployments and pods:

kubectl get deployments
kubectl get pods

Check HPA status:

kubectl get hpa

Access application:

# Get LoadBalancer URL
kubectl get svc hello-app

# Test endpoints
curl http://<LOAD_BALANCER_URL>/
curl http://<LOAD_BALANCER_URL>/healthz
Repository Structure
Copy.
├── .github/
│   └── workflows/
│       └── ci-cd.yml      # CI/CD pipeline configuration
├── app/
│   ├── app.py            # FastAPI application
│   └── requirements.txt   # Python dependencies
├── kubernetes/
│   ├── deployment.yaml   # K8s deployment and service
│   └── hpa.yaml         # Horizontal Pod Autoscaler config
├── terraform/            # Infrastructure as code
├── Dockerfile           # Container configuration
└── README.md           # This file
Troubleshooting

Pod status: kubectl get pods
HPA status: kubectl get hpa
Detailed HPA info: kubectl describe hpa hello-app-hpa
Pod logs: kubectl logs <pod-name>
Service status: kubectl get svc
Node status: kubectl get nodes

Clean Up
To remove all resources:
kubectl delete -f kubernetes/hpa.yaml
kubectl delete -f kubernetes/deployment.yaml
cd terraform
terraform destroy