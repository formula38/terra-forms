module "networking" {
  source           = "./modules/networking"
  vpc_cidr         = "10.0.0.0/16"
  vpc_name         = "cmmc-vpc"
  region           = var.region
  environment      = var.environment
  trusted_ip_range = var.trusted_ip_range
}

module "logging" {
  source          = "./modules/logging"
  vpc_id          = module.networking.vpc_id
  flow_log_bucket = "cmmc-flow-logs-${module.networking.random_suffix}"
  region          = var.region
}

module "kms" {
  source     = "./modules/kms"
  region     = var.region
  account_id = data.aws_caller_identity.current.account_id
}

module "s3" {
  source           = "./modules/s3"
  data_bucket_name = "cmmc-data-${random_string.bucket_suffix.result}"
  log_bucket_name  = "cmmc-logs-${random_string.bucket_suffix.result}"
  kms_key_arn      = module.kms.kms_key_arn
}

module "compute" {
  source             = "./modules/compute"
  name_prefix        = "cmmc"
  security_group_ids = [module.networking.sg_id]
  kms_key_arn        = module.kms.kms_key_arn
  data_bucket_arn    = module.s3.data_bucket_arn
  ami_id             = var.ami_id
  environment        = var.environment
  subnet_id          = module.networking.subnet_a_id
}

module "rds" {
  source              = "./modules/rds"
  name_prefix         = "cmmc"
  db_username         = var.db_username
  db_password         = var.db_password
  subnet_ids          = module.networking.subnet_ids
  db_subnet_group     = module.networking.db_subnet_group
  kms_key_id          = module.kms.kms_key_id
  security_group_ids  = [module.networking.sg_id]
  environment         = var.environment
}

module "config" {
  source          = "./modules/config"
  log_bucket_name = module.s3.log_bucket
  name_prefix     = "cmmc"
}

