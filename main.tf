locals {

  # more info about default vars could be found here: https://github.com/smartcontractkit/external-adapters-js/blob/develop/packages/core/bootstrap/README.md 
  # in order to make more environment variables configurable please create an issue or open a PR
  external_adapters = flatten([
    for key, value in var.external_adapters : [{
      name                   = key
      custom_task_definition = lookup(value, "custom", "false")
      version                = lookup(value, "version", "latest")
      api_tier               = lookup(value, "api_tier", "")
      api_key                = lookup(value, "api_key", "")
      ws_enabled             = lookup(value, "ws_enabled", false)
      app_port               = lookup(value, "app_port", 8080)
      alb_port               = lookup(value, "alb_port", null)
      health_path            = lookup(value, "health_path", "/health")
      cpu                    = lookup(value, "cpu", 256)
      memory                 = lookup(value, "memory", 512)
      cache_enabled          = lookup(value, "cache_enabled", "true")
      cache_type             = var.cache_redis ? lookup(value, "cache_type", "redis") : "local"
      cache_max_age          = lookup(value, "cache_max_age", "90000")
      cache_max_items        = lookup(value, "cache_max_items", "1000")
      cache_redis_timeout    = lookup(value, "cache_redis_timeout", "500")
      rate_limit_enabled     = lookup(value, "rate_limit_enabled", "true")
      warmup_enabled         = lookup(value, "warmup_enabled", "true")
      api_timeout            = lookup(value, "api_timeout", "30000")
      log_level              = lookup(value, "log_level", "info")
      debug                  = lookup(value, "debug", "false")
      api_verbose            = lookup(value, "api_verbose", "false")

      request_coalescing_enabled              = lookup(value, "request_coalescing_enabled", "false")
      request_coalescing_interval             = lookup(value, "request_coalescing_interval", "100")
      request_coalescing_interval_max         = lookup(value, "request_coalescing_interval_max", "1000")
      request_coalescing_interval_coefficient = lookup(value, "request_coalescing_interval_coefficient", "2")
      request_coalescing_entropy_max          = lookup(value, "request_coalescing_entropy_max", "0")
      experimental_metrics_enabled            = lookup(value, "experimental_metrics_enabled", "false")

      ea_specific_variables = flatten([
        for spec_var_key, spec_var_value in lookup(value, "ea_specific_variables", {}) : [{
          name  = spec_var_key
          value = spec_var_value
        }]
      ])

      ea_secret_variables = flatten([
        for spec_sec_var_key, spec_sec_var_value in lookup(value, "ea_secret_variables", {}) : [{
          secret_name  = spec_sec_var_key
          secret_value = spec_sec_var_value
        }]
      ])
    }]
  ])

  container_insights_monitoring = var.monitoring_enabled ? "enabled" : "disabled"
}

# ECS cluster
resource "aws_ecs_cluster" "this" {
  name = "${var.project}-${var.environment}-ea"
  setting {
    name  = "containerInsights"
    value = local.container_insights_monitoring
  }
}

resource "aws_ecs_task_definition" "this" {
  for_each = { for ea in local.external_adapters : ea.name => ea }

  family = "${var.project}-${var.environment}-${each.value.name}"

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = each.value.cpu
  memory                   = each.value.memory

  execution_role_arn = aws_iam_role.this.arn

  # container_definitions = data.template_file.ea_task_definitions[each.value.name].rendered
  container_definitions = templatefile(
    "${path.module}/ea_task_definitions/default.json.tpl",
    {
      project             = var.project
      environment         = var.environment
      ea_name             = each.value.name
      api_tier            = each.value.api_tier
      ws_enabled          = each.value.ws_enabled
      docker_image        = "public.ecr.aws/chainlink/adapters/${each.value.name}-adapter:${each.value.version}"
      aws_region          = var.aws_region
      port                = each.value.app_port
      cpu                 = each.value.cpu
      memory              = each.value.memory
      cache_enabled       = each.value.cache_enabled
      cache_type          = each.value.cache_type
      cache_max_age       = each.value.cache_max_age
      cache_max_items     = each.value.cache_max_items
      cache_redis_host    = each.value.cache_type == "redis" ? aws_memorydb_cluster.this[0].cluster_endpoint[0].address : ""
      cache_redis_port    = each.value.cache_type == "redis" ? aws_memorydb_cluster.this[0].cluster_endpoint[0].port : ""
      cache_redis_timeout = each.value.cache_type == "redis" ? each.value.cache_redis_timeout : ""
      rate_limit_enabled  = each.value.rate_limit_enabled
      warmup_enabled      = each.value.warmup_enabled
      api_timeout         = each.value.api_timeout
      log_level           = each.value.log_level
      debug               = each.value.debug
      api_verbose         = each.value.api_verbose

      request_coalescing_enabled              = each.value.request_coalescing_enabled
      request_coalescing_interval             = each.value.request_coalescing_interval
      request_coalescing_interval_max         = each.value.request_coalescing_interval_max
      request_coalescing_interval_coefficient = each.value.request_coalescing_interval_coefficient
      request_coalescing_entropy_max          = each.value.request_coalescing_entropy_max
      experimental_metrics_enabled            = each.value.experimental_metrics_enabled

      ea_specific_variables = each.value.ea_specific_variables
      ea_secret_variables   = module.ea_specific_secrets[each.value.name].secrets
    }
  )
}

# ECS service
resource "aws_ecs_service" "this" {
  for_each = { for ea in local.external_adapters : ea.name => ea }

  name                               = "${var.project}-${var.environment}-${each.value.name}"
  cluster                            = aws_ecs_cluster.this.id
  task_definition                    = aws_ecs_task_definition.this[each.value.name].arn
  deployment_maximum_percent         = "200"
  deployment_minimum_healthy_percent = "100"

  launch_type   = "FARGATE"
  desired_count = var.ea_desired_task_count

  network_configuration {
    subnets = var.vpc_private_subnets
    security_groups = (var.cache_redis && each.value.cache_type == "redis" ?
      [aws_security_group.tasks_sg.id, aws_security_group.memorydb_sg[0].id] :
      [aws_security_group.tasks_sg.id]
    )
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ea[each.value.name].arn
    container_name   = "${var.project}-${var.environment}-${each.value.name}"
    container_port   = each.value.app_port
  }
}

# Log groups to store logs from EAs
resource "aws_cloudwatch_log_group" "this" {
  for_each = { for ea in local.external_adapters : ea.name => ea }

  name              = "/aws/ecs/${var.project}-${var.environment}-${each.value.name}"
  retention_in_days = 7
}

# Disable because of the ResourceAlreadyExistsException issue in Terraform
# resource "aws_cloudwatch_log_group" "performance" {
#   count = local.container_insights_monitoring == "enabled" ? 1 : 0

#   name              = "/aws/ecs/containerinsights/${var.project}-${var.environment}-ea/performance"
#   retention_in_days = 14
# }

# SG for ECS Tasks
resource "aws_security_group" "tasks_sg" {
  name        = "${var.project}-${var.environment}-ea-ecs-tasks"
  description = "Allow trafic between alb and Chainlink EAs"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "ingress_allow_self" {
  type      = "ingress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  self      = true

  security_group_id = aws_security_group.tasks_sg.id
}

resource "aws_security_group_rule" "egress_allow_all" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.tasks_sg.id
}
