##############################################
# main-gdpr.tf - AWS Infrastructure for GDPR Compliance
##############################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
   backend "s3" {
    bucket       = "www.coldchainsecure.com"   # Existing bucket name
    key          = "terraform/state/gdpr.tfstate"
    region       = "us-west-1"                # Or whichever region your bucket is in
    encrypt      = true
    use_lockfile = true
  }
}

##############################################
# Variables
##############################################

variable "region" {
  description = "AWS region for deployment. Must be an EU region for GDPR data residency."
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Deployment environment (e.g., production, staging)"
  type        = string
  default     = "production"
}

variable "trusted_ip_range" {
  description = "Trusted IP range for administrative access (e.g., SSH/HTTPS)"
  type        = string
  default     = "203.0.113.0/24"
}

variable "db_username" {
  description = "Database username for the RDS instance"
  type        = string
  default     = "gdpr_dbadmin"
}

variable "db_password" {
  description = "Database password for the RDS instance (store securely)"
  type        = string
  sensitive   = true
}

##############################################
# Provider
##############################################

provider "aws" {
  region  = var.region
  profile = "default"   # Adjust as needed
}

##############################################
# Random Strings for Bucket Naming
##############################################

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
# Networking Resources - VPC, Subnets, and Routing
##############################################

resource "aws_vpc" "gdpr_vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name       = "gdpr-compliant-vpc"
    Compliance = "GDPR"
  }
}

resource "aws_subnet" "gdpr_subnet_a" {
  vpc_id            = aws_vpc.gdpr_vpc.id
  cidr_block        = "10.10.1.0/24"
  availability_zone = "${var.region}a"
  tags = {
    Name       = "gdpr-subnet-a"
    Compliance = "GDPR"
  }
}

resource "aws_subnet" "gdpr_subnet_b" {
  vpc_id            = aws_vpc.gdpr_vpc.id
  cidr_block        = "10.10.2.0/24"
  availability_zone = "${var.region}b"
  tags = {
    Name       = "gdpr-subnet-b"
    Compliance = "GDPR"
  }
}

resource "aws_internet_gateway" "gdpr_igw" {
  vpc_id = aws_vpc.gdpr_vpc.id
  tags = {
    Name       = "gdpr-igw"
    Compliance = "GDPR"
  }
}

resource "aws_route_table" "gdpr_rt" {
  vpc_id = aws_vpc.gdpr_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gdpr_igw.id
  }
  tags = {
    Name       = "gdpr-rt"
    Compliance = "GDPR"
  }
}

resource "aws_route_table_association" "gdpr_rta_a" {
  subnet_id      = aws_subnet.gdpr_subnet_a.id
  route_table_id = aws_route_table.gdpr_rt.id
}

resource "aws_route_table_association" "gdpr_rta_b" {
  subnet_id      = aws_subnet.gdpr_subnet_b.id
  route_table_id = aws_route_table.gdpr_rt.id
}

##############################################
# VPC Flow Logs for Network Auditability
##############################################

resource "aws_cloudwatch_log_group" "gdpr_vpc_flow" {
  name              = "/aws/vpc/gdpr-flow-logs"
  retention_in_days = 90
  tags = {
    Compliance  = "GDPR"
  }
}

resource "aws_iam_role" "gdpr_flow_role" {
  name = "gdpr_flow_log_role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "gdpr_flow_policy" {
  name = "gdpr_flow_policy"
  role = aws_iam_role.gdpr_flow_role.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }]
  })
}

resource "aws_flow_log" "gdpr_flow_log" {
  vpc_id               = aws_vpc.gdpr_vpc.id
  traffic_type         = "ALL"
  log_destination      = aws_cloudwatch_log_group.gdpr_vpc_flow.arn
  log_destination_type = "cloud-watch-logs"
  iam_role_arn         = aws_iam_role.gdpr_flow_role.arn
}

##############################################
# Encryption and Data Protection - KMS and S3
##############################################

resource "aws_kms_key" "gdpr_kms" {
  description             = "KMS key for GDPR compliant encryption (data at rest)"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "EnableRoot",
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action": "kms:*",
        "Resource": "*"
      },
      {
        "Sid": "AllowCloudTrail",
        "Effect": "Allow",
        "Principal": {
          "Service": "cloudtrail.amazonaws.com"
        },
        "Action": [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*"
        ],
        "Resource": "*"
      },
      {
        "Sid": "AllowAWSConfig",
        "Effect": "Allow",
        "Principal": {
          "Service": "config.amazonaws.com"
        },
        "Action": [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*"
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_s3_bucket" "gdpr_data_bucket" {
  bucket = "gdpr-data-bucket-${random_string.bucket_suffix.result}"
  tags = {
    Name        = "gdpr-data-bucket"
    Environment = var.environment
    Compliance  = "GDPR"
  }
}

resource "aws_s3_bucket_acl" "gdpr_data_bucket_acl" {
  bucket = aws_s3_bucket.gdpr_data_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "gdpr_data_bucket_enc" {
  bucket = aws_s3_bucket.gdpr_data_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.gdpr_kms.arn
    }
  }
}

