resource "aws_eks_node_group" "ubuntu_22_ngp" {
  cluster_name    = var.eks_cluster_name
  node_group_name = var.node_group_name

  remote_access {
    ec2_ssh_key = aws_key_pair.node_ssh_key.key_name
  }

  node_role_arn = aws_iam_role.node_role.arn
  subnet_ids    = var.eks_subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1 # if something went wrong or downtime at least 1 node will be available
  }

  depends_on = [
    aws_iam_role.node_role,
    aws_iam_role_policy_attachment.node_policy_attach
  ]
}


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


