resource "aws_kms_key" "cmmc_kms" {
  description             = "CMMC-compliant KMS key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowAdministration",
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action    = "kms:*",
        Resource  = "*"
      },
      {
        Sid       = "AllowUsageByServices",
        Effect    = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
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

data "aws_caller_identity" "current" {}
