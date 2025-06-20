terraform {
  backend "s3" {
    bucket         = "www.coldchainsecure.com"
    key            = "terraform/plans/cmmc.tfstate"
    region         = "us-west-1"
    encrypt        = true
  }
}
