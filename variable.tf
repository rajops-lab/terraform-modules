variable "region_name" {
  description = "AWS Region to deploy resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

variable "node_group_name" {
  description = "Assign name for the Node Group"
  type        = string
}

variable "nodegroup_keypair" {
  description = "Node group SSH keypair name"
  type        = string
}

variable "node_role_name" {
  description = "Role name for Node Group in eks cluster"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "eks_cluster_policy_arn" {
  description = "ARN of the IAM policy to attach to EKS Cluster Role"
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
  description = "Availability Zones for public subnets"
  type        = list(string)
}

variable "private_az" {
  description = "Availability Zones for private subnets"
  type        = list(string)
}

variable "pub_sub_tags" {
  description = "Tags for public subnets"
  type        = map(string)
}

variable "priv_sub_tags" {
  description = "Tags for private subnets"
  type        = map(string)
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_role" {
  description = "Name of EKS Cluster role to be used"
  type        = string
}