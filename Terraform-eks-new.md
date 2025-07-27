
POC for demonstrates deploying multiple Kubernetes environments (dev, staging, prod) on AWS using EKS with Infrastructure as Code.

###  Step-00: Introduction    
   1. **Goal**: Deploy EKS clusters for `dev`, `stage`, and `prod` using Terraform.
   2. **Structure**: Separate config files per environment; shared modules stored in a Git repo.
   3. **Modules**:
      * `eks_vpc`: Creates VPC, subnets, IGW, NAT, etc.
      * `eks_cluster`: Provisions EKS control plane.
      * `eks_node_group`: Creates EKS-managed EC2 worker nodes.
   4. **Remote State**: S3 bucket used for state storage; DynamoDB table for state locking.
   5. **Environments**: Each env has its own folder with `main.tf`, `variables.tf`, and `.tfvars`.
   6. **Makefile**: Used to initialize, plan, and apply clusters easily per environment or all at once.

### Step 02 - Project Directory  Structure
```txt
myapp/
├── Makefile
├── Makefile-guide.md
├── Multi-Environment_AWS-EKS_POC_using_Terraform.md
└── env
    ├── Stage
    │   ├── main.tf
    │   ├── stage.tfvars
    │   └── variables.tf
    ├── dev
    │   ├── dev.tfvars
    │   ├── main.tf
    │   └── variables.tf
    └── prod
        ├── main.tf
        ├── prod.tfvars
        └── variables.tf
```


### Step 03 - Following TF config files are needed

> [!Note]
> This modules already uploaded on github repo  still here i have kept module files for reference purpose skip this section and move to `Step 24` and follow below directory structure to start implementing

```txt
.
 ./Makefile
 ./Multi-Environment_AWS-EKS_POC_using_Terraform.md
 ./env
 ./env/Stage
 ./env/Stage/main.tf
 ./env/Stage/stage.tfvars
 ./env/Stage/variables.tf
 ./env/dev
 ./env/dev/dev.tfvars
 ./env/dev/main.tf
 ./env/dev/variables.tf
 ./env/prod
 ./env/prod/main.tf
 ./env/prod/prod.tfvars
 ./env/prod/variables.tf
```

### Create modules

####  Step 04 - env/modules/eks-vpc/01-provider.tf
```json
# Terraform block
terraform {
  # required_version = ">= 1.12"  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0" # it will keep major fixed and download latest minor version
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region_name # e.g., "us-east-1" - passed as a variable

  # Apply default tags to all AWS resources
  default_tags {
    tags = {
      Application = "EKS-Cluster"
      Tool        = "Terragrunt-managed-resource"
    }
  }
}
```
#### Step 05 - env/modules/eks-vpc/02-vpc.tf
```json
resource "aws_vpc" "eks-vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true # declare variable 2

  tags = {
    # i want to name this as Envname-resorcename-commonname
    "Name" = "${var.environment}-vpc" # declare varible 3
  }
}
```

#### Step 06 - env/modules/eks-vpc/03-variable.tf
```json

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
```

#### Step 07 - env/modules/eks-vpc/04-subnet.tf
```json
# Resource Block for public subnet
resource "aws_subnet" "eks_public_subnets" {
  count                   = length(var.public_subnets) # One subnet per CIDR block
  vpc_id                  = aws_vpc.eks-vpc.id
  cidr_block              = element(var.public_subnets, count.index)
  availability_zone       = element(var.public_az, count.index)
  map_public_ip_on_launch = true

  tags = merge(
    var.pub_sub_tags,                 # ✅ fixed from priv_sub_tags
    local.subnet_common_tags,
    {
      Name = "${var.environment}-public-subnet-${element(var.public_az, count.index)}"
    }
  )
}


# Resource Block for Private subnet
resource "aws_subnet" "eks_private_subnets" {
  count             = length(var.private_subnets) # One subnet per CIDR block
  vpc_id            = aws_vpc.eks-vpc.id
  cidr_block        = element(var.private_subnets, count.index)  
  availability_zone = element(var.private_az, count.index)
  # map_public_ip_on_launch = true   # Keep this commented for private subnets

  tags = merge(
    var.priv_sub_tags,
    local.subnet_common_tags,
    {
      Name = "${var.environment}-private-subnet-${element(var.private_az, count.index)}"
    }
  )
}

```

#### Step 08 - env/modules/eks-vpc/05-igw.tf
```json
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eks-vpc.id

  tags = {
    "key" = "${var.environment}-igw"
  }

}
```

#### Step 09 - env/modules/eks-vpc/06-nat_eip.tf
```json
# Allocate Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc" # 'vpc = true' is deprecated; use 'domain = "vpc"' instead

  tags = {
    Name = "${var.environment}-nat-eip"
  }
}
```

