resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.name_prefix}-db-subnet"
  subnet_ids = var.subnet_ids

  tags = merge(
    {
      Name        = "${var.name_prefix}-db-subnet"
      Environment = var.environment
    },
    var.common_tags
  )
}

resource "aws_db_instance" "postgres" {
  identifier             = "${var.name_prefix}-postgres"
  engine                 = "postgres"
  engine_version         = "13.4"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_encrypted      = true
  kms_key_id             = var.kms_key_id
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = var.security_group_ids
  username               = var.db_username
  password               = var.db_password
  skip_final_snapshot    = true

  tags = merge(
    {
      Name        = "${var.name_prefix}-rds"
      Environment = var.environment
    },
    var.common_tags
  )
}
