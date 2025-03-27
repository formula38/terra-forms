output "log_group_name" {
  description = "Name of the CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}

output "flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = aws_flow_log.vpc_flow_log.id
}
