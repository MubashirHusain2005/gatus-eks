output "vpc_id" {
  value = aws_vpc.eks_vpc.id
}

output "priv_subnet2a_id" {
  value = aws_subnet.private-subnet-2a.id
}

output "priv_subnet2b_id" {
  value = aws_subnet.private-subnet-2b.id
}
