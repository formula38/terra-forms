output "config_role_arn" {
  description = "IAM Role ARN used by AWS Config"
  value       = aws_iam_role.config_role.arn
}

output "config_recorder_name" {
  description = "AWS Config recorder name"
  value       = aws_config_configuration_recorder.recorder.name
}

output "config_delivery_channel" {
  description = "AWS Config delivery channel name"
  value       = aws_config_delivery_channel.delivery.name
}
