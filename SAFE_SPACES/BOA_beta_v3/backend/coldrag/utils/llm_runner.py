# coldrag/scripts/utils/llm_runner.py

import os
from dotenv import load_dotenv
from langchain.chains import RetrievalQA
from langchain.llms.base import LLM
from typing import Any, List, Mapping, Optional
import litellm

# Load environment variables from .env file
load_dotenv()

# --- Configuration ---
LLM_MODEL = os.getenv("LLM_MODEL", "ollama/mistral")
RETURN_SOURCES = os.getenv("LLM_RETURN_SOURCES", "true").lower() == "true"
CHAIN_TYPE = os.getenv("CHAIN_TYPE", "stuff")
# Get the base URL for the local LLM from environment variables
litellm.ollama_base_url = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")


class LiteLLM(LLM):
    """
    Custom LangChain LLM class to interface with LiteLLM.
    """
    @property
    def _llm_type(self) -> str:
        return "litellm"

    def _call(
        self,
        prompt: str,
        stop: Optional[List[str]] = None,
        **kwargs: Any,
    ) -> str:
        """
        The main call to LiteLLM completion.
        """
        messages = [{"content": prompt, "role": "user"}]
        
        try:
            response = litellm.completion(model=LLM_MODEL, messages=messages, **kwargs)
            return response.choices[0].message.content
        except Exception as e:
            print(f"Error calling LiteLLM: {e}")
            return f"Error: Could not get a response from the model. Details: {e}"

    @property
    def _identifying_params(self) -> Mapping[str, Any]:
        """Get the identifying parameters."""
        return {"model": LLM_MODEL}


def init_llm():
    """
    Initializes and returns the custom LiteLLM instance.
    """
    return LiteLLM()


def run_rag_chain(llm, retriever, prompt):
    """
    Runs the RetrievalQA chain with the initialized LLM.
    """
    print("🧠 Running LLM with embedded context via LiteLLM...")
    chain = RetrievalQA.from_chain_type(
        llm=llm,
        retriever=retriever,
        chain_type=CHAIN_TYPE,
        return_source_documents=RETURN_SOURCES,
    )
    return chain.invoke({"query": prompt})
