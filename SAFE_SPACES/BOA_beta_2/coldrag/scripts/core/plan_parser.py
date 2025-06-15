import json
from pathlib import Path

def load_json_file(path: str) -> dict:
    """Load a JSON file."""
    with open(path, 'r') as file:
        return json.load(file)

def extract_terraform_resources(plan_json: dict) -> list:
    """Extract resource blocks from a Terraform plan JSON."""
    return plan_json.get("resource_changes", [])
