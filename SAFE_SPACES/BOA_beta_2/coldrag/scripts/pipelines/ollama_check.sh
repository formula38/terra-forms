#!/bin/bash
# Modular Ollama availability and model readiness check
set -e

# Load env vars if needed
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
if [ -f "${ROOT_DIR}/.env" ]; then
    set -a
    source "${ROOT_DIR}/.env"
    set +a
fi

echo "🔍 Checking for Ollama..."

# Check for Ollama installation
if ! command -v ollama &> /dev/null; then
  echo "❌ Ollama not found."
  if [ "$OFFLINE_MODE" = "false" ]; then
    echo "🌐 Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
  else
    echo "🚫 Cannot install Ollama in offline mode."
    exit 1
  fi
fi

# Check for mistral model
if ! ollama list | grep -q "mistral"; then
  echo "🧠 Mistral model not found."
  if [ "$OFFLINE_MODE" = "false" ]; then
    echo "⬇️ Pulling mistral model..."
    ollama pull mistral
  else
    echo "🚫 Cannot pull model in offline mode."
    exit 1
  fi
else
  echo "✅ Ollama and 'mistral' model are ready."
fi
