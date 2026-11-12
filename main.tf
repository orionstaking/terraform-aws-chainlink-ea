locals {

  # more info about default vars could be found here: https://github.com/smartcontractkit/external-adapters-js/blob/develop/packages/core/bootstrap/README.md 
  # it's possible to pass or rewrite a default velue of any environemnt variable from the list in the link by adding it in 'ea_specific_variables' block
  external_adapters = flatten([
    for key, value in var.external_adapters : [{
      name                    = key
      version                 = lookup(value, "version", "auto")
      rate_limit_enabled      = lookup(value, "rate_limit_enabled", "true")
      rate_limit_api_provider = lookup(value, "rate_limit_api_provider", key)
      rate_limit_api_tier     = lookup(value, "rate_limit_api_tier", "")
      ea_port                 = lookup(value, "app_port", 8080)
      metrics_port            = lookup(value, "metrics_port", 9080)
      cpu                     = lookup(value, "cpu", 256)
      memory                  = lookup(value, "memory", 512)
      cache_enabled           = lookup(value, "cache_enabled", "true")
      cache_type              = var.cache_redis ? lookup(value, "cache_type", "redis") : "local"
      cache_key_group         = lookup(value, "cache_key_group", key)
      log_level               = lookup(value, "log_level", "info")
      alarms_disabled         = lookup(value, "alarms_disabled", "false")
      alb_target_group_name   = lookup(value, "alb_target_group_name", null)

      ea_specific_variables = flatten([
        for spec_var_key, spec_var_value in lookup(value, "ea_specific_variables", {}) : [{
          name  = spec_var_key
          value = spec_var_value
        }]
      ])

      ea_secret_parameters = try(tolist(lookup(value, "ea_secret_parameters", [])), [])
    }]
  ])

  legacy_secret_adapters = [
    for name, cfg in var.external_adapters : name
    if contains(keys(cfg), "ea_secret_variables")
  ]

  non_list_secret_parameters = [
    for name, cfg in var.external_adapters : name
    if contains(keys(cfg), "ea_secret_parameters") && !can(tolist(lookup(cfg, "ea_secret_parameters", [])))
  ]

  secret_specific_overlap = flatten([
    for name, cfg in var.external_adapters : [
      for secret_name in try(tolist(lookup(cfg, "ea_secret_parameters", [])), []) : "${name}/${secret_name}"
      if contains(keys(lookup(cfg, "ea_specific_variables", {})), secret_name)
    ]
  ])

  invalid_secret_parameter_names = flatten([
    for name, cfg in var.external_adapters : [
      for secret_name in try(tolist(lookup(cfg, "ea_secret_parameters", [])), []) : "${name}/${secret_name}"
      if !can(regex("^[A-Za-z_][A-Za-z0-9_]*$", secret_name))
    ] if can(tolist(lookup(cfg, "ea_secret_parameters", [])))
  ])

  duplicate_secret_parameters = [
    for name, cfg in var.external_adapters : name
    if can(tolist(lookup(cfg, "ea_secret_parameters", []))) && length(distinct(tolist(lookup(cfg, "ea_secret_parameters", [])))) != length(tolist(lookup(cfg, "ea_secret_parameters", [])))
  ]

  secret_parameter_names = flatten([
    for ea in local.external_adapters : [
      for parameter_name in ea.ea_secret_parameters : "/${var.project}/${var.environment}/ea/${ea.name}/${parameter_name}"
    ]
  ])

  secret_parameter_arns = [
    for parameter_name in local.secret_parameter_names : "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter${parameter_name}"
  ]

  ea_secret_parameters_ready = length(local.secret_parameter_names) == 0 ? true : data.external.ea_secret_parameters[0].result.ok == "true"

  container_insights_monitoring = var.monitoring_enabled ? "enabled" : "disabled"
}

data "external" "ea_secret_parameters" {
  count = length(local.secret_parameter_names) == 0 ? 0 : 1

  program = ["python3", "${path.module}/check_ssm_parameters.py"]

  query = {
    region = var.aws_region
    names  = jsonencode(local.secret_parameter_names)
  }
}

data "external" "latest_version" {
  for_each = { for ea in local.external_adapters : ea.name => ea if ea.version == "auto" }

  program = ["python3", "${path.module}/get_latest_adapter_tag.py"]
  query = {
    adapter_name = each.value.name
  }
}

# ECS cluster
resource "aws_ecs_cluster" "this" {
  name = "${var.project}-${var.environment}-ea"
  setting {
    name  = "containerInsights"
    value = local.container_insights_monitoring
  }

  lifecycle {
    precondition {
      condition     = length(local.legacy_secret_adapters) == 0
      error_message = "ea_secret_variables was removed in v3. Move secret names to ea_secret_parameters and create a SecureString at /${var.project}/${var.environment}/ea/<adapter>/<NAME> before apply. Still set on: ${join(", ", local.legacy_secret_adapters)}."
    }
    precondition {
      condition     = length(local.non_list_secret_parameters) == 0
      error_message = "ea_secret_parameters must be a list of environment variable names. Still a map or other type on: ${join(", ", local.non_list_secret_parameters)}."
    }
    precondition {
      condition     = length(local.secret_specific_overlap) == 0
      error_message = "A name cannot be both an ea_specific_variables entry and an ea_secret_parameters entry: ${join(", ", local.secret_specific_overlap)}."
    }
    precondition {
      condition     = length(local.invalid_secret_parameter_names) == 0
      error_message = "ea_secret_parameters names must match [A-Za-z_][A-Za-z0-9_]*: ${join(", ", local.invalid_secret_parameter_names)}."
    }
    precondition {
      condition     = length(local.duplicate_secret_parameters) == 0
      error_message = "ea_secret_parameters contains duplicate names for: ${join(", ", local.duplicate_secret_parameters)}."
    }
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
      project                 = var.project
      environment             = var.environment
      ea_name                 = each.value.name
      rate_limit_enabled      = each.value.rate_limit_enabled
      rate_limit_api_tier     = each.value.rate_limit_api_tier
      rate_limit_api_provider = each.value.rate_limit_api_provider
      docker_image            = "public.ecr.aws/chainlink/adapters/${each.value.name}-adapter"
      docker_tag              = each.value.version == "auto" ? data.external.latest_version[each.value.name].result.latest_version : each.value.version
      aws_region              = var.aws_region
      ea_port                 = each.value.ea_port
      metrics_port            = each.value.metrics_port
      cpu                     = each.value.cpu
      memory                  = each.value.memory
      cache_enabled           = each.value.cache_enabled
      cache_type              = each.value.cache_type
      cache_redis_host        = each.value.cache_type == "redis" ? aws_memorydb_cluster.this[0].cluster_endpoint[0].address : ""
      cache_redis_port        = each.value.cache_type == "redis" ? aws_memorydb_cluster.this[0].cluster_endpoint[0].port : ""
      cache_key_group         = each.value.cache_key_group
      log_level               = each.value.log_level
      ea_specific_variables   = each.value.ea_specific_variables
      ea_secret_parameters = [
        for parameter_name in each.value.ea_secret_parameters : {
          name      = parameter_name
          valueFrom = "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/${var.project}/${var.environment}/ea/${each.value.name}/${parameter_name}"
        }
      ]
    }
  )

  lifecycle {
    precondition {
      condition     = local.ea_secret_parameters_ready
      error_message = "One or more SSM parameters from ea_secret_parameters are missing or are not SecureString."
    }
  }
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
    container_port   = each.value.ea_port
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ea_metrics[each.value.name].arn
    container_name   = "${var.project}-${var.environment}-${each.value.name}"
    container_port   = each.value.metrics_port
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
