##############################################
# main.tf - AWS Infrastructure for PCI DSS Compliance
##############################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
  backend "s3" {
    bucket         = "tf-state-pci"                    # Replace with your state bucket name
    key            = "terraform/state/pci_dss.tfstate"   # Unique state file key
    region         = var.region
    encrypt        = true
    dynamodb_table = "tf-locks-pci"                      # Replace with your DynamoDB lock table name
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
  description = "Trusted IP range for accessing administrative resources"
  default     = "203.0.113.0/24"
}

variable "db_username" {
  description = "Database username for PCI DSS environment"
  default     = "pci_dbadmin"
}

variable "db_password" {
  description = "Sensitive database password for PCI DSS environment"
  type        = string
  sensitive   = true
}

provider "aws" {
  region = var.region
}

# Random strings for bucket name uniqueness
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
# Networking - Dedicated VPC for Cardholder Data Environment (CDE)
##############################################

resource "aws_vpc" "pci_vpc" {
  cidr_block           = "10.6.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "pci-vpc" }
}

resource "aws_subnet" "pci_subnet_cde_a" {
  vpc_id            = aws_vpc.pci_vpc.id
  cidr_block        = "10.6.1.0/24"
  availability_zone = "${var.region}a"
  tags = { Name = "pci-cde-subnet-a" }
}

resource "aws_subnet" "pci_subnet_cde_b" {
  vpc_id            = aws_vpc.pci_vpc.id
  cidr_block        = "10.6.2.0/24"
  availability_zone = "${var.region}b"
  tags = { Name = "pci-cde-subnet-b" }
}

resource "aws_internet_gateway" "pci_igw" {
  vpc_id = aws_vpc.pci_vpc.id
  tags   = { Name = "pci-igw" }
}

resource "aws_route_table" "pci_rt" {
  vpc_id = aws_vpc.pci_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.pci_igw.id
  }
  tags = { Name = "pci-rt" }
}

resource "aws_route_table_association" "pci_rta_a" {
  subnet_id      = aws_subnet.pci_subnet_cde_a.id
  route_table_id = aws_route_table.pci_rt.id
}

resource "aws_route_table_association" "pci_rta_b" {
  subnet_id      = aws_subnet.pci_subnet_cde_b.id
  route_table_id = aws_route_table.pci_rt.id
}

##############################################
# VPC Flow Logs for Detailed Network Auditing
##############################################

resource "aws_cloudwatch_log_group" "pci_vpc_flow" {
  name              = "/aws/vpc/pci-flow-logs"
  retention_in_days = 90
}

resource "aws_iam_role" "pci_flow_role" {
  name = "pci_flow_log_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "pci_flow_policy" {
  name = "pci_flow_policy"
  role = aws_iam_role.pci_flow_role.id
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

resource "aws_flow_log" "pci_flow" {
  vpc_id               = aws_vpc.pci_vpc.id
  traffic_type         = "ALL"
  log_destination      = aws_cloudwatch_log_group.pci_vpc_flow.arn
  log_destination_type = "cloud-watch-logs"
  iam_role_arn         = aws_iam_role.pci_flow_role.arn
}

##############################################
# Encryption - KMS Key with Strict Policy for PCI
##############################################

resource "aws_kms_key" "pci_kms" {
  description             = "KMS key for PCI DSS compliant encryption"
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

##############################################
# S3 Buckets - Isolated and Encrypted for Cardholder Data and Logging
##############################################

resource "aws_s3_bucket" "pci_data_bucket" {
  bucket = "pci-data-bucket-${random_string.bucket_suffix.result}"
  acl    = "private"
  tags   = { Name = "pci-data-bucket", Environment = var.environment }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pci_data_bucket_enc" {
  bucket = aws_s3_bucket.pci_data_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.pci_kms.arn
    }
  }
}

resource "aws_s3_bucket" "pci_log_bucket" {
  bucket = "pci-log-bucket-${random_string.log_bucket_suffix.result}"
  acl    = "private"
  tags   = { Name = "pci-log-bucket", Environment = var.environment }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pci_log_bucket_enc" {
  bucket = aws_s3_bucket.pci_log_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.pci_kms.arn
    }
  }
}

##############################################
# IAM Roles and Policies - Least Privilege for EC2 Instances
##############################################

resource "aws_iam_role" "pci_ec2_role" {
  name = "pci_ec2_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "pci_ec2_policy" {
  name = "pci_ec2_policy"
  role = aws_iam_role.pci_ec2_role.id
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
          aws_s3_bucket.pci_data_bucket.arn,
          "${aws_s3_bucket.pci_data_bucket.arn}/*"
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

resource "aws_iam_instance_profile" "pci_instance_profile" {
  name = "pci_instance_profile"
  role = aws_iam_role.pci_ec2_role.name
}

##############################################
# Compute Resources - EC2 Instance within the CDE
##############################################

resource "aws_instance" "pci_ec2" {
  ami                    = "ami-0c55b159cbfafe1f0"  # Replace with an approved AMI
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.pci_subnet_cde_a.id
  iam_instance_profile   = aws_iam_instance_profile.pci_instance_profile.name
  vpc_security_group_ids = [aws_security_group.pci_sg.id]
  ebs_block_device {
    device_name = "/dev/sda1"
    encrypted   = true
    kms_key_id  = aws_kms_key.pci_kms.arn
  }
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl enable httpd
    systemctl start httpd
  EOF
  tags = { Name = "pci-ec2", Environment = var.environment }
}

##############################################
# Security Groups - Restrictive Ingress/Egress for PCI Environment
##############################################

resource "aws_security_group" "pci_sg" {
  name        = "pci_sg"
  description = "Security group for PCI DSS compliant resources"
  vpc_id      = aws_vpc.pci_vpc.id

  ingress {
    description = "Allow HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.trusted_ip_range]
  }
  ingress {
    description = "Allow SSH traffic"
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
  tags = { Name = "pci_sg", Environment = var.environment }
}

##############################################
# Database Resources - RDS PostgreSQL with Encryption
##############################################

resource "aws_db_subnet_group" "pci_db_subnet" {
  name       = "pci-db-subnet"
  subnet_ids = [aws_subnet.pci_subnet_cde_a.id, aws_subnet.pci_subnet_cde_b.id]
  tags       = { Name = "pci-db-subnet", Environment = var.environment }
}

resource "aws_db_instance" "pci_rds" {
  identifier               = "pci-postgres"
  engine                   = "postgres"
  engine_version           = "13.4"
  instance_class           = "db.t3.micro"
  allocated_storage        = 20
  storage_encrypted        = true
  kms_key_id               = aws_kms_key.pci_kms.arn
  db_subnet_group_name     = aws_db_subnet_group.pci_db_subnet.name
  vpc_security_group_ids   = [aws_security_group.pci_sg.id]
  username                 = var.db_username
  password                 = var.db_password
  skip_final_snapshot      = true
  tags = {
    Name        = "pci-rds"
    Environment = var.environment
  }
}

##############################################
# Monitoring & Compliance - AWS Config and CloudTrail Integration
##############################################

resource "aws_config_configuration_recorder" "pci_config" {
  name     = "pci-config"
  role_arn = aws_iam_role.pci_config_role.arn
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_iam_role" "pci_config_role" {
  name = "pci_config_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "config.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_config_delivery_channel" "pci_config_channel" {
  name           = "pci-config-channel"
  s3_bucket_name = aws_s3_bucket.pci_log_bucket.id
  depends_on     = [aws_config_configuration_recorder.pci_config]
}

data "aws_caller_identity" "current" {}
