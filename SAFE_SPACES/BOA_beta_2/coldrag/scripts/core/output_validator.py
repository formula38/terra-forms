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


def clean_llm_response(raw_output: str) -> str:
    """Extract and clean JSON block from LLM response."""
    if isinstance(raw_output, dict):
        return raw_output  # already cleaned

    raw_output = raw_output.strip()
    raw_output = re.sub(r"^```(?:json)?\s*", "", raw_output, flags=re.MULTILINE)
    raw_output = re.sub(r"\s*```$", "", raw_output, flags=re.MULTILINE)

    # Extract only the first valid JSON object
    match = re.search(r"{.*}", raw_output, re.DOTALL)
    if match:
        return match.group(0).strip()
    return raw_output


def validate_and_write_output(
    response: dict,
    plan_input_path: str,
    output_json_path: str,
) -> None:
    """Validate and write LLM output to structured and raw files."""
    output_path = Path(output_json_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    raw_path = output_path.with_suffix(".raw.txt")

    # Extract only the 'result' string
    raw_output = response.get("result", "")
    if not isinstance(raw_output, str):
        raise TypeError("Expected LLM output to contain a 'result' string.")

    raw_output_clean = clean_llm_response(raw_output)

    # Save raw output
    with open(raw_path, "w") as f:
        f.write(raw_output_clean)

    # Validate input file
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

