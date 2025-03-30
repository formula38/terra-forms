variable "name_prefix" {
  description = "Prefix to use for resource names"
  type        = string
}

variable "data_bucket_name" {
  description = "Name of the data S3 bucket"
  type        = string
}

variable "log_bucket_name" {
  description = "Name of the log S3 bucket"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for bucket encryption"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

variable "s3_acl" {
  description = "The ACL to apply to the S3 buckets"
  type        = string
  default     = "private"
}

variable "sse_algorithm" {
  description = "The server-side encryption algorithm for S3 buckets"
  type        = string
  default     = "aws:kms"
}

