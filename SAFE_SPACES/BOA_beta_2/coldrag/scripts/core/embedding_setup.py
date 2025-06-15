from langchain_community.vectorstores import FAISS
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter

def build_faiss_index(documents: list, model_name="sentence-transformers/all-mpnet-base-v2"):
    """Embed documents and return FAISS retriever."""
    splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=100)
    chunks = splitter.split_documents(documents)
    embeddings = HuggingFaceEmbeddings(model_name=model_name)
    return FAISS.from_documents(chunks, embeddings).as_retriever(search_kwargs={"k": 10})
