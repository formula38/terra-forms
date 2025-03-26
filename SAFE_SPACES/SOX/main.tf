##############################################
# main-sox.tf - AWS Infrastructure for SOX Compliance
##############################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
  backend "s3" {
    bucket         = "www.coldchainsecure.com"
    key            = "terraform/state/sox.tfstate"
    region         = "us-west-1"
    encrypt        = true
    use_lockfile   = true
  }
}

variable "region" {
  default = "us-east-1"
}

variable "environment" {
  default = "production"
}

variable "trusted_ip_range" {
  default = "203.0.113.0/24"
}

variable "db_username" {
  default = "sox_dbadmin"
}

variable "db_password" {
  type      = string
  sensitive = true
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

resource "aws_vpc" "sox_vpc" {
  cidr_block           = "10.8.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "sox-vpc" }
}

resource "aws_subnet" "sox_subnet_a" {
  vpc_id            = aws_vpc.sox_vpc.id
  cidr_block        = "10.8.1.0/24"
  availability_zone = "${var.region}a"
  tags = { Name = "sox-subnet-a" }
}

resource "aws_subnet" "sox_subnet_b" {
  vpc_id            = aws_vpc.sox_vpc.id
  cidr_block        = "10.8.2.0/24"
  availability_zone = "${var.region}b"
  tags = { Name = "sox-subnet-b" }
}

resource "aws_internet_gateway" "sox_igw" {
  vpc_id = aws_vpc.sox_vpc.id
  tags   = { Name = "sox-igw" }
}

resource "aws_route_table" "sox_rt" {
  vpc_id = aws_vpc.sox_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sox_igw.id
  }
  tags = { Name = "sox-rt" }
}

resource "aws_route_table_association" "sox_rta_a" {
  subnet_id      = aws_subnet.sox_subnet_a.id
  route_table_id = aws_route_table.sox_rt.id
}

resource "aws_route_table_association" "sox_rta_b" {
  subnet_id      = aws_subnet.sox_subnet_b.id
  route_table_id = aws_route_table.sox_rt.id
}

# VPC Flow Logs for SOX
resource "aws_cloudwatch_log_group" "sox_vpc_flow" {
  name              = "/aws/vpc/sox-flow-logs"
  retention_in_days = 90
}

resource "aws_iam_role" "sox_flow_role" {
  name = "sox_flow_log_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "sox_flow_policy" {
  name = "sox_flow_policy"
  role = aws_iam_role.sox_flow_role.id
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

resource "aws_flow_log" "sox_flow" {
  vpc_id               = aws_vpc.sox_vpc.id
  traffic_type         = "ALL"
  log_destination      = aws_cloudwatch_log_group.sox_vpc_flow.arn
  log_destination_type = "cloud-watch-logs"
  iam_role_arn         = aws_iam_role.sox_flow_role.arn
}

# KMS Key for SOX encryption
resource "aws_kms_key" "sox_kms" {
  description             = "KMS key for SOX compliant encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Sid       = "AdminAccess",
        Effect    = "Allow",
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
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

# S3 Buckets for SOX data and logs
resource "aws_s3_bucket" "sox_data_bucket" {
  bucket = "sox-data-bucket-${random_string.bucket_suffix.result}"
  tags   = { Name = "sox-data-bucket", Environment = var.environment }
}

resource "aws_s3_bucket_acl" "sox_data_bucket" {
  bucket = aws_s3_bucket.sox_data_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sox_data_bucket_enc" {
  bucket = aws_s3_bucket.sox_data_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.sox_kms.arn
    }
  }
}

resource "aws_s3_bucket" "sox_log_bucket" {
  bucket = "sox-log-bucket-${random_string.log_bucket_suffix.result}"
  tags   = { Name = "sox-log-bucket", Environment = var.environment }
}

resource "aws_s3_bucket_acl" "sox_log_bucket" {
  bucket = aws_s3_bucket.sox_log_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sox_log_bucket_enc" {
  bucket = aws_s3_bucket.sox_log_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.sox_kms.arn
    }
  }
}

# IAM Role for SOX EC2 with strict least privilege
resource "aws_iam_role" "sox_ec2_role" {
  name = "sox_ec2_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "sox_ec2_policy" {
  name = "sox_ec2_policy"
  role = aws_iam_role.sox_ec2_role.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.sox_data_bucket.arn,
          "${aws_s3_bucket.sox_data_bucket.arn}/*"
        ]
      },
      {
        Effect   = "Allow",
        Action   = [ "cloudwatch:PutMetricData" ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "sox_instance_profile" {
  name = "sox_instance_profile"
  role = aws_iam_role.sox_ec2_role.name
}

# EC2 Instance for SOX with encrypted storage
resource "aws_instance" "sox_ec2" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.sox_subnet_a.id
  iam_instance_profile   = aws_iam_instance_profile.sox_instance_profile.name
  vpc_security_group_ids = [aws_security_group.sox_sg.id]
  ebs_block_device {
    device_name = "/dev/sda1"
    encrypted   = true
    kms_key_id  = aws_kms_key.sox_kms.arn
  }
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl enable httpd
    systemctl start httpd
  EOF
  tags = { Name = "sox-ec2", Environment = var.environment }
}

resource "aws_security_group" "sox_sg" {
  name        = "sox_sg"
  description = "Security group for SOX compliant resources"
  vpc_id      = aws_vpc.sox_vpc.id

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
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "sox_sg", Environment = var.environment }
}

resource "aws_db_subnet_group" "sox_db_subnet" {
  name       = "sox-db-subnet"
  subnet_ids = [aws_subnet.sox_subnet_a.id, aws_subnet.sox_subnet_b.id]
  tags       = { Name = "sox-db-subnet", Environment = var.environment }
}

resource "aws_db_instance" "sox_rds" {
  identifier               = "sox-postgres"
  engine                   = "postgres"
  engine_version           = "13.4"
  instance_class           = "db.t3.micro"
  allocated_storage        = 20
  storage_encrypted        = true
  kms_key_id               = aws_kms_key.sox_kms.arn
  db_subnet_group_name     = aws_db_subnet_group.sox_db_subnet.name
  vpc_security_group_ids   = [aws_security_group.sox_sg.id]
  username                 = var.db_username
  password                 = var.db_password
  skip_final_snapshot      = true
  tags = {
    Name        = "sox-rds"
    Environment = var.environment
  }
}

resource "aws_config_configuration_recorder" "sox_config" {
  name     = "sox-config"
  role_arn = aws_iam_role.sox_config_role.arn
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_iam_role" "sox_config_role" {
  name = "sox_config_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "config.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_config_delivery_channel" "sox_config_channel" {
  name           = "sox-config-channel"
  s3_bucket_name = aws_s3_bucket.sox_log_bucket.id
  depends_on     = [aws_config_configuration_recorder.sox_config]
}

data "aws_caller_identity" "current" {}
