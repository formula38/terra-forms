variable "account_id" {
  description = "AWS Account ID for KMS policy"
  type        = string
}

variable "environment" {
  description = "Environment tag (e.g., production)"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for KMS key name"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

