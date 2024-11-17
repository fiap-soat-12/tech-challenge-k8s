resource "aws_lb" "nginx_alb" {
  name                       = "tech-challenge-load-balancer"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_sg.id]
  subnets                    = [for subnet in data.aws_subnet.selected_subnets : subnet.id]
  enable_deletion_protection = false
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.nginx_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http_tg.arn
  }
}

resource "aws_lb_target_group" "http_tg" {
  name        = "http-target-group"
  port        = 30080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.default.id

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
  count            = length(data.aws_instance.worker_node_details)
  target_group_arn = aws_lb_target_group.http_tg.arn
  target_id        = data.aws_instance.worker_node_details[count.index].private_ip
  port             = 30080
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Security group for ALB"
  vpc_id      = data.aws_vpc.default.id

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
  from_port                = 30080
  to_port                  = 30443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
}
