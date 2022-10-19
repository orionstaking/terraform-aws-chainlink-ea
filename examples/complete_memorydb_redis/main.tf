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

  cache_redis = true

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
      cache_type              = "redis"
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
    tiingo = {
      # source code:  https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/tiingo
      # subscription: https://github.com/smartcontractkit/external-adapters-js/blob/develop/packages/sources/tiingo/src/config/limits.json
      version             = "1.10.7" # https://gallery.ecr.aws/chainlink/adapters/tiingo-adapter
      rate_limit_api_tier = "power"
      alb_port            = "1134"
      ea_secret_variables = {
        API_KEY = "API_KEY_VALUE" # https://api.tiingo.com/account/profile
      }
    }
    coinmarketcap = {
      # source code:  https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/coinmarketcap
      # subscription: https://github.com/smartcontractkit/external-adapters-js/blob/develop/packages/sources/coinmarketcap/src/config/limits.json
      version             = "1.3.39" # https://gallery.ecr.aws/chainlink/adapters/coinmarketcap-adapter
      rate_limit_api_tier = "startup"
      alb_port            = "1115"
      ea_secret_variables = {
        API_KEY = "API_KEY_VALUE" # https://pro.coinmarketcap.com/account
      }
    }
    cryptocompare = {
      # source code:  https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/cryptocompare
      # subscription: https://github.com/smartcontractkit/external-adapters-js/blob/develop/packages/sources/cryptocompare/src/config/limits.json
      version             = "1.3.26" # https://gallery.ecr.aws/chainlink/adapters/cryptocompare-adapter
      rate_limit_api_tier = "professional"
      alb_port            = "1114"
      ea_secret_variables = {
        API_KEY = "API_KEY_VALUE" # https://www.cryptocompare.com/cryptopian/api-keys
      }
    }
    alphavantage = {
      # source code:  https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/alphavantage
      # subscription: https://github.com/smartcontractkit/external-adapters-js/blob/develop/packages/sources/alphavantage/src/config/limits.json
      version             = "1.1.39" # https://gallery.ecr.aws/chainlink/adapters/alphavantage-adapter
      rate_limit_api_tier = "free"
      alb_port            = "1152"
      ea_secret_variables = {
        API_KEY = "API_KEY_VALUE" # https://www.alphavantage.co/support/#api-key
      }
    }
    coinpaprika = {
      # source code:  https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/coinpaprika
      # subscription: https://github.com/smartcontractkit/external-adapters-js/blob/develop/packages/sources/coinpaprika/src/config/limits.json
      version             = "1.8.10" # https://gallery.ecr.aws/chainlink/adapters/coinpaprika-adapter
      rate_limit_api_tier = "free"
      alb_port            = "1116"
      ea_secret_variables = {
        API_KEY = "API_KEY_VALUE" # https://coinpaprika.com/api/panel/
      }
    }
    coinapi = {
      # source code:  https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/coinapi
      # subscription: https://github.com/smartcontractkit/external-adapters-js/blob/develop/packages/sources/coinapi/src/config/limits.json
      version             = "1.1.41" # https://gallery.ecr.aws/chainlink/adapters/coinapi-adapter
      rate_limit_api_tier = "free"
      alb_port            = "1112"
      ea_secret_variables = {
        API_KEY = "API_KEY_VALUE" # https://www.coinapi.io/Account/GetCode
      }
    }
    fixer = {
      # source code:  https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/fixer
      # subscription: https://github.com/smartcontractkit/external-adapters-js/blob/develop/packages/sources/fixer/src/config/limits.json
      version             = "1.3.38" # https://gallery.ecr.aws/chainlink/adapters/fixer-adapter
      rate_limit_api_tier = "free"
      alb_port            = "1130"
      ea_secret_variables = {
        API_KEY = "API_KEY_VALUE" # https://fixer.io/
      }
    }
    currencylayer = {
      # source code:  https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/currencylayer
      # subscription: https://github.com/smartcontractkit/external-adapters-js/blob/develop/packages/sources/currencylayer/src/config/limits.json
      version             = "1.3.38" # https://gallery.ecr.aws/chainlink/adapters/currencylayer-adapter
      rate_limit_api_tier = "free"
      alb_port            = "1141"
      ea_secret_variables = {
        API_KEY = "API_KEY_VALUE" # https://currencylayer.com/product
      }
    }
    unibit = {
      # source code:  https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/unibit
      # subscription: https://github.com/smartcontractkit/external-adapters-js/blob/develop/packages/sources/unibit/src/config/limits.json
      version             = "1.3.35" # https://gallery.ecr.aws/chainlink/adapters/unibit-adapter
      rate_limit_api_tier = "freetrial"
      alb_port            = "1143"
      ea_secret_variables = {
        API_KEY = "API_KEY_VALUE" # https://unibit.ai/signin
      }
    }
    bitex = {
      # source code:  https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/bitex
      # subscription: https://github.com/smartcontractkit/external-adapters-js/blob/develop/packages/sources/bitex/src/config/limits.json
      version             = "1.3.40" # https://gallery.ecr.aws/chainlink/adapters/bitrex-adapter
      rate_limit_api_tier = "free"
      alb_port            = "1191"
      ea_secret_variables = {
        API_KEY = "API_KEY_VALUE" # https://sandbox.bitex.la/
      }
    }
    intrinio = {
      # source code:  https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/intrinio
      # subscription: https://github.com/smartcontractkit/external-adapters-js/blob/develop/packages/sources/intrinio/src/config/limits.json
      version             = "1.2.18" # https://gallery.ecr.aws/chainlink/adapters/intrinio-adapter
      rate_limit_api_tier = "bronze"
      alb_port            = "1192"
      ea_secret_variables = {
        API_KEY = "API_KEY_VALUE" # https://account.intrinio.com/account/api_keys/keys
      }
    }
    nomics = {
      # source code:  https://github.com/smartcontractkit/external-adapters-js/tree/develop/packages/sources/nomics
      # subscription: https://github.com/smartcontractkit/external-adapters-js/blob/develop/packages/sources/nomics/src/config/limits.json
      version             = "1.2.11" # https://gallery.ecr.aws/chainlink/adapters/nomics-adapter
      rate_limit_api_tier = "free"
      alb_port            = "1111"
      ea_secret_variables = {
        API_KEY = "API_KEY_VALUE" # https://p.nomics.com/pricing#free-plan
      }
    }
  }
}
