output "data_bucket_id" {
  description = "ID of the data bucket"
  value       = aws_s3_bucket.cmmc_data_bucket.id
}

output "log_bucket_id" {
  description = "ID of the log bucket"
  value       = aws_s3_bucket.cmmc_log_bucket.id
}

output "data_bucket_name" {
  description = "Name of the data bucket"
  value       = aws_s3_bucket.data.id
}

output "log_bucket_name" {
  description = "Name of the log bucket"
  value       = aws_s3_bucket.logs.id
}

output "data_bucket_arn" {
  description = "ARN of the data bucket"
  value       = aws_s3_bucket.data.arn
}
