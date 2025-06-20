resource "aws_iam_role" "ec2_role" {
  name = "${var.common_tags["Name"]}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ec2_policy" {
  name = "${var.common_tags["Name"]}-ec2-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # --- S3 Bucket Permissions ---
      {
        Sid      = "ListDataBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = var.data_bucket_arn
        Condition = {
          StringLike = {
            "s3:prefix" = ["home/", "logs/", "temp/*"]
          }
        }
      },
      {
        Sid    = "ReadWriteDataObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${var.data_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      },

      # --- CloudWatch Metrics Publishing ---
      {
        Sid      = "SendCustomMetrics"
        Effect   = "Allow"
        Action   = "cloudwatch:PutMetricData"
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:Namespace" = "Custom/CMMC"
          }
        }
      }
    ]
  })
}


resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.common_tags["Name"]}-instance-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "cmmc_ec2" {
  ami           = var.ami_id
  instance_type = var.instance_type

  subnet_id              = var.subnet_id
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  vpc_security_group_ids = var.security_group_ids

  ebs_block_device {
    device_name = var.ebs_device_name
    encrypted   = true
    kms_key_id  = var.kms_key_arn
  }

  disable_api_termination = true
  monitoring              = true
  source_dest_check       = true

  user_data_base64 = base64encode(file(var.user_data_script_path))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = merge(
    {
      Name        = "${var.common_tags["Name"]}-ec2-instance"
      Environment = var.environment
    },
    var.common_tags
  )
}
