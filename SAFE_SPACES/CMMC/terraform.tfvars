# =============================
# Shared / Root-level Variables
# =============================

region           = "us-east-1"
environment      = "production"
trusted_ip_range = "203.0.113.0/24"
created_by       = "coldchainsecure"
project          = "CMMC Infra"
owner            = "Coldchain Secure"
cost_center      = "CyberSec001"

# =============================
# Compute Module
# =============================

ami_id          = "ami-0c55b159cbfafe1f0" # AMI used by EC2 instance in compute module
ebs_device_name = "/dev/sda1"
instance_type   = "t3.micro" # or t3.small, m5.large, etc.

# =============================
# RDS Module
# =============================

db_username         = "dbadmin"
db_password         = "YourSecurePasswordHere!" # Consider secure storage for production use
engine              = "postgres"
engine_version      = "13.4"
instance_class      = "db.t3.small"
allocated_storage   = 20
storage_encrypted   = true
skip_final_snapshot = true

# =============================
# Networking Module
# =============================

vpc_cidr            = "10.0.0.0/16"
vpc_name            = "cmmc-vpc"
subnet_cidr_a       = "10.0.1.0/24"
subnet_cidr_b       = "10.0.2.0/24"
route_cidr_block    = "0.0.0.0/0"
availability_zone_a = "us-east-1a"
availability_zone_b = "us-east-1b"

# === Security Group Rules ===
security_group_ingress_rules = [
  {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.0/24"]
    ipv6_cidr_blocks = ["::/0"]
  },
  {
    description = "Allow SSH from Admin VPN"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.10.0/24"]
  },
  {
    description     = "Internal SG Communication"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    # security_groups = []
  }
]

security_group_egress_rules = [
  {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  },
  {
    description     = "Allow internal SG egress"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    # security_groups = []
  }
]


# =============================
# Common Tag Prefix / Naming
# =============================

name_prefix = "cmmc" # Used to prefix resource names across modules

# =============================
# Logging Module
# =============================

retention_in_days   = 90
flow_log_group_name = "vpc-flow-logs"
flow_log_role_name  = "flow-role"

# =============================
# S3 Module
# =============================

data_bucket_name = "data_bucket"
log_bucket_name  = "log_bucket"
s3_acl           = "private"
sse_algorithm    = "aws:kms"

# =============================
# CLOUDFRONT Module
# =============================

cloudfront_domain_aliases = ["example.cmmcsecure.com"]

use_existing_route53 = false