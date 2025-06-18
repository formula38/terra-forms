# coldrag/scripts/core/embedding_setup.py

from langchain_community.vectorstores import FAISS
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from dotenv import load_dotenv
import os

load_dotenv()

# Load from .env
CHUNK_SIZE = int(os.getenv("CHUNK_SIZE", 1000))
CHUNK_OVERLAP = int(os.getenv("CHUNK_OVERLAP", 100))
EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "sentence-transformers/all-mpnet-base-v2")
SEARCH_K = int(os.getenv("SEARCH_K", 10))

def build_faiss_index(documents: list, model_name: str = EMBEDDING_MODEL):
    """Embed documents and return a FAISS retriever."""
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=CHUNK_SIZE,
        chunk_overlap=CHUNK_OVERLAP
    )
    chunks = splitter.split_documents(documents)
    embeddings = HuggingFaceEmbeddings(model_name=model_name)
    return FAISS.from_documents(chunks, embeddings).as_retriever(
        search_kwargs={"k": SEARCH_K}
    )
