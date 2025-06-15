from pydantic import BaseModel, Field
from typing import List

class ComplianceViolation(BaseModel):
    resource: str = Field(..., description="Terraform resource name")
    issue: str = Field(..., description="Compliance issue description")
    severity: str = Field(..., description="Severity: Low, Medium, High")
    remediation: str = Field(..., description="Remediation steps")

def validate_outputs(outputs: list) -> List[ComplianceViolation]:
    """Parse and validate output into Pydantic models."""
    return [ComplianceViolation(**item) for item in outputs]
