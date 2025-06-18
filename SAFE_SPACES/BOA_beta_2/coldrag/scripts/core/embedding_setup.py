# coldrag/scripts/core/embedding_setup.py

import os
from dotenv import load_dotenv
from langchain.vectorstores import FAISS
from langchain_huggingface import HuggingFaceEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter


load_dotenv()

# --- Load from .env or use defaults ---
CHUNK_SIZE = int(os.getenv("CHUNK_SIZE", 1000))
CHUNK_OVERLAP = int(os.getenv("CHUNK_OVERLAP", 100))
EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "sentence-transformers/all-mpnet-base-v2")
SEARCH_K = int(os.getenv("SEARCH_K", 10))
SEARCH_TYPE = os.getenv("SEARCH_TYPE", "mmr")  # Options: 'similarity', 'mmr'

def load_embeddings_and_retriever(documents: list, model_path: str = EMBEDDING_MODEL):
    """Embed documents and return a FAISS retriever with configured search options."""
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=CHUNK_SIZE,
        chunk_overlap=CHUNK_OVERLAP
    )
    chunks = splitter.split_documents(documents)

    embeddings = HuggingFaceEmbeddings(model_name=model_path)
    vectorstore = FAISS.from_documents(chunks, embeddings)

    retriever = vectorstore.as_retriever(
        search_type=SEARCH_TYPE,
        search_kwargs={"k": SEARCH_K}
    )
    return retriever