resource "aws_s3_bucket" "gdpr_log_bucket" {
  bucket = "gdpr-log-bucket-${random_string.log_bucket_suffix.result}"
  tags = {
    Name        = "gdpr-log-bucket"
    Environment = var.environment
    Compliance  = "GDPR"
  }
}

resource "aws_s3_bucket_acl" "gdpr_log_bucket" {
  bucket = aws_s3_bucket.gdpr_log_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "gdpr_log_bucket_enc" {
  bucket = aws_s3_bucket.gdpr_log_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.gdpr_kms.arn
    }
  }
}

##############################################
# Security Controls - Security Groups and IAM for Least Privilege
##############################################

resource "aws_security_group" "gdpr_sg" {
  name        = "gdpr_sg"
  description = "Security group for GDPR compliant resources"
  vpc_id      = aws_vpc.gdpr_vpc.id

  ingress {
    description = "Allow HTTPS from trusted IP"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.trusted_ip_range]
  }

  ingress {
    description = "Allow SSH from trusted IP"
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
    Name        = "gdpr_sg"
    Compliance  = "GDPR"
    Environment = var.environment
  }
}

resource "aws_iam_role" "gdpr_ec2_role" {
  name = "gdpr_ec2_role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "gdpr_ec2_policy" {
  name = "gdpr_ec2_policy"
  role = aws_iam_role.gdpr_ec2_role.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ],
        "Resource": [
          aws_s3_bucket.gdpr_data_bucket.arn,
          "${aws_s3_bucket.gdpr_data_bucket.arn}/*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "cloudwatch:PutMetricData"
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "gdpr_instance_profile" {
  name = "gdpr_instance_profile"
  role = aws_iam_role.gdpr_ec2_role.name
}

##############################################
# Compute Resources - EC2 Instance with Encrypted Storage
##############################################

resource "aws_instance" "gdpr_ec2" {
  ami                    = "ami-03cc8375791cb8bcf"  # Example Ubuntu AMI in eu-west-1; verify current ID
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.gdpr_subnet_a.id
  iam_instance_profile   = aws_iam_instance_profile.gdpr_instance_profile.name
  vpc_security_group_ids = [aws_security_group.gdpr_sg.id]
  associate_public_ip_address = false   # Not publicly accessible by default
  ebs_block_device {
    device_name = "/dev/sda1"
    encrypted   = true
    kms_key_id  = aws_kms_key.gdpr_kms.arn
  }
  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    echo "GDPR Compliant Server" > /var/www/html/index.html
  EOF
  tags = {
    Name        = "gdpr-ec2-instance"
    Environment = var.environment
    Compliance  = "GDPR"
  }
}

##############################################
# Database Configuration - RDS PostgreSQL (Multi-AZ)
##############################################

resource "aws_db_subnet_group" "gdpr_db_subnet" {
  name       = "gdpr-db-subnet-group"
  subnet_ids = [aws_subnet.gdpr_subnet_a.id, aws_subnet.gdpr_subnet_b.id]
  tags = {
    Name        = "gdpr-db-subnet-group"
    Compliance  = "GDPR"
    Environment = var.environment
  }
}

resource "aws_db_instance" "gdpr_rds" {
  identifier               = "gdpr-postgres-instance"
  engine                   = "postgres"
  engine_version           = "13.4"
  instance_class           = "db.t3.micro"
  allocated_storage        = 20
  storage_encrypted        = true
  kms_key_id               = aws_kms_key.gdpr_kms.arn
  db_subnet_group_name     = aws_db_subnet_group.gdpr_db_subnet.name
  vpc_security_group_ids   = [aws_security_group.gdpr_sg.id]
  username                 = var.db_username
  password                 = var.db_password
  multi_az                 = true
  publicly_accessible      = false
  backup_retention_period  = 7
  delete_automated_backups = true
  tags = {
    Name        = "gdpr-rds-instance"
    Environment = var.environment
    Compliance  = "GDPR"
  }
}

##############################################
# Monitoring and Audit - CloudTrail and AWS Config
##############################################

resource "aws_cloudtrail" "gdpr_trail" {
  name                          = "gdpr-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.gdpr_log_bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  event_selector {
    read_write_type           = "All"
    include_management_events = true
    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::${aws_s3_bucket.gdpr_log_bucket.id}/*"]
    }
  }
  tags = {
    Compliance  = "GDPR"
    Environment = var.environment
  }
}

resource "aws_config_configuration_recorder" "gdpr_config_recorder" {
  name     = "gdpr-config-recorder"
  role_arn = aws_iam_role.gdpr_config_role.arn
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_iam_role" "gdpr_config_role" {
  name = "gdpr_config_role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": { "Service": "config.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }]
  })
}

resource "aws_config_delivery_channel" "gdpr_config_channel" {
  name           = "gdpr-config-channel"
  s3_bucket_name = aws_s3_bucket.gdpr_log_bucket.id
  depends_on     = [aws_config_configuration_recorder.gdpr_config_recorder]
}

##############################################
# Data Source
##############################################

data "aws_caller_identity" "current" {}

