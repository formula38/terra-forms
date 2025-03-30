output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_a_id" {
  description = "Subnet A ID"
  value       = aws_subnet.subnet_a.id
}

output "subnet_b_id" {
  description = "Subnet B ID"
  value       = aws_subnet.subnet_b.id
}

output "subnet_ids" {
  description = "List of both subnet IDs"
  value       = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
}

output "security_group_id" {
  description = "ID of the default security group"
  value       = aws_security_group.main_sg.id
}

