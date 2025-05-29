#!/usr/bin/env python3
"""RAG Inspector Script: Analyze Terraform Plan JSON using LangChain + Pydantic"""

import re
import json
import argparse
from pathlib import Path
from typing import List

from langchain.chains import RetrievalQA
from langchain_community.vectorstores import FAISS
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_ollama import OllamaLLM
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.schema import Document
from pydantic import BaseModel, Field, ValidationError

# --- Pydantic Model for Output Validation ---
class ComplianceViolation(BaseModel):
    resource_type: str = Field(..., description="Terraform AWS resource type")
    resource_name: str = Field(..., description="Resource name as defined in TF")
    compliance_concern: str = Field(..., description="What compliance issue it violates")
    standard: str = Field(..., description="HIPAA | PCI-DSS | FedRAMP")
    severity: str = Field(..., description="Low / Medium / High")
    remediation: str = Field(..., description="Suggested fix for the violation")

# --- Argument Parsing ---
parser = argparse.ArgumentParser(description="RAG compliance analyzer for Terraform plans")
parser.add_argument("plan_json", help="Path to Terraform plan JSON")
args = parser.parse_args()

# --- Load Terraform Plan JSON ---
with open(args.plan_json, "r") as f:
    data = json.load(f)
raw_text = json.dumps(data, indent=2)

# --- Chunk into Documents ---
text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=100)
chunks = text_splitter.split_text(raw_text)
docs = [Document(page_content=chunk) for chunk in chunks]

# --- Embeddings + Vector Store ---
EMBED_MODEL_NAME = "sentence-transformers/all-MiniLM-L6-v2"
embedding = HuggingFaceEmbeddings(model_name=EMBED_MODEL_NAME)
db = FAISS.from_documents(docs, embedding)
retriever = db.as_retriever()

# --- LLM Setup ---
llm = OllamaLLM(model="mistral")

# --- Load & Enhance Prompt Template ---
prompt_path = Path("prompts/compliance_prompt.txt")
if not prompt_path.exists():
    raise FileNotFoundError("Prompt template not found at prompts/compliance_prompt.txt")

prompt_template = prompt_path.read_text().strip()
# Append enforcement of JSON output, fields, and cross-resource validation instructions
template_suffix = """

IMPORTANT: **Only** output a JSON array of objects, each object **must** include exactly these six fields (no more, no fewer):
- resource_type
- resource_name
- compliance_concern
- standard  (HIPAA | PCI-DSS | FedRAMP)
- severity   (Low / Medium / High)
- remediation  (Short suggested fix for the violation)

Apply cross-resource validation:
- If an encryption resource exists for the same bucket, suppress the Unencrypted Storage finding.
- If a public-access-block resource exists for the same bucket, suppress the Public S3 finding.
- If a network ACL denies traffic that a security group allows, suppress the SG-level finding.

Do **not** include any explanation, markdown fences, code blocks, or prose—only the raw JSON array of objects."""
prompt_template += template_suffix

# --- Build RAG Chain ---
chain = RetrievalQA.from_chain_type(
    llm=llm,
    retriever=retriever,
    chain_type="stuff",
    return_source_documents=False
)

print("🔎 Inspecting Terraform plan with compliance-aware RAG...")

# --- Invoke LLM ---
response = chain.invoke({"query": prompt_template})

# --- Extract raw result string ---
if isinstance(response, dict):
    raw = response.get("result", "")
else:
    raw = str(response)

# --- Strip any code fences via regex ---
raw = re.sub(r"^```(?:json)?\s*", "", raw, flags=re.MULTILINE)
raw = re.sub(r"\s*```$", "", raw, flags=re.MULTILINE)

# --- Attempt JSON parse and Pydantic validation ---
output_path = Path("findings/compliance_violations.json")
output_path.parent.mkdir(parents=True, exist_ok=True)

try:
    parsed = json.loads(raw)
    if not isinstance(parsed, list):
        raise ValueError("Expected a JSON array at top level")

    violations: List[ComplianceViolation] = []
    for idx, item in enumerate(parsed):
        violations.append(ComplianceViolation(**item))

    with open(output_path, "w") as f:
        json.dump([v.model_dump() for v in violations], f, indent=2)

    print(f"✅ Compliance check complete. Results saved to: {output_path}")

except (json.JSONDecodeError, ValidationError, ValueError) as e:
    print("❌ Failed to parse or validate JSON:", e)
    with open(output_path, "w") as f:
        f.write(raw)
    print(f"🔖 Raw output saved to: {output_path}")