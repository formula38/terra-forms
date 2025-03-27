resource "aws_s3_bucket" "cmmc_data_bucket" {
  bucket = var.data_bucket_name
  tags   = {
    Name = "cmmc-data-bucket"
  }
}

resource "aws_s3_bucket_acl" "cmmc_data_acl" {
  bucket = aws_s3_bucket.cmmc_data_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cmmc_data_enc" {
  bucket = aws_s3_bucket.cmmc_data_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

resource "aws_s3_bucket" "cmmc_log_bucket" {
  bucket = var.log_bucket_name
  tags   = {
    Name = "cmmc-log-bucket"
  }
}

resource "aws_s3_bucket_acl" "cmmc_log_acl" {
  bucket = aws_s3_bucket.cmmc_log_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cmmc_log_enc" {
  bucket = aws_s3_bucket.cmmc_log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}
