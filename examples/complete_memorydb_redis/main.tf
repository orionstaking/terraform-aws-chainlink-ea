provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      Environment = "nonprod"
      Project     = "example"
      Chains      = "Ethereum"
      TF_MANAGED  = "true"
      TF_VERSION  = "1.1.7"
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
      version     = "1.6.7",
      api_tier    = "analyst",
      alb_port    = "1113",
      api_key     = "api_key",
      cpu         = 256,
      memory      = 512,
      log_level   = "info",
      health_path = "/health",
      timeout     = "30000"
      # full list in main README.md
    },
    tiingo = {
      version  = "1.10.7",
      api_tier = "power",
      alb_port = "1134",
      api_key  = "api_key"
    },
    coinmarketcap = {
      version  = "1.3.39",
      api_tier = "startup",
      alb_port = "1115",
      api_key  = "api_key"
    },
    cryptocompare = {
      version  = "1.3.26",
      api_tier = "professional",
      alb_port = "1114",
      api_key  = "api_key"
    }
  }
}
