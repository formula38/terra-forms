output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_subnet_ids" {
  value = module.networking.subnet_ids
}

output "kms_key_id" {
  value = module.kms.kms_key_id
}

output "ec2_instance_id" {
  value = module.compute.instance_id
}

output "rds_instance_id" {
  value = module.rds.db_instance_id
}

output "config_recorder_name" {
  value = module.config.config_recorder_name
}

# Fix to:
output "s3_data_bucket" {
  value = module.s3.data_bucket_name
}

output "s3_log_bucket" {
  value = module.s3.log_bucket_name
}
