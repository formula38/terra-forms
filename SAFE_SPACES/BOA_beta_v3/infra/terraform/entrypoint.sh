#!/bin/bash
set -e

# Fix permissions if running as root
if [ "$(id -u)" = "0" ]; then
    echo "[INFO] Running as root. Fixing permissions for /terraform..."
    chown -R 1000:1000 /terraform || echo "[WARN] Could not chown /terraform. Check permissions."
    # Re-exec as non-root user
    echo "[INFO] Switching to UID 1000 for Terraform operations."
    exec su-exec 1000:1000 "$0" "$@"
else
    if [ ! -w /terraform ]; then
        echo "[WARN] Not running as root and /terraform is not writable. You may encounter permission errors."
    fi
fi

# AWS Credential Detection and Setup
echo "🔍 Checking AWS credentials..."

# Check if AWS CLI is available and configured
if command -v aws &> /dev/null; then
    echo "[INFO] AWS CLI found, checking configuration..."
    
    # Check if AWS credentials directory exists and is readable
    if [ -d "/home/terraform/.aws" ]; then
        echo "✅ AWS credentials directory found"
        ls -la /home/terraform/.aws/
        
        # Check if credentials file exists
        if [ -f "/home/terraform/.aws/credentials" ]; then
            echo "✅ AWS credentials file found"
        else
            echo "⚠️  AWS credentials file not found"
        fi
        
        # Check if config file exists
        if [ -f "/home/terraform/.aws/config" ]; then
            echo "✅ AWS config file found"
        else
            echo "⚠️  AWS config file not found"
        fi
    else
        echo "⚠️  AWS credentials directory not found"
    fi
    
    # Test AWS credentials
    if aws sts get-caller-identity &> /dev/null; then
        echo "✅ AWS CLI credentials working"
        echo "📋 AWS Identity: $(aws sts get-caller-identity --query 'Arn' --output text)"
    else
        echo "⚠️  AWS CLI configured but credentials not working"
        echo "🔧 Checking for environment variables..."
        
        # Check if environment variables are set
        if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
            echo "✅ AWS credentials found in environment variables"
        else
            echo "❌ No AWS credentials found"
            echo "Please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables"
            echo "Or configure AWS CLI with: aws configure"
            exit 1
        fi
    fi
else
    echo "⚠️  AWS CLI not found, checking environment variables..."
    
    # Check if environment variables are set
    if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
        echo "✅ AWS credentials found in environment variables"
    else
        echo "❌ No AWS credentials found"
        echo "Please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables"
        exit 1
    fi
fi

# Handle AWS session token - only set if it has a valid value
if [ -n "$AWS_SESSION_TOKEN" ] && [ "$AWS_SESSION_TOKEN" != "" ]; then
    echo "[INFO] Using AWS session token for temporary credentials."
else
    echo "[INFO] No AWS session token found, using long-term credentials."
    unset AWS_SESSION_TOKEN
fi

# Set AWS CLI to not use shared config to avoid profile issues
export AWS_SDK_LOAD_CONFIG=false

echo "🚀 Starting Terraform build process..."

# Initialize Terraform if .terraform directory doesn't exist
if [ ! -d ".terraform" ]; then
    echo "📦 Initializing Terraform..."
    terraform init
fi

# Validate Terraform configuration
echo "✅ Validating Terraform configuration..."
terraform validate

# Format Terraform files
echo "🎨 Formatting Terraform files..."
terraform fmt -recursive

# Plan Terraform deployment
echo "📋 Creating Terraform plan..."
terraform plan -out=tfplan

# Copy plan file to binary directory for persistence
if [ -f "tfplan" ]; then
    echo "💾 Saving plan file to binary directory..."
    
    # Create binary directory if it doesn't exist
    mkdir -p /terraform/output/infra/terraform/binary
    
    # Generate timestamp in the existing format (HH-MM-SS_MM-DD-YYYY)
    TIMESTAMP=$(date +%H-%M-%S_%m-%d-%Y)
    
    # Save with timestamped name following existing pattern
    cp tfplan "/terraform/output/infra/terraform/binary/cmmc_tfplan_${TIMESTAMP}.binary"
    
    # Also save as latest for easy access
    cp tfplan "/terraform/output/infra/terraform/binary/latest_cmmc_tfplan.binary"
    
    echo "✅ Plan file saved to binary directory: cmmc_tfplan_${TIMESTAMP}.binary"
fi

# If APPLY=true is set, apply the plan
if [ "$APPLY" = "true" ]; then
    echo "🚀 Applying Terraform plan..."
    terraform apply tfplan
else
    echo "📄 Plan created successfully. Set APPLY=true to apply changes."
fi

echo "✅ Terraform build process completed!" 