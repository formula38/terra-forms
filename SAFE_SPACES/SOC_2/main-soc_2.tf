##############################################
# main.tf - AWS Infrastructure for SOC 2 Compliance
##############################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
  backend "s3" {
    bucket         = "tf-state-soc2"       # Change to your remote state bucket name
    key            = "terraform/state/soc2.tfstate"
    region         = var.region
    encrypt        = true
    dynamodb_table = "tf-locks-soc2"       # Change to your DynamoDB table name for state locking
  }
}

variable "region" {
  description = "AWS region for deployment"
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (production, staging, etc.)"
  default     = "production"
}

variable "trusted_ip_range" {
  description = "Trusted IP range for administrative access (e.g., SSH, HTTPS)"
  default     = "203.0.113.0/24"
}

variable "db_username" {
  description = "Database username for the RDS instance"
  default     = "soc2_dbadmin"
}

variable "db_password" {
  description = "Database password for the RDS instance"
  type        = string
  sensitive   = true
}

provider "aws" {
  region = var.region
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "random_string" "log_bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

##############################################
# VPC and Networking
##############################################
resource "aws_vpc" "soc2_vpc" {
  cidr_block           = "10.7.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name        = "soc2-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "soc2_subnet_a" {
  vpc_id            = aws_vpc.soc2_vpc.id
  cidr_block        = "10.7.1.0/24"
  availability_zone = "${var.region}a"
  tags = {
    Name        = "soc2-subnet-a"
    Environment = var.environment
  }
}

resource "aws_subnet" "soc2_subnet_b" {
  vpc_id            = aws_vpc.soc2_vpc.id
  cidr_block        = "10.7.2.0/24"
  availability_zone = "${var.region}b"
  tags = {
    Name        = "soc2-subnet-b"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "soc2_igw" {
  vpc_id = aws_vpc.soc2_vpc.id
  tags = {
    Name        = "soc2-igw"
    Environment = var.environment
  }
}

resource "aws_route_table" "soc2_rt" {
  vpc_id = aws_vpc.soc2_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.soc2_igw.id
  }
  tags = {
    Name        = "soc2-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "soc2_rta_a" {
  subnet_id      = aws_subnet.soc2_subnet_a.id
  route_table_id = aws_route_table.soc2_rt.id
}

resource "aws_route_table_association" "soc2_rta_b" {
  subnet_id      = aws_subnet.soc2_subnet_b.id
  route_table_id = aws_route_table.soc2_rt.id
}

##############################################
# VPC Flow Logs for Auditability
##############################################
resource "aws_cloudwatch_log_group" "soc2_vpc_flow" {
  name              = "/aws/vpc/soc2-flow-logs"
  retention_in_days = 90
}

resource "aws_iam_role" "soc2_flow_role" {
  name = "soc2_flow_log_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "vpc-flow-logs.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "soc2_flow_policy" {
  name = "soc2_flow_policy"
  role = aws_iam_role.soc2_flow_role.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "soc2_flow" {
  vpc_id               = aws_vpc.soc2_vpc.id
  traffic_type         = "ALL"
  log_destination      = aws_cloudwatch_log_group.soc2_vpc_flow.arn
  log_destination_type = "cloud-watch-logs"
  iam_role_arn         = aws_iam_role.soc2_flow_role.arn
}

##############################################
# Encryption (KMS) and S3 Buckets
##############################################
resource "aws_kms_key" "soc2_kms" {
  description             = "KMS key for SOC 2 compliant encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Sid       = "AdminAccess",
        Effect    = "Allow",
        Principal = { 
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action    = "kms:*",
        Resource  = "*"
      },
      {
        Sid       = "ServiceAccess",
        Effect    = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action    = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*"
        ],
        Resource  = "*"
      }
    ]
  })
}

resource "aws_s3_bucket" "soc2_data_bucket" {
  bucket = "soc2-data-bucket-${random_string.bucket_suffix.result}"
  acl    = "private"
  tags = {
    Name        = "soc2-data-bucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "soc2_data_bucket_enc" {
  bucket = aws_s3_bucket.soc2_data_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.soc2_kms.arn
    }
  }
}

resource "aws_s3_bucket" "soc2_log_bucket" {
  bucket = "soc2-log-bucket-${random_string.log_bucket_suffix.result}"
  acl    = "private"
  tags = {
    Name        = "soc2-log-bucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "soc2_log_bucket_enc" {
  bucket = aws_s3_bucket.soc2_log_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.soc2_kms.arn
    }
  }
}

