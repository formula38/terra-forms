from pathlib import Path
from langchain.schema import Document
from typing import List, Union

def log_loaded_docs(docs: List[Document]) -> None:
    """Log metadata for all loaded documents."""
    print(f"📄 Loaded {len(docs)} documents.")
    for doc in docs:
        meta = doc.metadata or {}
        file_name = Path(meta.get("source", "Unknown")).name
        label = meta.get("standard", "Unlabeled")
        print(f"— {file_name} [{label}]")


def log_llm_sources(response: dict) -> None:
    """Log metadata of documents used by the LLM."""
    sources: Union[List[Document], None] = response.get("source_documents", [])
    if not sources:
        print("⚠️ No source documents found in LLM response.")
        return

    print("📚 Source documents used by the LLM:\n")
    for i, doc in enumerate(sources, 1):
        if not isinstance(doc, Document):
            print(f"🔹 [{i}] Skipped: not a Document object (type={type(doc)})")
            continue

        meta = doc.metadata or {}
        print(f"🔹 [{i}] {meta.get('resource_name', 'Unnamed')} ({meta.get('resource_type', 'Unknown')})")
        print(f"    └─ Source: {meta.get('source', 'N/A')}")
        print(f"    └─ Standard: {meta.get('standard', 'Unlabeled')}\n")
