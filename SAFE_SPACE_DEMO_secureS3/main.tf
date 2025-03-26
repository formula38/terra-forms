# Creating a minimal setup for deploying
# encrypted S3 buckets,configuring IAM roles,
# and setting up AWS Config rules using Terraform


provider "aws" {
  region     = "us-west-2"
  access_key = ""
  secret_key = ""
}

resource "aws_kms_key" "mykey" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket" "mybucket" {
  bucket = "mybucket"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.mybucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.mykey.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_iam_role" "example_role" {
  name = "example-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "example_policy" {
  name   = "example_policy"
  role   = aws_iam_role.example_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.mybucket.arn,
          "${aws_s3_bucket.mybucket.arn}/*",
        ]
      },
    ]
  })
}

resource "aws_config_configuration_recorder" "main" {
  name     = "main"
  role_arn = aws_iam_role.example_role.arn

  recording_group {
    all_supported = true
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "main"
  s3_bucket_name = aws_s3_bucket.mybucket.bucket
}

resource "aws_iam_role_policy_attachment" "config_policy_attachment" {
  role       = aws_iam_role.example_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}




# Initialize Terraform
#   terrafrom init
#
# Validate Configuration
#   terrafom validate
#
# Plan the Deployment
#   terrafrom plan
#
# Apply the Configuration
#   terraform apply
#
#







