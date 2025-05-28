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

# --- Pydantic Model for Output ---
class ComplianceViolation(BaseModel):
    resource: str = Field(..., description="Terraform resource name")
    issue: str = Field(..., description="Description of the compliance issue")
    severity: str = Field(..., description="Low / Medium / High")
    remediation: str = Field(..., description="Suggested fix")

# --- Setup Embedding Model ---
EMBED_MODEL_NAME = "sentence-transformers/all-MiniLM-L6-v2"
embedding = HuggingFaceEmbeddings(model_name=EMBED_MODEL_NAME)

# --- Argument Parsing ---
parser = argparse.ArgumentParser(description="RAG compliance analyzer for Terraform plans")
parser.add_argument("plan_json", help="Path to Terraform plan JSON")
args = parser.parse_args()

# --- Load and chunk JSON content ---
with open(args.plan_json, "r") as f:
    data = json.load(f)

raw_text = json.dumps(data, indent=2)
text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=100)
chunks = text_splitter.split_text(raw_text)
docs = [Document(page_content=chunk) for chunk in chunks]

# --- Vector Store ---
db = FAISS.from_documents(docs, embedding)
retriever = db.as_retriever()

# --- LLM Setup ---
llm = Ollama(model="mistral")

# --- RAG Chain ---
chain = RetrievalQA.from_chain_type(
    llm=llm,
    retriever=retriever,
    chain_type="stuff",
    return_source_documents=False
)

# --- Run Query ---
query = "Identify any resources in this Terraform plan that may violate HIPAA or general cloud compliance standards. Output them as JSON."
response = chain.invoke({"query": query})

# --- Save Output ---
output_path = Path("findings/compliance_violations.json")
output_path.parent.mkdir(exist_ok=True)

# Ensure correct formatting
if isinstance(response, dict):
    result_text = response.get("result", "")
    with open(output_path, "w") as f:
        f.write(result_text)
else:
    with open(output_path, "w") as f:
        f.write(str(response))

print(f"✅ Compliance check complete. Results saved to: {output_path}")
