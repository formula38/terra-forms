output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.cmmc_ec2.id
}

output "instance_profile_name" {
  description = "The name of the instance profile"
  value       = aws_iam_instance_profile.instance_profile.name
}

output "ec2_role_arn" {
  description = "The ARN of the EC2 IAM role"
  value       = aws_iam_role.ec2_role.arn
}

output "public_ip" {
  value = aws_instance.cmmc_ec2.public_ip
}
