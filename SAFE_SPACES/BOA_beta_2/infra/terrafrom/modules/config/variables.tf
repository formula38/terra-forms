variable "log_bucket_name" {
  description = "Name of the S3 bucket for AWS Config delivery"
  type        = string
}

variable "log_bucket_arn" {
  description = "ARN of the S3 log bucket used by AWS Config"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

