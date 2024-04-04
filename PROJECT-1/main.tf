provider "aws" {
  region = "us-west-1"

  access_key = ""
  secret_key = ""
}

# 1. Create vpn
resource "aws_vpc" "vpc_custom" {
  cidr_block = "10.0.0.0/16"
}
# 2. Create Internet Gateway
resource "aws_internet_gateway" "ig_custom" {
  vpc_id = aws_vpc.vpc_custom.id
}
# 3. Create Custom Route Table
resource "aws_route_table" "rt_custom" {
  vpc_id = aws_vpc.vpc_custom.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig_custom.id
  }

  tags = {
    "Name" = "rt_custom"
  }
}
# 4. Create a Subnet
resource "aws_subnet" "subnet_custom" {
  vpc_id = aws_vpc.vpc_custom.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-1a"

  tags = {
    "Name" = "subnet_custom"
  }
}
# 5. Associate Subnet with Route Table
resource "aws_route_table_association" "rt_custom_association" {
  route_table_id = aws_route_table.rt_custom.id
  subnet_id = aws_subnet.subnet_custom.id
}
# 6. Create Security Group to Allow ports 22, 80, 443
resource "aws_security_group" "allow_web" {
  name = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id = aws_vpc.vpc_custom.id

  ingress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port = 08
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1" # any protocol
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "allow_web"
  }
}
# 7. Create a Network Interface with an IP in the Subnet whtat was Created in Step 4
resource "aws_network_interface" "nic_custom" {
  subnet_id = aws_subnet.subnet_custom.id
  private_ip = "10.0.1.50" # within the subnet range
  security_groups = [aws_security_group.allow_web.id]
}
# 8. Assign an elastic IP to the network interface Created in Step 7
resource "aws_eip" "eip_custom" {
  vpc = true
  network_interface = aws_network_interface.nic_custom.id
  associate_with_private_ip = "10.0.0.10"
  depends_on = [aws_internet_gateway.ig_custom]
}
# 9. Create Ubuntu Server and Install/Enable Apache2
resource "aws_instance" "web_server" {
  ami           = "ami-085925f297f89fce1"
  instance_type = "t2.micro"
  availability_zone = "us-west-1a"
  key_name = "key-party"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.nic_custom.id
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c `echo your very first web serv > /var/www/html/index.html`
                EOF

  tags = {
    "Name" = "web_server"
  }
}
# rds database
resource "aws_db_instance" "default" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}
# s3 bucket
resource "aws_s3_bucket" "example" {
  bucket = "my-tf-test-bucket"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}
