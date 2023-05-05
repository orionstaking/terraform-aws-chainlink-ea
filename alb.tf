resource "aws_lb" "this" {
  name               = var.project
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tasks_sg.id, aws_security_group.alb_sg.id]
  subnets            = var.vpc_public_subnets

  tags = {
    Name = var.project
  }
}

resource "aws_lb_target_group" "ea" {
  for_each = { for ea in local.external_adapters : ea.name => ea }

  name                 = trim(substr("${var.project}-${var.environment}-${each.value.name}", 0, 32), "-")
  port                 = each.value.ea_port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 10

  health_check {
    enabled             = true
    interval            = 10
    path                = "/${each.value.name}/health"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    protocol            = "HTTP"
    matcher             = "200"
  }
}

resource "aws_lb_target_group" "ea_metrics" {
  for_each = { for ea in local.external_adapters : ea.name => ea }

  name                 = trim(substr("m-${var.project}-${var.environment}-${each.value.name}", 0, 32), "-")
  port                 = each.value.metrics_port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 10

  health_check {
    enabled             = true
    interval            = 10
    path                = "/${each.value.name}/metrics"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    protocol            = "HTTP"
    matcher             = "200"
  }
}

resource "aws_lb_listener" "ea" {
  count = var.route53_enabled ? 0 : 1

  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "ALB for Chainlink external adapters"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener" "ea_secure" {
  count = var.route53_enabled ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = module.acm[0].acm_certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "ALB for Chainlink external adapters"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener_rule" "static" {
  for_each = { for ea in local.external_adapters : ea.name => ea }

  listener_arn = var.route53_enabled ? aws_lb_listener.ea_secure[0].arn : aws_lb_listener.ea[0].arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ea[each.value.name].arn
  }

  condition {
    path_pattern {
      values = ["/${each.value.name}"]
    }
  }
}

resource "aws_lb_listener_rule" "static_metrics" {
  for_each = { for ea in local.external_adapters : ea.name => ea }

  listener_arn = var.route53_enabled ? aws_lb_listener.ea_secure[0].arn : aws_lb_listener.ea[0].arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ea_metrics[each.value.name].arn
  }

  condition {
    path_pattern {
      values = ["/${each.value.name}/metrics"]
    }
  }
}

# ACM
resource "aws_route53_record" "this" {
  count = var.route53_enabled ? 1 : 0

  zone_id = var.route53_zoneid
  name    = "${var.route53_subdomain_name}.${var.route53_domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.this.dns_name]
}

module "acm" {
  count = var.route53_enabled ? 1 : 0

  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name = "${var.route53_subdomain_name}.${var.route53_domain_name}"
  zone_id     = var.route53_zoneid

  wait_for_validation = true
}

# ALB security group
resource "aws_security_group" "alb_sg" {
  name        = "${var.project}-alb-sg"
  description = "Allow alb traffic within VPC cidr block"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "egress_alb_allow_all" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.alb_sg.id
}
