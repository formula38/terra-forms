resource "aws_s3_bucket" "data" {
  bucket = var.data_bucket_name
  tags = merge(
    {
      Name = "${var.name_prefix}-data"
    },
    var.common_tags
  )
}

resource "aws_s3_bucket_acl" "data_acl" {
  bucket = aws_s3_bucket.data.id
  acl    = var.s3_acl
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_encryption" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = var.kms_key_arn
    }
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = var.log_bucket_name
  tags = merge(
    {
      Name = "${var.name_prefix}-logs"
    },
    var.common_tags
  )
}

resource "aws_s3_bucket_acl" "logs_acl" {
  bucket = aws_s3_bucket.logs.id
  acl    = var.s3_acl
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs_encryption" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = var.kms_key_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "data_block" {
  bucket = aws_s3_bucket.data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "logs_block" {
  bucket = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "data_policy" {
  bucket = aws_s3_bucket.data.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "DenyUnEncryptedUploads",
        Effect   = "Deny",
        Principal = "*",
        Action   = "s3:PutObject",
        Resource = "${aws_s3_bucket.data.arn}/*",
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      },
      {
        Sid      = "DenyInsecureTransport",
        Effect   = "Deny",
        Principal = "*",
        Action   = "s3:*",
        Resource = [
          "${aws_s3_bucket.data.arn}",
          "${aws_s3_bucket.data.arn}/*"
        ],
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# resource "aws_s3_bucket_policy" "data_policy" {
#   bucket = aws_s3_bucket.data.id

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Sid       = "EnforceTLSAccess",
#         Effect    = "Deny",
#         Principal = "*",
#         Action    = "s3:*",
#         Resource = [
#           "${aws_s3_bucket.data.arn}",
#           "${aws_s3_bucket.data.arn}/*"
#         ],
#         Condition = {
#           Bool = {
#             "aws:SecureTransport" = "false"
#           }
#         }
#       },
#       {
#         Sid       = "AllowCloudFrontReadOnlyAccess",
#         Effect    = "Allow",
#         Principal = {
#           Service = "cloudfront.amazonaws.com"
#         },
#         Action    = "s3:GetObject",
#         Resource  = "${aws_s3_bucket.data.arn}/*",
#         Condition = {
#           StringEquals = {
#             "AWS:SourceArn" = var.cloudfront_distribution_arn
#           }
#         }
#       }
#     ]
#   })

#   count = var.cloudfront_distribution_arn != "" ? 1 : 0
# }



resource "aws_s3_bucket_policy" "logs_policy" {
  bucket = aws_s3_bucket.logs.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowCloudTrailWrite",
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action = "s3:PutObject",
        Resource = "${aws_s3_bucket.logs.arn}/AWSLogs/${var.account_id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid = "EnforceTLSAccess",
        Effect = "Deny",
        Principal = "*",
        Action = "s3:*",
        Resource = [
          "${aws_s3_bucket.logs.arn}",
          "${aws_s3_bucket.logs.arn}/*"
        ],
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

