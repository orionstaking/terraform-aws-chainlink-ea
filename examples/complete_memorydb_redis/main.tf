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
      # https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/coingecko
      version       = "1.6.7", # https://gallery.ecr.aws/chainlink/adapters/coingecko-adapter
      api_tier_http = "analyst",
      alb_port      = "1113",
      api_key       = "api_key", # https://www.coingecko.com/en/developers/dashboard
      cpu           = 256,
      memory        = 512,
      log_level     = "info",
      health_path   = "/health",
      timeout       = "30000"
      # full list in main README.md
    },
    tiingo = {
      # https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/tiingo
      version       = "1.10.7", # https://gallery.ecr.aws/chainlink/adapters/tiingo-adapter
      api_tier_http = "power",
      alb_port      = "1134",
      api_key       = "api_key" # https://api.tiingo.com/account/profile
    },
    coinmarketcap = {
      # https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/coinmarketcap
      version       = "1.3.39", # https://gallery.ecr.aws/chainlink/adapters/coinmarketcap-adapter
      api_tier_http = "startup",
      alb_port      = "1115",
      api_key       = "api_key" # https://pro.coinmarketcap.com/account
    },
    cryptocompare = {
      # https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/cryptocompare
      version       = "1.3.26", # https://gallery.ecr.aws/chainlink/adapters/cryptocompare-adapter
      api_tier_http = "professional",
      alb_port      = "1114",
      api_key       = "api_key" # https://www.cryptocompare.com/cryptopian/api-keys
    },
    alphavantage = {
      # https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/alphavantage
      version       = "1.1.39", # https://gallery.ecr.aws/chainlink/adapters/alphavantage-adapter
      api_tier_http = "free",
      alb_port      = "1152",
      api_key       = "api_key" # https://www.alphavantage.co/support/#api-key
    },
    coinpaprika = {
      # https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/coinpaprika
      version       = "1.8.10", # https://gallery.ecr.aws/chainlink/adapters/coinpaprika-adapter
      api_tier_http = "free",
      alb_port      = "1116",
      api_key       = "api_key" # https://coinpaprika.com/api/panel/
    },
    coinapi = {
      # https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/coinapi
      version       = "1.1.41", # https://gallery.ecr.aws/chainlink/adapters/coinapi-adapter
      api_tier_http = "free",
      alb_port      = "1112",
      api_key       = "api_key" # https://www.coinapi.io/Account/GetCode
      ws_enabled    = true
    },
    fixer = {
      # https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/fixer
      version       = "1.3.38", # https://gallery.ecr.aws/chainlink/adapters/fixer-adapter
      api_tier_http = "free",
      alb_port      = "1130",
      api_key       = "api_key" # https://fixer.io/
    },
    currencylayer = {
      # https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/currencylayer
      version       = "1.3.38", # https://gallery.ecr.aws/chainlink/adapters/currencylayer-adapter
      api_tier_http = "free",
      alb_port      = "1141",
      api_key       = "api_key" # https://fixer.io/
    },
    unibit = {
      # https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/unibit
      version       = "1.3.35", # https://gallery.ecr.aws/chainlink/adapters/unibit-adapter
      api_tier_http = "freetrial",
      alb_port      = "1143",
      api_key       = "api_key" # https://unibit.ai/signin
    },
    bitex = {
      # https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/bitex
      version       = "1.3.40", # https://gallery.ecr.aws/chainlink/adapters/bitrex-adapter
      api_tier_http = "free",
      alb_port      = "1191",
      api_key       = "" # https://sandbox.bitex.la/
    },
    intrinio = {
      # https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/intrinio
      version       = "1.2.18", # https://gallery.ecr.aws/chainlink/adapters/intrinio-adapter
      api_tier_http = "bronze",
      alb_port      = "1192",
      api_key       = "api_key" # https://account.intrinio.com/account/api_keys/keys
    },
    nomics = {
      # https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/nomics
      version       = "1.2.11", # https://gallery.ecr.aws/chainlink/adapters/nomics-adapter
      api_tier_http = "free",
      alb_port      = "1111",
      api_key       = "api_key" # https://p.nomics.com/pricing#free-plan
    }
  }
}
