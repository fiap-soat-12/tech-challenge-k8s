resource "aws_lb" "alb" {
  name                       = "techchallenge-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_sg.id]
  subnets                    = [for subnet in data.aws_subnet.selected_private_subnets : subnet.id]
  enable_deletion_protection = false
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_http_tg.arn
  }
}

resource "aws_lb_target_group" "alb_http_tg" {
  name        = "techchallenge-alb-http-tg"
  port        = 30080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.selected_vpc.id

  health_check {
    path                = "/api/actuator/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }
}

resource "aws_lb_target_group_attachment" "http_targets" {
  for_each         = toset(data.aws_instances.eks_worker_instances.private_ips)
  target_group_arn = aws_lb_target_group.alb_http_tg.arn
  target_id        = each.value
  port             = 30080
}

resource "aws_security_group" "alb_sg" {
  name        = "techchallenge-alb-security-group"
  description = "Security group for ALB"
  vpc_id      = data.aws_vpc.selected_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

resource "aws_security_group_rule" "allow_alb_to_nodes" {
  type                     = "ingress"
  security_group_id        = data.aws_eks_cluster.fiap-tech-challenge-eks-cluster.vpc_config[0].cluster_security_group_id
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
}
