#!/bin/bash
set -e

# Go to the directory where the script resides (scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

PLAN_OUTPUT="${ROOT_DIR}/cmmc_compliant_tfplan"
PLAN_JSON="${ROOT_DIR}/cmmc_compliant_tfplan.json"
HTML_OUTPUT="${ROOT_DIR}/cmmc_compliant_plan_summary.html"

cd "$ROOT_DIR"

echo "📦 Generating Terraform plan from project root..."
terraform plan -out="${PLAN_OUTPUT}"

echo "📄 Converting plan to JSON..."
terraform show -json "${PLAN_OUTPUT}" > "${PLAN_JSON}"

echo "🖥️  Generating HTML summary..."
python3 "${SCRIPT_DIR}/terraform_json_to_html.py" "${PLAN_JSON}" "${HTML_OUTPUT}"

echo "✅ HTML summary generated at ${HTML_OUTPUT}"
