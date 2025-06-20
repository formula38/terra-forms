# coldrag/scripts/utils/llm_runner.py

import os
from dotenv import load_dotenv
from langchain_ollama import OllamaLLM
from langchain.chains import RetrievalQA

load_dotenv()

LLM_MODEL = os.getenv("LLM_MODEL", "mistral")
RETURN_SOURCES = os.getenv("LLM_RETURN_SOURCES", "true").lower() == "true"
CHAIN_TYPE = os.getenv("CHAIN_TYPE", "stuff")

def init_llm():
    return OllamaLLM(model=LLM_MODEL)

def run_rag_chain(llm, retriever, prompt):
    print("🧠 Running LLM with embedded context...")
    chain = RetrievalQA.from_chain_type(
        llm=llm,
        retriever=retriever,
        chain_type=CHAIN_TYPE,
        return_source_documents=RETURN_SOURCES
    )
    return chain.invoke({"query": prompt})
