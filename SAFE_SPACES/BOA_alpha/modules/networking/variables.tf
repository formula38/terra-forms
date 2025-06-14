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

variable "availability_zone_a" {
  description = "Availability Zone for Subnet A"
  type        = string
}

variable "availability_zone_b" {
  description = "Availability Zone for Subnet B"
  type        = string
}

variable "enable_igw_route" {
  description = "Whether to add a default route to the Internet Gateway"
  type        = bool
  default     = true
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

variable "security_group_ingress_rules" {
  description = "List of ingress rules for the security group"
  type = list(object({
    description      = string
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = list(string)
    ipv6_cidr_blocks = optional(list(string), [])
    security_groups  = optional(list(string), [])
    self             = optional(bool, false)
  }))
  default = []
}

variable "security_group_egress_rules" {
  description = "List of egress rules"
  type = list(object({
    description      = string
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = list(string)
    ipv6_cidr_blocks = optional(list(string), [])
    security_groups  = optional(list(string), [])
    self             = optional(bool, false)
  }))
  default = []
}

