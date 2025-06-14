output "kms_key_id" {
  description = "KMS Key ID"
  value       = aws_kms_key.cmmc_kms.key_id
}

output "kms_key_arn" {
  description = "KMS Key ARN"
  value       = aws_kms_key.cmmc_kms.arn
}
