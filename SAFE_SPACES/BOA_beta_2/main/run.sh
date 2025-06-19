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

# --- Make all .sh scripts executable ---
echo "🔐 Making all .sh files under $ROOT_DIR executable..."
find "$ROOT_DIR" -type f -name "*.sh" -exec chmod +x {} \;

# --- Virtual Environment Setup ---
if [ "$SETUP_VENV" = "true" ]; then
    VENV_DIR="${ROOT_DIR}/${VENV_PATH}"
    if [ -d "$VENV_DIR" ]; then
        echo "🔁 Re-activating virtual environment at $VENV_DIR..."
        source "${VENV_DIR}/bin/activate"
    else
        echo "❌ Virtual environment not found at $VENV_DIR. Cannot start server."
        exit 1
    fi
fi

bash "${SETUP_ENV_SCRIPT}"

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


# --- Reactivate venv for FastAPI ---
if [ "$SETUP_VENV" = "true" ]; then
    VENV_DIR="${ROOT_DIR}/${VENV_PATH}"
    if [ -d "$VENV_DIR" ]; then
        echo "🔁 Re-activating virtual environment at $VENV_DIR..."
        source "${VENV_DIR}/bin/activate"
    else
        echo "❌ Virtual environment not found at $VENV_DIR. Cannot start server."
        exit 1
    fi
fi


# --- Start FastAPI Server ---
FASTAPI_PORT="${FASTAPI_PORT:-8000}"
FASTAPI_HOST="${FASTAPI_HOST:-127.0.0.1}"

if [ "${START_FASTAPI:-false}" = "true" ]; then
    echo "🚀 Launching FastAPI server..."
    cd "${ROOT_DIR}" || exit 1
    uvicorn main.api.main:app --reload --host "$FASTAPI_HOST" --port "$FASTAPI_PORT"
else
    echo "⏭️ Skipping FastAPI server launch."
fi

