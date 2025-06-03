#!/usr/bin/env python3
"""RAG Inspector Script: Analyze Terraform Plan JSON using LangChain + Pydantic"""

import re
import json
import argparse
from enum import Enum
from pathlib import Path
from typing import List, Literal

from langchain.chains import RetrievalQA
from langchain_community.vectorstores import FAISS
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_ollama import OllamaLLM
from langchain.text_splitter import RecursiveCharacterTextSplitter, TokenTextSplitter
from langchain.schema import Document
from pydantic import BaseModel, Field, ValidationError

# --- Enum definitions ---
class ComplianceStandard(str, Enum):
    HIPAA = "HIPAA"
    PCI_DSS = "PCI-DSS"
    FedRAMP = "FedRAMP"
    CMMC = "CMMC"
    GDPR = "GDPR"
    GLBA = "GLBA"
    ISO_27001 = "ISO 27001"
    NIST = "NIST"
    SOC_2 = "SOC 2"
    SOX = "SOX"
    CIS_AWS = "CIS AWS"

class SeverityLevel(str, Enum):
    LOW = "Low"
    MEDIUM = "Medium"
    HIGH = "High"

# --- Pydantic Model for Output Validation ---
class ComplianceViolation(BaseModel):
    resource_type: str = Field(..., description="Terraform AWS resource type")
    resource_name: str = Field(..., description="Resource name as defined in TF")
    compliance_concern: str = Field(..., description="What compliance issue it violates")
    standards: List[Literal[
        "HIPAA", "PCI-DSS", "FedRAMP", "CMMC", "GDPR",
        "GLBA", "ISO 27001", "NIST", "SOC 2", "SOX", "CIS AWS"
    ]] = Field(..., description="Applicable compliance frameworks")
    severity: str = Field(..., description="Low / Medium / High")
    remediation: str = Field(..., description="Suggested fix for the violation")


# --- Argument Parsing ---
parser = argparse.ArgumentParser(description="RAG compliance analyzer for Terraform plans")
parser.add_argument("plan_json", help="Path to Terraform plan JSON")
parser.add_argument("output_path", help="Path to save compliance JSON")
args = parser.parse_args()

output_path = Path(args.output_path)


# --- Load Terraform Plan JSON ---
with open(args.plan_json, "r") as f:
    data = json.load(f)
raw_text = json.dumps(data, indent=2)

# --- Chunk into Documents ---

# text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=100)
# chunks = text_splitter.split_text(raw_text)

text_splitter = TokenTextSplitter(
    chunk_size=512,     # fits well under Mistral’s 1024-token limit
    chunk_overlap=50,
    #model_name="",   # or use mistral-compatible tokenizer if supported
    encoding_name="gpt2",  # ensures consistent tokenization
)
chunks = text_splitter.split_text(raw_text)

docs = [Document(page_content=chunk) for chunk in chunks]

# --- Embeddings + Vector Store ---
EMBED_MODEL_NAME = "sentence-transformers/all-MiniLM-L6-v2"
embedding = HuggingFaceEmbeddings(model_name=EMBED_MODEL_NAME)
db = FAISS.from_documents(docs, embedding)
retriever = db.as_retriever()

# --- LLM Setup ---
llm = OllamaLLM(
    model="mistral",
    # model="deepseek-r1",  # Use a model that supports structured output
    temperature=0,              # Low creativity, high determinism
    top_p=0.3,                    # Reduces randomness; encourages consistent structure
    top_k=20,                     # Lowers vocabulary scope — tightens focus
    num_ctx=4096,                 # Longer context = more Terraform plan handled
    repeat_penalty=1.2,          # Penalize repetition of violation patterns
    stop=["\n\n"],               # Stop at natural JSON segment breaks
    num_predict=1024,             # Expand response room for longer JSON lists
    seed=1,                     # Deterministic generation for reproducibility
    format="json",                # Forces structured output
    tfs_z=1.5,                  # TFS for controlled output length
    mirostat=2,                # Mirostat for adaptive control of output length
    mirostat_eta=0.1,          # Mirostat parameters for adaptive control
    mirostat_tau=5,            # Mirostat parameters for adaptive control
    max_threads=4,            # Parallel processing for faster response
    keep_alive=True,          # Keep connection alive for multiple queries
)

