#!/usr/bin/env python3
"""Modular RAG Inspector Script: Uses LangChain + Pydantic + Custom Modules to Analyze Terraform JSON"""

import os
import argparse
from pathlib import Path
from dotenv import load_dotenv

from coldrag.scripts.core.plan_parser import load_terraform_docs
from coldrag.scripts.core.reference_loader import load_reference_docs
from coldrag.scripts.core.embedding_setup import load_embeddings_and_retriever
from coldrag.scripts.core.llm_runner import init_llm, run_rag_chain
from coldrag.scripts.core.prompt_loader import load_prompt_template
from coldrag.scripts.core.output_validator import validate_and_write_output
from coldrag.scripts.core.debug_utils import log_loaded_docs, log_llm_sources

# --- Load environment variables ---
load_dotenv()
MODEL_PATH = os.getenv("EMBEDDING_MODEL")
PROMPT_FILE = os.getenv("PROMPT_FILE", "blanket_compliance_prompt.txt")

# --- CLI Setup ---
parser = argparse.ArgumentParser(description="RAG compliance analyzer for Terraform plans")
parser.add_argument("plan_json", help="Path to Terraform plan JSON")
parser.add_argument("output_path", help="Path to save compliance JSON")
parser.add_argument("--refdir", help="Optional directory of static compliance references")
args = parser.parse_args()

# --- Step 1: Load Terraform plan or state JSON ---
print("📄 Parsing Terraform input file...")
docs = load_terraform_docs(args.plan_json)

# --- Step 2: Load static reference files (if given) ---
if args.refdir:
    print(f"📚 Loading reference materials from: {args.refdir}")
    ref_docs = load_reference_docs(args.refdir)
    docs.extend(ref_docs)

log_loaded_docs(docs)

# --- Step 3: Create vector index using embeddings ---
retriever = load_embeddings_and_retriever(docs, model_path=MODEL_PATH)

# --- Step 4: Load the LLM and Prompt ---
llm = init_llm()
prompt_template = load_prompt_template(PROMPT_FILE)

# --- Step 5: Run the Retrieval-Augmented Chain ---
print("🧠 Running LLM with embedded context...")
response = run_rag_chain(llm, retriever, prompt_template)

log_llm_sources(response)

# --- Step 6: Validate and Save Output ---
validate_and_write_output(response, args.plan_json, args.output_path)

print("✅ RAG Inspector analysis complete.")
