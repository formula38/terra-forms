variable "name_prefix" {
  description = "Prefix to use for resource names"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for the RDS DB Subnet Group"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group(s) to associate with the RDS instance"
  type        = list(string)
}

variable "db_username" {
  description = "Database master username"
  type        = string
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "kms_key_id" {
  description = "KMS key for RDS encryption"
  type        = string
}

variable "allocated_storage" {
  description = "Amount of storage in GB"
  type        = number
  default     = 20
}

variable "instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "13.4"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "db_subnet_group" {
  description = "The name of the DB subnet group"
  type        = string
}

