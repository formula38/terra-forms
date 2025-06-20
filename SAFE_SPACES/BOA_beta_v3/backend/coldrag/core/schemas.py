from enum import Enum
from typing import List, Literal
from pydantic import BaseModel, Field


class ComplianceStandard(str, Enum):
    HIPAA = "HIPAA"
    PCI_DSS = "PCI-DSS"
    FedRAMP = "FedRAMP"
    CMMC = "CMMC"
    GDPR = "GDPR"
    GLBA = "GLBA"
    ISO_27001 = "ISO 27001"
    NIST = "NIST"
    SOC_2 = "SOC 2"
    SOX = "SOX"
    CIS = "CIS"
    CIS_AWS = "CIS AWS"
    CIS_AZURE = "CIS Azure"
    CIS_GCP = "CIS GCP"


class SeverityLevel(str, Enum):
    LOW = "Low"
    MEDIUM = "Medium"
    HIGH = "High"


class ComplianceViolation(BaseModel):
    resource_type: str = Field(..., description="Type of the Terraform resource")
    resource_name: str = Field(..., description="Name/address of the Terraform resource")
    compliance_concern: str = Field(..., description="Description of the compliance issue")
    standards: List[Literal[
        "HIPAA", "PCI-DSS", "FedRAMP", "CMMC", "GDPR",
        "GLBA", "ISO 27001", "NIST", "SOC 2", "SOX",
        "CIS", "CIS AWS", "CIS Azure", "CIS GCP"
    ]] = Field(..., description="List of impacted standards")
    severity: str = Field(..., description="Low / Medium / High")
    remediation: str = Field(..., description="Recommended fix or action")
