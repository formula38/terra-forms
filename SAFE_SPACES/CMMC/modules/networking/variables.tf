variable "region" {
  description = "AWS region for deployment"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., production)"
  type        = string
}

variable "trusted_ip_range" {
  description = "Trusted IP range for security group ingress"
  type        = string
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
}

variable "vpc_name" {
  description = "Name tag for VPC"
}

variable "subnet_cidr_a" {
  description = "CIDR block for subnet A"
  type        = string
}

variable "subnet_cidr_b" {
  description = "CIDR block for subnet B"
  type        = string
}
