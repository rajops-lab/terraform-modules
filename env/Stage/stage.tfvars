region_name         = "us-east-1"
environment         = "stage"

eks_cluster_name    = "eks-stage-cluster"
cluster_role        = "AWSEKSClusterRole-stage"
eks_cluster_policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

node_group_name     = "stage-node-group"
node_role_name      = "NodeRoleAccess"
nodegroup_keypair   = "eks_node_key"

vpc_cidr_block      = "10.20.0.0/16"

public_subnets      = ["10.20.0.0/24", "10.20.2.0/24"]
private_subnets     = ["10.20.1.0/24", "10.20.3.0/24"]

public_az           = ["us-east-1a", "us-east-1b"]
private_az          = ["us-east-1a", "us-east-1b"]

pub_sub_tags = {
  "kubernetes.io/role/elb" = "1"
}

priv_sub_tags = {
  "kubernetes.io/role/internal-elb" = "1"
}
