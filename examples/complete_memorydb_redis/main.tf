provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      Environment = "nonprod"
      Project     = "example"
      Chains      = "Ethereum"
      TF_MANAGED  = "true"
      TF_SERVICE  = "chainlink_ea"
    }
  }
}

data "aws_caller_identity" "current" {}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
}

module "chainlink_ea" {
  source = "../../."

  project             = "example"
  environment         = "nonprod"
  aws_region          = "eu-west-1"
  aws_account_id      = data.aws_caller_identity.current.account_id
  vpc_id              = module.vpc.vpc_id
  vpc_public_subnets  = module.vpc.public_subnets
  vpc_private_subnets = module.vpc.private_subnets

  cache_redis = true

  external_adapters = {
    coingecko = {
      # source code:  https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/coingecko
      # subscription: https://github.com/smartcontractkit/external-adapters-js/blob/develop/packages/sources/coingecko/src/config/limits.json
      version                 = "1.6.7"     # optional, if not specified the module will find the latest version from public AWS ECR
      rate_limit_enabled      = "true"      # optional, defaults to "true"
      rate_limit_api_tier     = "analyst"   # optional, Rate limiting tier to use from the available options for the adapter. If not present, the adapter will run using the first tier on the list.
      rate_limit_api_provider = "coingecko" # optional, default value is set to adapter's name
      ea_port                 = "8080"      # optional, defaults to "8080"
      health_path             = "/health"   # optional, defaults to "/health"
      cpu                     = 256         # optional, defaults to "256"
      memory                  = 512         # optional, defaults to "512"
      cache_enabled           = "true"      # optional, defaults to "true"
      cache_type              = "redis"     # optional, default to "local"
      cache_key_group         = "coingecko" # optional, default value is set to adapter's name
      log_level               = "info"      # optional, default to "info"
      alarms_disabled         = "false"     # optional, default to "false", global monitoring variable should be true

      # Optional block for secret environment variables required by the adapter
      # For each secret variable, AWS Secrets Manager object and its value will be created
      # It's possible to leave value as an empty string, in this case only AWS Secrets Manager object
      #   will be created. Then you need to set the value for this object manually using AWS web console
      #   or CLI. In this case value of the secret variable won't be stored in terraform state files.
      ea_secret_variables = {
        API_KEY = "API_KEY_VALUE" # https://www.coingecko.com/en/developers/dashboard
      }

      # Optional block for any specific anvironment variables required by adapter
      ea_specific_variables = {
        SPECIFIC_VAR_KEY_1 = "SPECIFIC_VAR_VALUE_1",
        SPECIFIC_VAR_KEY_1 = "SPECIFIC_VAR_VALUE_2"
      }
    }
  }
}

resource "aws_security_group_rule" "allow_all" {
  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow all traffic"

  security_group_id = module.chainlink_ea.alb_security_group_id
}