variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "nonprod"
}

variable "aws_region" {
  description = "AWS Region (required for CloudWatch logs configuration)"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account id. Used to add alarms to dashboard"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where Chainlink EAs should be deployed"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  type        = string
}

variable "vpc_private_subnets" {
  description = "VPC private subnets where Chainlink EAs should be deployed (at least 2)"
  type        = list(any)
}

variable "external_adapters" {
  description = "Map of external adapters that needs to be deployed. See example in ./examples/complete_memorydb_redis"
  default     = {}
  type        = any
}

variable "tfstate_secrets_store" {
  description = "Defines whether to store EA's secrets in plane text in terraform store or not. If 'true', secrets for EA should be specified in external_adapters var. If 'false', it is recommended to run the module with 'initialize' variabe equals to 'true' to set the secrets manually in AWS Secrets Manager"
  default     = true
  type        = bool
}

variable "secret_objects_only" {
  description = "If 'true' and 'tfstate_secrets_store' is 'false', 'terraform apply' will create only AWS Secrets Manager objects to store API keys for EA's. Once all required secrets will be set manually, set this var to 'true' to create remaining AWS infra to run EA's"
  default     = false
  type        = bool
}

variable "ea_desired_task_count" {
  description = "Number of instances of the task definition to place and keep running"
  default     = 1
  type        = number
}

variable "cache_redis" {
  description = "Defines which cache type should be used. Options: local or redis. false means that local cache type should be used for each external adapter. It's possible to use different cache type for different external adapters. To do so set this variable to true to use redis cache by default. Then for specific external adapters set `cache_type` to `local` using `external_adapters` terraform variable"
  default     = false
  type        = string
}

variable "memorydb_node_type" {
  description = "The compute and memory capacity of the nodes in the cluster"
  default     = "db.t4g.small"
  type        = string
}

variable "memorydb_shards_count" {
  description = "The number of shards in the cluster"
  default     = 1
  type        = number
}

variable "memorydb_snapshot_retention_limit" {
  description = "The number of days for which MemoryDB retains automatic snapshots before deleting them. When set to 0, automatic backups are disabled"
  default     = 0
  type        = number
}

variable "memorydb_num_replicas_per_shard" {
  description = "The number of replicas to apply to each shard, up to a maximum of 5"
  default     = 0
  type        = number
}

variable "monitoring_enabled" {
  description = "Defines whether to create CloudWatch dashboard and custom metrics or not"
  default     = true
  type        = bool
}

variable "sns_topic_arn" {
  description = "SNS topic arn for alerts. If not specified, module will create an empty topic and provide topic arn in the output. Then it will be possible to specify required notification method for this topic"
  default     = ""
  type        = string
}
