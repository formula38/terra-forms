#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
source "${ROOT_DIR}/.env"

echo "🧠 Starting model training..."

if [ ! -d "${MODEL_OUTPUT_DIR}" ]; then
    echo "📦 Fine-tuned model not found. Bootstrapping..."
    python3 "${SCRIPT_DIR}/models/train_model.py"
else
    echo "✅ Fine-tuned model already exists at ${MODEL_OUTPUT_DIR}."
fi
