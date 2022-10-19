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

  project     = "example"
  environment = "nonprod"

  aws_region     = "eu-west-1"
  aws_account_id = data.aws_caller_identity.current.account_id

  vpc_id              = module.vpc.vpc_id
  vpc_cidr_block      = module.vpc.vpc_cidr_block
  vpc_private_subnets = module.vpc.private_subnets

  external_adapters = {
    coingecko = {
      # source code:  https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/coingecko
      # subscription: https://github.com/smartcontractkit/external-adapters-js/blob/develop/packages/sources/coingecko/src/config/limits.json
      version                 = "1.6.7" # https://gallery.ecr.aws/chainlink/adapters/coingecko-adapter
      rate_limit_enabled      = "true"
      rate_limit_api_tier     = "analyst"
      rate_limit_api_provider = "coingecko"
      ea_port                 = "8080"
      alb_port                = "1113"
      health_path             = "/health"
      cpu                     = 256
      memory                  = 512
      cache_enabled           = "true"
      cache_type              = "local"
      cache_key_group         = "coingecko"
      log_level               = "info"
      ea_secret_variables = {
        API_KEY = "API_KEY_VALUE" # https://www.coingecko.com/en/developers/dashboard
      }
      ea_specific_variables = {
        SPECIFIC_VAR_KEY_1 = "SPECIFIC_VAR_VALUE_1",
        SPECIFIC_VAR_KEY_1 = "SPECIFIC_VAR_VALUE_2"
      }
    }
  }
}
