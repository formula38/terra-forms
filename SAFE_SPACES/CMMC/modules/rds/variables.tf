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

variable "engine" {
  description = "Database engine type (e.g., postgres, mysql)"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Version of the database engine"
  type        = string
  default     = "13.4"
}

variable "instance_class" {
  description = "The instance class for the RDS instance"
  type        = string
  default     = "db.t3.micro"
}


variable "allocated_storage" {
  description = "Amount of allocated storage in GB"
  type        = number
  default     = 20
}

variable "storage_encrypted" {
  description = "Whether to enable encryption at rest"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Whether to skip final snapshot on DB deletion"
  type        = bool
  default     = true
}
