resource "aws_iam_role" "config_role" {
  name = "${var.name_prefix}_config_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "config.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_config_configuration_recorder" "recorder" {
  name     = "${var.name_prefix}_config_recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "channel" {
  name           = "${var.name_prefix}_config_channel"
  s3_bucket_name = var.log_bucket_name

  depends_on = [aws_config_configuration_recorder.recorder]
}
