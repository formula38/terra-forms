#!/bin/bash

set -e  # Exit immediately on error

PLAN_FILE="../cmmc_compliant_tfplan"
PLAN_JSON="../cmmc_compliant_tfplan.json"
HTML_OUTPUT="../cmmc_compliant_plan_summary.html"

echo "🔧 Creating virtual environment (if needed)..."
if [ ! -d "venv" ]; then
  python3 -m venv venv
  source venv/bin/activate
  pip install --upgrade pip
  pip install -r requirements.txt
else
  source venv/bin/activate
fi

echo "📦 Dependencies installed and virtual environment activated."

echo "📐 Running terraform plan..."
cd ../
terraform init > /dev/null
terraform plan -out "${PLAN_FILE}"

echo "📄 Converting plan to JSON..."
terraform show -json "${PLAN_FILE}" > "${PLAN_JSON}"

echo "🖥️  Generating HTML summary..."
cd terraform-cost-estimator/
python3 ../scripts/terraform_json_to_html.py "${PLAN_JSON}" "${HTML_OUTPUT}"

echo "✅ Done! HTML summary written to: ${HTML_OUTPUT}"
