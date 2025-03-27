# modules/logging/variables.tf

variable "vpc_id" {
  description = "ID of the VPC for which to enable flow logs"
  type        = string
}

variable "log_group_name" {
  description = "Name of the CloudWatch log group"
  type        = string
  default     = "/aws/vpc/cmmc-flow-logs"
}

variable "flow_log_bucket" {
  description = "The name of the CloudWatch Log Group for VPC flow logs"
  type        = string
}

variable "region" {
  description = "AWS region for resource placement"
  type        = string
}

variable "retention_in_days" {
  description = "Retention period for log group"
  type        = number
  default     = 90
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "flow_log_role_name" {
  description = "Name for the IAM role used for flow logs"
  type        = string
}