#### Step 10 - env/modules/eks-vpc/07-nat_gw.tf
```json
resource "aws_nat_gateway" "nat_gw" {
  subnet_id     = element(aws_subnet.eks_public_subnets.*.id,0)
  allocation_id = aws_eip.nat_eip.id
  
  depends_on = [
    aws_subnet.eks_public_subnets,
    aws_eip.nat_eip
  ]
  
  tags = {
    "Name" = "${var.environment}-nat-gw"
  }
}
```

#### Step 11 - env/modules/eks-vpc/08-route_table.tf
```json
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.eks-vpc.id

  tags = {
    "Name" = "${var.environment}-public-rt"
  }
}

resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.eks-vpc.id

  tags = {
    "Name" = "${var.environment}-private-rt"
  }
}

resource "aws_route" "public_igw" {
  route_table_id         = aws_route_table.public_route.id
  gateway_id             = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
  depends_on = [
    aws_internet_gateway.igw
  ]
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private_route.id
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
  destination_cidr_block = "0.0.0.0/0"
  depends_on = [
    aws_nat_gateway.nat_gw
  ]
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(var.public_subnets)
  subnet_id      = element(aws_subnet.eks_public_subnets.*.id, count.index)
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "private_assoc" {
  count          = length(var.private_subnets)
  subnet_id      = element(aws_subnet.eks_private_subnets.*.id, count.index)
  route_table_id = aws_route_table.private_route.id
}
```

#### Step 12 - env/modules/eks-vpc/09-security-groups.tf
```json
resource "aws_security_group" "default_group" {
  name        = "${var.environment}-default-sg"
  description = "Default security group for EKS VPC network"
  vpc_id      = aws_vpc.eks-vpc.id
  depends_on = [
    aws_vpc.eks-vpc
  ]

  tags = {
    "Name" = "${var.environment}-default-sg"
  }
}
```

#### Step 13 - env/modules/eks-vpc/10-security_groups-rules.tf
```json
resource "aws_security_group_rule" "ing_ssh_rule" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default_group.id
}

resource "aws_security_group_rule" "ing_http_rule" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default_group.id
}

resource "aws_security_group_rule" "default_egress_rule" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default_group.id
}
```

#### Step 14 - env/modules/eks-vpc/11-outputs.tf
```json
output "vpc_name" {
  description = "Display name of the VPC network for EKS Cluster"
  value       = aws_vpc.eks-vpc.id
}

output "pub_subnets" {
  description = "List Public subnets that will be used by EKS Cluster"
  value       = aws_subnet.eks_public_subnets.*.id
}

output "priv_subnets" {
  description = "List Private subnets that will be used by EKS Cluster"
  value       = aws_subnet.eks_private_subnets.*.id
}

output "sg_name" {
  description = "List security group name used for EKS Cluster control plane"
  value       = aws_security_group.default_group.id
}
```

#### Step 15 - env/modules/eks_cluster/variables.tf
```json
variable "eks_cluster_name" {
  description = "Name of the EKS Cluster"
  type        = string
  default = "eks-demo-live-cluster"

}

variable "eks_subnet_ids" {
  description = "List subnet ids on which EKS Cluster to be launched"
  type        = list(string)
}

variable "cluster_role" {
  description = "Name of EKS Cluster role to be used"
  type        = string
  default = "AWSEKSClusterRole"
}

variable "eks_cluster_policy_arn" {
  description = "ARN of the policy to assign for EKS Cluster Role"
  type        = string
  default     = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

locals {
  common_tags = {
    "Appication" = "EKS_Cluster"
  }
}
```

#### Step 16 - env/modules/eks_cluster/ekc_cluster.tf
```json
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = var.eks_subnet_ids
  }

  depends_on = [
    aws_iam_role.eks_cluster_role
  ]
}
```

#### Step 17 - env/modules/eks_cluster/eks_role_policy.tf
```json
resource "aws_iam_role" "eks_cluster_role" {
  name = var.cluster_role

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "EKSASSUMEROLE"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "eks-cluster-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "eks_clusterpolicy_attach" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = var.eks_cluster_policy_arn
}

```

#### Step 18 - env/modules/eks_cluster/outputs.tf
```json
output "cluster_name" {
  value = aws_eks_cluster.eks_cluster.id
}
```

#### Step 19 - env/modules/eks-node_group/node_group.tf
```json
resource "aws_eks_node_group" "ubuntu_22_ngp" {
  cluster_name    = var.eks_cluster_name
  node_group_name = var.node_group_name

  remote_access {
    ec2_ssh_key = aws_key_pair.node_ssh_key.key_name
  }

  node_role_arn = aws_iam_role.node_role.arn
  subnet_ids    = var.eks_subnet_ids

  scaling_config {
    desired_size = 3
    max_size     = 4
    min_size     = 1
  }

  update_config {
    max_unavailable = 2 # if something went wrong or downtime at least 1 nodes will be available
  }

  depends_on = [
    aws_iam_role.node_role,
    aws_iam_role_policy_attachment.node_policy_attach
  ]
}
```

