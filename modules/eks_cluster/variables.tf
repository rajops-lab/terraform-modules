variable "eks_cluster_name" {
  description = "Name of the EKS Cluster"
  type        = string
  default     = "eks-demo-live-cluster"
}

variable "environment" {
  description = "Environment name (qa/sandbox/prod)"
  type        = string
}

variable "eks_subnet_ids" {
  description = "List of subnet IDs on which EKS Cluster will be launched"
  type        = list(string)
}

variable "cluster_role" {
  description = "Name of the EKS Cluster IAM Role"
  type        = string
  default     = "AWSEKSClusterRole"
}

variable "eks_cluster_policy_arn" {
  description = "ARN of the policy to attach to the EKS Cluster Role"
  type        = string
  default     = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

locals {
  common_tags = {
    Application = "EKS_Cluster"       
    # Environment = var.environment      # Dynamically adds environment
  }
}
