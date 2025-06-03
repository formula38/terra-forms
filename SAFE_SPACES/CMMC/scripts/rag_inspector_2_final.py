#!/usr/bin/env python3
"""RAG Inspector: Analyze Terraform plan files for compliance violations via local LLM + vector search."""

import os
import re
import json
import argparse
from enum import Enum
from pathlib import Path
from typing import List, Literal

import fitz  # PyMuPDF
from pydantic import BaseModel, Field, ValidationError
from langchain.schema import Document
from langchain_ollama import OllamaLLM
from langchain.chains import RetrievalQA
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_community.vectorstores import FAISS

# --- Enum Definitions ---
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

class ComplianceViolation(BaseModel):
    resource_type: str
    resource_name: str
    compliance_concern: str
    standards: List[Literal[
        "HIPAA", "PCI-DSS", "FedRAMP", "CMMC", "GDPR",
        "GLBA", "ISO 27001", "NIST", "SOC 2", "SOX", "CIS AWS"
    ]]
    severity: str
    remediation: str

# --- CLI Args ---
parser = argparse.ArgumentParser(description="Analyze Terraform plan against compliance frameworks")
parser.add_argument("plan_json", help="Path to .json plan file or directory of .tf/.txt")
parser.add_argument("output_path", help="Where to save structured compliance findings")
parser.add_argument("--refdir", help="Optional reference directory for static docs", default=None)
args = parser.parse_args()

plan_path = Path(args.plan_json)
output_path = Path(args.output_path)
docs: List[Document] = []

# --- Load Prompts ---
PROMPTS_DIR = Path(__file__).parent / "prompts"
if PROMPTS_DIR.exists():
    print(f"📂 Including prompts from: {PROMPTS_DIR}")
    for file in PROMPTS_DIR.glob("*"):
        if file.name == "terraform_compliance_prompt_optimized.txt":
            continue
        if file.suffix in {".json", ".tf", ".txt"}:
            try:
                content = file.read_text(errors="ignore")
                docs.append(Document(
                    page_content=content,
                    metadata={
                        "source": file.name,
                        "standard": file.parent.name.upper()
                    }
                ))
            except Exception as e:
                print(f"⚠️ Could not load prompt {file.name}: {e}")

# --- Load Optional Reference Directory ---
if args.refdir:
    ref_dir = Path(args.refdir)
    if ref_dir.exists():
        print(f"📂 Including static reference docs from: {ref_dir}")
        for file in ref_dir.rglob("*"):
            if file.suffix.lower() in {".json", ".tf", ".txt"}:
                try:
                    content = file.read_text(errors="ignore")
                    docs.append(Document(
                        page_content=content,
                        metadata={
                            "source": file.name,
                            "standard": file.parent.name.upper()
                        }
                    ))
                except Exception as e:
                    print(f"⚠️ Error reading static ref file {file.name}: {e}")
    else:
        print(f"❌ Reference directory not found at {ref_dir}")

# --- Parse Terraform Plan or Dir of Files ---
if plan_path.is_file():
    with open(plan_path) as f:
        plan_data = json.load(f)
    for change in plan_data.get("resource_changes", []):
        docs.append(Document(
            page_content=json.dumps(change, indent=2),
            metadata={
                "resource_type": change.get("type", "unknown"),
                "resource_name": change.get("name") or change.get("address") or "unknown"
            }
        ))
elif plan_path.is_dir():
    for file in plan_path.rglob("*"):
        if file.name == "terraform_compliance_prompt_optimized.txt":
            continue
        if file.suffix.lower() in {".json", ".tf", ".txt"}:
            try:
                content = file.read_text(errors="ignore")
                docs.append(Document(
                    page_content=content,
                    metadata={
                        "source": file.name,
                        "standard": file.parent.name.upper()
                    }
                ))
            except Exception as e:
                print(f"⚠️ Could not read {file.name}: {e}")

# --- Log what's loaded ---
print(f"📄 Loaded {len(docs)} documents.")
for doc in docs:
    meta = doc.metadata or {}
    print(f"— {Path(meta.get('source', 'Unknown')).name} [{meta.get('standard', 'Unlabeled')}]")

# --- Embeddings + Retrieval ---
embedding = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")
db = FAISS.from_documents(docs, embedding)
retriever = db.as_retriever()

# --- LLM Configuration ---
llm = OllamaLLM(
    model="mistral",
    temperature=0,
    top_p=0.3,
    top_k=20,
    num_ctx=4096,
    repeat_penalty=1.2,
    stop=["\n\n"],
    num_predict=1024,
    seed=1,
    format="json",
    tfs_z=1.5,
    mirostat=2,
    mirostat_eta=0.1,
    mirostat_tau=5,
    keep_alive=True,
)

# --- Load Prompt Template ---
prompt_file = PROMPTS_DIR / "terraform_compliance_prompt_optimized.txt"
if not prompt_file.exists():
    raise FileNotFoundError(f"Missing required prompt at: {prompt_file}")
base_prompt = prompt_file.read_text().strip() + """
You must return a single JSON object with exactly two keys:
- "violations": a list of objects, each with:
    - resource_type
    - resource_name (must be real from the Terraform plan, no placeholders)
    - compliance_concern
    - standards (list of compliance labels)
    - severity (Low, Medium, or High)
    - remediation

- "recommendations": a list of 3–5 high-level actions (short text only).

⚠️ DO NOT fabricate resource names like <BUCKET_NAME>. Use real values found in the Terraform JSON.
⚠️ DO NOT return markdown, prose, or comments. Only valid raw JSON should be returned.
"""

# --- Query Chain ---
print("🔎 Inspecting Terraform plan with compliance-aware RAG...")
qa_chain = RetrievalQA.from_chain_type(llm=llm, retriever=retriever, chain_type="stuff")
response = qa_chain.invoke({"query": base_prompt})

# --- Parse & Validate Output ---
raw = re.sub(r"^```(?:json)?\s*|\s*```$", "", str(response), flags=re.MULTILINE)
raw_path = output_path.with_suffix(".raw.txt")
output_path.parent.mkdir(parents=True, exist_ok=True)

with open(raw_path, "w") as f:
    f.write(raw)

try:
    parsed = json.loads(raw)
except json.JSONDecodeError as e:
    print(f"❌ JSON decoding failed: {e}")
    raw = re.sub(r"^```(?:json)?\s*|\s*```$", "", raw.strip(), flags=re.MULTILINE)
    try:
        parsed = json.loads(raw)
    except Exception as e2:
        print("❌ Still failed after cleaning markdown fences.")
        with open(output_path, "w") as f:
            f.write(raw)
        raise e2
    violations = [ComplianceViolation(**v) for v in parsed.get("violations", []) if v.get("resource_name")]
    report = {
        "violations": [v.model_dump() for v in violations],
        "recommendations": parsed.get("recommendations", [])
    }
    with open(output_path, "w") as f:
        json.dump(report, f, indent=2)
    print(f"✅ Compliance check complete. Results saved to: {output_path}")
except Exception as e:
    print(f"❌ Failed to parse or validate JSON: {e}")
    with open(output_path, "w") as f:
        f.write(raw)
    print(f"⚠️ Raw output saved to: {output_path}")
