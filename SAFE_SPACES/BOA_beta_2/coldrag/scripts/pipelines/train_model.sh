#!/bin/bash
set -e

source "${ROOT_DIR}/.env"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."

echo "🧠 Starting model training..."

if [ ! -d "${MODEL_OUTPUT_DIR}" ]; then
    echo "📦 Fine-tuned model not found. Bootstrapping..."
    python3 "${SCRIPT_DIR}/../train_model.py"
else
    echo "✅ Fine-tuned model already exists at ${MODEL_OUTPUT_DIR}."
fi
