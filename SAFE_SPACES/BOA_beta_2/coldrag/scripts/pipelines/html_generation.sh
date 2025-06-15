#!/bin/bash
# Generates HTML summary from JSON plan

python3 output/scripts/terraform_json_to_html.py --input ${PLAN_JSON} --output ${HTML_OUTPUT} --theme ${THEME}
