output "vpc_id" {
  description = "ID of the VPC created for EKS"
  value       = module.eks_vpc.vpc_name
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.eks_vpc.pub_subnets
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.eks_vpc.priv_subnets
}

output "eks_cluster_name" {
  description = "EKS Cluster name"
  value       = module.eks_cluster.cluster_name
}

output "node_group_name" {
  description = "EKS Node Group name"
  value       = var.node_group_name
}

