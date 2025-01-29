resource "aws_eks_cluster" "eks_cluster" {
  name     = var.eks_cluster_name
  role_arn = data.aws_iam_role.lab_role.arn

  vpc_config {
    subnet_ids = [for subnet in data.aws_subnet.selected_subnets : subnet.id]
  }
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = var.node_group_name
  node_role_arn   = data.aws_iam_role.lab_role.arn

  subnet_ids = [for subnet in data.aws_subnet.selected_subnets : subnet.id]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  depends_on = [
    aws_eks_cluster.eks_cluster
  ]
}

resource "aws_security_group_rule" "allow_app_to_order_instance_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = tolist(data.aws_db_instance.tc_order_db_instance.vpc_security_groups)[0]
  source_security_group_id = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

resource "aws_security_group_rule" "allow_app_to_cook_instance_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = tolist(data.aws_db_instance.tc_cook_db_instance.vpc_security_groups)[0]
  source_security_group_id = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}
