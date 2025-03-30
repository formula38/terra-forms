# ============================
# Networking Module Outputs
# ============================

output "vpc_id" {
  value = module.networking.vpc_id
}

output "subnet_ids" {
  value = module.networking.subnet_ids
}

output "subnet_a_id" {
  value = module.networking.subnet_a_id
}

output "subnet_b_id" {
  value = module.networking.subnet_b_id
}

output "security_group_id" {
  value = module.networking.security_group_id
}

# ============================
# KMS Module Outputs
# ============================

output "kms_key_id" {
  value = module.kms.kms_key_id
}

output "kms_key_arn" {
  value = module.kms.kms_key_arn
}

# ============================
# S3 Module Outputs
# ============================

output "data_bucket_name" {
  value = module.s3.data_bucket_name
}

output "log_bucket_name" {
  value = module.s3.log_bucket_name
}

# ============================
# Compute Module Outputs
# ============================

output "ec2_instance_id" {
  value = module.compute.instance_id
}

output "ec2_public_ip" {
  value = module.compute.public_ip
}

# ============================
# RDS Module Outputs
# ============================

output "rds_endpoint" {
  value = module.rds.db_endpoint
}

output "rds_instance_id" {
  value = module.rds.db_instance_id
}

# ============================
# Config Module Outputs
# ============================

output "aws_config_recorder_name" {
  value = module.config.config_recorder_name
}

output "aws_config_delivery_channel" {
  value = module.config.config_delivery_channel
}
