from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
from fastapi.staticfiles import StaticFiles
import json
import os
from datetime import datetime


# ✅ Create app first
app = FastAPI()
# app.mount("/", StaticFiles(directory="frontend/bizops-dashboard/dist/bizops-dashboard", html=True), name="static")

# ✅ Register middleware AFTER app is defined
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Replace with specific domains in prod
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Example request schema
class RAGRequest(BaseModel):
    plan_json: str
    output_path: str
    refdir: Optional[str] = None
    user_message: Optional[str] = None

class ComplianceViolation(BaseModel):
    type: str
    description: str
    severity: str
    resource: Optional[str] = None

class RAGResponse(BaseModel):
    message: str
    plan_json: str
    output_path: str
    refdir: Optional[str] = None
    analysis: Optional[dict] = None
    compliance_violations: Optional[List[ComplianceViolation]] = None

@app.get("/")
def root():
    return {"message": "BizOpsAgent FastAPI is live 🎯"}

@app.post("/rag")
async def rag_handler(payload: RAGRequest):
    # Simulate RAG processing based on user message
    user_message = payload.user_message or "Analyze compliance"
    
    # Generate mock compliance violations for demonstration
    mock_violations = generate_mock_violations(user_message)
    
    # Create response based on user message
    response_message = generate_response_message(user_message, mock_violations)
    
    return RAGResponse(
        message=response_message,
        plan_json=payload.plan_json,
        output_path=payload.output_path,
        refdir=payload.refdir,
        analysis={
            "timestamp": datetime.now().isoformat(),
            "total_violations": len(mock_violations),
            "severity_breakdown": {
                "high": len([v for v in mock_violations if v.severity == "high"]),
                "medium": len([v for v in mock_violations if v.severity == "medium"]),
                "low": len([v for v in mock_violations if v.severity == "low"])
            }
        },
        compliance_violations=mock_violations
    )

def generate_mock_violations(user_message: str) -> List[ComplianceViolation]:
    """Generate mock compliance violations based on user message"""
    violations = []
    
    if "security" in user_message.lower():
        violations.extend([
            ComplianceViolation(
                type="Security Group Configuration",
                description="Security group allows unrestricted access on port 22",
                severity="high",
                resource="aws_security_group.web_sg"
            ),
            ComplianceViolation(
                type="Encryption at Rest",
                description="RDS instance is not encrypted",
                severity="medium",
                resource="aws_db_instance.main"
            )
        ])
    
    if "compliance" in user_message.lower():
        violations.extend([
            ComplianceViolation(
                type="CMMC Compliance",
                description="Missing logging configuration for compliance requirements",
                severity="medium",
                resource="aws_cloudtrail.main"
            ),
            ComplianceViolation(
                type="Data Classification",
                description="S3 bucket lacks proper data classification tags",
                severity="low",
                resource="aws_s3_bucket.data"
            )
        ])
    
    if "report" in user_message.lower():
        violations.extend([
            ComplianceViolation(
                type="Audit Trail",
                description="Insufficient audit logging for compliance reporting",
                severity="medium",
                resource="aws_cloudwatch_log_group.audit"
            )
        ])
    
    # Default violations if no specific keywords
    if not violations:
        violations = [
            ComplianceViolation(
                type="General Compliance",
                description="Terraform configuration needs compliance review",
                severity="medium",
                resource="terraform_configuration"
            )
        ]
    
    return violations

def generate_response_message(user_message: str, violations: List[ComplianceViolation]) -> str:
    """Generate a human-like response based on the analysis"""
    total_violations = len(violations)
    high_severity = len([v for v in violations if v.severity == "high"])
    
    if total_violations == 0:
        return "✅ Great news! Your Terraform configuration appears to be compliant with standard security practices. No violations were detected."
    
    if high_severity > 0:
        return f"⚠️ I found {total_violations} compliance violations in your configuration, including {high_severity} high-severity issues that require immediate attention. Please review the details below."
    
    return f"📋 I've analyzed your Terraform configuration and found {total_violations} compliance violations. While none are critical, I recommend addressing these issues to improve your security posture."

