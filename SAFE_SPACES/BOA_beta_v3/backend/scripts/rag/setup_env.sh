#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."

# Activate or create virtualenv
# if [ "$SETUP_VENV" = "true" ]; then
#     VENV_DIR="../${VENV_PATH}"
#     if [ ! -d "$VENV_DIR" ]; then
#         echo "🛠️ Creating virtual environment at $VENV_DIR..."
#         python3 -m venv "$VENV_DIR"
#     fi

#     # Activate
#     echo "📦 Activating virtual environment..."
#     source "${VENV_DIR}/bin/activate"
# fi

# --- Internet & Install Checks ---
if [ "$OFFLINE_MODE" = "false" ]; then
    echo "🌐 Checking internet connectivity..."
    if ! ping -q -c 1 -W 1 8.8.8.8 > /dev/null; then
        echo "⚠️ No internet detected. Offline mode enforced."
        OFFLINE_MODE=true
    fi
fi

# --- Install Requirements ---
if [ "$INSTALL_REQUIREMENTS" = "true" ] && [ "$OFFLINE_MODE" = "false" ]; then
    echo "📦 Installing Python packages from $REQUIREMENTS_FILE..."
    pip install --upgrade pip --break-system-packages
    pip install -r "${REQUIREMENTS_FILE}" --break-system-packages
else
    echo "🚫 Skipping Python dependency installation"
fi


# Ensure jq is installed for JSON processing
if command -v apt-get &> /dev/null; then
    echo "📦 Ensuring system packages: jq"
    # sudo apt-get update && sudo apt-get install -y jq
else
    echo "⚠️ Unsupported system package manager. Please install jq manually."
fi
