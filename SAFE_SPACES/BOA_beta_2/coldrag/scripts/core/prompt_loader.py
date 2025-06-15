from pathlib import Path

def load_prompt(path: str) -> str:
    """Load a prompt template from a file."""
    with open(path, 'r') as file:
        return file.read()
