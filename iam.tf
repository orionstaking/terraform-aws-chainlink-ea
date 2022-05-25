# ECS execution role with access to ECR and Cloudwatch
data "aws_iam_policy_document" "this" {
  count = local.create ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "*",
    ]
  }

  dynamic "statement" {
    for_each = { for ea in local.external_adapters : ea.name => ea }

    content {
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
        "kms:Decrypt"
      ]
      resources = [
        aws_secretsmanager_secret.api_key_obj[statement.value.name].arn
      ]
    }
  }
}

resource "aws_iam_policy" "this" {
  count = local.create ? 1 : 0

  name        = "${var.project}-${var.environment}-ea-task-exec-policy"
  description = "Provides access to ECR and Cloudwatch logs"
  policy      = data.aws_iam_policy_document.this[0].json
}

resource "aws_iam_role" "this" {
  count = local.create ? 1 : 0

  name = "${var.project}-${var.environment}-ea-ecs-tasks"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "this" {
  count = local.create ? 1 : 0

  policy_arn = aws_iam_policy.this[0].arn
  role       = aws_iam_role.this[0].name
}
