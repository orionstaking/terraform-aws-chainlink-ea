# Chainlink External Adapters Terraform Module

Terraform module which creates AWS infra for Chainlink External Adapters:
  - AWS Fargate
  - AWS Application Load Balancer
  - AWS Secrets Manager (to store API keys and other secrets)
  - AWS IAM
  - AWS MemoryDB (to enable Redis cache)
  - AWS CloudWatch

Supports all adapters available on [chainlink/adapters](https://gallery.ecr.aws/?searchTerm=chainlink%2Fadapters).

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

  monitoring_enabled = true
  elb_alarms_enabled = false

  # Examples for all supprted and tested adapters could be found in ./examples/complete_memorydb_redis
  external_adapters = {
    coingecko = {
      version                 = "1.6.7" # required, check latest version on adapters repository
      rate_limit_api_tier     = "analyst" # required, check available options in adapter sc repository
      alb_port                = "1113" # required, should be unique
      rate_limit_enabled      = "true" # optional, defaults to "true"
      rate_limit_api_provider = "coingecko" # optional, default value is set to adapter's name
      ea_port                 = "8080" # optional, defaults to "8080"
      health_path             = "/health" # optional, defaults to "/health"
      cpu                     = "256" # optional, defaults to "256"
      memory                  = "512" # optional, defaults to "512"
      cache_enabled           = "true" # optional, defaults to "true"
      cache_type              = "local" # optional, default to "local"
      cache_key_group         = "coingecko" # optional, default value is set to adapter's name
      log_level               = "info" # optional, default to "info"
      alarms_disabled         = "false" # optional, default to "false"

      # Optional block for secret environment variables required by the adapter
      # For each secret variable, AWS Secrets Manager object and its value will be created
      # It's possible to leave value as an empty string, in this case only AWS Secrets Manager object
      #   will be created. Then you need to set the value for this object manually using AWS web console
      #   or CLI. In this case value of the secret variable won't be stored in terraform state files.
      ea_secret_variables = {
        API_KEY = "api_key_value"
      }

      # Optional block for any specific anvironment variables required by adapter
      ea_specific_variables = {
        SPECIFIC_ENV_VAR_KEY_1 = "SPECIFIC_ENV_VAR_VALUE_1"
        SPECIFIC_ENV_VAR_KEY_2 = "SPECIFIC_ENV_VAR_VALUE_2"
      }
    }
  }
}
```

List of Chainlink EA's supported environment variables that could be specified using `external_adapters` variable.
  - `version`: **required**, defines version of docker image from [adapter's ECR public repo](https://gallery.ecr.aws/chainlink/adapters/{adapter_name}-adapter)
  - `rate_limit_enabled`: optional, defines `RATE_LIMIT_ENABLES` from [default vars list](https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/core/bootstrap#server-configuration). Defaults to `true`
  - `rate_limit_api_provider`: optional, defines `RATE_LIMIT_API_PROVIDER` from [default vars list](https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/core/bootstrap#server-configuration). Defaults to EA's name
  - `rate_limit_api_tier`: optional, defines `RATE_LIMIT_API_TIER` from [default vars list](https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/core/bootstrap#server-configuration). Defaults to `""`
  - `ea_port`: oprional, defines `EA_PORT` from [default vars list](https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/core/bootstrap#server-configuration). Defaults to `8080`
  - `alb_port`: **required**, defines port on which ALB target group will listen requests from ALB. This port then should be specified in `Bridges` tab of Chainlink Node
  - `health_path`: optional, defines path on which ALB target group will check EA's health. Defaults to `/health`
  - `cpu`: optional, defines allocated CPU for EA. Defaults to `256`
  - `memory`: optional, defines allocated Memory for EA. Defaults to `512`
  - `cache_enabled`: optional, defines `CACHE_ENABLED` from [default vars list](https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/core/bootstrap#server-configuration). Defaults to `true`
  - `cache_type`: optional, defines what type of cache should be used for EA. Available options are `local` and `redis`. Defaults to `local`. To use `redis` it's also necessary to set `cache_redis` terraform variable to `true`
  - `cache_key_group`: optional, defines `CACHE_KEY_GROUP` from [default vars list](https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/core/bootstrap#server-configuration). Defaults to EA's name
  - `log_level`: optional, defines `LOG_LEVEL` from [default vars list](https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/core/bootstrap#server-configuration). Defaults to `info`
  - `alarms_disabled`: optional, defines whether alarm action items should be executed or not for a specific external adapter. Could be helpful during planned maintenance. Defaults to `false`

Any other specific or non-default variable could be set using `ea_specific_variables` variable in `external_adapters` block. Please check available options [here](https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/core/bootstrap#server-configuration) and usage examples in examples directory.

For any secret variable please use `ea_secret_variables` variable in `external_adapters` block. Please check examples in examples directory.

## Notes

### AWS Secrets Manager

AWS Secrets Manager is used to keep all secret values required for an External Adapter.

#### AWS SM without storing secrets in terraform state in plain text (!OPTIONAL)

There is an ability to create empty AWS Secrets Manager objects that will be connected to ECS Fargate task. This action will prevent storing secrets in terraform state files in plain text.

The list of required actions:
  - Leave all secret variables veriables in `ea_secret_variables` with an empty string like `""`. Check an exhausive example in .examples/basic_secrets folder.
  - Run `terraform apply`
  - Manually update created AWS SM objects (using AWS Console/CLI/etc.)
  - Restart related External Adapters in ECS (using AWS Console/CLI/etc.) to update them with new values from AWS SM objects.

#### Additional (non default) secrets required for an External Adapter

In most cases all External adapters are needed to store only API_KEY environment variable in AWS SM.

Sometimes, an External Adapter like [bank-frick](https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/bank-frick) is required more sensetive variables than just API_KEY. In this case, it's possible to include all required values in `ea_secret_variables` block in `external_adapters` variable.

Check an exhausive example in .examples/basic_secrets folder.

### Usage of custom task definition file (when default template is not enough)

There is an ability to customize environement variables and task definition for each external adaptes.

The list of required actions:
  - Set `custom` parameter equals to `true` in `external_adapters` module variable.
  - Add custom task definition template to ./ea_task_definitions/{custom_ea}.json.tpl
  - run `terraform apply`

## Examples

- [Basic example with local cache](./examples/basic_local_cache/main.tf)
- [Complete example with MemoryDB](./examples/complete_memorydb_redis/main.tf)
- [Basic example with AWS SM usage](./examples/basic_specific_secrets/main.tf)

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
| <a name="provider_external"></a> [external](#provider\_external) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ea_secrets"></a> [ea\_secrets](#module\_ea\_secrets) | ./modules/ea_secrets | n/a |

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
| [external_external.latest_version](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | AWS account id. Used to add alarms to dashboard | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region (required for CloudWatch logs configuration) | `string` | n/a | yes |
| <a name="input_cache_redis"></a> [cache\_redis](#input\_cache\_redis) | Defines which cache type should be used. Options: local or redis. false means that local cache type should be used for each external adapter. It's possible to use different cache type for different external adapters. To do so set this variable to true to use redis cache by default. Then for specific external adapters set `cache_type` to `local` using `external_adapters` terraform variable | `string` | `false` | no |
| <a name="input_ea_desired_task_count"></a> [ea\_desired\_task\_count](#input\_ea\_desired\_task\_count) | Number of instances of the task definition to place and keep running | `number` | `1` | no |
| <a name="input_elb_alarms_enabled"></a> [elb\_alarms\_enabled](#input\_elb\_alarms\_enabled) | Defines whether to create CloudWatch alarms of 4XX and 5XX status codes on ALB or not. Alarms will be created only if `monitoring_enabled` variable is set to `true` | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | `"nonprod"` | no |
| <a name="input_external_adapters"></a> [external\_adapters](#input\_external\_adapters) | Map of external adapters that needs to be deployed. See example in ./examples/complete\_memorydb\_redis | `any` | `{}` | no |
| <a name="input_memorydb_node_type"></a> [memorydb\_node\_type](#input\_memorydb\_node\_type) | The compute and memory capacity of the nodes in the cluster | `string` | `"db.t4g.small"` | no |
| <a name="input_memorydb_num_replicas_per_shard"></a> [memorydb\_num\_replicas\_per\_shard](#input\_memorydb\_num\_replicas\_per\_shard) | The number of replicas to apply to each shard, up to a maximum of 5 | `number` | `0` | no |
| <a name="input_memorydb_shards_count"></a> [memorydb\_shards\_count](#input\_memorydb\_shards\_count) | The number of shards in the cluster | `number` | `1` | no |
| <a name="input_memorydb_snapshot_retention_limit"></a> [memorydb\_snapshot\_retention\_limit](#input\_memorydb\_snapshot\_retention\_limit) | The number of days for which MemoryDB retains automatic snapshots before deleting them. When set to 0, automatic backups are disabled | `number` | `0` | no |
| <a name="input_monitoring_enabled"></a> [monitoring\_enabled](#input\_monitoring\_enabled) | Defines whether to create CloudWatch dashboard and custom metrics or not | `bool` | `true` | no |
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | n/a | yes |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | SNS topic arn for alerts. If not specified, module will create an empty topic and provide topic arn in the output. Then it will be possible to specify required notification method for this topic | `string` | `""` | no |
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
