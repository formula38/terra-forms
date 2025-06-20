# =============================
# Shared / Root-level Variables
# =============================

cost_center      = "CyberSec001"
created_by       = "coldchainsecure"
environment      = "production"
owner            = "Coldchain Secure"
project          = "CMMC Infra"
region           = "us-east-1"
trusted_ip_range = "203.0.113.0/24"

# =============================
# Common Tag Prefix / Naming
# =============================

name_prefix = "cmmc"

# =============================
# Compute Module
# =============================

ami_id          = "ami-0c55b159cbfafe1f0"
ebs_device_name = "/dev/sda1"
instance_type   = "t3.micro"
user_data_script_path = "../../backend/scripts/infra/ec2_user_data.sh"


# =============================
# RDS Module
# =============================

allocated_storage   = 20
db_password         = "YourSecurePasswordHere!" # 🔐 Consider storing securely
db_username         = "dbadmin"
engine              = "postgres"
engine_version      = "13.4"
instance_class      = "db.t3.small"
skip_final_snapshot = true
storage_encrypted   = true

# =============================
# Networking Module
# =============================

availability_zone_a = "us-east-1a"
availability_zone_b = "us-east-1b"
route_cidr_block    = "0.0.0.0/0"
subnet_cidr_a       = "10.0.1.0/24"
subnet_cidr_b       = "10.0.2.0/24"
vpc_cidr            = "10.0.0.0/16"
vpc_name            = "cmmc-vpc"

# === Security Group Rules ===

security_group_ingress_rules = [
  {
    description      = "Allow HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["203.0.113.0/24"]
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
    description = "Internal SG Communication"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
  }
]

security_group_egress_rules = [
  {
    description      = "Allow all outbound"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  },
  {
    description = "Allow internal SG egress"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }
]

# =============================
# Logging Module
# =============================

flow_log_group_name = "vpc-flow-logs"
flow_log_role_name  = "flow-role"
retention_in_days   = 90

# =============================
# S3 Module
# =============================

data_bucket_name = "data_bucket"
log_bucket_name  = "log_bucket"
s3_acl           = "private"
sse_algorithm    = "aws:kms"

# =============================
# CloudFront Module
# =============================

cloudfront_domain_aliases = ["example.cmmcsecure.com"]
use_existing_route53      = false
