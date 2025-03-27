output "rds_instance_id" {
  value       = aws_db_instance.postgres.id
  description = "RDS instance ID"
}

output "rds_endpoint" {
  value       = aws_db_instance.postgres.endpoint
  description = "RDS endpoint"
}

output "rds_db_name" {
  value       = aws_db_instance.postgres.db_name
  description = "Database name"
}

output "db_subnet_group" {
  value       = aws_db_subnet_group.db_subnet_group.name
  description = "RDS subnet group name"
}
