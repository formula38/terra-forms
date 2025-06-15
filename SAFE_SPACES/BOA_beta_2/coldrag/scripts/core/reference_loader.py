from langchain.document_loaders import PyPDFLoader, TextLoader, JSONLoader
from pathlib import Path

def load_documents(directory: str):
    """Load documents from a directory supporting .pdf, .txt, .json."""
    docs = []
    for path in Path(directory).rglob("*"):
        if path.suffix == ".pdf":
            docs.extend(PyPDFLoader(str(path)).load())
        elif path.suffix == ".txt":
            docs.extend(TextLoader(str(path)).load())
        elif path.suffix == ".json":
            docs.extend(JSONLoader(str(path)).load())
    return docs
