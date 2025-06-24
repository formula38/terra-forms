#!/bin/bash

# Secure Environment Variable Setup for Terraform Build
# This script helps you set up environment variables without hardcoding credentials

echo "🔐 Terraform Build Environment Setup"
echo "====================================="

# Function to securely prompt for input
secure_input() {
    local prompt="$1"
    local var_name="$2"
    local is_secret="$3"
    
    if [ "$is_secret" = "true" ]; then
        # Use -s flag to hide input for secrets
        read -s -p "$prompt: " value
        echo  # Add newline after hidden input
    else
        read -p "$prompt: " value
    fi
    
    # Export the variable
    export "$var_name=$value"
    echo "✅ $var_name set"
}

# Check if AWS CLI is configured
if command -v aws &> /dev/null; then
    echo "🔍 Checking AWS CLI configuration..."
    if aws sts get-caller-identity &> /dev/null; then
        echo "✅ AWS CLI is configured and working"
        echo "📋 Current AWS identity:"
        aws sts get-caller-identity --query 'Arn' --output text
        
        # Option to use AWS CLI credentials
        read -p "🤔 Use AWS CLI credentials? (y/n): " use_aws_cli
        if [[ $use_aws_cli =~ ^[Yy]$ ]]; then
            echo "✅ Using AWS CLI credentials - no manual setup needed"
            echo "🚀 You can now run: docker-compose run --rm terraform-build"
            exit 0
        fi
    else
        echo "⚠️  AWS CLI is installed but not configured"
    fi
else
    echo "⚠️  AWS CLI not found - will need manual credential setup"
fi

echo ""
echo "🔑 Manual AWS Credential Setup"
echo "=============================="

# Prompt for AWS credentials
secure_input "AWS Access Key ID" "AWS_ACCESS_KEY_ID" "false"
secure_input "AWS Secret Access Key" "AWS_SECRET_ACCESS_KEY" "true"

# Optional session token (for temporary credentials)
read -p "🔑 Do you have an AWS Session Token? (y/n): " has_session_token
if [[ $has_session_token =~ ^[Yy]$ ]]; then
    secure_input "AWS Session Token" "AWS_SESSION_TOKEN" "true"
else
    export AWS_SESSION_TOKEN=""
fi

# AWS Region
read -p "🌍 AWS Region (default: us-east-1): " aws_region
export AWS_DEFAULT_REGION=${aws_region:-us-east-1}

echo ""
echo "🏗️  Terraform Configuration"
echo "==========================="

# Terraform variables
read -p "🏷️  Environment (default: production): " tf_env
export TF_VAR_environment=${tf_env:-production}

read -p "📁 Project name (default: BOA_Beta_v3): " tf_project
export TF_VAR_project=${tf_project:-BOA_Beta_v3}

read -p "👤 Owner (default: coldchainsecure): " tf_owner
export TF_VAR_owner=${tf_owner:-coldchainsecure}

read -p "💰 Cost Center (default: IT): " tf_cost_center
export TF_VAR_cost_center=${tf_cost_center:-IT}

echo ""
echo "✅ Environment variables set successfully!"
echo ""
echo "🚀 To run Terraform build:"
echo "   docker-compose run --rm terraform-build"
echo ""
echo "🚀 To apply changes:"
echo "   APPLY=true docker-compose run --rm terraform-build"
echo ""
echo "💡 Note: These variables are only set for this shell session."
echo "   To make them permanent, add them to your ~/.bashrc or ~/.zshrc"
echo ""
echo "🔒 Security reminder: Never commit credentials to version control!" 