#### Step 20 - env/modules/eks-node_group/node_role_policy.tf
```json
resource "aws_iam_role" "node_role" {
  name = var.node_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "AssumeNodeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "node_policy_attach" {
  count      = length(local.node_policy_arn)
  policy_arn = element(values(local.node_policy_arn), count.index)
  role       = aws_iam_role.node_role.name

  depends_on = [
    aws_iam_role.node_role
  ]
}
```

#### Step 21 - env/modules/eks-node_group/node_ssh_key.tf
```json
resource "aws_key_pair" "node_ssh_key" {
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCf81o8Fk5Y65d5H68rG2EwItI1VUFHCdvb++7TqtkN9Ibk3jjFrQz+evbyL2QYqaVdiSz8aJbwAb8Tdwz8TilyS65qr4mDMaZfwr0dsFBddT/J2lp/oXJLG48027Jg6OtKKxNlbdtNMrGZ9IIO2VxH0u+nrBDYePCvZwDYxjdF1bMHApQNBh5g/7mbHasd4SqzuWpFzmpRu+F1Ubqm/1fIR4F767q4jHU+OVbLthcSmGTIMYnQOxfbtpADXRMroK1pT1OJAOT612wXZ+tfwxbX/R8z4rXLIewnQV/5ZwBEusMBMuAMdyvZi6cdu/DVVYOdNzafl28vaYAw5oTeHI+v+tEzfu6CqiatINwQ/2nSCDPjtBVjnxouZWatzWvmi+A50qZVfViWMTQRj6WAALM3DBz7RK0Id+udB3gGk0Wfd78DgqH4HE/lCBFs/XhkocOMTdLdoUenJ5reohFSXXXcYKvBUsfVvNt0YqswZdtybuJEcK7nuWr8jJrEF+O+erIdik9c9dyn/b6FEyExJOlhYspFLjIvDxRj70ZL0Yi9kYHE1kLKYVvy6WIsxCV0QrNWbszSz1rgpOgvoOyxYXnUXgq3Nk6Lz3KwbVaDdLFjg3u9u5oU03Oa4PVvERhhk+ZjymgM2gOeId9S36bOrldzlsvjXuTtAuJwBI52wftrIQ== rajeshavhd@gmail.com"
  key_name   = "eks_node_key"
}

```

#### Step 22 - env/modules/eks-node_group/outputs.tf
```json
# will add based on requirement
```

#### Step 23 -  env/modules/eks-node_group/variables.tf
```json
locals {
  node_policy_arn = {
    "node_policy" = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    "acr_policy"  = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    "cni_policy"  = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  }
}

variable "node_group_name" {
  description = "Assign name for the Node Group"
  type        = string
  default     = "webapp-node-group"
}

variable "node_role_name" {
  description = "Role name for Node Group in eks cluster"
  type        = string
  default     = "NodeRoleAccess"
}

variable "nodegroup_keypair" {
  description = "Key pair name to attach for EC2 nodes in Node group"
  type        = string  
}

variable "eks_cluster_name" {
  description = "Name of EKS Cluster, pulled from eks_cluster module"
  type        = string
}

variable "eks_subnet_ids" {
  description = "List subnet ids on which EKS Cluster to be launched"
  type        = list(string)
}

```

### Step 24- /env/main.tf (same For prod, dev and stage)
```json
# ─── main.tf (for each env: dev, stage, prod) ───

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

# Optional backend (for centralized state)
terraform {
  backend "s3" {
    bucket         = "myeksterraform-bucket"
    key            = "env/dev/terraform.tfstate"  # or stage/prod depending on env
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

### Step -25 /env/.tfvars 

>[!Note]
>create .tfvar files in mentioned location `./env/prod/prod.tfvars , ./env/prod/stage.tfvars,./env/prod/dev.tfvars` need some minor changes highlighted 
>- make sure subnet is different

```json
# prod.tfvars 
region_name         = "us-east-1"
environment         = "prod" # change name according

eks_cluster_name    = "eks-prod-cluster"   # change name according prod/dev/stage
cluster_role        = "AWSEKSClusterRole"
eks_cluster_policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

node_group_name     = "prod-node-group"  # change name according
node_role_name      = "NodeRoleAccess"
nodegroup_keypair   = "eks_node_key"

vpc_cidr_block      = "10.50.0.0/16"

public_subnets      = ["10.50.0.0/24", "10.50.2.0/24"]
private_subnets     = ["10.50.1.0/24", "10.50.3.0/24"]

public_az           = ["us-east-1a", "us-east-1b"]
private_az          = ["us-east-1a", "us-east-1b"]

