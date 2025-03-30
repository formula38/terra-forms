# =============================
# Shared / Root-level Variables
# =============================

region           = "us-east-1"
environment      = "production"
trusted_ip_range = "203.0.113.0/24"
created_by       = "coldchainsecure"
created_on       = "2025-03-28" # Or dynamically from automation


# =============================
# Compute Module
# =============================

ami_id          = "ami-0c55b159cbfafe1f0" # AMI used by EC2 instance in compute module
ebs_device_name = "/dev/sda1"

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

vpc_cidr         = "10.0.0.0/16"
vpc_name         = "cmmc-vpc"
subnet_cidr_a    = "10.0.1.0/24"
subnet_cidr_b    = "10.0.2.0/24"
route_cidr_block = "0.0.0.0/0"

# =============================
# Common Tag Prefix / Naming
# =============================

name_prefix        = "cmmc" # Used to prefix resource names across modules
flow_log_role_name = "flow-role"

# =============================
# Logging Module
# =============================

retention_in_days = 90
log_destination   = "vpc-flow-logs"

# =============================
# S3 Module
# =============================

data_bucket_name = "data_bucket"
log_bucket_name  = "log_bucket"
s3_acl           = "private"
sse_algorithm    = "aws:kms"
