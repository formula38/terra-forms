#!/bin/bash

set -euo pipefail

# --- Configurable Paths ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAN_JSON="${SCRIPT_DIR}/../cmmc_compliant_tfplan.json"
FINDINGS_DIR="${SCRIPT_DIR}/findings"
RAG_SCRIPT="${SCRIPT_DIR}/rag_inspector_2_final_cleaned.py"
PROMPTS_DIR="${SCRIPT_DIR}/prompts"
REFERENCE_DIR="/mnt/f/Cybersecurity Engineering/cvelistV5-main/cvelistV5-main/cves"  # Static reference dir
OUTPUT_JSON="${FINDINGS_DIR}/compliance_violations.json"

# --- Functions ---
check_ollama() {
  echo "🔍 Checking Ollama availability..."
  if ! ollama list | grep -q 'mistral'; then
    echo "❌ 'mistral' model not found in Ollama."
    exit 1
  fi
  echo "✅ Ollama and 'mistral' model are ready."
}

run_rag_inspector() {
  echo "🧠 Running multi-file RAG Inspector..."
  check_ollama
  mkdir -p "${FINDINGS_DIR}"

  if [[ -d "${REFERENCE_DIR}" ]]; then
    echo "📂 Including static reference docs from: ${REFERENCE_DIR}"
    python3 "${RAG_SCRIPT}" "${PLAN_JSON}" "${OUTPUT_JSON}" --refdir "${REFERENCE_DIR}"
  else
    echo "⚠️ Reference directory not found at ${REFERENCE_DIR}. Running without it..."
    python3 "${RAG_SCRIPT}" "${PLAN_JSON}" "${OUTPUT_JSON}"
  fi
}

# --- Run ---
run_rag_inspector
