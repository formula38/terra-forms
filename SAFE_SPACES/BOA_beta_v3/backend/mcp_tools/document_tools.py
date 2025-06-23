#!/usr/bin/env python3
"""MCP Tools for Document Generation"""

import json
import asyncio
from pathlib import Path
from typing import Dict, List, Any, Optional
from datetime import datetime

from mcp_server_legacy import Tool, ToolParameter

class DocumentGeneratorTool(Tool):
    """Generate various types of documentation from analysis results"""
    
    def __init__(self):
        super().__init__(
            tool_id="document_generator",
            name="Document Generator",
            description="Generate various types of documentation from analysis results",
            parameters=[
                {"name": "analysis_file", "type": "string", "required": True, "description": "Path to analysis results file"},
                {"name": "document_type", "type": "string", "required": True, "description": "Type of document to generate (executive_summary, technical_report, compliance_report)"},
                {"name": "output_format", "type": "string", "required": False, "description": "Output format (html, markdown, json)", "default": "html"},
                {"name": "include_charts", "type": "boolean", "required": False, "description": "Include charts and visualizations", "default": True}
            ],
            invoke_func=self._generate_document
        )
    
    async def _generate_document(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate document based on analysis results"""
        try:
            analysis_file = params["analysis_file"]
            document_type = params["document_type"]
            output_format = params.get("output_format", "html")
            include_charts = params.get("include_charts", True)
            
            # Load analysis data
            if not Path(analysis_file).exists():
                return {
                    "status": "error",
                    "error": f"Analysis file not found: {analysis_file}"
                }
            
            with open(analysis_file, 'r') as f:
                analysis_data = json.load(f)
            
            # Generate document based on type
            if document_type == "executive_summary":
                content = self._generate_executive_summary(analysis_data, include_charts)
            elif document_type == "technical_report":
                content = self._generate_technical_report(analysis_data, include_charts)
            elif document_type == "compliance_report":
                content = self._generate_compliance_report(analysis_data, include_charts)
            else:
                return {
                    "status": "error",
                    "error": f"Unsupported document type: {document_type}"
                }
            
            # Save document
            output_file = analysis_file.replace('.json', f'_{document_type}.{output_format}')
            
            with open(output_file, 'w') as f:
                if output_format == "json":
                    json.dump(content, f, indent=2)
                else:
                    f.write(content)
            
            return {
                "status": "success",
                "document_file": output_file,
                "document_type": document_type,
                "output_format": output_format,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                "status": "error",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
    
    def _generate_executive_summary(self, analysis_data: Dict[str, Any], include_charts: bool) -> str:
        """Generate executive summary document"""
        violations = analysis_data.get("compliance_violations", [])
        total_violations = len(violations)
        high_severity = len([v for v in violations if v.get("severity") == "high"])
        medium_severity = len([v for v in violations if v.get("severity") == "medium"])
        low_severity = len([v for v in violations if v.get("severity") == "low"])
        
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Executive Summary - Infrastructure Analysis</title>
            <style>
                body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }}
                .container {{ max-width: 1200px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
                .header {{ text-align: center; border-bottom: 3px solid #007acc; padding-bottom: 20px; margin-bottom: 30px; }}
                .summary-box {{ background-color: #f8f9fa; border-radius: 8px; padding: 20px; margin: 20px 0; }}
                .metric {{ display: inline-block; margin: 10px 20px; text-align: center; }}
                .metric-value {{ font-size: 2em; font-weight: bold; color: #007acc; }}
                .metric-label {{ color: #666; font-size: 0.9em; }}
                .high {{ color: #dc3545; }}
                .medium {{ color: #ffc107; }}
                .low {{ color: #28a745; }}
                .recommendations {{ background-color: #e7f3ff; border-left: 4px solid #007acc; padding: 20px; margin: 20px 0; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>📊 Executive Summary</h1>
                    <h2>Infrastructure Compliance Analysis</h2>
                    <p>Generated on: {datetime.now().strftime('%B %d, %Y at %I:%M %p')}</p>
                </div>
                
                <div class="summary-box">
                    <h3>🔍 Key Findings</h3>
                    <div class="metric">
                        <div class="metric-value">{total_violations}</div>
                        <div class="metric-label">Total Violations</div>
                    </div>
                    <div class="metric">
                        <div class="metric-value high">{high_severity}</div>
                        <div class="metric-label">High Severity</div>
                    </div>
                    <div class="metric">
                        <div class="metric-value medium">{medium_severity}</div>
                        <div class="metric-label">Medium Severity</div>
                    </div>
                    <div class="metric">
                        <div class="metric-value low">{low_severity}</div>
                        <div class="metric-label">Low Severity</div>
                    </div>
                </div>
                
                <div class="recommendations">
                    <h3>💡 Executive Recommendations</h3>
                    <ul>
                        <li><strong>Immediate Action Required:</strong> Address {high_severity} high-severity violations within 48 hours</li>
                        <li><strong>Short-term Goals:</strong> Resolve {medium_severity} medium-severity issues within 30 days</li>
                        <li><strong>Long-term Strategy:</strong> Implement automated compliance monitoring and reporting</li>
                        <li><strong>Risk Mitigation:</strong> Establish regular security and compliance reviews</li>
                    </ul>
                </div>
                
                <div class="summary-box">
                    <h3>📈 Business Impact</h3>
                    <p>This analysis identified potential compliance risks that could impact:</p>
                    <ul>
                        <li>Regulatory compliance and audit readiness</li>
                        <li>Data security and customer trust</li>
                        <li>Operational continuity and risk management</li>
                        <li>Cost optimization and resource efficiency</li>
                    </ul>
                </div>
            </div>
        </body>
        </html>
        """
        
        return html_content
    
    def _generate_technical_report(self, analysis_data: Dict[str, Any], include_charts: bool) -> str:
        """Generate technical report document"""
        violations = analysis_data.get("compliance_violations", [])
        
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Technical Report - Infrastructure Analysis</title>
            <style>
                body {{ font-family: 'Courier New', monospace; margin: 0; padding: 20px; background-color: #1e1e1e; color: #d4d4d4; }}
                .container {{ max-width: 1200px; margin: 0 auto; background-color: #2d2d30; padding: 30px; border-radius: 5px; }}
                .header {{ border-bottom: 2px solid #007acc; padding-bottom: 20px; margin-bottom: 30px; }}
                .section {{ margin: 20px 0; padding: 15px; background-color: #3c3c3c; border-radius: 5px; }}
                .violation {{ margin: 10px 0; padding: 10px; border-left: 4px solid #ff4444; background-color: #2d2d30; }}
                .high {{ border-left-color: #ff0000; }}
                .medium {{ border-left-color: #ff8800; }}
                .low {{ border-left-color: #ffcc00; }}
                .code-block {{ background-color: #1e1e1e; padding: 10px; border-radius: 3px; font-family: 'Consolas', monospace; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🔧 Technical Report</h1>
                    <h2>Infrastructure Compliance Analysis</h2>
                    <p>Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}</p>
                </div>
                
                <div class="section">
                    <h3>📋 Analysis Overview</h3>
                    <p>Total violations found: <strong>{len(violations)}</strong></p>
                    <p>Analysis scope: Terraform configuration files</p>
                    <p>Compliance framework: CMMC, CIS, NIST</p>
                </div>
                
                <div class="section">
                    <h3>🚨 Detailed Violations</h3>
        """
        
        for i, violation in enumerate(violations, 1):
            severity_class = violation.get("severity", "medium")
            html_content += f"""
                    <div class="violation {severity_class}">
                        <h4>Violation #{i}: {violation.get('type', 'Unknown')}</h4>
                        <p><strong>Severity:</strong> {violation.get('severity', 'medium').upper()}</p>
                        <p><strong>Description:</strong> {violation.get('description', 'No description')}</p>
                        <p><strong>Resource:</strong> {violation.get('resource', 'Unknown')}</p>
                        <div class="code-block">
                            <strong>Remediation:</strong><br>
                            {self._get_remediation_steps(violation)}
                        </div>
                    </div>
            """
        
        html_content += """
                </div>
                
                <div class="section">
                    <h3>🔍 Technical Details</h3>
                    <p>This analysis was performed using:</p>
                    <ul>
                        <li>RAG (Retrieval-Augmented Generation) for context-aware analysis</li>
                        <li>LangChain for document processing and LLM integration</li>
                        <li>Custom compliance rule engine</li>
                        <li>Vector embeddings for semantic search</li>
                    </ul>
                </div>
            </div>
        </body>
        </html>
        """
        
        return html_content
    
    def _generate_compliance_report(self, analysis_data: Dict[str, Any], include_charts: bool) -> str:
        """Generate compliance-specific report"""
        violations = analysis_data.get("compliance_violations", [])
        
        # Group violations by compliance framework
        framework_violations = {
            "CMMC": [],
            "CIS": [],
            "NIST": [],
            "Other": []
        }
        
        for violation in violations:
            violation_type = violation.get("type", "").lower()
            if "cmmc" in violation_type:
                framework_violations["CMMC"].append(violation)
            elif "cis" in violation_type:
                framework_violations["CIS"].append(violation)
            elif "nist" in violation_type:
                framework_violations["NIST"].append(violation)
            else:
                framework_violations["Other"].append(violation)
        
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Compliance Report - Infrastructure Analysis</title>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f0f0f0; }}
                .container {{ max-width: 1200px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
                .header {{ background-color: #2c3e50; color: white; padding: 20px; border-radius: 5px; text-align: center; }}
                .framework-section {{ margin: 20px 0; padding: 20px; border: 1px solid #ddd; border-radius: 5px; }}
                .framework-title {{ background-color: #34495e; color: white; padding: 10px; border-radius: 3px; }}
                .violation {{ margin: 10px 0; padding: 10px; border-left: 4px solid #e74c3c; background-color: #fdf2f2; }}
                .compliance-status {{ display: inline-block; padding: 5px 10px; border-radius: 3px; color: white; font-weight: bold; }}
                .compliant {{ background-color: #27ae60; }}
                .non-compliant {{ background-color: #e74c3c; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>📋 Compliance Report</h1>
                    <h2>Infrastructure Compliance Analysis</h2>
                    <p>Generated: {datetime.now().strftime('%B %d, %Y')}</p>
                </div>
        """
        
        for framework, violations_list in framework_violations.items():
            if violations_list:
                status_class = "non-compliant" if violations_list else "compliant"
                status_text = "Non-Compliant" if violations_list else "Compliant"
                
                html_content += f"""
                <div class="framework-section">
                    <div class="framework-title">
                        <h3>{framework} Framework</h3>
                        <span class="compliance-status {status_class}">{status_text}</span>
                    </div>
                    <p>Violations found: {len(violations_list)}</p>
                """
                
                for violation in violations_list:
                    html_content += f"""
                    <div class="violation">
                        <h4>{violation.get('type', 'Unknown Violation')}</h4>
                        <p><strong>Severity:</strong> {violation.get('severity', 'medium').upper()}</p>
                        <p><strong>Description:</strong> {violation.get('description', 'No description')}</p>
                        <p><strong>Resource:</strong> {violation.get('resource', 'Unknown')}</p>
                    </div>
                    """
                
                html_content += "</div>"
        
        html_content += """
            </div>
        </body>
        </html>
        """
        
        return html_content
    
    def _get_remediation_steps(self, violation: Dict[str, Any]) -> str:
        """Get remediation steps for a violation"""
        violation_type = violation.get("type", "").lower()
        
        remediation_steps = {
            "security group": "1. Review security group rules\n2. Remove unnecessary open ports\n3. Implement least privilege access",
            "encryption": "1. Enable encryption at rest\n2. Configure encryption in transit\n3. Use KMS for key management",
            "logging": "1. Enable CloudTrail logging\n2. Configure CloudWatch logs\n3. Set up log retention policies",
            "default": "1. Review the specific resource configuration\n2. Apply security best practices\n3. Test changes in non-production environment"
        }
        
        for key, steps in remediation_steps.items():
            if key in violation_type:
                return steps
        
        return remediation_steps["default"] 