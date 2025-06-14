resource "aws_kms_key" "cmmc_kms" {
  description             = "CMMC-compliant KMS key for data encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Admin/root access
      {
        Sid: "AllowAdminKeyManagement",
        Effect: "Allow",
        Principal: {
          AWS: "arn:aws:iam::${var.account_id}:root"
        },
        Action: [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ],
        Resource: "*"
      },

      # CloudTrail encryption permissions
      {
        Sid: "AllowCloudTrailKMSUsage",
        Effect: "Allow",
        Principal: {
          Service: "cloudtrail.amazonaws.com"
        },
        Action: [
          "kms:GenerateDataKey*",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:DescribeKey"
        ],
        Resource: "*"
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
