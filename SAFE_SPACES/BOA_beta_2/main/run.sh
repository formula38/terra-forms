#!/bin/bash
set -e

# Load environment variables
if [ -f .env ]; then
    echo "Loading environment variables from .env..."
    export $(grep -v '^#' .env | xargs)
else
    echo ".env file not found. Exiting."
    exit 1
fi

echo "[+] Starting BizOpsAgent pipeline..."

# Optional: Terraform Infrastructure Pipeline
if [ "$RUN_TERRAFORM" = "true" ]; then
    echo "[*] Running Terraform pipeline..."
    bash "$TERRAFORM_SCRIPT"
else
    echo "[*] Skipping Terraform pipeline."
fi

# Optional: Model Training Pipeline
if [ "$TRAIN_MODEL" = "true" ]; then
    echo "[*] Running model training..."
    bash "$TRAIN_MODEL_SCRIPT"
else
    echo "[*] Skipping model training."
fi

# RAG Compliance Inspection
echo "[*] Running RAG Inspector..."
bash "$RAG_INSPECTOR_SCRIPT"

# Optional: HTML Generation
if [ "$GENERATE_HTML" = "true" ]; then
    echo "[*] Generating HTML summary..."
    bash "$HTML_GEN_SCRIPT"
else
    echo "[*] Skipping HTML generation."
fi

echo "[✓] Pipeline complete."
