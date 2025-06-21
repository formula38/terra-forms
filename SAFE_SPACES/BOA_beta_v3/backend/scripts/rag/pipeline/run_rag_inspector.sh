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

# Get the virtual environment python path
VENV_PYTHON="${ROOT_DIR}/${VENV_PATH}/bin/python3"

# Execute Python script with or without reference docs
RAG_SCRIPT_PATH="${RAG_INSPECTOR_MODULE:-coldrag/scripts/core/rag_inspector.py}"

if [[ -d "$REFERENCE_DIR" ]]; then
  echo "📂 Including reference docs from $REFERENCE_DIR"
  "$VENV_PYTHON" "$RAG_SCRIPT_PATH" "$PLAN_INPUT" "$OUTPUT_FILE" --refdir "$REFERENCE_DIR"
else
  echo "⚠️ Reference directory not found — running without"
  "$VENV_PYTHON" "$RAG_SCRIPT_PATH" "$PLAN_INPUT" "$OUTPUT_FILE"
fi
