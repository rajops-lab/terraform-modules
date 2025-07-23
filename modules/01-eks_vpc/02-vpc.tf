resource "aws_vpc" "eks-vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true # declare variable 2

  tags = {
    # i want to name this as Envname-resorcename-commonname
    "Name" = "${var.environment}-vpc" # declare varible 3
  }
}