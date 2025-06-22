#!/usr/bin/env python3
"""MCP Tools for RAG-based Terraform Analysis"""

import os
import sys
import json
import asyncio
from pathlib import Path
from typing import Dict, List, Any, Optional
from datetime import datetime

# Add the backend directory to the path
ROOT_DIR = Path(__file__).resolve().parent.parent.parent
sys.path.append(str(ROOT_DIR))

from backend.mcp_server_legacy import Tool, ToolParameter
from backend.coldrag.rag_inspector import run_rag_pipeline
from backend.coldrag.utils.plan_parser import load_terraform_docs
from backend.coldrag.utils.reference_loader import load_reference_docs
from backend.coldrag.utils.output_validator import validate_and_write_output

class TerraformAnalyzerTool(Tool):
    """MCP Tool wrapper for the existing RAG inspector functionality"""
    
    def __init__(self):
        super().__init__(
            tool_id="terraform_analyzer",
            name="Terraform Configuration Analyzer",
            description="Analyze Terraform configurations for compliance violations using RAG",
            parameters=[
                ToolParameter("plan_json", "string", True, "Path to Terraform plan JSON file"),
                ToolParameter("output_path", "string", True, "Path to save analysis results"),
                ToolParameter("refdir", "string", False, "Optional directory of compliance references"),
                ToolParameter("user_message", "string", False, "User query for analysis")
            ],
            invoke_func=self._analyze_terraform
        )
    
    async def _analyze_terraform(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze Terraform configuration using RAG"""
        try:
            plan_json = params["plan_json"]
            output_path = params["output_path"]
            refdir = params.get("refdir")
            user_message = params.get("user_message", "Analyze compliance")
            
            # Ensure output directory exists
            output_dir = Path(output_path).parent
            output_dir.mkdir(parents=True, exist_ok=True)
            
            # Run the RAG pipeline
            result = await asyncio.to_thread(
                run_rag_pipeline,
                plan_path=Path(plan_json),
                output_path=Path(output_path),
                ref_docs_enabled=bool(refdir)
            )
            
            # Load the generated output for additional processing
            if Path(output_path).exists():
                with open(output_path, 'r') as f:
                    analysis_data = json.load(f)
            else:
                analysis_data = {"status": "analysis_complete", "result": result}
            
            return {
                "analysis_status": "completed",
                "output_file": output_path,
                "analysis_data": analysis_data,
                "user_query": user_message,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                "analysis_status": "error",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }

class ComplianceReporterTool(Tool):
    """Generate compliance reports and summaries"""
    
    def __init__(self):
        super().__init__(
            tool_id="compliance_reporter",
            name="Compliance Report Generator",
            description="Generate detailed compliance reports and summaries",
            parameters=[
                ToolParameter("analysis_file", "string", True, "Path to analysis results file"),
                ToolParameter("report_format", "string", False, "Report format (html, json, pdf)", default="html"),
                ToolParameter("include_recommendations", "boolean", False, "Include remediation recommendations", default=True)
            ],
            invoke_func=self._generate_compliance_report
        )
    
    async def _generate_compliance_report(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate compliance report from analysis results"""
        try:
            analysis_file = params["analysis_file"]
            report_format = params.get("report_format", "html")
            include_recommendations = params.get("include_recommendations", True)
            
            # Load analysis data
            if not Path(analysis_file).exists():
                return {
                    "status": "error",
                    "error": f"Analysis file not found: {analysis_file}"
                }
            
            with open(analysis_file, 'r') as f:
                analysis_data = json.load(f)
            
            # Generate report based on format
            if report_format == "html":
                report_content = self._generate_html_report(analysis_data, include_recommendations)
                report_file = analysis_file.replace('.json', '_report.html')
            elif report_format == "json":
                report_content = self._generate_json_report(analysis_data, include_recommendations)
                report_file = analysis_file.replace('.json', '_report.json')
            else:
                return {
                    "status": "error",
                    "error": f"Unsupported report format: {report_format}"
                }
            
            # Save report
            with open(report_file, 'w') as f:
                if report_format == "html":
                    f.write(report_content)
                else:
                    json.dump(report_content, f, indent=2)
            
            return {
                "status": "success",
                "report_file": report_file,
                "report_format": report_format,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                "status": "error",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
    
    def _generate_html_report(self, analysis_data: Dict[str, Any], include_recommendations: bool) -> str:
        """Generate HTML compliance report"""
        violations = analysis_data.get("compliance_violations", [])
        total_violations = len(violations)
        
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Compliance Analysis Report</title>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 20px; }}
                .header {{ background-color: #f0f0f0; padding: 20px; border-radius: 5px; }}
                .violation {{ margin: 10px 0; padding: 10px; border-left: 4px solid #ff4444; background-color: #fff5f5; }}
                .high {{ border-left-color: #ff0000; }}
                .medium {{ border-left-color: #ff8800; }}
                .low {{ border-left-color: #ffcc00; }}
                .summary {{ background-color: #e8f5e8; padding: 15px; border-radius: 5px; margin: 20px 0; }}
            </style>
        </head>
        <body>
            <div class="header">
                <h1>🔍 Compliance Analysis Report</h1>
                <p>Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
            </div>
            
            <div class="summary">
                <h2>📊 Summary</h2>
                <p>Total violations found: <strong>{total_violations}</strong></p>
                <p>Analysis status: <strong>{analysis_data.get('status', 'completed')}</strong></p>
            </div>
        """
        
        if violations:
            html_content += "<h2>🚨 Compliance Violations</h2>"
            for violation in violations:
                severity_class = violation.get("severity", "medium")
                html_content += f"""
                <div class="violation {severity_class}">
                    <h3>{violation.get('type', 'Unknown Violation')}</h3>
                    <p><strong>Severity:</strong> {violation.get('severity', 'medium').upper()}</p>
                    <p><strong>Description:</strong> {violation.get('description', 'No description')}</p>
                    <p><strong>Resource:</strong> {violation.get('resource', 'Unknown')}</p>
                </div>
                """
        
        if include_recommendations:
            html_content += """
            <h2>💡 Recommendations</h2>
            <ul>
                <li>Review all high-severity violations immediately</li>
                <li>Address medium-severity issues within 30 days</li>
                <li>Document low-severity findings for future reference</li>
                <li>Implement automated compliance checks in CI/CD pipeline</li>
            </ul>
            """
        
        html_content += """
        </body>
        </html>
        """
        
        return html_content
    
    def _generate_json_report(self, analysis_data: Dict[str, Any], include_recommendations: bool) -> Dict[str, Any]:
        """Generate JSON compliance report"""
        report = {
            "report_type": "compliance_analysis",
            "generated_at": datetime.now().isoformat(),
            "summary": {
                "total_violations": len(analysis_data.get("compliance_violations", [])),
                "analysis_status": analysis_data.get("status", "completed")
            },
            "violations": analysis_data.get("compliance_violations", [])
        }
        
        if include_recommendations:
            report["recommendations"] = [
                "Review all high-severity violations immediately",
                "Address medium-severity issues within 30 days",
                "Document low-severity findings for future reference",
                "Implement automated compliance checks in CI/CD pipeline"
            ]
        
        return report

class SecurityAuditorTool(Tool):
    """Specialized security analysis tool"""
    
    def __init__(self):
        super().__init__(
            tool_id="security_auditor",
            name="Security Auditor",
            description="Perform specialized security analysis on Terraform configurations",
            parameters=[
                ToolParameter("plan_json", "string", True, "Path to Terraform plan JSON file"),
                ToolParameter("security_framework", "string", False, "Security framework to check against", default="CIS"),
                ToolParameter("include_secrets_scan", "boolean", False, "Include secrets scanning", default=True)
            ],
            invoke_func=self._audit_security
        )
    
    async def _audit_security(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Perform security audit on Terraform configuration"""
        try:
            plan_json = params["plan_json"]
            security_framework = params.get("security_framework", "CIS")
            include_secrets_scan = params.get("include_secrets_scan", True)
            
            # Load Terraform plan
            docs = await asyncio.to_thread(load_terraform_docs, plan_json)
            
            # Perform security analysis
            security_findings = []
            
            # Check for common security issues
            for doc in docs:
                content = doc.page_content.lower()
                
                # Check for hardcoded secrets
                if include_secrets_scan:
                    if any(secret in content for secret in ["password", "secret", "key", "token"]):
                        security_findings.append({
                            "type": "Potential Hardcoded Secret",
                            "severity": "high",
                            "description": "Potential hardcoded secret found in configuration",
                            "resource": doc.metadata.get("source", "unknown")
                        })
                
                # Check for open security groups
                if "0.0.0.0/0" in content and "security_group" in content:
                    security_findings.append({
                        "type": "Open Security Group",
                        "severity": "high",
                        "description": "Security group allows access from anywhere (0.0.0.0/0)",
                        "resource": doc.metadata.get("source", "unknown")
                    })
                
                # Check for unencrypted resources
                if "encryption" not in content and any(resource in content for resource in ["rds", "s3", "ebs"]):
                    security_findings.append({
                        "type": "Unencrypted Resource",
                        "severity": "medium",
                        "description": "Resource may not be encrypted at rest",
                        "resource": doc.metadata.get("source", "unknown")
                    })
            
            return {
                "security_audit_status": "completed",
                "framework": security_framework,
                "total_findings": len(security_findings),
                "security_findings": security_findings,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                "security_audit_status": "error",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            } 