variable "vpc_id" {
  description = "The ID of the VPC to attach flow logs to."
  type        = string
}

variable "log_group_name" {
  description = "The name of the CloudWatch Log Group for flow logs."
  type        = string
  }

variable "retention_in_days" {
  description = "Number of days to retain logs"
  type        = number
  }

variable "flow_log_role_name" {
  description = "IAM Role name for flow logs."
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

variable "environment" {
  description = "Environment tag."
  type        = string
  }