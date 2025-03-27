resource "aws_iam_role" "ec2_role" {
  name = "${var.name_prefix}_ec2_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ec2_policy" {
  name = "${var.name_prefix}_ec2_policy"
  role = aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          var.data_bucket_arn,
          "${var.data_bucket_arn}/*"
        ]
      },
      {
        Effect   = "Allow",
        Action   = ["cloudwatch:PutMetricData"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.name_prefix}_instance_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "cmmc_ec2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name
  vpc_security_group_ids = var.security_group_ids

  ebs_block_device {
    device_name = "/dev/sda1"
    encrypted   = true
    kms_key_id  = var.kms_key_arn
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl enable httpd
              systemctl start httpd
              EOF

  tags = {
    Name        = "${var.name_prefix}-ec2"
    Environment = var.environment
  }
}
