import json
import re
from pathlib import Path
from coldrag.scripts.core.schemas import ComplianceViolation  # if using Pydantic
from typing import Union

def clean_llm_response(raw):
    """Remove markdown formatting if response is a string."""
    if isinstance(raw, str):
        raw = re.sub(r"^```(?:json)?\s*", "", raw.strip(), flags=re.MULTILINE)
        raw = re.sub(r"\s*```$", "", raw, flags=re.MULTILINE)
        return raw
    return raw  # Already a dict or valid object

def validate_and_write_output(response: dict, plan_path: str, output_path: str):
    raw_output = response.get("result") or response  # Fallback

    raw_output_clean = clean_llm_response(raw_output)

    # Validate JSON structure
    parsed = None
    try:
        parsed = json.loads(raw_output_clean) if isinstance(raw_output_clean, str) else raw_output_clean
        # Optional: validate using Pydantic
        # validated = ComplianceViolation(**parsed)
        with open(output_path, "w") as f:
            json.dump(parsed, f, indent=2)
        print(f"✅ Parsed and saved structured output to: {output_path}")
    except Exception as e:
        print(f"❌ Failed to parse or validate JSON: {e}")
        fallback = Path(output_path).with_suffix(".raw.txt")
        with open(fallback, "w") as f:
            f.write(raw_output_clean if isinstance(raw_output_clean, str) else str(raw_output_clean))
        print(f"⚠️ Raw output still saved to: {fallback}")
