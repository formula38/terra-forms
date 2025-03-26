##############################################
# main-fedramp.tf - AWS Infrastructure for FedRAMP Compliance
##############################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
  backend "s3" {
    bucket         = "tf-state-fedramp"             # Replace with your state bucket name
    key            = "terraform/state/fedramp.tfstate"
    region         = var.region
    encrypt        = true
    dynamodb_table = "tf-locks-fedramp"             # Replace with your DynamoDB lock table name
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
  description = "Trusted IP range for accessing resources"
  default     = "203.0.113.0/24"
}

variable "db_username" {
  description = "Database username"
  default     = "fedramp_dbadmin"
}

variable "db_password" {
  description = "Database password (sensitive)"
  type        = string
  sensitive   = true
}

provider "aws" {
  region = var.region
}

# Generate randomized suffixes for unique bucket naming
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
# Networking: VPC, Subnets, Internet Gateway, and Routing
##############################################
resource "aws_vpc" "fedramp_vpc" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "fedramp-vpc"
  }
}

resource "aws_subnet" "fedramp_subnet_a" {
  vpc_id            = aws_vpc.fedramp_vpc.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "${var.region}a"
  tags = {
    Name = "fedramp-subnet-a"
  }
}

resource "aws_subnet" "fedramp_subnet_b" {
  vpc_id            = aws_vpc.fedramp_vpc.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "${var.region}b"
  tags = {
    Name = "fedramp-subnet-b"
  }
}

resource "aws_internet_gateway" "fedramp_igw" {
  vpc_id = aws_vpc.fedramp_vpc.id
  tags = {
    Name = "fedramp-igw"
  }
}

resource "aws_route_table" "fedramp_rt" {
  vpc_id = aws_vpc.fedramp_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.fedramp_igw.id
  }
  tags = {
    Name = "fedramp-rt"
  }
}

resource "aws_route_table_association" "fedramp_rta_a" {
  subnet_id      = aws_subnet.fedramp_subnet_a.id
  route_table_id = aws_route_table.fedramp_rt.id
}

resource "aws_route_table_association" "fedramp_rta_b" {
  subnet_id      = aws_subnet.fedramp_subnet_b.id
  route_table_id = aws_route_table.fedramp_rt.id
}

##############################################
# VPC Flow Logs for Network Auditing
##############################################
resource "aws_cloudwatch_log_group" "fedramp_vpc_flow" {
  name              = "/aws/vpc/fedramp-flow-logs"
  retention_in_days = 90
}

resource "aws_iam_role" "fedramp_flow_role" {
  name = "fedramp_flow_log_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "fedramp_flow_policy" {
  name = "fedramp_flow_log_policy"
  role = aws_iam_role.fedramp_flow_role.id
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

resource "aws_flow_log" "fedramp_flow" {
  vpc_id               = aws_vpc.fedramp_vpc.id
  traffic_type         = "ALL"
  log_destination      = aws_cloudwatch_log_group.fedramp_vpc_flow.arn
  log_destination_type = "cloud-watch-logs"
  iam_role_arn         = aws_iam_role.fedramp_flow_role.arn
}

##############################################
# Encryption: KMS Key for FedRAMP-Compliant Encryption
##############################################
resource "aws_kms_key" "fedramp_kms" {
  description             = "KMS key for FedRAMP compliant encryption"
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
        Sid       = "AllowFedRAMPServices",
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
# Storage: S3 Buckets with Server-Side Encryption
##############################################
resource "aws_s3_bucket" "fedramp_data_bucket" {
  bucket = "fedramp-data-bucket-${random_string.bucket_suffix.result}"
  acl    = "private"
  tags = {
    Name        = "fedramp-data-bucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "fedramp_data_bucket_enc" {
  bucket = aws_s3_bucket.fedramp_data_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.fedramp_kms.arn
    }
  }
}

resource "aws_s3_bucket" "fedramp_log_bucket" {
  bucket = "fedramp-log-bucket-${random_string.log_bucket_suffix.result}"
  acl    = "private"
  tags = {
    Name        = "fedramp-log-bucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "fedramp_log_bucket_enc" {
  bucket = aws_s3_bucket.fedramp_log_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.fedramp_kms.arn
    }
  }
}

