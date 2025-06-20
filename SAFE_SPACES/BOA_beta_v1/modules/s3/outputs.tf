output "data_bucket_id" {
  description = "ID of the S3 data bucket"
  value       = aws_s3_bucket.data.id
}

output "data_bucket_arn" {
  description = "ARN of the S3 data bucket"
  value       = aws_s3_bucket.data.arn
}

output "log_bucket_id" {
  description = "ID of the S3 log bucket"
  value       = aws_s3_bucket.logs.id
}

output "log_bucket_arn" {
  description = "ARN of the S3 log bucket"
  value       = aws_s3_bucket.logs.arn
}

output "data_bucket_name" {
  description = "Name of the data S3 bucket"
  value       = aws_s3_bucket.data.bucket
}

output "log_bucket_name" {
  description = "Name of the S3 bucket for AWS Config delivery"
  value       = aws_s3_bucket.logs.bucket
}
