terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket = "2bcloud-tfstate"
    key    = "terraform.tfstate"
    region = "eu-central-1"
  }
}

provider "aws" {
  region = "eu-central-1"
}

# VPC
resource "aws_vpc" "two_bcloud_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "2bcloud-vpc-${var.environment}"
    "kubernetes.io/cluster/2bcloud-eks-${var.environment}" = "shared"
  }
}

# Subnets
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.two_bcloud_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "2bcloud-public-subnet-1"
    "kubernetes.io/cluster/2bcloud-eks-${var.environment}" = "shared"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.two_bcloud_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "2bcloud-public-subnet-2"
    "kubernetes.io/cluster/2bcloud-eks-${var.environment}" = "shared"
    "kubernetes.io/role/elb" = "1"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "two_bcloud_igw" {
  vpc_id = aws_vpc.two_bcloud_vpc.id

  tags = {
    Name = "2bcloud-igw"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.two_bcloud_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.two_bcloud_igw.id
  }

  tags = {
    Name = "2bcloud-public-rt"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# EKS Cluster Security Group
resource "aws_security_group" "eks_cluster" {
  name        = "2bcloud-eks-cluster-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.two_bcloud_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "2bcloud-eks-cluster-sg"
  }
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "2bcloud-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Role Policy Attachments for EKS Cluster
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# EKS Cluster
resource "aws_eks_cluster" "two_bcloud_eks" {
  name     = "2bcloud-eks-${var.environment}"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids         = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_group_ids = [aws_security_group.eks_cluster.id]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# IAM Role for EKS Node Group
resource "aws_iam_role" "eks_node_role" {
  name = "2bcloud-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Node Group Security Group
resource "aws_security_group" "eks_nodes" {
  name        = "2bcloud-eks-node-sg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = aws_vpc.two_bcloud_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "2bcloud-eks-node-sg"
    "kubernetes.io/cluster/2bcloud-eks-${var.environment}" = "owned"
  }
}

# Node Group IAM Policy Attachments
resource "aws_iam_role_policy_attachment" "eks_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# EKS Node Group
resource "aws_eks_node_group" "two_bcloud_nodes" {
  cluster_name    = aws_eks_cluster.two_bcloud_eks.name
  node_group_name = "2bcloud-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["t3.small"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only
  ]
}

# ECR Repository
resource "aws_ecr_repository" "two_bcloud_repo" {
  name = "2bcloud-repo-${var.environment}"
}

# Variables
variable "environment" {
  description = "Deployment environment"
  default     = "dev"
}

# Outputs
output "eks_cluster_endpoint" {
  value = aws_eks_cluster.two_bcloud_eks.endpoint
}

output "ecr_repository_url" {
  value = aws_ecr_repository.two_bcloud_repo.repository_url
}
