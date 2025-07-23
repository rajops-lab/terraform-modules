locals {
  subnet_common_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# variable to define the cluster name
variable "cluster_name" {
  description = "Cluster name for eks cluster"
  type        = string
  default     = "eks-demo-live-cluster"
}
variable "region_name" {
  description = "Region name to launch VPC network"
  type        = string      # Accepts a string input like "us-east-1"
  default     = "us-east-1" # All resources will be launched in this region by default
}

# Variable to define the CIDR block of the VPC
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC network"
  type        = string         # Accepts string input in CIDR notation
  default     = "10.10.0.0/16" # This range will be used for private IPs in the VPC
}

# Variable to define the environment name (e.g., dev, stage, prod, QA)
variable "environment" {
  description = "Environment name for deployment"
  type        = string # Used for tagging and logical separation
  default     = "Development"  # Default environment is development
}

# Variable to define public subnet CIDR blocks
variable "public_subnets" {
  description = "provide public subnet CIDR values"
  type        = list(string)                     # A list of CIDR blocks as strings
  default     = ["10.10.0.0/24", "10.10.2.0/24"] # Two public subnets
}

# Variable to define private subnet CIDR blocks
variable "private_subnets" {
  description = "provide private subnet CIDR values"
  type        = list(string)                     # A list of CIDR blocks as strings
  default     = ["10.10.1.0/24", "10.10.3.0/24"] # Two private subnets
}

# Variable to define Availability Zones for public subnets
variable "public_az" {
  description = "AZ names for public subnet"
  type        = list(string)
  default = [     # AZs where public subnets will be created
    "us-east-1a", # First AZ
    "us-east-1b"  # Second AZ
  ]
}

# Variable to define Availability Zones for private subnets
variable "private_az" {
  description = "AZ names for private subnet"
  type        = list(string)
  default = [     # AZs where private subnets will be created
    "us-east-1a", # First AZ
    "us-east-1b"  # Second AZ
  ]
}

# Public subnet tags for internet-facing ELB
variable "pub_sub_tags" {
  description = "Provide tags that need to be part of the EKS network to manage internet-facing ELB"
  type        = map(any)
  default     = {
    "kubernetes.io/role/elb" = "1"
  }
}

# Private subnet tags for internal ELB
variable "priv_sub_tags" {
  description = "Provide tags that need to be part of the EKS network to manage internal ELB"
  type        = map(any)
  default     = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

