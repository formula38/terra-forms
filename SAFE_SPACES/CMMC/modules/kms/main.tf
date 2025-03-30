resource "aws_kms_key" "cmmc_kms" {
  description             = "CMMC-compliant KMS key for data encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowAdminAccess",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      {
        Sid    = "AllowCloudTrailUsage",
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*"
        ],
        Resource = "*"
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.name_prefix}-kms"
      Environment = var.environment
    },
    var.common_tags
  )
}