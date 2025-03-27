variable "name_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs for EC2 instance"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "KMS Key ARN for EBS volume encryption"
  type        = string
}

variable "data_bucket_arn" {
  description = "ARN of the S3 data bucket"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "environment" {
  description = "Environment label (e.g., production)"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the EC2 instance"
  type        = string
}
