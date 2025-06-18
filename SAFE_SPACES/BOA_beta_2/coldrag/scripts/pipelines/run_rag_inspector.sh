#!/bin/bash
# Runs RAG inspector against Terraform plan JSON

set -euo pipefail

echo "🕵️ Running RAG Inspector..."

PLAN_INPUT="${PLAN_JSON}"

# Use tfstate if present
if [[ -f "$STATE_JSON" ]]; then
  echo "📄 Found tfstate — using for compliance analysis"
  PLAN_INPUT="$STATE_JSON"
else
  echo "📄 Falling back to tfplan JSON"
fi

# Create findings dir if not exists
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Execute Python script with or without reference docs
if [[ -d "$REFERENCE_DIR" ]]; then
  echo "📂 Including reference docs from $REFERENCE_DIR"
  python3 coldrag/scripts/rag_inspector.py "$PLAN_INPUT" "$OUTPUT_FILE" --refdir "$REFERENCE_DIR"
else
  echo "⚠️ Reference directory not found — running without"
  python3 coldrag/scripts/rag_inspector.py "$PLAN_INPUT" "$OUTPUT_FILE"
fi
