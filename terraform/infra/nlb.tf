resource "aws_lb" "nlb" {
  name               = var.nlb_name
  internal           = true
  load_balancer_type = "network"
  security_groups    = [aws_security_group.nlb_sg.id]
  subnets            = [for subnet in data.aws_subnet.selected_private_subnets : subnet.id]
}

resource "aws_security_group" "nlb_sg" {
  name        = "${var.nlb_name}-sg"
  description = "Security group for the Network Load Balancer"
  vpc_id      = data.aws_vpc.selected_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "nlb_target_group" {
  name        = "${var.nlb_name}-tg"
  port        = 30080
  protocol    = "TCP"
  vpc_id      = data.aws_vpc.selected_vpc.id
  target_type = "instance"
}

resource "aws_lb_target_group_attachment" "http_targets" {
  for_each         = toset(data.aws_instances.eks_worker_instances.ids)
  target_group_arn = aws_lb_target_group.nlb_target_group.arn
  target_id        = each.value
  port             = 30080
}

resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_target_group.arn
  }
}

resource "aws_security_group_rule" "allow_nlb_to_nodeport" {
  type                     = "ingress"
  from_port                = 30080
  to_port                  = 30080
  protocol                 = "TCP"
  security_group_id        = data.aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.nlb_sg.id
}
