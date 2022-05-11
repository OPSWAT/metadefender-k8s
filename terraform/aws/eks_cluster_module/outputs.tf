output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.vpc.cidr_block
}

output "public_subnets" {
  value = [for subnet in aws_subnet.pub_subnet : subnet.id]
}

output "private_subnets" {
  value = [for subnet in aws_subnet.priv_subnet : subnet.id]
}

output "eks_cluster_oicd_url" {
  value = aws_eks_cluster.eks_cluster.identity.0.oidc.0.issuer
}