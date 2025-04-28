#!/bin/bash

set -euo pipefail

# --- CONFIG ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
PLAN_FILE="${ROOT_DIR}/cmmc_compliant_tfplan"
PLAN_JSON="${ROOT_DIR}/cmmc_compliant_tfplan.json"
HTML_OUTPUT="${ROOT_DIR}/cmmc_compliant_plan_summary.html"
ESTIMATOR_DIR="${SCRIPT_DIR}/terraform-cost-estimator"

# --- ARGS ---
MODE="full"
THEME="dark"

for arg in "$@"; do
  case $arg in
    --plan-only)
      MODE="plan"
      shift
      ;;
    --html-only)
      MODE="html"
      shift
      ;;
    --dark)
      THEME="dark"
      shift
      ;;
    --light)
      THEME="light"
      shift
      ;;
    --full)
      MODE="full"
      shift
      ;;
    *)
      echo "Unknown option: $arg"
      exit 1
      ;;
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

pip install --upgrade pip
pip install -r "${ESTIMATOR_DIR}/requirements.txt"

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
    generate_html
    ;;
esac

echo "✅ Finished! Output HTML: ${HTML_OUTPUT}"

