/*
CMMC Compliance AWS Infrastructure
This configuration sets up an AWS environment meeting CMMC requirements.
CMMC controls include access control, audit logging, configuration management, incident response, and more.
*/

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
  backend "s3" {
    bucket         = "tf-cmmc-state-bucket"
    key            = "cmmc/main.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "tf-cmmc-lock-table"
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

// Random suffix for resource naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

// VPC and Networking
resource "aws_vpc" "cmmc_vpc" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "CMMC_VPC"
  }
}

resource "aws_subnet" "cmmc_subnet_a" {
  vpc_id            = aws_vpc.cmmc_vpc.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "CMMC_Subnet_A" }
}

resource "aws_subnet" "cmmc_subnet_b" {
  vpc_id            = aws_vpc.cmmc_vpc.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "us-east-1b"
  tags = { Name = "CMMC_Subnet_B" }
}

resource "aws_internet_gateway" "cmmc_igw" {
  vpc_id = aws_vpc.cmmc_vpc.id
  tags = { Name = "CMMC_IGW" }
}

resource "aws_route_table" "cmmc_route" {
  vpc_id = aws_vpc.cmmc_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cmmc_igw.id
  }
  tags = { Name = "CMMC_Route_Table" }
}

resource "aws_route_table_association" "cmmc_assoc_a" {
  subnet_id      = aws_subnet.cmmc_subnet_a.id
  route_table_id = aws_route_table.cmmc_route.id
}

resource "aws_route_table_association" "cmmc_assoc_b" {
  subnet_id      = aws_subnet.cmmc_subnet_b.id
  route_table_id = aws_route_table.cmmc_route.id
}

// VPC Flow Logs for audit requirements
resource "aws_cloudwatch_log_group" "cmmc_flow_logs" {
  name              = "/aws/vpc/cmmc-flow-logs"
  retention_in_days = 90
}

resource "aws_iam_role" "cmmc_flow_log_role" {
  name = "CMMC_Flow_Log_Role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "cmmc_flow_log_policy" {
  name = "CMMC_Flow_Log_Policy"
  role = aws_iam_role.cmmc_flow_log_role.id
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

resource "aws_flow_log" "cmmc_vpc_flow" {
  vpc_id               = aws_vpc.cmmc_vpc.id
  traffic_type         = "ALL"
  log_destination      = aws_cloudwatch_log_group.cmmc_flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  iam_role_arn         = aws_iam_role.cmmc_flow_log_role.arn
}

// KMS Key for encryption
resource "aws_kms_key" "cmmc_kms" {
  description             = "CMMC encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Sid       = "EnableIAMUserPermissions",
      Effect    = "Allow",
      Principal = { AWS = "*" },
      Action    = "kms:*",
      Resource  = "*"
    }]
  })
}

// S3 Bucket for sensitive data with encryption
resource "aws_s3_bucket" "cmmc_data" {
  bucket = "cmmc-data-${random_string.suffix.result}"
  tags = {
    Name = "CMMC_Data_Bucket"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cmmc_data_encryption" {
  bucket = aws_s3_bucket.cmmc_data.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cmmc_kms.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

// IAM Roles and Policies for least privilege access
resource "aws_iam_role" "cmmc_ec2_role" {
  name = "CMMC_EC2_Role"
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
  name = "CMMC_EC2_Policy"
  role = aws_iam_role.cmmc_ec2_role.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.cmmc_data.arn,
          "${aws_s3_bucket.cmmc_data.arn}/*"
        ]
      },
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

// EC2 instance for management
resource "aws_instance" "cmmc_server" {
  ami                    = "ami-0abcdef1234567890"  # Replace with a CMMC-approved AMI
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.cmmc_subnet_a.id
  iam_instance_profile   = aws_iam_instance_profile.cmmc_profile.name
  vpc_security_group_ids = [aws_security_group.cmmc_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y awslogs
              EOF

  tags = {
    Name = "CMMC_Server"
  }
}

resource "aws_iam_instance_profile" "cmmc_profile" {
  name = "CMMC_Instance_Profile"
  role = aws_iam_role.cmmc_ec2_role.name
}

// Security Group for instance
resource "aws_security_group" "cmmc_sg" {
  name   = "CMMC_SG"
  vpc_id = aws_vpc.cmmc_vpc.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
  }
  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "CMMC_SG"
  }
}

// AWS Config for continuous auditing
resource "aws_config_configuration_recorder" "cmmc_recorder" {
  name     = "cmmc-recorder"
  role_arn = aws_iam_role.cmmc_config_role.arn
}

resource "aws_iam_role" "cmmc_config_role" {
  name = "CMMC_Config_Role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Principal = { Service = "config.amazonaws.com" },
      Effect    = "Allow"
    }]
  })
}

resource "aws_config_delivery_channel" "cmmc_channel" {
  name           = "cmmc-delivery-channel"
  s3_bucket_name = aws_s3_bucket.cmmc_data.id
  depends_on     = [aws_config_configuration_recorder.cmmc_recorder]
}
