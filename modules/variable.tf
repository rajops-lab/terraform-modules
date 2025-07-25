variable "region_name" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev/stage/prod)"
  type        = string
}

variable "eks_cluster_name" {
  description = "EKS Cluster name"
  type        = string
}

variable "node_group_name" {
  description = "Name for EKS Node Group"
  type        = string
}

variable "node_role_name" {
  description = "IAM role name for node group"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet CIDRs"
  type        = list(string)
}

variable "public_az" {
  description = "Availability zones for public subnets"
  type        = list(string)
}

variable "private_az" {
  description = "Availability zones for private subnets"
  type        = list(string)
}

variable "pub_sub_tags" {
  description = "Tags for public subnets"
  type        = map(any)
}

variable "priv_sub_tags" {
  description = "Tags for private subnets"
  type        = map(any)
}

variable "cluster_role" {
  description = "IAM role name for the EKS cluster"
  type        = string
}

variable "eks_cluster_policy_arn" {
  description = "Policy ARN for EKS cluster IAM role"
  type        = string
}

variable "nodegroup_keypair" {
  description = "SSH key pair name for EKS worker nodes"
  type        = string
}
