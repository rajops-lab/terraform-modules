# Allocate Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc" # 'vpc = true' is deprecated; use 'domain = "vpc"' instead

  tags = {
    Name = "${var.environment}-nat-eip"
  }
}
