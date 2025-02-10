# 2BCloud Assignment

This repository implements a **CI/CD pipeline** to deploy a containerized web application to **AWS EKS**, using **Terraform, Docker, Kubernetes, and GitHub Actions**.

---

## ** Project Overview**
### **Infrastructure (AWS)**
- **EKS Cluster** (`t3.small` node type)
- **ECR Repository**: `2bcloud-repo-dev`
- **AWS Load Balancer** for external access

### **Web Application**
A Python **FastAPI** app with:
- `"/"` → **Returns "Hello World"**
- `"/healthz"` → **Health check endpoint**

### **Containerization**
- **Base image**: `python:3.12-slim`
- **Runs on port 8000**
- **Stored in AWS ECR**

### **Kubernetes Deployment**
- **Deployment with HPA support**
- **LoadBalancer service type**
- **Health check & resource management**
- **HPA (1-5 pods, 50% CPU target)**

### **CI/CD Pipeline**
A **GitHub Actions** workflow automating:
- **Docker image build**
- **Push to AWS ECR**
- **Deployment to EKS**

---

## ** Setup**
### **Prerequisites**
Ensure you have the following installed and configured:
- [AWS CLI](https://aws.amazon.com/cli/)
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/)
- [`Terraform`](https://developer.hashicorp.com/terraform/downloads)
- [`Docker`](https://www.docker.com/get-started)
- [`metrics-server`](https://github.com/kubernetes-sigs/metrics-server) (for HPA)

---

## ** Provision Infrastructure**

- cd terraform
- terraform init
- terraform apply


 Deploy Application:

 # Update kubeconfig
 - aws eks update-kubeconfig --name 2bcloud-eks-dev --region eu-central-1 

 # Deploy app
- kubectl apply -f kubernetes/deployment.yaml

# Deploy HPA
- kubectl apply -f kubernetes/metrics-server.yaml
# Wait for it to be running
- kubectl get pods -n kube-system | grep metrics-server
- kubectl apply -f kubernetes/hpa.yaml

# Verify HPA
- kubectl get hpa

Horizontal Pod Autoscaler (HPA):
- Scaling Config:
- Min pods: 1
- Max pods: 5
- Target CPU utilization: 50%

# Install Apache Bench
- sudo apt-get install apache2-utils

# Get service URL
- export SERVICE_URL=$(kubectl get svc hello-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Simulate traffic
- ab -n 10000 -c 100 http://$SERVICE_URL/

# Monitor scaling
- kubectl get hpa -w
- kubectl get pods -w

Verification
# Check deployments & pods
- kubectl get deployments
- kubectl get pods

# Check HPA status
- kubectl get hpa

# Get LoadBalancer URL
- kubectl get svc hello-app

# Test endpoints
- curl http://<LOAD_BALANCER_URL>/
- curl http://<LOAD_BALANCER_URL>/healthz

📁 Repository Structure
.
├── .github/workflows/ci-cd.yml  # CI/CD pipeline
├── app/
│   ├── app.py                  # FastAPI app
│   └── requirements.txt         # Dependencies
├── kubernetes/
│   ├── deployment.yaml         # Deployment & service
│   └── hpa.yaml                # HPA config
├── terraform/                  # Infrastructure as code
├── Dockerfile                  # Container configuration
└── README.md                   # Documentation

Troubleshooting:
# Check pod status
kubectl get pods

# Check HPA status
kubectl get hpa

# Get detailed HPA information
kubectl describe hpa hello-app-hpa

# Check pod logs
kubectl logs <pod-name>

# Check service status
kubectl get svc

# Check node status
kubectl get nodes

Clean Up:
- kubectl delete -f kubernetes/hpa.yaml
- kubectl delete -f kubernetes/deployment.yaml
- cd terraform
- terraform destroy
