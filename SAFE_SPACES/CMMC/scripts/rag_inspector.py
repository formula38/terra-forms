#!/usr/bin/env python3
"""RAG Inspector Script: Analyze Terraform Plan JSON using LangChain + Pydantic"""

import os
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
from langchain.text_splitter import TokenTextSplitter
from langchain.schema import Document
from pydantic import BaseModel, Field, ValidationError

try:
    import fitz  # PyMuPDF for PDF parsing
except ImportError:
    fitz = None

# --- Enums ---
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
    CIS = "CIS"
    CIS_AWS = "CIS AWS"
    CIS_AZURE = "CIS Azure"
    CIS_GCP = "CIS GCP"


class SeverityLevel(str, Enum):
    LOW = "Low"
    MEDIUM = "Medium"
    HIGH = "High"

# --- Output Schema ---
class ComplianceViolation(BaseModel):
    resource_type: str
    resource_name: str
    compliance_concern: str
    standards: List[Literal[
        "HIPAA", "PCI-DSS", "FedRAMP", "CMMC", "GDPR",
        "GLBA", "ISO 27001", "NIST", "SOC 2", "SOX",
        "CIS", "CIS AWS", "CIS Azure", "CIS GCP"
    ]]
    severity: str
    remediation: str

# --- CLI ---
parser = argparse.ArgumentParser(description="RAG compliance analyzer for Terraform plans")
parser.add_argument("plan_json", help="Path to Terraform plan JSON")
parser.add_argument("output_path", help="Path to save compliance JSON")
parser.add_argument("--refdir", help="Optional reference directory", default=None)
args = parser.parse_args()

input_path = Path(args.plan_json)
output_path = Path(args.output_path)
docs = []

# --- Include Prompts Directory ---
PROMPTS_DIR = Path(__file__).parent / "prompts"
PROMPT = "blanket_compliance_prompt.txt"

if PROMPTS_DIR.exists():
    print(f"📂 Including prompts from: {PROMPTS_DIR}")
    for file in PROMPTS_DIR.glob("*"):
        if file.name == PROMPT:
            continue
        try:
            content = file.read_text()
            docs.append(Document(
                page_content=content,
                metadata={"source": file.name, "standard": "PROMPTS"}
            ))
        except Exception as e:
            print(f"⚠️ Error reading prompt file {file.name}: {e}")

# --- Load Terraform Plan or State ---
if input_path.is_file():
    with open(input_path, "r") as f:
        data = json.load(f)

    # --- First try: resource_changes (from plan output) ---
    changes = data.get("resource_changes", [])

    # --- Fallback: full state resources (from terraform.tfstate) ---
    if not changes:
        root_module = data.get("values", {}).get("root_module", {})
        resources = root_module.get("resources", [])
        for res in resources:
            resource_type = res.get("type", "unknown")
            resource_name = res.get("name", "unknown")
            docs.append(Document(
                page_content=json.dumps(res, indent=2),
                metadata={
                    "resource_type": resource_type,
                    "resource_name": resource_name,
                    "standard": resource_type.upper(),
                    "source": resource_name.upper()
                }
            ))
    else:
        for change in changes:
            resource_type = change.get("type", "unknown")
            resource_name = change.get("address", "unknown")
            docs.append(Document(
                page_content=json.dumps(change, indent=2),
                metadata={
                    "resource_type": resource_type,
                    "resource_name": resource_name,
                    "standard": resource_type.upper(),
                    "source": resource_name.upper()
                }
            ))


# --- Reference Directory ---
if args.refdir:
    ref_dir = Path(args.refdir)
    if ref_dir.exists():
        print(f"📂 Including static reference docs from: {ref_dir}")
        for file in ref_dir.rglob("*"):
            if file.suffix.lower() in {".txt", ".json", ".md", ".pdf"} and file.is_file():
                try:
                    content = ""
                    if file.suffix.lower() == ".json":
                        content = json.dumps(json.load(open(file)), indent=2)
                    elif file.suffix.lower() == ".pdf" and fitz:
                        with fitz.open(file) as pdf:
                            content = "\n".join(page.get_text() for page in pdf)
                    else:
                        content = file.read_text(errors="ignore")

                    docs.append(Document(
                        page_content=content,
                        metadata={
                            "source": file.name,
                            "standard": file.parent.name.upper()
                        }
                    ))
                except Exception as e:
                    print(f"⚠️ Error reading {file.name}: {e}")

