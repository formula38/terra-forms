#!/bin/bash
set -euo pipefail

# Use ROOT_DIR from .env — do not redefine it here
VENV_DIR="${ROOT_DIR}/${VENV_PATH}"

# Create virtual environment if toggled
if [ "$SETUP_VENV" = "true" ]; then
    if [ ! -d "$VENV_DIR" ]; then
        echo "🛠️ Creating virtual environment at $VENV_DIR..."
        python3 -m venv "$VENV_DIR"
    fi
    source "${VENV_DIR}/bin/activate"
    echo "📦 Virtual environment activated."
fi

# --- INTERNET CHECK (unless already offline) ---
if [ "$OFFLINE_MODE" = false ]; then
    echo "🌐 Checking internet..."
    if ping -q -c 1 -W 1 8.8.8.8 > /dev/null; then
        HAS_INTERNET=true
    else
        echo "⚠️ No internet detected. Falling back to offline mode."
        OFFLINE_MODE=true
    fi
fi

# Install dependencies if allowed
if [ "$OFFLINE_MODE" = "false" ] && [ "$INSTALL_REQUIREMENTS" = "true" ]; then
    echo "📦 Installing dependencies from $REQUIREMENTS_FILE..."
    pip install --upgrade pip --break-system-packages
    pip install -r "${REQUIREMENTS_FILE}" --break-system-packages
else
    echo "🚫 Skipping dependency installation."
fi

# Ensure jq is installed for JSON processing
if command -v apt-get &> /dev/null; then
    echo "📦 Ensuring system packages: jq"
    sudo apt-get update && sudo apt-get install -y jq
elif command -v brew &> /dev/null; then
    echo "📦 Ensuring system packages via Homebrew: jq"
    brew install jq
else
    echo "⚠️ Unsupported system package manager. Please install jq manually."
fi
