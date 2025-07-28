# Terraform block
terraform {
  required_version = ">= 1.12"  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=6.0" # ~> will keep major fixed and download latest minor version
    }
  }
}

# ✅ Configure the AWS Provider
provider "aws" {
  region = var.region_name # e.g., "us-east-1" - passed as a variable
  # profile = "default"
  # secret_key = 
  # access_key =

  # Apply default tags to all AWS resources
  default_tags {
    tags = {
      Application = "EKS-Cluster"
      Tool        = "Terraform-managed-resource"           
    }
  }
}
