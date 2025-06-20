# coldrag/scripts/core/prompt_loader.py

import os
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
load_dotenv()
DEFAULT_PROMPTS_DIR = os.getenv("DEFAULT_PROMPTS_DIR", "prompts/shared")
DEFAULT_PROMPT_FILE = os.getenv("DEFAULT_PROMPT_FILE", "blanket_compliance_prompt.txt")

def load_prompt_template(prompt_file: str = None) -> str:
    """
    Load a prompt template file from the configured prompts directory.
    Falls back to the default prompt if none is provided.
    """
    filename = prompt_file or DEFAULT_PROMPT_FILE
    prompts_path = Path(DEFAULT_PROMPTS_DIR)

    prompt_path = prompts_path / filename
    if not prompt_path.exists():
        raise FileNotFoundError(f"Prompt template not found: {prompt_path}")
    
    with open(prompt_path, "r", encoding="utf-8") as file:
        return file.read().strip()
