#!/bin/bash

set -euo pipefail

# --- CONFIG ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
PLAN_FILE="${ROOT_DIR}/cmmc_compliant_tfplan"
PLAN_JSON="${ROOT_DIR}/cmmc_compliant_tfplan.json"
HTML_OUTPUT="${ROOT_DIR}/cmmc_compliant_plan_summary.html"
ESTIMATOR_DIR="${SCRIPT_DIR}/terraform-cost-estimator"
RAG_SCRIPT="${SCRIPT_DIR}/rag_inspector.py"
FINDINGS_OUTPUT="${SCRIPT_DIR}/findings/compliance_violations.json"

# --- ARGS ---
MODE="full"
THEME="dark"

for arg in "$@"; do
  case $arg in
    --plan-only) MODE="plan"; shift ;;
    --html-only) MODE="html"; shift ;;
    --rag-only) MODE="rag"; shift ;;
    --dark) THEME="dark"; shift ;;
    --light) THEME="light"; shift ;;
    --full) MODE="full"; shift ;;
    *) echo "Unknown option: $arg"; exit 1 ;;
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

# --- DEPENDENCIES ---
pip install --upgrade pip --break-system-packages
pip install -r "${ESTIMATOR_DIR}/requirements.txt" --break-system-packages
pip install langchain faiss-cpu ollama sentence-transformers pydantic --break-system-packages

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

run_rag_inspector() {
  echo "🧠 Running RAG-based compliance scan..."
  mkdir -p "${SCRIPT_DIR}/findings"
  python3 "${RAG_SCRIPT}" "${PLAN_JSON}"
  echo "📄 RAG findings written to: ${FINDINGS_OUTPUT}"
}

# --- FLOW CONTROL ---
case $MODE in
  plan)
    run_terraform_plan
    ;;
  html)
    generate_html
    ;;
  rag)
    run_rag_inspector
    ;;
  full)
    run_terraform_plan
    generate_html
    run_rag_inspector
    ;;
esac

echo "✅ Finished! Output HTML: ${HTML_OUTPUT}"