##############################################
# IAM Roles and Instance Profile for Compute
##############################################
resource "aws_iam_role" "soc2_ec2_role" {
  name = "soc2_ec2_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "soc2_ec2_policy" {
  name = "soc2_ec2_policy"
  role = aws_iam_role.soc2_ec2_role.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = [
          aws_s3_bucket.soc2_data_bucket.arn,
          "${aws_s3_bucket.soc2_data_bucket.arn}/*"
        ]
      },
      {
        Effect   = "Allow",
        Action   = ["cloudwatch:PutMetricData"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "soc2_instance_profile" {
  name = "soc2_instance_profile"
  role = aws_iam_role.soc2_ec2_role.name
}

##############################################
# Compute Resources
##############################################
resource "aws_instance" "soc2_ec2" {
  ami                    = "ami-0c55b159cbfafe1f0"  # Replace with a validated AMI for your use case
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.soc2_subnet_a.id
  iam_instance_profile   = aws_iam_instance_profile.soc2_instance_profile.name
  vpc_security_group_ids = [aws_security_group.soc2_sg.id]
  ebs_block_device {
    device_name = "/dev/sda1"
    encrypted   = true
    kms_key_id  = aws_kms_key.soc2_kms.arn
  }
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl enable httpd
    systemctl start httpd
  EOF
  tags = {
    Name        = "soc2-ec2-instance"
    Environment = var.environment
  }
}

##############################################
# Security Groups
##############################################
resource "aws_security_group" "soc2_sg" {
  name        = "soc2_sg"
  description = "Security group for SOC 2 compliant resources (EC2, RDS, etc.)"
  vpc_id      = aws_vpc.soc2_vpc.id

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.trusted_ip_range]
  }
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.trusted_ip_range]
  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "soc2_sg"
    Environment = var.environment
  }
}

##############################################
# RDS PostgreSQL Setup
##############################################
resource "aws_db_subnet_group" "soc2_db_subnet" {
  name       = "soc2-db-subnet"
  subnet_ids = [aws_subnet.soc2_subnet_a.id, aws_subnet.soc2_subnet_b.id]
  tags = {
    Name        = "soc2-db-subnet"
    Environment = var.environment
  }
}

resource "aws_db_instance" "soc2_rds" {
  identifier               = "soc2-postgres"
  engine                   = "postgres"
  engine_version           = "13.4"
  instance_class           = "db.t3.micro"
  allocated_storage        = 20
  storage_encrypted        = true
  kms_key_id               = aws_kms_key.soc2_kms.arn
  db_subnet_group_name     = aws_db_subnet_group.soc2_db_subnet.name
  vpc_security_group_ids   = [aws_security_group.soc2_sg.id]
  username                 = var.db_username
  password                 = var.db_password
  skip_final_snapshot      = true
  tags = {
    Name        = "soc2-rds"
    Environment = var.environment
  }
}

##############################################
# AWS Config for Continuous Compliance Monitoring
##############################################
resource "aws_config_configuration_recorder" "soc2_config" {
  name     = "soc2-config"
  role_arn = aws_iam_role.soc2_config_role.arn
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_iam_role" "soc2_config_role" {
  name = "soc2_config_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "config.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_config_delivery_channel" "soc2_config_channel" {
  name           = "soc2-config-channel"
  s3_bucket_name = aws_s3_bucket.soc2_log_bucket.id
  depends_on     = [aws_config_configuration_recorder.soc2_config]
}

data "aws_caller_identity" "current" {}
