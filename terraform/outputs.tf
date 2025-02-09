output "cluster_name" {
  value = aws_eks_cluster.two_bcloud_eks.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.two_bcloud_eks.endpoint
}

output "ecr_repository_url" {
  value = aws_ecr_repository.two_bcloud_repo.repository_url
}
