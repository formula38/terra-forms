import json
from pathlib import Path
from typing import List
from langchain.schema import Document


def load_json_file(path: str) -> dict:
    """Load a JSON file into a dictionary."""
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def extract_documents_from_plan(data: dict) -> List[Document]:
    """Extract Document objects from a Terraform plan JSON (resource_changes)."""
    docs = []
    changes = data.get("resource_changes", [])
    for change in changes:
        resource_type = change.get("type", "unknown")
        resource_name = change.get("address", "unknown")
        docs.append(Document(
            page_content=json.dumps(change, indent=2),
            metadata={
                "resource_type": resource_type,
                "resource_name": resource_name,
                "standard": resource_type.upper(),
                "source": resource_name.upper()
            }
        ))
    return docs


def extract_documents_from_state(data: dict) -> List[Document]:
    """Extract Document objects from a Terraform state JSON (root_module.resources)."""
    docs = []
    resources = data.get("values", {}).get("root_module", {}).get("resources", [])
    for res in resources:
        resource_type = res.get("type", "unknown")
        resource_name = res.get("name", "unknown")
        docs.append(Document(
            page_content=json.dumps(res, indent=2),
            metadata={
                "resource_type": resource_type,
                "resource_name": resource_name,
                "standard": resource_type.upper(),
                "source": resource_name.upper()
            }
        ))
    return docs


def load_terraform_docs(json_path: str) -> List[Document]:
    """
    Load Terraform resources from either plan or state JSON into Document format.
    """
    input_path = Path(json_path)
    if not input_path.exists() or input_path.stat().st_size == 0:
        raise ValueError(f"⚠️ Input file {input_path} is missing or empty.")

    data = load_json_file(str(input_path))

    # Prefer resource_changes (plan) if available, else fallback to state format
    if data.get("resource_changes"):
        print("📐 Parsing Terraform plan (resource_changes)...")
        return extract_documents_from_plan(data)
    elif data.get("values"):
        print("📐 Parsing Terraform state (values.root_module.resources)...")
        return extract_documents_from_state(data)
    else:
        raise ValueError(f"❌ Unsupported or unrecognized Terraform JSON format: {json_path}")
