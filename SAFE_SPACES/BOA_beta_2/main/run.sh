#!/bin/bash

# Load environment variables from .env
set -o allexport
source .env
set +o allexport

# Activate virtual environment if present
if [ -d "venv" ]; then
  source venv/bin/activate
fi

# Define paths using modular layout
SCRIPT_DIR="./scripts"
CORE_DIR="./core"
OUTPUT_DIR="./html_outputs"
CONFIG_DIR="./config"
MODEL_DIR="./models"

# Log directories
mkdir -p logs $OUTPUT_DIR

echo "🔍 Starting RAG Inspector Pipeline..."
echo "🧩 Compliance Mode: $COMPLIANCE"
echo "📄 Reference Directory: $REFERENCE_DIR"
echo "📦 Output: $HTML_OUTPUT"

python3 $SCRIPT_DIR/run_rag_inspector.py \
  --plan-json "$PLAN_JSON" \
  --state-json "$STATE_JSON" \
  --plan-file "$PLAN_FILE" \
  --output-html "$OUTPUT_DIR/$HTML_OUTPUT" \
  --reference-dir "$REFERENCE_DIR" \
  --output-json "$OUTPUT_FILE" \
  --offline "$OFFLINE_MODE"

echo "✅ Finished generating report: $OUTPUT_DIR/$HTML_OUTPUT"
