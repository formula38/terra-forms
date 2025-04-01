# =======================================
# AWS CMMC-Compliant Infrastructure Entry
# =======================================


# =======================
# 🧠 NETWORKING MODULE
# =======================
module "networking" {
  source                       = "./modules/networking"
  vpc_cidr                     = var.vpc_cidr
  vpc_name                     = var.vpc_name
  region                       = var.region
  availability_zone_a          = var.availability_zone_a
  availability_zone_b          = var.availability_zone_b
  route_cidr_block             = var.route_cidr_block
  subnet_cidr_a                = var.subnet_cidr_a
  subnet_cidr_b                = var.subnet_cidr_b
  trusted_ip_range             = var.trusted_ip_range
  environment                  = var.environment
  security_group_ingress_rules = var.security_group_ingress_rules
  security_group_egress_rules  = var.security_group_egress_rules

  common_tags = local.common_tags
}


# =======================
# 📊 LOGGING MODULE
# =======================
module "logging" {
  source              = "./modules/logging"
  name_prefix         = var.name_prefix
  vpc_id              = module.networking.vpc_id
  retention_in_days   = var.retention_in_days
  flow_log_group_arn  = module.logging.flow_log_group_arn
  environment         = var.environment
  flow_log_group_name = var.flow_log_group_name
  flow_log_role_name  = var.flow_log_role_name

  common_tags = local.common_tags
}

# =======================
# 🔐 KMS ENCRYPTION MODULE
# =======================
module "kms" {
  source      = "./modules/kms"
  name_prefix = var.name_prefix
  account_id  = data.aws_caller_identity.current.account_id
  environment = var.environment

  common_tags = local.common_tags
}

# =======================
# 📦 S3 MODULE
# =======================
module "s3" {
  source           = "./modules/s3"
  name_prefix      = var.name_prefix
  account_id       = data.aws_caller_identity.current.account_id
  data_bucket_name = var.data_bucket_name
  log_bucket_name  = var.log_bucket_name
  kms_key_arn      = module.kms.kms_key_arn
  s3_acl           = var.s3_acl
  sse_algorithm    = var.sse_algorithm

  common_tags = local.common_tags
}

# =======================
# 📦 CLOUDFRONT MODULE
# =======================
module "cloudfront" {
  source                         = "./modules/cloudfront"
  name_prefix                    = var.name_prefix
  origin_bucket_name             = "${var.data_bucket_name}.s3.${var.region}.amazonaws.com"
  cloudfront_domain_aliases      = var.cloudfront_domain_aliases
  cloudfront_waf_web_acl_id      = var.cloudfront_waf_web_acl_id
  cloudfront_acm_certificate_arn = module.acm.acm_certificate_arn

  common_tags = local.common_tags
}

# =======================
# 📦 ROUTE53 MODULE
# =======================
module "route53" {
  source            = "./modules/route53"
  domain_name       = var.cloudfront_domain_aliases[0]
  use_existing_zone = var.use_existing_route53
}

# =======================
# 📦 ACM MODULE
# =======================
module "acm" {
  source                    = "./modules/acm"
  domain_name               = var.cloudfront_domain_aliases[0]
  subject_alternative_names = var.cloudfront_domain_aliases
  route53_zone_id           = module.route53.zone_id

  common_tags = local.common_tags
}

# =======================
# 📦 WAF MODULE
# =======================
module "waf" {
  source = "./modules/waf"

  common_tags = local.common_tags
}

# =======================
# 🖥️ EC2 COMPUTE MODULE
# =======================
module "compute" {
  source             = "./modules/compute"
  name_prefix        = var.name_prefix
  ami_id             = var.ami_id
  instance_type      = var.instance_type
  ebs_device_name    = var.ebs_device_name
  environment        = var.environment
  subnet_id          = module.networking.subnet_a_id
  security_group_ids = [module.networking.security_group_id]
  kms_key_arn        = module.kms.kms_key_arn
  data_bucket_arn    = module.s3.data_bucket_arn

  common_tags = local.common_tags
}

# =======================
# 🛢️ RDS POSTGRES MODULE
# =======================
module "rds" {
  source              = "./modules/rds"
  name_prefix         = var.name_prefix
  db_username         = var.db_username
  db_password         = var.db_password
  engine              = var.engine
  engine_version      = var.engine_version
  instance_class      = var.instance_class
  allocated_storage   = var.allocated_storage
  storage_encrypted   = var.storage_encrypted
  skip_final_snapshot = var.skip_final_snapshot
  subnet_ids          = module.networking.subnet_ids
  kms_key_id          = module.kms.kms_key_id
  security_group_ids  = [module.networking.security_group_id]
  environment         = var.environment

  common_tags = local.common_tags
}

# =======================
# 🧾 AWS CONFIG MODULE
# =======================
module "config" {
  source          = "./modules/config"
  name_prefix     = var.name_prefix
  log_bucket_name = var.log_bucket_name
  log_bucket_arn  = module.s3.log_bucket_arn
}

# =======================
# 🧾 AWS Cloudtrail MODULE
# =======================
module "cloudtrail" {
  source          = "./modules/cloudtrail"
  name_prefix     = var.name_prefix
  log_bucket_name = var.log_bucket_name
  kms_key_id      = module.kms.kms_key_id
  common_tags     = local.common_tags
}

# ====================
# Global
# ====================

locals {
  created_on = formatdate("YYYY-MM-DD", timestamp())
  common_tags = {
    Name        = var.name_prefix
    Environment = var.environment
    CreatedBy   = var.created_by
    CreatedOn   = local.created_on
    project     = var.project
    owner       = var.owner
    cost_center = var.cost_center
  }
}
