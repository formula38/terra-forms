terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }

  backend "s3" {
    bucket         = "www.coldchainsecure.com"
    key            = "terraform/state/cmmc.tfstate"
    region         = "us-west-1"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}

provider "random" {}

data "aws_caller_identity" "current" {}

