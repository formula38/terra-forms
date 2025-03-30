# =============================
# Shared / Root-level Variables
# =============================

variable "region" {
  description = "AWS region for deployment"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, production)"
  type        = string
}

variable "trusted_ip_range" {
  description = "CIDR block for trusted IPs"
  type        = string
}
# =============================
# Compute Module
# =============================

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
}

variable "ebs_device_name" {
  description = "The name of the EBS device attached to the EC2 instance"
  type        = string
}

# =============================
# RDS Module
# =============================

variable "db_username" {
  description = "Username for RDS database"
  type        = string
}

variable "db_password" {
  description = "Password for RDS database"
  type        = string
  sensitive   = true
}

# =============================
# Networking Module
# =============================

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC for tagging"
  type        = string
}

variable "subnet_cidr_a" {
  description = "CIDR block for Subnet A"
  type        = string
}

variable "subnet_cidr_b" {
  description = "CIDR block for Subnet B"
  type        = string
}

variable "route_cidr_block" {
  description = "CIDR block for the default route in the route table"
  type        = string
}

# =============================
# Common Tag Prefix / Naming
# =============================

variable "name_prefix" {
  description = "Prefix to apply to named resources"
  type        = string
}

variable "created_by" {
  description = "Who created the infrastructure"
  type        = string
}

variable "created_on" {
  description = "When the infrastructure was created"
  type        = string
}

# =============================
# Logging Module
# =============================

variable "retention_in_days" {
  description = "Retention period for CloudWatch logs"
  type        = number
  default     = 90
}

variable "log_destination" {
  description = "The name of the CloudWatch Log Group for flow logs."
  type        = string
}

variable "flow_log_role_name" {
  description = "IAM Role name for flow logs."
  type        = string
}

# =============================
# S3 Module
# =============================

variable "data_bucket_name" {
  description = "Name for the main S3 data bucket"
  type        = string
}

variable "log_bucket_name" {
  description = "Name for the S3 log bucket"
  type        = string
}
