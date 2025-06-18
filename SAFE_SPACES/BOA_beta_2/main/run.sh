#!/bin/bash
set -euo pipefail

echo "🔧 Starting BizOpsAgent pipeline..."

# --- Load environment variables ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."

if [ -f "${ROOT_DIR}/.env" ]; then
    echo "📥 Loading environment variables from .env..."
    set -a
    source "${ROOT_DIR}/.env"
    set +a
else
    echo "❌ .env file not found at root. Exiting."
    exit 1
fi

# --- Virtual Environment Setup ---
bash "${SCRIPT_DIR}/scripts/setup_env.sh"

# --- Ollama Check ---
if [ "$CHECK_OLLAMA" = "true" ]; then
    echo "🔍 Running Ollama availability check..."
    bash "$OLLAMA_CHECK_SCRIPT"
fi

# --- Terraform Pipeline ---
if [ "$RUN_TERRAFORM" = "true" ]; then
    echo "📐 Running Terraform plan pipeline..."
    bash "$TERRAFORM_SCRIPT"
else
    echo "⏭️ Skipping Terraform pipeline."
fi

# --- Model Training ---
if [ "$TRAIN_MODEL" = "true" ]; then
    echo "🧠 Training embedding model..."
    bash "$TRAIN_MODEL_SCRIPT"
else
    echo "⏭️ Skipping model training."
fi

# --- RAG Compliance Inspector ---
echo "🕵️ Running RAG Inspector..."
bash "$RAG_INSPECTOR_SCRIPT"

# --- HTML Report Generation ---
if [ "$GENERATE_HTML" = "true" ]; then
    echo "🖼️ Generating HTML summary..."
    bash "$HTML_GEN_SCRIPT"
else
    echo "⏭️ Skipping HTML generation."
fi

echo "✅ BizOpsAgent pipeline complete."
