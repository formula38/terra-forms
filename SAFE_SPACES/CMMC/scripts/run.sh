#!/bin/bash

set -e  # Exit immediately if a command fails

# Set paths relative to the script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
PLAN_FILE="${ROOT_DIR}/cmmc_compliant_tfplan"
PLAN_JSON="${ROOT_DIR}/cmmc_compliant_tfplan.json"
HTML_OUTPUT="${ROOT_DIR}/cmmc_compliant_plan_summary.html"
ESTIMATOR_DIR="${SCRIPT_DIR}/terraform-cost-estimator"

echo "🔧 Creating virtual environment (if needed)..."
if [ ! -d "${ESTIMATOR_DIR}/venv" ]; then
  python3 -m venv "${ESTIMATOR_DIR}/venv"
  source "${ESTIMATOR_DIR}/venv/bin/activate"
  pip install --upgrade pip
  pip install -r "${ESTIMATOR_DIR}/requirements.txt"
else
  source "${ESTIMATOR_DIR}/venv/bin/activate"
fi

echo "📦 Dependencies installed and virtual environment activated."

echo "📐 Running terraform plan..."
cd "${ROOT_DIR}"
terraform init > /dev/null
terraform plan -out "${PLAN_FILE}"

echo "📄 Converting plan to JSON..."
terraform show -json "${PLAN_FILE}" > "${PLAN_JSON}"

echo "🖥️  Generating HTML summary..."
python3 "${SCRIPT_DIR}/terraform_json_to_html.py" "${PLAN_JSON}" "${HTML_OUTPUT}"

echo "✅ Done! HTML summary written to: ${HTML_OUTPUT}"
