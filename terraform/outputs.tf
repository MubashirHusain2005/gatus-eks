output "vpc_id" {
  value = aws_vpc.eks_vpc.id
}

output "cluster" {
  value = aws_eks_cluster.eks_cluster
}