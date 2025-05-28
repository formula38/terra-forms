#!/usr/bin/env python3
"""RAG Inspector Script: Analyze Terraform Plan JSON using LangChain + Pydantic"""

import os
import json
import argparse
from pathlib import Path
from typing import List

from langchain.chains import RetrievalQA
from langchain_community.vectorstores import FAISS
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.llms.ollama import Ollama
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.schema import Document
from pydantic import BaseModel, Field

# --- Pydantic Model for Output Validation (Optional Use) ---
class ComplianceViolation(BaseModel):
    resource_type: str = Field(..., description="Terraform AWS resource type")
    resource_name: str = Field(..., description="Resource name as defined in TF")
    compliance_concern: str = Field(..., description="What compliance issue it violates")
    standard: str = Field(..., description="HIPAA | PCI-DSS | FedRAMP")
    severity: str = Field(..., description="Low / Medium / High")

# --- Argument Parsing ---
parser = argparse.ArgumentParser(description="RAG compliance analyzer for Terraform plans")
parser.add_argument("plan_json", help="Path to Terraform plan JSON")
args = parser.parse_args()

# --- Load Terraform Plan ---
with open(args.plan_json, "r") as f:
    data = json.load(f)

raw_text = json.dumps(data, indent=2)
text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=100)
chunks = text_splitter.split_text(raw_text)
docs = [Document(page_content=chunk) for chunk in chunks]

# --- Embeddings + Vector Store ---
EMBED_MODEL_NAME = "sentence-transformers/all-MiniLM-L6-v2"
embedding = HuggingFaceEmbeddings(model_name=EMBED_MODEL_NAME)
db = FAISS.from_documents(docs, embedding)
retriever = db.as_retriever()

# --- LLM Setup ---
llm = Ollama(model="mistral")

# --- Load Prompt Template ---
prompt_path = Path("prompts/compliance_prompt.txt")
if not prompt_path.exists():
    raise FileNotFoundError("Prompt template not found at prompts/compliance_prompt.txt")

with open(prompt_path, "r") as f:
    prompt_template = f.read()

# --- RAG Chain ---
chain = RetrievalQA.from_chain_type(
    llm=llm,
    retriever=retriever,
    chain_type="stuff",
    return_source_documents=False
)

print("🔎 Inspecting Terraform plan with compliance-aware RAG...")

# --- Run Query ---
response = chain.invoke({"query": prompt_template})

# --- Parse and Clean Output ---
output_path = Path("findings/compliance_violations.json")
output_path.parent.mkdir(parents=True, exist_ok=True)

# If response is wrapped in markdown ```json block, strip it
if isinstance(response, dict):
    raw = response.get("result", "")
else:
    raw = str(response)

# Remove markdown code block formatting
if raw.startswith("```json"):
    raw = raw.lstrip("```json").rstrip("```").strip()
elif raw.startswith("```"):
    raw = raw.lstrip("```").rstrip("```").strip()

try:
    parsed = json.loads(raw)
    with open(output_path, "w") as f:
        json.dump(parsed, f, indent=2)
    print(f"✅ Compliance check complete. Results saved to: {output_path}")
except json.JSONDecodeError as e:
    print("❌ Failed to parse model output as JSON. Raw output saved instead.")
    with open(output_path, "w") as f:
        f.write(raw)
