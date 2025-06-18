import json
import re
from pathlib import Path
from typing import List, Dict, Any
from pydantic import BaseModel, Field, ValidationError


class ComplianceViolation(BaseModel):
    resource_type: str
    resource_name: str
    compliance_concern: str
    standards: List[str]
    severity: str
    remediation: str


def clean_llm_response(raw: str) -> str:
    """Remove markdown or code block formatting from LLM JSON output."""
    raw = re.sub(r"^```(?:json)?\s*", "", raw, flags=re.MULTILINE)
    raw = re.sub(r"\s*```$", "", raw, flags=re.MULTILINE)
    return raw.strip()


def validate_and_write_output(
    raw_output: str,
    plan_input_path: str,
    output_json_path: str,
) -> None:
    """Validate and write LLM output to structured and raw files."""
    raw_output_clean = clean_llm_response(raw_output)
    output_path = Path(output_json_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    raw_path = output_path.with_suffix(".raw.txt")

    # Always save raw output for inspection
    with open(raw_path, "w") as f:
        f.write(raw_output_clean)

    # Ensure plan input is valid before continuing
    input_path = Path(plan_input_path)
    if not input_path.exists() or input_path.stat().st_size == 0:
        raise ValueError(f"Input file {input_path} is missing or empty.")

    try:
        parsed = json.loads(raw_output_clean)
        if not isinstance(parsed, dict):
            raise ValueError("Expected top-level JSON object.")

        violations_raw = parsed.get("violations", [])
        recommendations = parsed.get("recommendations", [])

        violations = [
            ComplianceViolation(**v)
            for v in violations_raw
            if v.get("resource_name")
        ]

        report = {
            "violations": [v.model_dump() for v in violations],
            "recommendations": recommendations
        }

        with open(output_path, "w") as f:
            json.dump(report, f, indent=2)
        print(f"✅ Compliance check complete. Results saved to: {output_path}")

    except (json.JSONDecodeError, ValidationError, ValueError) as e:
        print(f"❌ Failed to parse or validate JSON: {e}")
        print(f"⚠️ Raw output still saved to: {raw_path}")
