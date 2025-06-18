#!/bin/bash
# Generates HTML summary from JSON plan

set -euo pipefail

if [[ ! -f "${PLAN_JSON}" ]]; then
  echo "❌ Plan JSON not found at: ${PLAN_JSON}"
  exit 1
fi

mkdir -p "$(dirname "$HTML_OUTPUT")"

python3 ${ROOT_DIR}/output/scripts/terraform_json_to_html.py \
  --input "${PLAN_JSON}" \
  --output "${HTML_OUTPUT}" \
  --theme "${THEME}"
