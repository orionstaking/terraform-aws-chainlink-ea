# SNS topic for alerts if custom not specified
resource "aws_sns_topic" "this" {
  count = local.create && var.monitoring_enabled && var.sns_topic_arn == "" ? 1 : 0

  name = "${var.project}-${var.environment}-ea"
}

# Log errors to Metrics transformation
resource "aws_cloudwatch_log_metric_filter" "log_errors" {
  for_each = { for ea in local.external_adapters : ea.name => ea if local.create && var.monitoring_enabled }

  name           = "${var.project}-${var.environment}-${each.value.name}"
  pattern        = "error"
  log_group_name = aws_cloudwatch_log_group.this[each.value.name].name

  metric_transformation {
    name          = "${var.project}-${var.environment}-ea-${each.value.name}-log-error"
    namespace     = "${var.project}-${var.environment}-ea-log-errors"
    value         = "1"
    default_value = "0"
  }
}

# Alarms based on logs
resource "aws_cloudwatch_metric_alarm" "log_alarms" {
  for_each = { for ea in local.external_adapters : ea.name => ea if local.create && var.monitoring_enabled }

  alarm_name          = "${var.project}-${var.environment}-ea-${each.value.name}-log-error"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  metric_name         = "${var.project}-${var.environment}-ea-${each.value.name}-log-error"
  namespace           = "${var.project}-${var.environment}-ea-log-errors"
  period              = "180"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Errors detected in ${each.value.name} external adapter CloudWatch log group"
  actions_enabled     = "true"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.sns_topic_arn == "" ? [aws_sns_topic.this[0].arn] : [var.sns_topic_arn]
  ok_actions          = var.sns_topic_arn == "" ? [aws_sns_topic.this[0].arn] : [var.sns_topic_arn]
}

