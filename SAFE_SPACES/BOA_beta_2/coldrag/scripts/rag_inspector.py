#!/usr/bin/env python3
"""Main RAG Inspector entry point."""

import os
import argparse
from pathlib import Path
from dotenv import load_dotenv

from coldrag.scripts.core.embedding_setup import load_embeddings_and_retriever
from coldrag.scripts.core.llm_runner import init_llm, run_rag_chain
from coldrag.scripts.core.prompt_loader import load_prompt_template
from coldrag.scripts.core.plan_parser import load_terraform_docs
from coldrag.scripts.core.reference_loader import load_reference_docs
from coldrag.scripts.core.output_validator import validate_and_write_output

# --- Load env variables ---
load_dotenv()
MODEL_NAME = os.getenv("EMBEDDING_MODEL")
PROMPT_FILE = os.getenv("PROMPT_FILE", "blanket_compliance_prompt.txt")

# --- CLI Setup ---
parser = argparse.ArgumentParser(description="RAG compliance analyzer for Terraform plans")
parser.add_argument("plan_json", help="Path to Terraform plan JSON")
parser.add_argument("output_path", help="Path to save compliance JSON")
parser.add_argument("--refdir", help="Optional reference directory", default=None)
args = parser.parse_args()

# --- Load documents ---
docs = load_terraform_docs(args.plan_json)
if args.refdir:
    docs.extend(load_reference_docs(args.refdir))

# --- RAG Setup ---
retriever = load_embeddings_and_retriever(docs, model_path=MODEL_NAME)
llm = init_llm()
prompt = load_prompt_template(PROMPT_FILE)

# --- Run LLM + RAG ---
response = run_rag_chain(llm, retriever, prompt)

# --- Validate and Write Output ---
validate_and_write_output(response, args.plan_json, args.output_path)
