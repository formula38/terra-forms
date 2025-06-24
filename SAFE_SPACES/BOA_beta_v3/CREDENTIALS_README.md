# 🔐 Secure Credential Management for Terraform Build

This guide explains how to manage AWS credentials securely without hardcoding them in your project.

## 🚀 Quick Start

### Option 1: Use AWS CLI (Recommended for Local Development)

If you have AWS CLI configured, you don't need to set any environment variables:

```bash
# Check if AWS CLI is configured
aws sts get-caller-identity

# Run Terraform build
docker-compose run --rm terraform-build
```

### Option 2: Interactive Setup

Use the provided setup script:

```bash
# Run the interactive setup
./set_env.sh

# Then run Terraform build
docker-compose run --rm terraform-build
```

### Option 3: Manual Environment Variables

Set environment variables manually:

```bash
# Set AWS credentials
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
export AWS_DEFAULT_REGION="us-east-1"

# Set Terraform variables
export TF_VAR_environment="production"
export TF_VAR_project="BOA_Beta_v3"
export TF_VAR_owner="coldchainsecure"
export TF_VAR_cost_center="IT"

# Run Terraform build
docker-compose run --rm terraform-build
```

## 🔧 Advanced Configuration

### AWS CLI Profiles

If you have multiple AWS accounts, use profiles:

```bash
# Configure a profile
aws configure --profile terraform-dev

# Use the profile in docker-compose
AWS_PROFILE=terraform-dev docker-compose run --rm terraform-build
```

### IAM Roles (Production)

For production deployments, use IAM roles instead of access keys:

```bash
# If running on EC2 with IAM role, no credentials needed
docker-compose run --rm terraform-build
```

### Temporary Credentials

For temporary access (e.g., from AWS SSO):

```bash
# Get temporary credentials
aws sts get-session-token --duration-seconds 3600

# Set the temporary credentials
export AWS_ACCESS_KEY_ID="temporary_access_key"
export AWS_SECRET_ACCESS_KEY="temporary_secret_key"
export AWS_SESSION_TOKEN="temporary_session_token"

# Run Terraform build
docker-compose run --rm terraform-build
```

## 🛡️ Security Best Practices

### 1. Never Hardcode Credentials

❌ **Don't do this:**
```bash
# Never put real credentials in scripts or config files
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

✅ **Do this instead:**
```bash
# Use environment variables
export AWS_ACCESS_KEY_ID="your_key"
export AWS_SECRET_ACCESS_KEY="your_secret"
```

### 2. Use Least Privilege

Create IAM users/roles with only the necessary permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "s3:*",
                "iam:*",
                "cloudwatch:*",
                "logs:*",
                "rds:*",
                "route53:*",
                "acm:*",
                "cloudfront:*",
                "wafv2:*",
                "config:*",
                "kms:*"
            ],
            "Resource": "*"
        }
    ]
}
```

### 3. Rotate Credentials Regularly

- Rotate access keys every 90 days
- Use temporary credentials when possible
- Monitor credential usage with CloudTrail

### 4. Use AWS Secrets Manager

For production environments, consider using AWS Secrets Manager:

```bash
# Store credentials in Secrets Manager
aws secretsmanager create-secret \
    --name "terraform-credentials" \
    --description "Terraform build credentials" \
    --secret-string '{"AWS_ACCESS_KEY_ID":"your_key","AWS_SECRET_ACCESS_KEY":"your_secret"}'

# Retrieve and use in your application
CREDENTIALS=$(aws secretsmanager get-secret-value --secret-id "terraform-credentials" --query SecretString --output text)
export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r .AWS_ACCESS_KEY_ID)
export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r .AWS_SECRET_ACCESS_KEY)
```

## 🔍 Troubleshooting

### Common Issues

1. **"No credentials found"**
   ```bash
   # Check if AWS CLI is configured
   aws configure list
   
   # Or set environment variables
   export AWS_ACCESS_KEY_ID="your_key"
   export AWS_SECRET_ACCESS_KEY="your_secret"
   ```

2. **"Access Denied"**
   - Check IAM permissions
   - Verify the AWS account/region
   - Ensure credentials are not expired

3. **"Invalid session token"**
   ```bash
   # Clear session token if not using temporary credentials
   unset AWS_SESSION_TOKEN
   ```

### Debug Mode

Enable debug logging:

```bash
# Set debug environment variable
export TF_LOG=DEBUG

# Run with verbose output
docker-compose run --rm terraform-build
```

## 📋 Environment Variables Reference

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `AWS_ACCESS_KEY_ID` | AWS access key | - | Yes* |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key | - | Yes* |
| `AWS_SESSION_TOKEN` | AWS session token | - | No |
| `AWS_DEFAULT_REGION` | AWS region | us-east-1 | No |
| `TF_VAR_environment` | Environment name | production | No |
| `TF_VAR_project` | Project name | BOA_Beta_v3 | No |
| `TF_VAR_owner` | Resource owner | coldchainsecure | No |
| `TF_VAR_cost_center` | Cost center | IT | No |
| `APPLY` | Apply changes | false | No |

*Not required if using AWS CLI profiles or IAM roles

## 🚀 Production Deployment

For production deployments, consider:

1. **CI/CD Integration**: Use GitHub Actions, GitLab CI, or AWS CodePipeline
2. **IAM Roles**: Use EC2 instance profiles or ECS task roles
3. **Secrets Management**: Use AWS Secrets Manager or HashiCorp Vault
4. **Audit Logging**: Enable CloudTrail for all API calls
5. **Backup Strategy**: Implement state file backups and versioning

## 📚 Additional Resources

- [AWS CLI Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/) 