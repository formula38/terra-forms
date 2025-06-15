#!/bin/bash
# Runs RAG inspector against Terraform plan

python3 coldrag/scripts/rag_inspector.py --input ${PLAN_JSON} --output ${OUTPUT_FILE} --offline ${OFFLINE_MODE}
