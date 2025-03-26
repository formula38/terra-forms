##############################################
# main-cmmc.tf - AWS Infrastructure for CMMC Compliance
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
    key            = "terraform/state/cmmc.tfstate"
    region         = "us-west-1"                # Or whichever region your bucket is in
    encrypt        = true
    use_lockfile   = true
  }
}

variable "region" {
  description = "AWS region for deployment"
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (e.g., production)"
  default     = "production"
}

variable "trusted_ip_range" {
  description = "Trusted IP range for access"
  default     = "203.0.113.0/24"
}

variable "db_username" {
  description = "Database username"
  default     = "dbadmin"
}

variable "db_password" {
  description = "Database password"
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

resource "aws_vpc" "cmmc_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "cmmc-vpc" }
}

resource "aws_subnet" "cmmc_subnet_a" {
  vpc_id            = aws_vpc.cmmc_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}a"
  tags = { Name = "cmmc-subnet-a" }
}

resource "aws_subnet" "cmmc_subnet_b" {
  vpc_id            = aws_vpc.cmmc_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.region}b"
  tags = { Name = "cmmc-subnet-b" }
}

resource "aws_internet_gateway" "cmmc_igw" {
  vpc_id = aws_vpc.cmmc_vpc.id
  tags = { Name = "cmmc-igw" }
}

resource "aws_route_table" "cmmc_rt" {
  vpc_id = aws_vpc.cmmc_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cmmc_igw.id
  }
  tags = { Name = "cmmc-rt" }
}

resource "aws_route_table_association" "cmmc_rta_a" {
  subnet_id      = aws_subnet.cmmc_subnet_a.id
  route_table_id = aws_route_table.cmmc_rt.id
}

resource "aws_route_table_association" "cmmc_rta_b" {
  subnet_id      = aws_subnet.cmmc_subnet_b.id
  route_table_id = aws_route_table.cmmc_rt.id
}

# VPC Flow Logs for auditing network traffic
resource "aws_cloudwatch_log_group" "cmmc_vpc_flow" {
  name              = "/aws/vpc/cmmc-flow-logs"
  retention_in_days = 90
}

resource "aws_iam_role" "cmmc_flow_role" {
  name = "cmmc_flow_log_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "cmmc_flow_policy" {
  name = "cmmc_flow_log_policy"
  role = aws_iam_role.cmmc_flow_role.id
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

resource "aws_flow_log" "cmmc_flow" {
  vpc_id               = aws_vpc.cmmc_vpc.id
  traffic_type         = "ALL"
  log_destination      = aws_cloudwatch_log_group.cmmc_vpc_flow.arn
  log_destination_type = "cloud-watch-logs"
  iam_role_arn         = aws_iam_role.cmmc_flow_role.arn
}

# KMS Key for encryption with strict policies
resource "aws_kms_key" "cmmc_kms" {
  description             = "KMS key for CMMC compliant encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowAdministration",
        Effect    = "Allow",
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
        Action    = "kms:*",
        Resource  = "*"
      },
      {
        Sid       = "AllowUsageByServices",
        Effect    = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action    = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*"
        ],
        Resource = "*"
      }
    ]
  })
}

# S3 Buckets for data and logs with encryption
resource "aws_s3_bucket" "cmmc_data_bucket" {
  bucket = "cmmc-data-bucket-${random_string.bucket_suffix.result}"
  tags   = { Name = "cmmc-data-bucket", Environment = var.environment }
}

resource "aws_s3_bucket_acl" "cmmc_data_bucket" {
  bucket = aws_s3_bucket.cmmc_data_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cmmc_data_bucket_enc" {
  bucket = aws_s3_bucket.cmmc_data_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.cmmc_kms.arn
    }
  }
}

resource "aws_s3_bucket" "cmmc_log_bucket" {
  bucket = "cmmc-log-bucket-${random_string.log_bucket_suffix.result}"
  tags   = { Name = "cmmc-log-bucket", Environment = var.environment }
}

resource "aws_s3_bucket_acl" "cmmc_log_bucket" {
  bucket = aws_s3_bucket.cmmc_log_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cmmc_log_bucket_enc" {
  bucket = aws_s3_bucket.cmmc_log_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.cmmc_kms.arn
    }
  }
}

# IAM Role for EC2 with strict least privilege
resource "aws_iam_role" "cmmc_ec2_role" {
  name = "cmmc_ec2_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cmmc_ec2_policy" {
  name = "cmmc_ec2_policy"
  role = aws_iam_role.cmmc_ec2_role.id
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
          aws_s3_bucket.cmmc_data_bucket.arn,
          "${aws_s3_bucket.cmmc_data_bucket.arn}/*"
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

resource "aws_iam_instance_profile" "cmmc_instance_profile" {
  name = "cmmc_instance_profile"
  role = aws_iam_role.cmmc_ec2_role.name
}

# EC2 Instance for demonstration with encrypted EBS
resource "aws_instance" "cmmc_ec2" {
  ami                    = "ami-0c55b159cbfafe1f0"  # Example AMI; adjust as needed
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.cmmc_subnet_a.id
  iam_instance_profile   = aws_iam_instance_profile.cmmc_instance_profile.name
  vpc_security_group_ids = [aws_security_group.cmmc_sg.id]
  ebs_block_device {
    device_name = "/dev/sda1"
    encrypted   = true
    kms_key_id  = aws_kms_key.cmmc_kms.arn
  }
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl enable httpd
    systemctl start httpd
  EOF
  tags = { Name = "cmmc-ec2-instance", Environment = var.environment }
}

# Security Group for EC2, RDS, etc.
resource "aws_security_group" "cmmc_sg" {
  name        = "cmmc_sg"
  description = "Security group for CMMC compliant resources"
  vpc_id      = aws_vpc.cmmc_vpc.id

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
  tags = { Name = "cmmc_sg", Environment = var.environment }
}

# RDS PostgreSQL with encryption
resource "aws_db_subnet_group" "cmmc_db_subnet" {
  name       = "cmmc-db-subnet"
  subnet_ids = [aws_subnet.cmmc_subnet_a.id, aws_subnet.cmmc_subnet_b.id]
  tags       = { Name = "cmmc-db-subnet", Environment = var.environment }
}

resource "aws_db_instance" "cmmc_rds" {
  identifier               = "cmmc-postgres"
  engine                   = "postgres"
  engine_version           = "13.4"
  instance_class           = "db.t3.micro"
  allocated_storage        = 20
  storage_encrypted        = true
  kms_key_id               = aws_kms_key.cmmc_kms.arn
  db_subnet_group_name     = aws_db_subnet_group.cmmc_db_subnet.name
  vpc_security_group_ids   = [aws_security_group.cmmc_sg.id]
  username                 = var.db_username
  password                 = var.db_password
  skip_final_snapshot      = true
  tags = {
    Name        = "cmmc-rds"
    Environment = var.environment
  }
}

# AWS Config for continuous monitoring
resource "aws_config_configuration_recorder" "cmmc_config" {
  name     = "cmmc-config"
  role_arn = aws_iam_role.cmmc_config_role.arn
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_iam_role" "cmmc_config_role" {
  name = "cmmc_config_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "config.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_config_delivery_channel" "cmmc_config_channel" {
  name           = "cmmc-config-channel"
  s3_bucket_name = aws_s3_bucket.cmmc_log_bucket.id
  depends_on     = [aws_config_configuration_recorder.cmmc_config]
}

data "aws_caller_identity" "current" {}