##############################################
# Compute: EC2 Instance and IAM Roles (Least Privilege)
##############################################
resource "aws_iam_role" "fedramp_ec2_role" {
  name = "fedramp_ec2_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "fedramp_ec2_policy" {
  name = "fedramp_ec2_policy"
  role = aws_iam_role.fedramp_ec2_role.id
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
          aws_s3_bucket.fedramp_data_bucket.arn,
          "${aws_s3_bucket.fedramp_data_bucket.arn}/*"
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

resource "aws_iam_instance_profile" "fedramp_instance_profile" {
  name = "fedramp_instance_profile"
  role = aws_iam_role.fedramp_ec2_role.name
}

resource "aws_instance" "fedramp_ec2" {
  ami                    = "ami-0c55b159cbfafe1f0"  # Example AMI – adjust as needed
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.fedramp_subnet_a.id
  iam_instance_profile   = aws_iam_instance_profile.fedramp_instance_profile.name
  vpc_security_group_ids = [aws_security_group.fedramp_sg.id]
  ebs_block_device {
    device_name = "/dev/sda1"
    encrypted   = true
    kms_key_id  = aws_kms_key.fedramp_kms.arn
  }
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl enable httpd
    systemctl start httpd
  EOF
  tags = {
    Name        = "fedramp-ec2"
    Environment = var.environment
  }
}

resource "aws_security_group" "fedramp_sg" {
  name        = "fedramp_sg"
  description = "Security group for FedRAMP compliant resources"
  vpc_id      = aws_vpc.fedramp_vpc.id

  ingress {
    description = "Allow HTTPS from trusted IP range"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.trusted_ip_range]
  }
  ingress {
    description = "Allow SSH from trusted IP range"
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
    Name        = "fedramp_sg"
    Environment = var.environment
  }
}

##############################################
# Database: RDS PostgreSQL with Encryption and High Availability
##############################################
resource "aws_db_subnet_group" "fedramp_db_subnet" {
  name       = "fedramp-db-subnet"
  subnet_ids = [aws_subnet.fedramp_subnet_a.id, aws_subnet.fedramp_subnet_b.id]
  tags = {
    Name        = "fedramp-db-subnet"
    Environment = var.environment
  }
}

resource "aws_db_instance" "fedramp_rds" {
  identifier               = "fedramp-postgres"
  engine                   = "postgres"
  engine_version           = "13.4"
  instance_class           = "db.t3.micro"
  allocated_storage        = 20
  storage_encrypted        = true
  kms_key_id               = aws_kms_key.fedramp_kms.arn
  db_subnet_group_name     = aws_db_subnet_group.fedramp_db_subnet.name
  vpc_security_group_ids   = [aws_security_group.fedramp_sg.id]
  username                 = var.db_username
  password                 = var.db_password
  skip_final_snapshot      = true
  tags = {
    Name        = "fedramp-rds"
    Environment = var.environment
  }
}

##############################################
# Monitoring & Audit: AWS Config for Continuous Monitoring
##############################################
resource "aws_config_configuration_recorder" "fedramp_config" {
  name     = "fedramp-config"
  role_arn = aws_iam_role.fedramp_config_role.arn
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_iam_role" "fedramp_config_role" {
  name = "fedramp_config_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "config.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_config_delivery_channel" "fedramp_config_channel" {
  name           = "fedramp-config-channel"
  s3_bucket_name = aws_s3_bucket.fedramp_log_bucket.id
  depends_on     = [aws_config_configuration_recorder.fedramp_config]
}

data "aws_caller_identity" "current" {}
