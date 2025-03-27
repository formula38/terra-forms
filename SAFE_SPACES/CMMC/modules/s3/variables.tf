variable "data_bucket_name" {
  description = "Name of the S3 bucket for data storage"
  type        = string
}

variable "log_bucket_name" {
  description = "Name of the S3 bucket for log storage"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encryption"
  type        = string
}
