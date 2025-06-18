#!/bin/bash
set -euo pipefail

echo "📐 Running terraform init and plan..."

cd "$ROOT_DIR/infra/terraform" || {
  echo "❌ Could not navigate to $ROOT_DIR/infra/terraform"
  exit 1
}

# Init Terraform
terraform init -input=false > /dev/null

# Plan and output to binary
terraform plan -out="$PLAN_FILE"

# Convert plan to JSON
terraform show -json "$PLAN_FILE" > "$PLAN_JSON"
echo "✅ Terraform plan JSON exported to $PLAN_JSON"

# Export tfstate if available
if [ -f terraform.tfstate ]; then
  echo "📄 Found terraform.tfstate — exporting to JSON"
  terraform show -json terraform.tfstate > "$STATE_JSON"
else
  echo "⚠️ No tfstate available — skipping tfstate export"
  rm -f "$STATE_JSON" 2>/dev/null || true
fi
