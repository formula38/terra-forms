resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.name_prefix}-db-subnet"
  subnet_ids = var.subnet_ids
  tags = {
    Name        = "${var.name_prefix}-db-subnet"
    Environment = var.environment
  }
}

resource "aws_db_instance" "postgres" {
  identifier               = "${var.name_prefix}-postgres"
  engine                   = "postgres"
  engine_version           = var.engine_version
  instance_class           = var.instance_class
  allocated_storage        = var.allocated_storage
  storage_encrypted        = true
  kms_key_id               = var.kms_key_id
  db_subnet_group_name     = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids   = var.security_group_ids
  username                 = var.db_username
  password                 = var.db_password
  skip_final_snapshot      = true

  tags = {
    Name        = "${var.name_prefix}-rds"
    Environment = var.environment
  }
}
