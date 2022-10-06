<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_secretsmanager_secret.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ea_name"></a> [ea\_name](#input\_ea\_name) | Name of external adapter. Passed from main Chainlink EA's module | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name. Passed from main Chainlink EA's module | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Project name. Passed from main Chainlink EA's module | `string` | n/a | yes |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Name of the default EA's execution role. Passed from main Chainlink EA's module | `string` | n/a | yes |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | Map of secrets that needs to be created in AWS SM for specific adapter. Passed from main Chainlink EA's module | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_secrets"></a> [secrets](#output\_secrets) | n/a |
<!-- END_TF_DOCS -->