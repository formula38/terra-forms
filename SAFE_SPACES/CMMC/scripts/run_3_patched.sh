#!/bin/bash

set -euo pipefail

# --- CONFIG ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
PLAN_FILE="${ROOT_DIR}/cmmc_compliant_tfplan"
PLAN_JSON="${ROOT_DIR}/cmmc_compliant_tfplan.json"
HTML_OUTPUT="${ROOT_DIR}/cmmc_compliant_plan_summary.html"
ESTIMATOR_DIR="${SCRIPT_DIR}/terraform-cost-estimator"
FINDINGS_DIR="${SCRIPT_DIR}/findings"
RAG_SCRIPT="${SCRIPT_DIR}/rag_inspector_2_modified.py"

# --- ARGS ---
MODE="full"
THEME="dark"

for arg in "$@"; do
  case $arg in
    --plan-only) MODE="plan" ;;
    --html-only) MODE="html" ;;
    --dark) THEME="dark" ;;
    --light) THEME="light" ;;
    --full) MODE="full" ;;
    *) echo "Unknown option: $arg" && exit 1 ;;
  esac
done

echo "🔧 Mode: ${MODE} | Theme: ${THEME}"

# --- VENV SETUP ---
if [ ! -d "${ESTIMATOR_DIR}/venv" ]; then
  echo "🛠️ Creating new virtual environment..."
  python3 -m venv "${ESTIMATOR_DIR}/venv"
fi

source "${ESTIMATOR_DIR}/venv/bin/activate"
echo "📦 Virtual environment activated."

# --- Install Python dependencies ---
pip install --upgrade pip --break-system-packages
pip install -r "${ESTIMATOR_DIR}/requirements.txt" --break-system-packages

# RAG-specific dependencies
RAG_REQUIREMENTS="${SCRIPT_DIR}/requirements-rag.txt"
if [ -f "$RAG_REQUIREMENTS" ]; then
  pip install -r "$RAG_REQUIREMENTS" --break-system-packages
else
  echo "langchain langchain-community langchain-ollama langchain-huggingface" > "$RAG_REQUIREMENTS"
  pip install -r "$RAG_REQUIREMENTS" --break-system-packages
fi

# --- FUNCTIONS ---
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
    if ping -c 1 ollama.com &> /dev/null; then
      echo "📡 Internet detected. Installing Ollama..."
      curl -fsSL https://ollama.com/install.sh | sh
    else
      echo "⚠️ No internet. Install Ollama manually: https://ollama.com"
      exit 1
    fi
  fi

  if ! ollama list | grep -q "mistral"; then
    echo "⬇️ Pulling 'mistral' model..."
    ollama pull mistral
  else
    echo "✅ Ollama and 'mistral' model are ready."
  fi

  # if ! ollama list | grep -q "deepseek-r1"; then
  #   echo "⬇️ Pulling 'deepseek-r1' model..."
  #   ollama pull deepseek-r1
  # else
  #   echo "✅ Ollama and 'deepseek-r1' model are ready."
  # fi
}

run_rag_inspector() {
  echo "🧠 Running air-gapped RAG Inspector..."
  check_ollama
  mkdir -p "${FINDINGS_DIR}"
  python3 "${RAG_SCRIPT}" "${PLAN_JSON}" "${FINDINGS_DIR}/compliance_violations.json"
}

if [[ -f "${FINDINGS_DIR}/compliance_violations.raw.txt" ]]; then
  echo "🕵️ Raw LLM response saved to compliance_violations.raw.txt for inspection."
fi

# --- FLOW CONTROL ---
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

echo "✅ Finished! Output HTML: ${HTML_OUTPUT}"

# --- MULTI-RAG EXECUTION ---
chmod +x "${SCRIPT_DIR}/run_multirag.sh"
"${SCRIPT_DIR}/run_multirag.sh"
