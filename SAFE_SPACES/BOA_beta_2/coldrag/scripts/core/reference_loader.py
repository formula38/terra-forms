import os
from dotenv import load_dotenv
from pathlib import Path
from langchain.document_loaders import (
    PyPDFLoader,
    TextLoader,
    JSONLoader,
    UnstructuredMarkdownLoader
)

load_dotenv()
ALLOWED_EXTENSIONS = {".pdf", ".txt", ".json", ".md"}

def load_reference_docs(directory: str):
    """Recursively load supported documents from a reference directory."""
    docs = []
    ref_path = Path(directory)

    if not ref_path.exists():
        print(f"⚠️ Reference path {directory} does not exist.")
        return docs

    for file in ref_path.rglob("*"):
        if not file.is_file() or file.suffix.lower() not in ALLOWED_EXTENSIONS:
            continue

        try:
            if file.suffix == ".pdf":
                docs.extend(PyPDFLoader(str(file)).load())
            elif file.suffix == ".txt":
                docs.extend(TextLoader(str(file)).load())
            elif file.suffix == ".json":
                docs.extend(JSONLoader(str(file)).load())
            elif file.suffix == ".md":
                docs.extend(UnstructuredMarkdownLoader(str(file)).load())
        except Exception as e:
            print(f"❌ Failed to load {file.name}: {e}")

    print(f"📚 Loaded {len(docs)} reference documents from: {directory}")
    return docs
