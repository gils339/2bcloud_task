variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "2bcloud-eks-dev"
}

variable "node_group_name" {
  description = "EKS node group name"
  type        = string
  default     = "2bcloud-node-group"
}

variable "instance_type" {
  description = "EC2 instance type for node group"
  type        = string
  default     = "t3.small"
}
