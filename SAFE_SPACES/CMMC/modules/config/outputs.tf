output "config_recorder_name" {
  value       = aws_config_configuration_recorder.recorder.name
  description = "AWS Config recorder name"
}

output "config_delivery_channel_name" {
  value       = aws_config_delivery_channel.channel.name
  description = "AWS Config delivery channel name"
}

output "config_role_arn" {
  value       = aws_iam_role.config_role.arn
  description = "IAM role ARN used by AWS Config"
}
