resource "tls_private_key" "node_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "node_ssh_key" {
  key_name   = var.nodegroup_keypair
  public_key = tls_private_key.node_ssh_key.public_key_openssh
}
