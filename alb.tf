resource "aws_lb" "this" {
  count = local.create ? 1 : 0

  name               = var.project
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tasks_sg[0].id, aws_security_group.alb_sg[0].id]
  subnets            = var.vpc_private_subnets

  tags = {
    Name = var.project
  }
}

resource "aws_lb_target_group" "ea" {
  for_each = { for ea in local.external_adapters : ea.name => ea if local.create }

  name                 = each.value.name
  port                 = each.value.app_port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 10

  health_check {
    enabled             = true
    interval            = 10
    path                = each.value.health_path
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    protocol            = "HTTP"
    matcher             = "200"
  }
}

resource "aws_lb_listener" "ea" {
  for_each = { for ea in local.external_adapters : ea.name => ea if local.create }

  load_balancer_arn = aws_lb.this[0].arn
  port              = each.value.alb_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ea[each.value.name].arn
  }
}

# ALB security group
resource "aws_security_group" "alb_sg" {
  count = local.create ? 1 : 0

  name        = "${var.project}-alb-sg"
  description = "Allow alb traffic within VPC cidr block"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "ingress_alb_allow_ea" {
  for_each = { for ea in local.external_adapters : ea.name => ea if local.create }

  type        = "ingress"
  from_port   = 0
  to_port     = each.value.alb_port
  protocol    = "tcp"
  cidr_blocks = ["${var.vpc_cidr_block}"]

  security_group_id = aws_security_group.alb_sg[0].id
}

resource "aws_security_group_rule" "egress_alb_allow_all" {
  count = local.create ? 1 : 0

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.alb_sg[0].id
}
