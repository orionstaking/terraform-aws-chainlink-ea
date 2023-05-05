terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.40.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.2.3"
    }
  }
}
