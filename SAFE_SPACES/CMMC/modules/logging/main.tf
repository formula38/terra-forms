##############################################
# modules/logging/main.tf - CMMC Flow Logs
##############################################

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = var.log_group_name
  retention_in_days = var.retention_in_days
  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role" "cmmc_flow_role" {
  name = var.flow_log_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "cmmc_flow_policy" {
  name = var.flow_log_policy_name
  role = aws_iam_role.cmmc_flow_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "vpc_flow_log" {
  vpc_id               = var.vpc_id
  traffic_type         = "ALL"
  log_destination      = aws_cloudwatch_log_group.cmmc_vpc_flow.arn
  log_destination_type = "cloud-watch-logs"
  iam_role_arn         = aws_iam_role.cmmc_flow_role.arn
  tags = {
    Environment = var.environment
  }
}
