resource "aws_iam_role" "config_role" {
  name = "${var.name_prefix}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "config.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "config_policy" {
  name = "${var.name_prefix}-config-policy"
  role = aws_iam_role.config_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "AllowS3PutObject",
        Effect: "Allow",
        Action: [
          "s3:PutObject"
        ],
        Resource: "${var.log_bucket_arn}/AWSLogs/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid: "AllowConfigPermissions",
        Effect: "Allow",
        Action: [
          "config:Put*",
          "config:Get*",
          "config:Describe*"
        ],
        Resource: "*"
      }
    ]
  })
}


resource "aws_config_configuration_recorder" "recorder" {
  name     = "${var.name_prefix}-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "delivery" {
  name           = "${var.name_prefix}-delivery-channel"
  s3_bucket_name = var.log_bucket_name

  snapshot_delivery_properties {
    delivery_frequency = "Six_Hours" # Options: One_Hour, Three_Hours, Six_Hours, Twelve_Hours, TwentyFour_Hours
  }

  depends_on = [aws_config_configuration_recorder.recorder]
}

