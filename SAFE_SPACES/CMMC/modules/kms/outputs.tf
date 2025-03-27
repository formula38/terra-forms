####################################
# modules/kms/outputs.tf
####################################

output "kms_key_id" {
  description = "The ID of the KMS key"
  value       = aws_kms_key.cmmc_kms.key_id
}

output "kms_key_arn" {
  description = "The ARN of the KMS key"
  value       = aws_kms_key.cmmc_kms.arn
}
