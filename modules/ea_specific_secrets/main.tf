resource "aws_secretsmanager_secret" "this" {
  for_each = { for secret in var.secrets : secret.secret_name => secret }

  name        = "${var.project}/${var.environment}/ea/${var.ea_name}/${each.value.secret_name}"
  description = "${each.value.secret_name} secret for ${var.ea_name} adapter for ${var.project}-${var.environment} project"

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "this" {
  for_each = { for secret in var.secrets : secret.secret_name => secret if secret.secret_value != "" }

  secret_id     = aws_secretsmanager_secret.this[each.value.secret].id
  secret_string = each.value.secret_value
}

# ECS execution role with access to ECR and Cloudwatch
data "aws_iam_policy_document" "this" {
  count = var.secrets != [] ? 1 : 0

  dynamic "statement" {
    for_each = { for secret in var.secrets : secret.secret_name => secret }

    content {
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
        "kms:Decrypt"
      ]
      resources = [
        aws_secretsmanager_secret.this[statement.value.secret_name].arn
      ]
    }
  }
}

resource "aws_iam_policy" "this" {
  count = var.secrets != [] ? 1 : 0

  name        = "${var.project}-${var.environment}-ea-${var.ea_name}-specific-secrets-policy"
  description = "Provides access to External adapter specific secrets"
  policy      = data.aws_iam_policy_document.this[0].json
}

resource "aws_iam_role_policy_attachment" "this" {
  count = var.secrets != [] ? 1 : 0

  policy_arn = aws_iam_policy.this[0].arn
  role       = var.role_name
}
