# AWS SecretsManager objects for Chainlink EA's
module "ea_secrets" {
  for_each = { for ea in local.external_adapters : ea.name => ea }
  source   = "./modules/ea_secrets"

  project     = var.project
  environment = var.environment
  ea_name     = each.value.name
  secrets     = each.value.ea_secret_variables
  role_name   = aws_iam_role.this.name
}
