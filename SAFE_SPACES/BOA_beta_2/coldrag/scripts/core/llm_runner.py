import os
from dotenv import load_dotenv
from langchain.chains import RetrievalQA
from langchain_community.llms.ollama import Ollama

load_dotenv()

# --- Load config from environment ---
LLM_MODEL = os.getenv("LLM_MODEL", "mistral")
LLM_RETURN_SOURCES = os.getenv("LLM_RETURN_SOURCES", "true").lower() == "true"
CHAIN_TYPE = os.getenv("CHAIN_TYPE", "stuff")

def init_llm():
    """Initialize Ollama LLM with environment-based parameters."""
    return Ollama(model=LLM_MODEL)

def run_rag_chain(llm, retriever, prompt):
    """Execute the RetrievalQA chain with provided LLM, retriever, and prompt."""
    chain = RetrievalQA.from_chain_type(
        llm=llm,
        retriever=retriever,
        chain_type=CHAIN_TYPE,
        return_source_documents=LLM_RETURN_SOURCES,
    )
    return chain.invoke({"query": prompt})