# metric alarms
resource "aws_cloudwatch_metric_alarm" "memory_utilization" {
  for_each = { for ea in local.external_adapters : ea.name => ea if local.create && var.monitoring_enabled }

  alarm_name          = "${var.project}-${var.environment}-ea-${each.value.name}-MemoryUtilizationHigh"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  threshold           = "80"
  alarm_description   = "Memory utilization has exceeded 80%"
  actions_enabled     = "true"
  alarm_actions       = var.sns_topic_arn == "" ? [aws_sns_topic.this[0].arn] : [var.sns_topic_arn]
  ok_actions          = var.sns_topic_arn == "" ? [aws_sns_topic.this[0].arn] : [var.sns_topic_arn]

  metric_query {
    id          = "e1"
    expression  = "m2*100/m1"
    label       = "Memory utilization"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "MemoryReserved"
      namespace   = "ECS/ContainerInsights"
      period      = "60"
      stat        = "Average"

      dimensions = {
        ClusterName = "${var.project}-${var.environment}-ea"
        ServiceName = "${var.project}-${var.environment}-${each.value.name}"
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "MemoryUtilized"
      namespace   = "ECS/ContainerInsights"
      period      = "60"
      stat        = "Average"

      dimensions = {
        ClusterName = "${var.project}-${var.environment}-ea"
        ServiceName = "${var.project}-${var.environment}-${each.value.name}"
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  for_each = { for ea in local.external_adapters : ea.name => ea if local.create && var.monitoring_enabled }

  alarm_name          = "${var.project}-${var.environment}-ea-${each.value.name}-CPUUtilizationHigh"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  threshold           = "80"
  alarm_description   = "CPU utilization has exceeded 80%"
  actions_enabled     = "true"
  alarm_actions       = var.sns_topic_arn == "" ? [aws_sns_topic.this[0].arn] : [var.sns_topic_arn]
  ok_actions          = var.sns_topic_arn == "" ? [aws_sns_topic.this[0].arn] : [var.sns_topic_arn]

  metric_query {
    id          = "e1"
    expression  = "m2*100/m1"
    label       = "CPU utilization"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "CpuReserved"
      namespace   = "ECS/ContainerInsights"
      period      = "60"
      stat        = "Average"

      dimensions = {
        ClusterName = "${var.project}-${var.environment}-ea"
        ServiceName = "${var.project}-${var.environment}-${each.value.name}"
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "CpuUtilized"
      namespace   = "ECS/ContainerInsights"
      period      = "60"
      stat        = "Average"

      dimensions = {
        ClusterName = "${var.project}-${var.environment}-ea"
        ServiceName = "${var.project}-${var.environment}-${each.value.name}"
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "elb" {
  for_each = local.create && var.monitoring_enabled ? toset(["4XX", "5XX"]) : []

  alarm_name          = "${var.project}-${var.environment}-ea-elb-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "HTTPCode_ELB_${each.key}_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "180"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "The number of HTTP 4XX client error codes for ${var.project}-${var.environment} has increased"
  actions_enabled     = "true"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.sns_topic_arn == "" ? [aws_sns_topic.this[0].arn] : [var.sns_topic_arn]
  ok_actions          = var.sns_topic_arn == "" ? [aws_sns_topic.this[0].arn] : [var.sns_topic_arn]

  dimensions = {
    LoadBalancer = aws_lb.this[0].arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "memorydb_cpu" {
  count = local.create && var.monitoring_enabled ? 1 : 0

  alarm_name          = "${var.project}-${var.environment}-ea-memorydb-CPUUtilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/MemoryDB"
  period              = "180"
  statistic           = "Sum"
  threshold           = "80"
  alarm_description   = "CPU utilization of MemoryDB cluster has exceeded 80%"
  actions_enabled     = "true"
  alarm_actions       = var.sns_topic_arn == "" ? [aws_sns_topic.this[0].arn] : [var.sns_topic_arn]
  ok_actions          = var.sns_topic_arn == "" ? [aws_sns_topic.this[0].arn] : [var.sns_topic_arn]

  dimensions = {
    ClusterName = "${var.project}-${var.environment}-ea"
  }
}

resource "aws_cloudwatch_metric_alarm" "memorydb_memory" {
  count = local.create && var.monitoring_enabled ? 1 : 0

  alarm_name          = "${var.project}-${var.environment}-ea-memorydb-DatabaseMemoryUsagePercentage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/MemoryDB"
  period              = "180"
  statistic           = "Sum"
  threshold           = "80"
  alarm_description   = "Memory utilization of MemoryDB cluster has exceeded 80%"
  actions_enabled     = "true"
  alarm_actions       = var.sns_topic_arn == "" ? [aws_sns_topic.this[0].arn] : [var.sns_topic_arn]
  ok_actions          = var.sns_topic_arn == "" ? [aws_sns_topic.this[0].arn] : [var.sns_topic_arn]

  dimensions = {
    ClusterName = "${var.project}-${var.environment}-ea"
  }
}

# CW Dashboards for EA
data "template_file" "ea" {
  for_each = { for ea in local.external_adapters : ea.name => ea if local.create && var.monitoring_enabled }

  template = file(
    "${path.module}/templates/cw_dashboard_ea.json.tpl",
  )

  vars = {
    project     = var.project
    environment = var.environment
    region      = var.aws_region
    account_id  = var.aws_account_id
    ea_name     = each.value.name
    log_group   = aws_cloudwatch_log_group.this[each.value.name].name
  }
}

resource "aws_cloudwatch_dashboard" "ea" {
  for_each = { for ea in local.external_adapters : ea.name => ea if local.create && var.monitoring_enabled }

  dashboard_name = "${var.project}-${var.environment}-ea-${each.value.name}"
  dashboard_body = data.template_file.ea[each.value.name].rendered
}

# CW Dashboard for ELB and MemoryDB
data "template_file" "comm" {
  count = local.create && var.monitoring_enabled ? 1 : 0

  template = file(
    "${path.module}/templates/cw_dashboard_comm.json.tpl",
  )

  vars = {
    project        = var.project
    environment    = var.environment
    region         = var.aws_region
    elb_arn_suffix = aws_lb.this[0].arn_suffix
  }
}

resource "aws_cloudwatch_dashboard" "comm" {
  count = local.create && var.monitoring_enabled ? 1 : 0

  dashboard_name = "${var.project}-${var.environment}-ea-common"
  dashboard_body = data.template_file.comm[0].rendered
}
