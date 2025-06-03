
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
from langchain.text_splitter import TokenTextSplitter
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
    resource_type: str
    resource_name: str
    compliance_concern: str
    standards: List[Literal[
        "HIPAA", "PCI-DSS", "FedRAMP", "CMMC", "GDPR",
        "GLBA", "ISO 27001", "NIST", "SOC 2", "SOX", "CIS AWS"
    ]]
    severity: str
    remediation: str

# --- Argument Parsing ---
parser = argparse.ArgumentParser(description="RAG compliance analyzer for Terraform plans")
parser.add_argument("plan_json", help="Path to Terraform plan JSON")
parser.add_argument("output_path", help="Path to save compliance JSON")
args = parser.parse_args()

output_path = Path(args.output_path)

# --- Multi-File RAG Support ---
input_path = Path(args.plan_json)
docs = []

if input_path.is_file():
    # Single file mode (JSON plan)
    with open(input_path, "r") as f:
        data = json.load(f)
    resource_changes = data.get("resource_changes", [])
    for change in resource_changes:
        resource_type = change.get("type", "unknown")
        resource_name = change.get("name", "unknown")
        content = json.dumps(change, indent=2)
        docs.append(Document(page_content=content, metadata={
            "resource_type": resource_type,
            "resource_name": resource_name
        }))
elif input_path.is_dir():
    # Multi-file mode
    for file in input_path.glob("*"):
        if file.suffix in {".json", ".tf", ".txt"}:
            if file.suffix == ".json":
                with open(file) as f:
                    try:
                        data = json.load(f)
                        if isinstance(data, dict) and "resource_changes" in data:
                            for change in data["resource_changes"]:
                                docs.append(Document(page_content=json.dumps(change, indent=2), metadata={
                                    "resource_type": change.get("type", "unknown"),
                                    "resource_name": change.get("name", "unknown")
                                }))
                        else:
                            docs.append(Document(page_content=json.dumps(data, indent=2)))
                    except Exception:
                        docs.append(Document(page_content=file.read_text()))
            else:
                docs.append(Document(page_content=file.read_text(), metadata={"source": str(file)}))
else:
    raise ValueError(f"Invalid path: {input_path}")

# --- Embeddings + Vector Store ---
embedding = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")
db = FAISS.from_documents(docs, embedding)
retriever = db.as_retriever()

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
    max_threads=4,
    keep_alive=True,
)

# --- Load Prompt Template ---
script_dir = Path(__file__).parent.resolve()
prompt_path = script_dir / "prompts"
if not prompt_path.exists():
    raise FileNotFoundError(f"Prompt template not found at {prompt_path}")

prompt_template = prompt_path.read_text().strip()
template_suffix = """
You must return a single JSON object with exactly two keys:
- "violations": a list of objects, each with:
    - resource_type
    - resource_name (match the 'name' field in the plan JSON)
    - compliance_concern
    - standards (list of standards impacted)
    - severity (Low, Medium, or High)
    - remediation

- "recommendations": a list of 3–5 high-level actions.

Do not return markdown or code fences.
"""
prompt_template += template_suffix

# --- Build RAG Chain ---
chain = RetrievalQA.from_chain_type(
    llm=llm,
    retriever=retriever,
    chain_type="stuff",
    return_source_documents=False,
)

# --- Invoke LLM ---
print("🔎 Inspecting Terraform plan with compliance-aware RAG...")
response = chain.invoke({"query": prompt_template})

# --- Parse LLM Output ---
raw = response.get("result", "") if isinstance(response, dict) else str(response)
raw = re.sub(r"^```(?:json)?\s*", "", raw, flags=re.MULTILINE)
raw = re.sub(r"\s*```$", "", raw, flags=re.MULTILINE)

output_path.parent.mkdir(parents=True, exist_ok=True)
raw_path = output_path.with_suffix(".raw.txt")
with open(raw_path, "w") as f:
    f.write(raw)

try:
    parsed = json.loads(raw)
    if not isinstance(parsed, dict):
        raise ValueError("Expected JSON object")
    violations_raw = parsed.get("violations", [])
    recommendations = parsed.get("recommendations", [])
    violations: List[ComplianceViolation] = [
        ComplianceViolation(**v) for v in violations_raw if v.get("resource_name")
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
