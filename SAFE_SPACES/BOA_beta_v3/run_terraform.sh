#!/bin/bash

# Terraform Build Script with Automatic AWS Credential Extraction
# This script extracts AWS credentials from your host AWS CLI and runs the Terraform container

echo "🔐 Terraform Build with AWS Credentials"
echo "======================================="

# Check if AWS CLI is configured
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install AWS CLI first."
    exit 1
fi

# Test AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI not configured or credentials not working."
    echo "Please run: aws configure"
    exit 1
fi

echo "✅ AWS CLI configured and working"
echo "📋 AWS Identity: $(aws sts get-caller-identity --query 'Arn' --output text)"

# Extract AWS credentials
echo "🔍 Extracting AWS credentials..."

# Get AWS credentials from CLI
AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
AWS_DEFAULT_REGION=$(aws configure get region || echo "us-east-1")

# Check if credentials were extracted successfully
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "❌ Failed to extract AWS credentials from AWS CLI"
    exit 1
fi

echo "✅ AWS credentials extracted successfully"
echo "🌍 Region: $AWS_DEFAULT_REGION"

# Set environment variables for docker-compose
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION

# Set Terraform variables with defaults
export TF_VAR_environment=${TF_VAR_environment:-production}
export TF_VAR_project=${TF_VAR_project:-BOA_Beta_v3}
export TF_VAR_owner=${TF_VAR_owner:-coldchainsecure}
export TF_VAR_cost_center=${TF_VAR_cost_center:-IT}

echo ""
echo "🚀 Running Terraform build..."
echo "Environment: $TF_VAR_environment"
echo "Project: $TF_VAR_project"
echo "Owner: $TF_VAR_owner"
echo "Cost Center: $TF_VAR_cost_center"
echo ""

# Run the Terraform container
docker-compose run --rm terraform-build

echo ""
echo "✅ Terraform build completed!" 