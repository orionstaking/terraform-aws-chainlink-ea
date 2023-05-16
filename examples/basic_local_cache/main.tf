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

  external_adapters = {
    coingecko = {
      ea_secret_variables = {
        API_KEY = "API_KEY_VALUE" # https://www.coingecko.com/en/developers/dashboard
      }
    }
    tiingo = {
      ea_secret_variables = {
        API_KEY = "API_KEY_VALUE" # https://api.tiingo.com/account/profile
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
