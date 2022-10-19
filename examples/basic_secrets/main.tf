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
      version     = "1.6.7"
      api_tier    = "analyst"
      alb_port    = "1113"
      ea_secret_variables = {
        API_KEY        = "API_KEY_VALUE" # Value of AWS SM object will be set to "API_KEY_VALUE"
        SECRET_VAR_KEY = "SECRET_VAR_VALUE" # Value of AWS SM object will be set to "SECRET_VAR_VALUE"
      }
    }
    bank-frick = {
      version  = "0.0.7"
      api_tier = "production"
      alb_port = "1182"
      ea_specific_variables = {
        PAGE_SIZE    = "500"
        API_ENDPOINT = "API_ENDPOINT_VALUE"
      }
      ea_secret_variables = {
        API_KEY     = "" # If leave an empty string, value of AWS SM object won't be set. You'll need to set a value manually
        PRIVATE_KEY = "" # If leave an empty string, value of AWS SM object won't be set. You'll need to set a value manually
      }
    }
  }
}