pub_sub_tags = {
  "kubernetes.io/role/elb" = "1"
}

priv_sub_tags = {
  "kubernetes.io/role/internal-elb" = "1"
}
```

```json
# dev.tfvars
region_name         = "us-east-1"
environment         = "dev"

eks_cluster_name    = "eks-dev-cluster"
cluster_role        = "AWSEKSClusterRole"
eks_cluster_policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

node_group_name     = "dev-node-group"
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
```

```json
# stage.tfvars
region_name         = "us-east-1"
environment         = "stage"

eks_cluster_name    = "eks-stage-cluster"
cluster_role        = "AWSEKSClusterRole"
eks_cluster_policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

node_group_name     = "stage-node-group"
node_role_name      = "NodeRoleAccess"
nodegroup_keypair   = "eks_node_key"

vpc_cidr_block      = "10.10.0.0/16"

public_subnets      = ["10.10.0.0/24", "10.10.2.0/24"]
private_subnets     = ["10.10.1.0/24", "10.10.3.0/24"]

public_az           = ["us-east-1a", "us-east-1b"]
private_az          = ["us-east-1a", "us-east-1b"]

pub_sub_tags = {
  "kubernetes.io/role/elb" = "1"
}

priv_sub_tags = {
  "kubernetes.io/role/internal-elb" = "1"
}
```

### Step 26- /env/variables.tf
>[!Note]
> variables are defined in .tfvars so variables.tf file will stay similar for all
> add below variables.tf file in all dev , prod and stage folder

```json
# create variables.tf file for all environment

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

```

### Step 27 - Execute Terraform Command

```html
# Terraform Initialize
cd env/dev && terraform init
cd env/stage && terraform init
cd env/prod  && terraform init

# Terraform Validate
cd env/dev && terraform validate
cd env/stage && terraform validate
cd env/prod  && terraform validate

# Terraform plan
cd env/dev && terraform plan -var-file="dev.tfvars"
cd env/stage && terraform plan -var-file="stage.tfvars"
cd env/prod && terraform plan -var-file="prod.tfvars"

# Terraform Apply
cd env/dev && terraform apply -var-file="dev.tfvars"
cd env/stage && terraform apply -var-file="stage.tfvars"
cd env/prod && terraform apply -var-file="prod.tfvars"
```

```t
# Another way to run command is using Makefile
for that we meed to install make package
sudo apt install make
```

#### Create Makefile
```c
ENVS := dev stage prod
ACTIONS := init plan apply validate

$(foreach env,$(ENVS), \
  $(foreach action,$(ACTIONS), \
    $(eval $(action)-$(env): \
      ; cd env/$(env) && terraform $(action) $(if $(filter $(action),plan apply),-var-file="$(env).tfvars",)) \
  ) \
)
```
#### How to run makefile command
```t

# run this from parent directory no need to switch directory to run command 
make init-dev       # Runs terraform init with backend config for dev
make init-stage     # For stage env
make init-prod      # For prod env 
make validate-dev
make validate-stage
make validate-prod

# Still supports:
make plan-prod
make apply-dev

```

### Step 28 - Install Kubectl (optional - If not Installed  ) 
  follow steps from official documentation
  [Install kubectl CLI](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html)

### Step 29: Configure kubeconfig for kubectl
```t
# Configure kubeconfig for kubectl
aws eks --region <region-code> update-kubeconfig --name <cluster_name>
aws eks --region us-east-1 update-kubeconfig --name eks-dev-cluster
aws eks --region us-east-1 update-kubeconfig --name eks-prod-cluster
aws eks --region us-east-1 update-kubeconfig --name eks-stage-cluster

# List Worker Nodes
kubectl get nodes
kubectl get nodes -o wide

# Verify Services
kubectl get svc
```

### Step-30: Verify Namespaces and Resources in Namespaces
```t
# Verify Namespaces
kubectl get namespaces
kubectl get ns 
Observation: 4 namespaces will be listed by default
1. kube-node-lease
2. kube-public
3. default
4. kube-system

# Verify Resources in kube-node-lease namespace
kubectl get all -n kube-node-lease

# Verify Resources in kube-public namespace
kubectl get all -n kube-public

# Verify Resources in default namespace
kubectl get all -n default
Observation: 
1. Kubernetes Service: Cluster IP Service for Kubernetes Endpoint

# Verify Resources in kube-system namespace
kubectl get all -n kube-system
Observation: 
1. Kubernetes Deployment: coredns
2. Kubernetes DaemonSet: aws-node, kube-proxy
3. Kubernetes Service: kube-dns
4. Kubernetes Pods: coredns, aws-node, kube-proxy
```

### Step-31: EKS Security Groups
- EKS Cluster Security Group (added)
- EKS Node Security Group (Not added)

### Discussion & Comments on above