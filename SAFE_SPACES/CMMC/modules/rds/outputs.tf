output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.postgres.id
}

output "db_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "db_subnet_group" {
  description = "RDS subnet group name"
  value       = aws_db_subnet_group.db_subnet_group.name
}
