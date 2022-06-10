# AWS SecretsManager objects for Chainlink EA's
resource "aws_secretsmanager_secret" "api_key_obj" {
  for_each = { for ea in local.external_adapters : ea.name => ea if local.create || var.secret_objects_only }

  name        = "${var.project}/${var.environment}/ea/${each.value.name}"
  description = "${each.value.name} API key for ${var.project}-${var.environment} project"

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "api_key" {
  for_each = { for ea in local.external_adapters : ea.name => ea if local.create && var.tfstate_secrets_store && ea.api_key != "" }

  secret_id     = aws_secretsmanager_secret.api_key_obj[each.value.name].id
  secret_string = each.value.api_key
}
