variable "name_prefix" {
  description = "Prefix to use for resource names"
  type        = string
  }
  
variable "db_username" {
  description = "RDS database username"
  type        = string
  }

variable "db_password" {
  description = "RDS database password"
  type        = string
  sensitive   = true
  }

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
  }

variable "kms_key_id" {
  description = "KMS key ID for RDS encryption"
  type        = string
  }

variable "security_group_ids" {
  description = "Security group IDs to assign to the RDS instance"
  type        = list(string)
  }

variable "environment" {
  description = "Deployment environment name"
  type        = string
  }

  variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  }