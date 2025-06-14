#!/bin/bash
yum update -y
amazon-linux-extras enable epel
yum install -y epel-release

# Install Apache
yum install -y httpd
systemctl enable httpd
systemctl start httpd

# Install CloudWatch Agent
yum install -y amazon-cloudwatch-agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -c ssm:AmazonCloudWatch-linux-config \
  -s

# Install and configure SSM Agent
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
