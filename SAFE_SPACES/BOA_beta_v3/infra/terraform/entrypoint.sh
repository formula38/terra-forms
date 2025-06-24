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

# Handle AWS session token - only set if it has a valid value
if [ -n "$AWS_SESSION_TOKEN" ] && [ "$AWS_SESSION_TOKEN" != "" ]; then
    echo "[INFO] Using AWS session token for temporary credentials."
else
    echo "[INFO] No AWS session token found, using long-term credentials."
    unset AWS_SESSION_TOKEN
fi

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