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

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "user_data_script_path" {
  description = "Path to the EC2 user data script"
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

variable "engine" {
  description = "Database engine type (e.g., postgres, mysql)"
  type        = string
}

variable "engine_version" {
  description = "Version of the database engine"
  type        = string
}

variable "instance_class" {
  description = "The instance class for the RDS instance"
  type        = string
}

variable "allocated_storage" {
  description = "Amount of allocated storage in GB"
  type        = number
}

variable "storage_encrypted" {
  description = "Whether to enable encryption at rest"
  type        = bool
}

variable "skip_final_snapshot" {
  description = "Whether to skip final snapshot on DB deletion"
  type        = bool
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

variable "availability_zone_a" {
  description = "Availability Zone for Subnet A"
  type        = string
}

variable "availability_zone_b" {
  description = "Availability Zone for Subnet B"
  type        = string
}

variable "security_group_ingress_rules" {
  description = "List of ingress rules for the security group"
  type = list(object({
    description      = string
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = optional(list(string), [])
    ipv6_cidr_blocks = optional(list(string), [])
    security_groups  = optional(list(string), [])
  }))
}

variable "security_group_egress_rules" {
  description = "List of egress rules for the security group"
  type = list(object({
    description      = string
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = optional(list(string), [])
    ipv6_cidr_blocks = optional(list(string), [])
    security_groups  = optional(list(string), [])
  }))
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

variable "project" {
  description = "Project name"
  type        = string
}

variable "owner" {
  description = "Owner of the infrastructure"
  type        = string
}

variable "cost_center" {
  description = "Cost center for tracking"
  type        = string
}

# =============================
# Logging Module
# =============================

variable "retention_in_days" {
  description = "Retention period for CloudWatch logs"
  type        = number
}

variable "flow_log_group_name" {
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

variable "s3_acl" {
  description = "The ACL to apply to the S3 buckets"
  type        = string
}

variable "sse_algorithm" {
  description = "The server-side encryption algorithm for S3 buckets"
  type        = string
}

# =============================
# CloudFront & ACM
# =============================

variable "cloudfront_domain_aliases" {
  description = "List of custom domain aliases for CloudFront"
  type        = list(string)
}

variable "use_existing_route53" {
  description = "Flag to determine if an existing hosted zone should be used"
  type        = bool
}