# --- Load & Enhance Prompt Template ---
script_dir = Path(__file__).parent.resolve()
prompt_path = script_dir / "prompts" / "terraform_compliance_prompt_optimized.txt"
if not prompt_path.exists():
    raise FileNotFoundError(f"Prompt template not found at {prompt_path}")


prompt_template = prompt_path.read_text().strip()
# Append enforcement of JSON output, fields, and cross-resource validation instructions
template_suffix = """
You must return a single JSON object with **exactly two keys**:
- "violations": a list of objects, each with **exactly** these six fields:
    - resource_type
    - resource_name
    - compliance_concern
    - standards: a list of one or more from [HIPAA, PCI-DSS, FedRAMP, CMMC, GDPR, GLBA, ISO 27001, NIST, SOC 2, SOX, CIS AWS]
    - severity (Low, Medium, or High)
    - remediation (a short fix recommendation)
- "recommendations": a list of 3–5 short, high-level actions to improve overall compliance posture.

❗ Strict formatting rules:
- Output must be **a single JSON object** — no markdown, no prose, no code fences.
- Do not include any extra commentary or explanation.
- If a violation applies to multiple standards, include all applicable ones in the `standards` list.

🔍 Cross-resource validation rules:
- If an encryption config exists for a bucket, omit any “Unencrypted Storage” violation for it.
- If a public-access-block resource exists for a bucket, omit any “Public S3” finding.
- If a network ACL blocks traffic allowed by a security group, omit the SG-level finding.

Respond ONLY with valid JSON object. Do not include any explanation, markdown, commentary, or surrounding text. 
The output MUST begin with { and end with }. No <think> tags.

🚫 Do not output a raw array. Only return a well-formed JSON object with the two required keys.
"""

prompt_template += template_suffix

# --- Build RAG Chain ---
chain = RetrievalQA.from_chain_type(
    llm=llm,
    retriever=retriever,
    chain_type="stuff",  # Use map-reduce for better aggregation
    return_source_documents=False,
    # chain_type_kwargs={
    #     "prompt": prompt_template,
    #     "verbose": True,  # Enable verbose logging for debugging
    # }
    # kwargs={
    #     "prompt": prompt_template,
    #     "verbose": True,  # Enable verbose logging for debugging
    # }
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
output_path.parent.mkdir(parents=True, exist_ok=True)
raw_path = output_path.with_suffix(".raw.txt")

with open(raw_path, "w") as f:
    f.write(raw)

try:
    parsed = json.loads(raw)
    if not isinstance(parsed, dict):
        raise ValueError("Expected top-level JSON object")

    violations_raw = parsed.get("violations", [])
    recommendations = parsed.get("recommendations", [])

    violations: List[ComplianceViolation] = []
    for item in violations_raw:
        if not item.get("resource_name"):
            print("⚠️ Skipping violation with missing resource_name:", item)
            continue
        violations.append(ComplianceViolation(**item))

    report = {
        "violations": [v.model_dump() for v in violations],
        "recommendations": recommendations if isinstance(recommendations, list) else []
    }

    with open(output_path, "w") as f:
        json.dump(report, f, indent=2)
    print(f"✅ Compliance check complete. Results saved to: {output_path}")

except (json.JSONDecodeError, ValidationError, ValueError) as e:
    print("❌ Failed to parse/validate LLM output:", e)
    print(f"⚠️ Skipping update to: {output_path} — raw text written to: {raw_path}")




# 🛑 If JSON output from LLM is invalid (e.g. malformed or missing fields)
except (json.JSONDecodeError, ValidationError, ValueError) as e:
    print("❌ Failed to parse or validate JSON:", e)
    # still write out raw text to aid debugging
    with open(output_path, "w") as f:
        f.write(raw)
    print(f"🔖 Raw output saved to: {output_path}")
