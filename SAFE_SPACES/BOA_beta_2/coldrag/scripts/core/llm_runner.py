from langchain.chains import RetrievalQA
from langchain_community.llms.ollama import Ollama

def create_chain(llm_model="mistral", retriever=None):
    """Create a RetrievalQA chain."""
    llm = Ollama(model=llm_model)
    return RetrievalQA.from_chain_type(llm=llm, retriever=retriever, chain_type="stuff")
