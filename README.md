# Chainlink External Adapters Terraform Module

Terraform module which creates AWS infra for Chainlink External Adapters:
  - AWS Fargate
  - AWS Application Load Balancer
  - AWS Secrets Manager (to store API keys)
  - AWS IAM
  - AWS MemoryDB (to enable Redis cache)
  - AWS CloudWatch

At the time of writing, the following External Adapters are fully supported and tested:
  - coingecko
  - coinmarketcap
  - tiingo
  - cryptocompare
  - alphavantage
  - coinpaprika
  - coinapi
  - fixer
  - currencylayer
  - unibit
  - bitex
  - intrinio
  - nomics

All adapters, that available on [chainlink/adapters](https://gallery.ecr.aws/?searchTerm=chainlink%2Fadapters) could be supported as well, but not tested yet.

Terraform module for Chainlink Node: [here](https://github.com/orionterra/terraform-aws-chainlink-node)

## Architecture overview

<img src="./drawio/cl-node-orion.png" width="700">

Where:

- ![#DAE8FC](https://via.placeholder.com/15/DAE8FC/DAE8FC.png) Covered by Chainlink Node terraform [module](https://github.com/orionterra/terraform-aws-chainlink-node)
- ![#D5E8D4](https://via.placeholder.com/15/D5E8D4/D5E8D4.png) Covered by this Chainlink External Adapters terraform [module](https://github.com/orionterra/terraform-aws-chainlink-ea)
- ![#D0CEE2](https://via.placeholder.com/15/D0CEE2/D0CEE2.png) Covered by RDS community terraform [module](https://github.com/terraform-aws-modules/terraform-aws-rds-aurora)
- ![#FFE6CC](https://via.placeholder.com/15/FFE6CC/FFE6CC.png) Covered by VPC community terraform [module](https://github.com/terraform-aws-modules/terraform-aws-vpc)

## Usage

### Basic example

```hcl
module "chainlink_ea" {
  source  = "ChainOrion/chainlink-ea/aws"

  project     = "example"
  environment = "nonprod"

  aws_region     = "eu-west-1"
  aws_account_id = data.aws_caller_identity.current.account_id

  vpc_id              = "vpc-09e1usdaedafe00f2"
  vpc_cidr_block      = "10.100.0.0/20"
  vpc_private_subnets = [ "subnet-082682fbde3f95edc", "subnet-092clfgc8f424cab3" ]

  # Examples for all supprted and tested adapters could be found in ./examples/complete_memorydb_redis
  external_adapters = {
    coingecko = {
      version  = "1.6.7",
      api_tier = "analyst",
      alb_port = "1113",
      api_key  = "api_key"
    }
  }
}
```

List of Chainlink EA's supported environment variables that could be specified using `external_adapters` variable.
  - timeout
  - cache_enabled
  - cache_type
  - cache_max_age
  - cache_redis_timeout
  - rate_limit_enabled
  - warmup_enabled
  - log_level
  - debug
  - api_verbose
  - external_metrics_enabled
  - retry
  - request_coalescing_enabled
  - request_coalescing_interval
  - request_coalescing_interval_max
  - request_coalescing_interval_coefficient
  - request_coalescing_entropy_max

## Notes

### AWS SM without storing secrets in terraform state in plain text (!OPTIONAL)

! Only when running from scratch. Setting `secret_objects_only` equals `true` when adding a new adapter to the list will lead to AWS Chainlink EA's infra destruction (Fargate cluster, MemoryDB, etc.)

There is an ability to create empty AWS Secrets Manager object for API key when running for the first time. Then, you will need to manyally update the secrets with API key values. This action will prevent storing secrets in terraform state in plain text.

The list of required actions:
  - run `terraform apply` with `secret_objects_only` equals `true` and `tfstate_secrets_store` equals `false` to create emtpy AWS SM objects for API keys storing.
  - Manually update created AWS SM objects (using AWS Console/CLI/etc.)
  - run `terraform apply` once again with `secret_objects_only` equals `false` and `tfstate_secrets_store` equals `false`

### Usage of custom task definition file (when default template is not enough)

There is an ability to customize environement variables and task definition for each external adaptes.

The list of required actions:
  - Set `custom` parameter equals to `true` in `external_adapters` module variable.
  - Add custom task definition template to ./ea_task_definitions/{custom_ea}.json.tpl
  - run `terraform apply`

## Examples

- [Complete example with MemoryDB](./examples/complete_memorydb_redis/main.tf)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.12.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.12.0 |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_dashboard.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_metric_filter.log_errors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_metric_filter) | resource |
| [aws_cloudwatch_metric_alarm.cpu_utilization](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.elb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.log_alarms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.memory_utilization](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.memorydb_cpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.memorydb_memory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_ecs_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.ea](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.ea](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_memorydb_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/memorydb_cluster) | resource |
| [aws_memorydb_parameter_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/memorydb_parameter_group) | resource |
| [aws_memorydb_subnet_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/memorydb_subnet_group) | resource |
| [aws_secretsmanager_secret.api_key_obj](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.api_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_security_group.alb_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.memorydb_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.tasks_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.egress_alb_allow_all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.egress_allow_all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.egress_mem_allow_all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ingress_alb_allow_ea](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ingress_allow_self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ingress_mem_allow_self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_sns_topic.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [template_file.ea_task_definitions](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | AWS account id. Used to add alarms to dashboard | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region (required for CloudWatch logs configuration) | `string` | n/a | yes |
| <a name="input_cache_redis"></a> [cache\_redis](#input\_cache\_redis) | Defines which cache type should be used. Options: local or redis. false means that local cache type should be used for each external adapter. It's possible to use different cache type for different external adapters. To do so set this variable to true to use redis cache by default. Then for specific external adapters set `cache_type` to `local` using `external_adapters` terraform variable | `string` | `false` | no |
| <a name="input_ea_desired_task_count"></a> [ea\_desired\_task\_count](#input\_ea\_desired\_task\_count) | Number of instances of the task definition to place and keep running | `number` | `1` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | `"nonprod"` | no |
| <a name="input_external_adapters"></a> [external\_adapters](#input\_external\_adapters) | n/a | `map` | `{}` | no |
| <a name="input_memorydb_node_type"></a> [memorydb\_node\_type](#input\_memorydb\_node\_type) | The compute and memory capacity of the nodes in the cluster | `string` | `"db.t4g.small"` | no |
| <a name="input_memorydb_num_replicas_per_shard"></a> [memorydb\_num\_replicas\_per\_shard](#input\_memorydb\_num\_replicas\_per\_shard) | The number of replicas to apply to each shard, up to a maximum of 5 | `number` | `0` | no |
| <a name="input_memorydb_shards_count"></a> [memorydb\_shards\_count](#input\_memorydb\_shards\_count) | The number of shards in the cluster | `number` | `1` | no |
| <a name="input_memorydb_snapshot_retention_limit"></a> [memorydb\_snapshot\_retention\_limit](#input\_memorydb\_snapshot\_retention\_limit) | The number of days for which MemoryDB retains automatic snapshots before deleting them. When set to 0, automatic backups are disabled | `number` | `0` | no |
| <a name="input_monitoring_enabled"></a> [monitoring\_enabled](#input\_monitoring\_enabled) | Defines whether to create CloudWatch dashboard and custom metrics or not | `bool` | `true` | no |
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | n/a | yes |
| <a name="input_secret_objects_only"></a> [secret\_objects\_only](#input\_secret\_objects\_only) | If 'true' and 'tfstate\_secrets\_store' is 'false', 'terraform apply' will create only AWS Secrets Manager objects to store API keys for EA's. Once all required secrets will be set manually, set this var to 'true' to create remaining AWS infra to run EA's | `bool` | `false` | no |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | SNS topic arn for alerts. If not specified, module will create an empty topic and provide topic arn in the output. Then it will be possible to specify required notification method for this topic | `string` | `""` | no |
| <a name="input_tfstate_secrets_store"></a> [tfstate\_secrets\_store](#input\_tfstate\_secrets\_store) | Defines whether to store EA's secrets in plane text in terraform store or not. If 'true', secrets for EA should be specified in external\_adapters var. If 'false', it is recommended to run the module with 'initialize' variabe equals to 'true' to set the secrets manually in AWS Secrets Manager | `bool` | `true` | no |
| <a name="input_vpc_cidr_block"></a> [vpc\_cidr\_block](#input\_vpc\_cidr\_block) | The CIDR block of the VPC | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC where Chainlink EAs should be deployed | `string` | n/a | yes |
| <a name="input_vpc_private_subnets"></a> [vpc\_private\_subnets](#input\_vpc\_private\_subnets) | VPC private subnets where Chainlink EAs should be deployed (at least 2) | `list(any)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_chainlink_ea_endpoints"></a> [chainlink\_ea\_endpoints](#output\_chainlink\_ea\_endpoints) | External Adapter endpoints that could be accessible inside VPC CIDR block |
| <a name="output_chainlink_ea_load_balancer"></a> [chainlink\_ea\_load\_balancer](#output\_chainlink\_ea\_load\_balancer) | Internal ALB endpoint to accress EA's |
| <a name="output_chainlink_ea_memory_db_address"></a> [chainlink\_ea\_memory\_db\_address](#output\_chainlink\_ea\_memory\_db\_address) | DNS hostname of the cluster configuration endpoint |
| <a name="output_chainlink_ea_memory_db_port"></a> [chainlink\_ea\_memory\_db\_port](#output\_chainlink\_ea\_memory\_db\_port) | Port number that the cluster configuration endpoint is listening on |
<!-- END_TF_DOCS -->

## License

MIT License. See [LICENSE](https://github.com/orionterra/terraform-aws-chainlink-ea/tree/master/LICENSE) for full details.

## Docs update

More about [terraform-docs](https://terraform-docs.io/user-guide/introduction/).

```bash
terraform-docs .
```
