variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID for EC2 instance"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to associate with EC2"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "KMS key ARN for EBS encryption"
  type        = string
}

variable "data_bucket_arn" {
  description = "ARN of the S3 data bucket the EC2 instance needs access to"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "enable_cloudwatch_agent" {
  description = "Toggle for enabling CloudWatch agent installation"
  type        = bool
  default     = true
}

variable "enable_ssm_agent" {
  description = "Toggle for enabling SSM agent and patch compliance"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

variable "user_data_script_path" {
  type        = string
  description = "Path to the EC2 user data script"
}

variable "ebs_device_name" {
  description = "The name of the EBS device attached to the EC2 instance"
  type        = string
}
