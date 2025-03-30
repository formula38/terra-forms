resource "aws_cloudwatch_log_group" "cmmc_vpc_flow" {
  name              = var.log_deestination
  retention_in_days = var.retention_in_days

  tags = merge(
    {
      Environment = var.environment
    },
    var.common_tags
  )
}

resource "aws_iam_role" "cmmc_flow_role" {
  name = "${var.name_prefix}-flow-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })

  tags = merge(
    {
      Environment = var.environment
    },
    var.common_tags
  )
}

resource "aws_iam_role_policy" "cmmc_flow_policy" {
  name = "cmmc_flow_log_policy"
  role = aws_iam_role.cmmc_flow_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "vpc_flow_log" {
   log_destination_type = "cloud-watch-logs"
   log_destination      = var.log_deestination
   iam_role_arn         = aws_iam_role.cmmc_flow_role.arn
   traffic_type         = "ALL"
   vpc_id               = var.vpc_id
}
