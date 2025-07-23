# now for public subnet we need to create internet gateway 
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eks-vpc.id

  tags = {
    "key" = "${var.environment}-igw"
  }

}


