from pathlib import Path
from langchain.schema import Document
from typing import List


def log_loaded_documents(docs: List[Document]):
    print(f"📄 Loaded {len(docs)} documents.")
    for doc in docs:
        meta = doc.metadata or {}
        file_name = Path(meta.get("source", "Unknown")).name
        label = meta.get("standard", "Unlabeled")
        print(f"— {file_name} [{label}]")


def log_llm_sources(source_docs: List[Document]):
    print("📚 Source documents used by the LLM:\n")
    for i, doc in enumerate(source_docs, 1):
        meta = doc.metadata
        print(f"🔹 [{i}] {meta.get('resource_name', 'Unnamed')} ({meta.get('resource_type', 'Unknown')})")
        print(f"    └─ Source: {meta.get('source', 'N/A')}")
        print(f"    └─ Standard: {meta.get('standard', 'Unlabeled')}")
        print()  # extra line for readability
