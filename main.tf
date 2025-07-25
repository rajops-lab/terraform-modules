module "eks_vpc" {
  source            = "git::git@github.com:rajops-lab/terraform-modules.git//modules/eks_vpc?ref=v2.0.0"

  region_name       = var.region_name
  environment       = var.environment
  vpc_cidr_block    = var.vpc_cidr_block
  public_subnets    = var.public_subnets
  private_subnets   = var.private_subnets
  public_az         = var.public_az
  private_az        = var.private_az
  pub_sub_tags      = var.pub_sub_tags
  priv_sub_tags     = var.priv_sub_tags
  cluster_name      = var.eks_cluster_name
}

module "eks_cluster" {
  source                  = "git::git@github.com:rajops-lab/terraform-modules.git//modules/eks_cluster?ref=v2.0.0"

  eks_cluster_name        = var.eks_cluster_name
  eks_subnet_ids          = flatten([module.eks_vpc.pub_subnets, module.eks_vpc.priv_subnets])
  cluster_role            = var.cluster_role
  eks_cluster_policy_arn  = var.eks_cluster_policy_arn

  depends_on = [
    module.eks_vpc
  ]
}

module "eks_node_group" {
  source              = "git::git@github.com:rajops-lab/terraform-modules.git//modules/eks_node_group?ref=v2.0.0"

  eks_subnet_ids      = flatten([module.eks_vpc.pub_subnets, module.eks_vpc.priv_subnets])
  eks_cluster_name    = module.eks_cluster.cluster_name
  node_group_name     = var.node_group_name
  node_role_name      = var.node_role_name
  nodegroup_keypair   = var.nodegroup_keypair

  depends_on = [
    module.eks_cluster,
    module.eks_vpc
  ]
}

terraform {
  backend "s3" {}
}

