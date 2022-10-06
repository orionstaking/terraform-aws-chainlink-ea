# AWS SecretsManager objects for Chainlink EA's
resource "aws_secretsmanager_secret" "api_key_obj" {
  for_each = { for ea in local.external_adapters : ea.name => ea }

  name        = "${var.project}/${var.environment}/ea/${each.value.name}"
  description = "${each.value.name} API key for ${var.project}-${var.environment} project"

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "api_key" {
  for_each = { for ea in local.external_adapters : ea.name => ea if ea.api_key != "" }

  secret_id     = aws_secretsmanager_secret.api_key_obj[each.value.name].id
  secret_string = each.value.api_key
}

module "ea_specific_secrets" {
  for_each = { for ea in local.external_adapters : ea.name => ea }
  source   = "./modules/ea_specific_secrets"

  project     = var.project
  environment = var.environment
  ea_name     = each.value.name
  secrets     = each.value.ea_specific_secret_variables
  role_name   = aws_iam_role.this.name
}
