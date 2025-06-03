#!/bin/bash

set -euo pipefail

# Define paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_DIR="${SCRIPT_DIR}/prompts"
OUTPUT_DIR="${SCRIPT_DIR}/findings"
OUTPUT_FILE="${OUTPUT_DIR}/compliance_violations.json"
RAG_SCRIPT="${SCRIPT_DIR}/rag_inspector_2_final.py"

# Ensure output directory exists
mkdir -p "${OUTPUT_DIR}"

# Run the RAG inspector with multi-file ingestion
echo "🔍 Running RAG Inspector on directory: ${PROMPTS_DIR}"
python3 "${RAG_SCRIPT}" "${PROMPTS_DIR}" "${OUTPUT_FILE}"
