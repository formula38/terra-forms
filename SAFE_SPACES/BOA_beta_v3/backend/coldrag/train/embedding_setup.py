# coldrag/scripts/core/embedding_setup.py

import os
from dotenv import load_dotenv
from langchain_community.vectorstores import Qdrant
from langchain_huggingface import HuggingFaceEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
import qdrant_client


load_dotenv()

# --- Load from .env or use defaults ---
CHUNK_SIZE = int(os.getenv("CHUNK_SIZE", 1000))
CHUNK_OVERLAP = int(os.getenv("CHUNK_OVERLAP", 100))
EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "sentence-transformers/all-mpnet-base-v2")
SEARCH_K = int(os.getenv("SEARCH_K", 10))
SEARCH_TYPE = os.getenv("SEARCH_TYPE", "mmr")  # Options: 'similarity', 'mmr'

# --- Qdrant Configuration ---
QDRANT_HOST = os.getenv("QDRANT_HOST", "localhost")
QDRANT_PORT = int(os.getenv("QDRANT_PORT", 6333))
QDRANT_COLLECTION_NAME = os.getenv("QDRANT_COLLECTION_NAME", "cmmc_documents")


def load_embeddings_and_retriever(documents: list, model_path: str = EMBEDDING_MODEL):
    """
    Embed documents and return a Qdrant retriever with configured search options.
    """
    # 1. Split documents into chunks
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=CHUNK_SIZE,
        chunk_overlap=CHUNK_OVERLAP
    )
    chunks = splitter.split_documents(documents)

    # 2. Initialize embeddings model
    embeddings = HuggingFaceEmbeddings(model_name=model_path)

    # 3. Setup Qdrant client and vector store
    # Using the service name `vector-db` from docker-compose
    client = qdrant_client.QdrantClient(host=QDRANT_HOST, port=QDRANT_PORT)

    print(f"🔌 Connecting to Qdrant at {QDRANT_HOST}:{QDRANT_PORT}...")
    
    # Check if collection exists, create if not
    try:
        client.get_collection(collection_name=QDRANT_COLLECTION_NAME)
        print(f"Collection '{QDRANT_COLLECTION_NAME}' already exists.")
        # If it exists, we can just create the LangChain wrapper
        vectorstore = Qdrant(
            client=client,
            collection_name=QDRANT_COLLECTION_NAME,
            embeddings=embeddings,
        )

    except Exception:
        print(f"Collection '{QDRANT_COLLECTION_NAME}' not found. Creating and populating it.")
        # If it doesn't exist, create it and add documents
        vectorstore = Qdrant.from_documents(
            documents=chunks,
            embedding=embeddings,
            host=QDRANT_HOST,
            port=QDRANT_PORT,
            collection_name=QDRANT_COLLECTION_NAME,
            force_recreate=True, # Use with caution, deletes existing collection
        )

    print("✅ Qdrant vector store is ready.")

    # 4. Create retriever
    retriever = vectorstore.as_retriever(
        search_type=SEARCH_TYPE,
        search_kwargs={"k": SEARCH_K}
    )
    return retriever
