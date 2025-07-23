module "eks_vpc" {
  source = "git::git@github.com:rajops-lab/terraform-modules.git//modules/01-eks_vpc?ref=v1.0.1"

  environment     = var.environment
  region_name     = var.region_name
  vpc_cidr_block  = var.vpc_cidr_block
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

module "eks_cluster" {
  source = "git::git@github.com:rajops-lab/terraform-modules.git//modules/02-eks_cluster?ref=v1.0.1"

  eks_subnet_ids = flatten([module.eks_vpc.pub_subnets, module.eks_vpc.priv_subnets])
  eks_cluster_name = var.eks_cluster_name
  cluster_role     = var.cluster_role

  depends_on = [
    module.eks_vpc
  ]
}

module "eks_node_group" {
  source = "git::git@github.com:rajops-lab/terraform-modules.git//modules/03-eks_node_group?ref=v1.0.1"

  eks_subnet_ids   = flatten([module.eks_vpc.pub_subnets, module.eks_vpc.priv_subnets])
  eks_cluster_name = module.eks_cluster.cluster_name
  node_group_name   = var.node_group_name
  node_role_name    = var.node_role_name
  nodegroup_keypair = var.nodegroup_keypair

  depends_on = [
    module.eks_cluster,
    module.eks_vpc
  ]
}