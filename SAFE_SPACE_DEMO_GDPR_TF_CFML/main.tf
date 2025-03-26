# Terraform: Terraform will handle the infrastructure provisioning and security setup,
# including the VPC, subnets, IAM roles, security groups, S3 buckets, RDS instance, and
# EC2 instances. Terraform will also deploy an EC2 instance using an Adobe ColdFusion AMI.



provider "aws" {
  region     = "eu-west-1"  # Use an EU region for GDPR compliance
  access_key = ""
  secret_key = ""
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main_vpc"
  }
}

resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"
  tags = {
    Name = "main_subnet"
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main_igw"
  }
}

resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }
  tags = {
    Name = "main_rt"
  }
}

resource "aws_route_table_association" "main_rta" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_rt.id
}

resource "aws_kms_key" "mykey" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
  enable_key_rotation     = true  # Enable key rotation for compliance
  tags = {
    Name = "gdpr_kms_key"
  }
}

resource "aws_s3_bucket" "mybucket" {
  bucket = "my-gdpr-compliant-bucket"
  tags = {
    Name        = "gdpr_s3_bucket"
    Environment = "production"
  }
}

resource "aws_s3_bucket" "log_bucket" {
  bucket = "my-gdpr-compliant-log-bucket"
  tags = {
    Name        = "gdpr_s3_bucket"
    Environment = "production"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secure_s3_mybucket" {
  bucket = aws_s3_bucket.mybucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.mykey.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web_sg"
  }
}

resource "aws_iam_role" "example_ec2_rol" {
  name = "example_ec2_rol"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "example_s3_policy" {
  name = "example_s3_policy"
  role = aws_iam_role.example_ec2_rol.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",  # Allow putting logs
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.mybucket.arn,
          "${aws_s3_bucket.mybucket.arn}/*",
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "config_policy_attachment" {
  role       = aws_iam_role.example_ec2_rol.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_iam_instance_profile" "example_ec2_profile" {
  name = "example_ec2_profile"
  role = aws_iam_role.example_ec2_rol.name
}

resource "aws_instance" "web_server" {
  ami           = "ami-xxxxxxxx"  # Adobe ColdFusion AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.main_subnet.id
  iam_instance_profile = aws_iam_instance_profile.example_ec2_profile.name

  security_groups = [aws_security_group.web_sg.name]

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y nginx unzip curl

    # Install Terraform
    TERRAFORM_VERSION="1.5.6"
    curl -LO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    sudo mv terraform /usr/bin/
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

    # Create the directory for the ColdFusion project and Terraform files
    mkdir -p /var/www/html/terraform

    # Embed the main.cfm file into the instance
    cat <<'EOC' > /var/www/html/main.cfm
    <cfscript>
        // Define the paths to your Terraform files
        terraformDirectory = "/var/www/html/terraform";
        terraformExecutable = "/usr/bin/terraform";

        // Initialize Terraform
        initCommand = terraformExecutable & " init";
        result = cfexecute(name="bash", arguments="-c " & initCommand, timeout="600", variable="initOutput");
        writeOutput("<h3>Terraform Initialization:</h3>");
        writeOutput("<pre>" & initOutput & "</pre>");

        // Apply additional Terraform configuration if needed
        applyCommand = terraformExecutable & " apply -auto-approve";
        result = cfexecute(name="bash", arguments="-c " & applyCommand, timeout="1200", variable="applyOutput");
        writeOutput("<h3>Terraform Apply:</h3>");
        writeOutput("<pre>" & applyOutput & "</pre>");

        // Output or analyze specific Terraform outputs
        outputCommand = terraformExecutable & " output -json";
        result = cfexecute(name="bash", arguments="-c " & outputCommand, timeout="600", variable="outputJson");
        terraformOutputs = deserializeJSON(outputJson);
        writeOutput("<h3>Terraform Outputs:</h3>");
        writeOutput("<pre>" & serializeJSON(terraformOutputs, true) & "</pre>");

        // Analyze logs or outputs for GDPR compliance
        s3Encryption = terraformOutputs["mybucket_encryption"]["value"];
        if (s3Encryption eq "enabled") {
            writeOutput("<p>S3 Bucket is encrypted: Compliant</p>");
        } else {
            writeOutput("<p>S3 Bucket is not encrypted: Non-compliant</p>");
        }
    </cfscript>
    EOC

    # Embed the main.tf Terraform configuration file
    cat <<'EOT' > /var/www/html/terraform/main.tf
    provider "aws" {
      region     = "eu-west-1"
    }

    resource "aws_s3_bucket" "mybucket" {
      bucket = "my-second-bucket"
      acl    = "private"
    }
    EOT

    # Start ColdFusion service if needed
    sudo service coldfusion start
  EOF

  tags = {
    Name = "web_server"
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "main-subnet-group"
  subnet_ids = [aws_subnet.main_subnet.id]

  tags = {
    Name = "main-subnet-group"
  }
}

resource "aws_db_instance" "postgres_instance" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "13.3"
  instance_class       = "db.t3.micro"
  db_name              = "mydb"
  username             = "admin"
  password             = "password123"  # Store sensitive data securely
  parameter_group_name = "default.postgres13"
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  multi_az             = true  # Multi-AZ for high availability
  publicly_accessible  = false  # Keep the database private
  storage_encrypted    = true
  kms_key_id           = aws_kms_key.mykey.arn
  backup_retention_period = 7  # Retain backups for 7 days
  delete_automated_backups = true

  tags = {
    Name = "postgres_instance"
    Environment = "production"
  }
}

resource "aws_config_configuration_recorder" "main" {
  name     = "main"
  role_arn = aws_iam_role.example_ec2_rol.arn

  recording_group {
    all_supported = true
  }

  depends_on = [aws_iam_role_policy_attachment.config_policy_attachment]
}

resource "aws_config_delivery_channel" "main" {
  name           = "main"
  s3_bucket_name = aws_s3_bucket.mybucket.bucket
}

resource "aws_cloudtrail" "main" {
  name                          = "main-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.log_bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
    data_resource {
      type = "AWS::S3::Object"
      values = [
        aws_s3_bucket.mybucket.arn,
        "${aws_s3_bucket.mybucket.arn}/*",
      ]
    }
  }
}

output "mybucket_encryption" {
  value = aws_s3_bucket_server_side_encryption_configuration.secure_s3_mybucket.rule.apply_server_side_encryption_by_default.sse_algorithm != "" ? "enabled" : "not enabled"
}
