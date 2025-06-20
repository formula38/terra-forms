#!/bin/bash
# Generates HTML summary from JSON plan

set -euo pipefail

if [[ ! -f "${PLAN_JSON}" ]]; then
  echo "❌ Plan JSON not found at: ${PLAN_JSON}"
  exit 1
fi

mkdir -p "$(dirname "$HTML_OUTPUT")"

python3 ${TERRAFORM_HTML_REPORT} \
  --input "$PLAN_JSON" \
  --output "$HTML_OUTPUT" \
  --theme "$THEME" \
  --compliance "$OUTPUT_FILE"