output "log_group_name" {
  description = "The name of the VPC flow log group"
  value       = aws_cloudwatch_log_group.cmmc_vpc_flow.name
}

output "flow_log_id" {
  description = "The ID of the VPC flow log"
  value       = aws_flow_log.vpc_flow_log.id
}

output "log_destination" {
  description = "The name of the CloudWatch Log Group for flow logs."
  value       = aws_flow_log.vpc_flow_log.log_destination
}

output "flow_log_role_name" {
  description = "IAM Role name for flow logs."
  value       = aws_iam_role.cmmc_flow_role.name
}