# ✅ Log what was ingested
print(f"📄 Loaded {len(docs)} documents.")
for doc in docs:
    meta = doc.metadata or {}
    file_name = Path(meta.get("source", "Unknown")).name
    label = meta.get("standard", "Unlabeled")
    print(f"— {file_name} [{label}]")

# --- Embedding + Vector DB ---
embedding = HuggingFaceEmbeddings(model_name="./scripts/models/mpnet-finetuned")
# embedding = HuggingFaceEmbeddings(model_name="sentence-transformers/all-mpnet-base-v2")
db = FAISS.from_documents(docs, embedding)
retriever = db.as_retriever(
    search_type="mmr",              # Enables MMR
    search_kwargs={"k": 20}         # Fetch 10 diverse and relevant docs
)

# --- LLM Setup ---
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
)

# --- Load Prompt Template ---
prompt_path = PROMPTS_DIR / PROMPT
if not prompt_path.exists():
    raise FileNotFoundError(f"Prompt template not found at {prompt_path}")
prompt_template = prompt_path.read_text().strip() + """
You must return a single JSON object with exactly two keys:
- "violations": a list of objects, each with:
    - resource_type
    - resource_name (match the 'name' field in the plan JSON)
    - compliance_concern
    - standards (list of standards impacted)
    - severity (Low, Medium, or High)
    - remediation

- "recommendations": a list of 3–5 high-level actions.

⚠️ DO NOT return markdown, prose, or comments. Only valid raw JSON should be returned.
⚠️ When referencing CIS standards, specify the provider-specific variant (e.g., "CIS AWS", "CIS Azure", or "CIS GCP") if the control applies to a particular cloud platform.
"""

# --- Execute Chain ---
print("🔎 Inspecting Terraform plan with compliance-aware RAG...")
chain = RetrievalQA.from_chain_type(
    llm=llm, 
    retriever=retriever, 
    chain_type="stuff",
    return_source_documents=True,
    )
response = chain.invoke({"query": prompt_template})
# See which docs made it in
print("📚 Source documents used by the LLM:\n")
for i, doc in enumerate(response["source_documents"], 1):
    meta = doc.metadata
    print(f"🔹 [{i}] {meta.get('resource_name', 'Unnamed')} ({meta.get('resource_type', 'Unknown')})")
    print(f"    └─ Source: {meta.get('source', 'N/A')}")
    print(f"    └─ Standard: {meta.get('standard', 'Unlabeled')}")
    print()  # extra line for readability


# --- Parse LLM Output ---
raw = response.get("result", "") if isinstance(response, dict) else str(response)
raw = re.sub(r"^```(?:json)?\s*", "", raw, flags=re.MULTILINE)
raw = re.sub(r"\s*```$", "", raw, flags=re.MULTILINE)

output_path.parent.mkdir(parents=True, exist_ok=True)
raw_path = output_path.with_suffix(".raw.txt")

if not input_path.exists() or input_path.stat().st_size == 0:
    raise ValueError(f"Input file {input_path} is missing or empty.")

with open(input_path, "r") as f:
    try:
        data = json.load(f)
    except json.JSONDecodeError as e:
        raise ValueError(f"Invalid JSON in input file {input_path}: {e}")



try:
    parsed = json.loads(raw)
    if not isinstance(parsed, dict):
        raise ValueError("Expected JSON object")
    violations_raw = parsed.get("violations", [])
    recommendations = parsed.get("recommendations", [])
    violations = [
        ComplianceViolation(**v)
        for v in violations_raw
        if v.get("resource_name")
    ]
    report = {
        "violations": [v.model_dump() for v in violations],
        "recommendations": recommendations
    }
    with open(output_path, "w") as f:
        json.dump(report, f, indent=2)
    print(f"✅ Compliance check complete. Results saved to: {output_path}")
except (json.JSONDecodeError, ValidationError, ValueError) as e:
    print("❌ Failed to parse or validate JSON:", e)
    with open(output_path, "w") as f:
        f.write(raw)
    print(f"⚠️ Raw output saved to: {output_path}")
