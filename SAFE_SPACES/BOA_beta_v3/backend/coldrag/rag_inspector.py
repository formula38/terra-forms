#!/usr/bin/env python3
"""Modular RAG Inspector Script: Uses LangChain + Pydantic + Custom Modules to Analyze Terraform JSON"""

import os, sys
import argparse
from pathlib import Path
from dotenv import load_dotenv

ROOT_DIR = Path(__file__).resolve().parent.parent
sys.path.append(str(ROOT_DIR))

from coldrag.utils.plan_parser import load_terraform_docs
from coldrag.utils.reference_loader import load_reference_docs
from coldrag.train.embedding_setup import load_embeddings_and_retriever
from coldrag.utils.llm_runner import init_llm, run_rag_chain
from coldrag.utils.prompt_loader import load_prompt_template
from coldrag.utils.output_validator import validate_and_write_output
from coldrag.utils.inspector_utils import log_loaded_docs, log_llm_sources

# --- Load environment variables ---
load_dotenv()
MODEL_PATH = os.getenv("EMBEDDING_MODEL")
PROMPT_FILE = os.getenv("DEFAULT_PROMPT_FILE", "blanket_compliance_prompt.txt")

# coldrag/scripts/rag_inspector.py
def run_rag_pipeline(plan_path: Path, output_path: Path, ref_docs_enabled=True) -> dict:
    """
    Programmatic version of the CLI rag_inspector.
    """
    import os
    from coldrag.utils.reference_loader import load_reference_docs
    from coldrag.utils.plan_parser import load_terraform_docs
    from coldrag.train.embedding_setup import load_embeddings_and_retriever
    from coldrag.utils.llm_runner import init_llm, run_rag_chain
    from coldrag.utils.prompt_loader import load_prompt_template
    from coldrag.utils.output_validator import validate_and_write_output

    MODEL_PATH = os.getenv("EMBEDDING_MODEL", "sentence-transformers/all-mpnet-base-v2")
    PROMPT_FILE = os.getenv("DEFAULT_PROMPT_FILE", "blanket_compliance_prompt.txt")

    docs = load_terraform_docs(str(plan_path))

    if ref_docs_enabled:
        ref_dir = os.getenv("REFERENCE_DIR", "")
        if ref_dir:
            ref_docs = load_reference_docs(ref_dir)
            docs.extend(ref_docs)

    retriever = load_embeddings_and_retriever(docs, model_path=MODEL_PATH)
    llm = init_llm()
    prompt_template = load_prompt_template(PROMPT_FILE)
    response = run_rag_chain(llm, retriever, prompt_template)
    validate_and_write_output(response, str(plan_path), str(output_path))

    return {"status": "analysis complete"}

if __name__ == "__main__":
    # --- CLI Setup ---
    parser = argparse.ArgumentParser(description="RAG compliance analyzer for Terraform plans")
    parser.add_argument("plan_json", help="Path to Terraform plan JSON")
    parser.add_argument("output_path", help="Path to save compliance JSON")
    parser.add_argument("--refdir", help="Optional directory of static compliance references")
    args = parser.parse_args()

    ##############################################
    # Check for required binaries and Python packages (debugging)
    import importlib.util
    import shutil

    if shutil.which("jq") is None:
        print("❌ 'jq' binary not found. Please install via your package manager.")

    if importlib.util.find_spec("pypdf") is None:
        print("❌ 'pypdf' not found in current environment.")

    ############################################
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
    retriever = load_embeddings_and_retriever(docs, model_path=MODEL_PATH if MODEL_PATH else "sentence-transformers/all-mpnet-base-v2")

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