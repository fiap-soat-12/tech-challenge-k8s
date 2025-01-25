resource "aws_lb" "alb" {
  name               = var.alb_name
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for subnet in data.aws_subnet.selected_public_subnets : subnet.id]

  enable_deletion_protection = false
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.alb_name}-sg"
  description = "Security group for the Application Load Balancer"
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

resource "aws_lb_target_group" "alb_target_group" {
  name        = "${var.alb_name}-tg"
  port        = 30080
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.selected_vpc.id
  target_type = "instance"

  health_check {
    protocol            = "HTTP"
    path                = "/api/actuator/health"
    port                = "30080"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group_attachment" "nginx_nodeport_attachment" {
  count            = length(data.aws_instances.eks_worker_instances.ids)
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  target_id        = element(data.aws_instances.eks_worker_instances.ids, count.index)
  port             = 30080
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }
}

resource "aws_lb_listener_rule" "grafana_rule" {
  listener_arn = aws_lb_listener.alb_listener.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/grafana*"]
    }
  }
}

resource "aws_security_group_rule" "allow_alb_to_nodeport" {
  type                     = "ingress"
  from_port                = 30080
  to_port                  = 30080
  protocol                 = "tcp"
  security_group_id        = data.aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.alb_sg.id
}
