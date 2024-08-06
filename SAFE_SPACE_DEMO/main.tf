# Creating a minimal setup for deploying
# encrypted S3 buckets,configuring IAM roles,
# and setting up AWS Config rules using Terraform


# - **AWS Provider:** Specifies the AWS region.
provider "aws" {
  region = "us-west-2"

  access_key = ""
  secret_key = ""
}


# - **S3 Bucket:** Creates an encrypted S3 bucket with server-side encryption using AES256.
resource "aws_s3_bucket" "encrypted_bucket" {
  bucket = "my-secure-bucket"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}


# - **IAM Role:** Creates an IAM role that can be assumed by EC2 instances.
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


# - **IAM Role Policy:** Attaches a policy to the IAM role allowing access to the S3 bucket.
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
          aws_s3_bucket.encrypted_bucket.arn,
          "${aws_s3_bucket.encrypted_bucket.arn}/*",
        ]
      },
    ]
  })
}


# - **AWS Config Recorder:** Sets up AWS Config to record configuration changes.
resource "aws_config_configuration_recorder" "main" {
  name     = "main"
  role_arn = aws_iam_role.example_role.arn

  recording_group {
    all_supported = true
  }
}


# - **AWS Config Delivery Channel:** Configures AWS Config to deliver configuration snapshots to the S3 bucket.
resource "aws_config_delivery_channel" "main" {
  name           = "main"
  s3_bucket_name = aws_s3_bucket.encrypted_bucket.bucket
}


# - **IAM Role Policy Attachment:** Attaches the AWSConfigRole managed policy to the IAM role to allow AWS Config to use it.
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







