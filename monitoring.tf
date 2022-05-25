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
  evaluation_periods  = "1"
  metric_name         = "${var.project}-${var.environment}-ea-${each.value.name}-log-error"
  namespace           = "${var.project}-${var.environment}-ea-log-errors"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Errors detected in ${each.value.name} external adapter CloudWatch log group"
  actions_enabled     = "true"
  alarm_actions       = var.sns_topic_arn == "" ? [aws_sns_topic.this[0].arn] : [var.sns_topic_arn]
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

# CW Dashboard
data "template_file" "this" {
  for_each = { for ea in local.external_adapters : ea.name => ea if local.create && var.monitoring_enabled }

  template = file(
    "${path.module}/templates/cw_dashboard.json.tpl",
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

resource "aws_cloudwatch_dashboard" "this" {
  for_each = { for ea in local.external_adapters : ea.name => ea if local.create && var.monitoring_enabled }

  dashboard_name = "${var.project}-${var.environment}-ea-${each.value.name}"
  dashboard_body = data.template_file.this[each.value.name].rendered
}
