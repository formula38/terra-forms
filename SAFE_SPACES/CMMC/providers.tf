terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }

  backend "s3" {
    bucket       = "www.coldchainsecure.com"
    key          = "terraform/state/cmmc.tfstate"
    region       = "us-west-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}
