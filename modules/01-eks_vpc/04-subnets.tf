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
