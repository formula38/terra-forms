#!/bin/bash

set -euo pipefail

# --- CONFIG ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
PLAN_FILE="${ROOT_DIR}/cmmc_compliant_tfplan"
PLAN_JSON="${ROOT_DIR}/cmmc_compliant_tfplan.json"
HTML_OUTPUT="${ROOT_DIR}/cmmc_compliant_plan_summary.html"
ESTIMATOR_DIR="${SCRIPT_DIR}/terraform-cost-estimator"
PROMPTS_DIR="${SCRIPT_DIR}/prompts"
REFERENCE_DIR="/mnt/f/Cybersecurity Engineering/coldchainsecure/cold_rag"
FINDINGS_DIR="${SCRIPT_DIR}/findings"
OUTPUT_FILE="${FINDINGS_DIR}/compliance_violations.json"
RAG_SCRIPT="${SCRIPT_DIR}/rag_inspector.py"

MODE="full"
THEME="dark"
OFFLINE_MODE=false

# --- ARG PARSING ---
for arg in "$@"; do
  case $arg in
    --plan-only) MODE="plan" ;;
    --html-only) MODE="html" ;;
    --dark) THEME="dark" ;;
    --light) THEME="light" ;;
    --full) MODE="full" ;;
    --offline) OFFLINE_MODE=true ;;
    *) echo "Unknown option: $arg" && exit 1 ;;
  esac
done

echo "🔧 Mode: ${MODE} | Theme: ${THEME} | Offline: ${OFFLINE_MODE}"

# --- VENV SETUP ---
if [ ! -d "${ESTIMATOR_DIR}/venv" ]; then
  echo "🛠️ Creating virtual environment..."
  python3 -m venv "${ESTIMATOR_DIR}/venv"
fi

source "${ESTIMATOR_DIR}/venv/bin/activate"
echo "📦 Virtual environment activated."

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

# --- Install Dependencies (if online) ---
if [ "$OFFLINE_MODE" = false ]; then
  pip install --upgrade pip --break-system-packages
  pip install -r "${ESTIMATOR_DIR}/requirements.txt" --break-system-packages

  RAG_REQUIREMENTS="${SCRIPT_DIR}/requirements-rag.txt"
  if [ -f "$RAG_REQUIREMENTS" ]; then
    pip install -r "$RAG_REQUIREMENTS" --break-system-packages
  else
    echo "langchain langchain-community langchain-ollama langchain-huggingface pymupdf" > "$RAG_REQUIREMENTS"
    pip install -r "$RAG_REQUIREMENTS" --break-system-packages
  fi
else
  echo "🚫 Offline mode enabled — skipping pip installs"
fi

# --- Functions ---
run_terraform_plan() {
  echo "📐 Running terraform init and plan..."
  cd "${ROOT_DIR}"
  terraform init -input=false > /dev/null
  terraform plan -out "${PLAN_FILE}"
  terraform show -json "${PLAN_FILE}" > "${PLAN_JSON}"
}

generate_html() {
  echo "🖥️  Generating HTML report with ${THEME} theme..."
  cd "${SCRIPT_DIR}"
  python3 terraform_json_to_html.py "${PLAN_JSON}" "${HTML_OUTPUT}" "${THEME}"
}

check_ollama() {
  echo "🔍 Checking Ollama availability..."
  if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama is not installed."
    if [ "$OFFLINE_MODE" = false ]; then
      echo "📡 Installing Ollama from remote..."
      curl -fsSL https://ollama.com/install.sh | sh
    else
      echo "❗ Offline mode: Cannot install Ollama. Exiting."
      exit 1
    fi
  fi

  if ! ollama list | grep -q "mistral"; then
    if [ "$OFFLINE_MODE" = false ]; then
      echo "⬇️ Pulling 'mistral' model..."
      ollama pull mistral
    else
      echo "❗ Offline mode: 'mistral' model not found and cannot pull. Exiting."
      exit 1
    fi
  else
    echo "✅ Ollama and 'mistral' model are ready."
  fi
}

run_rag_inspector() {
  echo "🧠 Running multi-file RAG Inspector..."
  check_ollama
  mkdir -p "${FINDINGS_DIR}"

  if [[ -d "${REFERENCE_DIR}" ]]; then
    echo "📂 Including static reference docs from: ${REFERENCE_DIR}"
    python3 "${RAG_SCRIPT}" "${PLAN_JSON}" "${OUTPUT_FILE}" --refdir "${REFERENCE_DIR}"
  else
    echo "⚠️ Reference directory not found at ${REFERENCE_DIR}. Running without it..."
    python3 "${RAG_SCRIPT}" "${PLAN_JSON}" "${OUTPUT_FILE}"
  fi
}

# --- MAIN FLOW ---
case $MODE in
  plan)
    run_terraform_plan
    ;;
  html)
    generate_html
    ;;
  full)
    run_terraform_plan
    run_rag_inspector
    generate_html
    ;;
esac

if [[ -f "${FINDINGS_DIR}/compliance_violations.raw.txt" ]]; then
  echo "🕵️ Raw LLM response saved to compliance_violations.raw.txt for inspection."
fi

echo "✅ Finished! Output HTML: ${HTML_OUTPUT}"
