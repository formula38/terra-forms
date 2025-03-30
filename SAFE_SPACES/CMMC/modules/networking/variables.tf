variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
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
  description = "CIDR block for route table default route"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment tag (e.g. production)"
  type        = string
}

variable "trusted_ip_range" {
  description = "CIDR block for trusted IP ingress"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}
