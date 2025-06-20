output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.cmmc_ec2.id
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.cmmc_ec2.public_ip
}

output "private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.cmmc_ec2.private_ip
}

output "instance_profile" {
  description = "IAM instance profile name"
  value       = aws_iam_instance_profile.ec2_instance_profile.name
}
