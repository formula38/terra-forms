#!/usr/bin/env python3
"""Security Agent for MCP System"""

import asyncio
import json
from pathlib import Path
from typing import Dict, List, Any, Optional
from datetime import datetime

from mcp_server_legacy import Agent

class SecurityAgent(Agent):
    """Agent specialized in security analysis and auditing"""
    
    def __init__(self):
        super().__init__(
            agent_id="security_agent",
            name="Security Analysis Agent",
            system_prompt="""
            You are a security analysis agent specializing in infrastructure security.
            
            Your primary goals:
            1. Perform comprehensive security audits of Terraform configurations
            2. Identify security vulnerabilities and misconfigurations
            3. Analyze security posture against industry standards
            4. Provide security remediation recommendations
            5. Monitor security trends and patterns
            
            Your responsibilities:
            - Conduct security-focused analysis using specialized tools
            - Identify hardcoded secrets, open security groups, and encryption issues
            - Analyze against CIS, NIST, and other security frameworks
            - Provide detailed security reports with risk assessments
            - Track security findings and remediation progress
            
            Available tools: security_auditor, terraform_analyzer, document_generator
            
            Always prioritize high-risk security findings and provide clear remediation steps.
            """,
            tools=["security_auditor", "terraform_analyzer", "document_generator"]
        )
    
    async def _execute_action_impl(self, action: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Implementation of security agent actions"""
        
        if action == "audit_security":
            return await self._audit_security(parameters)
        elif action == "analyze_secrets":
            return await self._analyze_secrets(parameters)
        elif action == "check_encryption":
            return await self._check_encryption(parameters)
        elif action == "generate_security_report":
            return await self._generate_security_report(parameters)
        elif action == "get_security_status":
            return await self._get_security_status(parameters)
        else:
            raise ValueError(f"Unknown action: {action}")
    
    async def _audit_security(self, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Perform comprehensive security audit"""
        try:
            plan_json = parameters["plan_json"]
            security_framework = parameters.get("security_framework", "CIS")
            include_secrets_scan = parameters.get("include_secrets_scan", True)
            output_path = parameters.get("output_path", f"output/security_audit_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json")
            
            # Step 1: Run security audit
            self.state.update_progress(0.3)
            security_result = await self._invoke_tool("security_auditor", {
                "plan_json": plan_json,
                "security_framework": security_framework,
                "include_secrets_scan": include_secrets_scan
            })
            
            if security_result.get("status") == "error":
                return {
                    "status": "error",
                    "message": f"Security audit failed: {security_result.get('error')}",
                    "timestamp": datetime.now().isoformat()
                }
            
            # Step 2: Run additional Terraform analysis for context
            self.state.update_progress(0.6)
            terraform_result = await self._invoke_tool("terraform_analyzer", {
                "plan_json": plan_json,
                "output_path": output_path,
                "user_message": f"Security analysis focusing on {security_framework} framework"
            })
            
            # Step 3: Generate security report
            self.state.update_progress(0.8)
            report_result = await self._invoke_tool("document_generator", {
                "analysis_file": output_path,
                "document_type": "technical_report",
                "output_format": "html"
            })
            
            # Combine results
            combined_results = {
                "security_audit": security_result.get("result", {}),
                "terraform_analysis": terraform_result.get("result", {}),
                "report_file": report_result.get("result", {}).get("document_file")
            }
            
            # Store in memory
            audit_summary = {
                "plan_json": plan_json,
                "security_framework": security_framework,
                "audit_timestamp": datetime.now().isoformat(),
                "total_security_findings": security_result.get("result", {}).get("total_findings", 0),
                "high_risk_findings": len([f for f in security_result.get("result", {}).get("security_findings", []) 
                                         if f.get("severity") == "high"]),
                "report_file": report_result.get("result", {}).get("document_file")
            }
            
            self.memory.store_long_term(f"security_audit_{datetime.now().strftime('%Y%m%d_%H%M%S')}", audit_summary)
            
            return {
                "status": "success",
                "message": "Security audit completed successfully",
                "security_findings": security_result.get("result", {}).get("security_findings", []),
                "total_findings": security_result.get("result", {}).get("total_findings", 0),
                "high_risk_count": audit_summary["high_risk_findings"],
                "report_file": report_result.get("result", {}).get("document_file"),
                "framework": security_framework,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                "status": "error",
                "message": f"Security audit failed: {str(e)}",
                "timestamp": datetime.now().isoformat()
            }
    
    async def _analyze_secrets(self, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze for hardcoded secrets and sensitive information"""
        try:
            plan_json = parameters["plan_json"]
            
            # Run security audit with focus on secrets
            result = await self._invoke_tool("security_auditor", {
                "plan_json": plan_json,
                "include_secrets_scan": True
            })
            
            if result.get("status") == "error":
                return {
                    "status": "error",
                    "message": f"Secrets analysis failed: {result.get('error')}",
                    "timestamp": datetime.now().isoformat()
                }
            
            # Filter for secrets-related findings
            security_findings = result.get("result", {}).get("security_findings", [])
            secrets_findings = [f for f in security_findings if "secret" in f.get("type", "").lower()]
            
            return {
                "status": "success",
                "message": "Secrets analysis completed",
                "secrets_findings": secrets_findings,
                "total_secrets": len(secrets_findings),
                "high_risk_secrets": len([f for f in secrets_findings if f.get("severity") == "high"]),
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                "status": "error",
                "message": f"Secrets analysis failed: {str(e)}",
                "timestamp": datetime.now().isoformat()
            }
    
    async def _check_encryption(self, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Check encryption configuration and compliance"""
        try:
            plan_json = parameters["plan_json"]
            
            # Run security audit with focus on encryption
            result = await self._invoke_tool("security_auditor", {
                "plan_json": plan_json,
                "include_secrets_scan": False
            })
            
            if result.get("status") == "error":
                return {
                    "status": "error",
                    "message": f"Encryption check failed: {result.get('error')}",
                    "timestamp": datetime.now().isoformat()
                }
            
            # Filter for encryption-related findings
            security_findings = result.get("result", {}).get("security_findings", [])
            encryption_findings = [f for f in security_findings if "encryption" in f.get("type", "").lower()]
            
            # Analyze encryption status
            encryption_status = {
                "total_resources_checked": len(security_findings),
                "encryption_issues": len(encryption_findings),
                "encryption_compliance": "compliant" if len(encryption_findings) == 0 else "non-compliant",
                "findings": encryption_findings
            }
            
            return {
                "status": "success",
                "message": "Encryption check completed",
                "encryption_status": encryption_status,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                "status": "error",
                "message": f"Encryption check failed: {str(e)}",
                "timestamp": datetime.now().isoformat()
            }
    
    async def _generate_security_report(self, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Generate comprehensive security report"""
        try:
            analysis_file = parameters["analysis_file"]
            
            result = await self._invoke_tool("document_generator", {
                "analysis_file": analysis_file,
                "document_type": "technical_report",
                "output_format": "html",
                "include_charts": True
            })
            
            return {
                "status": "success",
                "message": "Security report generated successfully",
                "report_file": result.get("result", {}).get("document_file"),
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                "status": "error",
                "message": f"Security report generation failed: {str(e)}",
                "timestamp": datetime.now().isoformat()
            }
    
    async def _get_security_status(self, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Get current security status and trends"""
        try:
            # Retrieve recent security audits from memory
            recent_audits = []
            for key, value in self.memory.long_term.items():
                if key.startswith("security_audit_"):
                    recent_audits.append(value["value"])
            
            # Sort by timestamp
            recent_audits.sort(key=lambda x: x.get("audit_timestamp", ""), reverse=True)
            
            # Calculate security metrics
            total_audits = len(recent_audits)
            total_findings = sum(audit.get("total_security_findings", 0) for audit in recent_audits)
            total_high_risk = sum(audit.get("high_risk_findings", 0) for audit in recent_audits)
            
            # Calculate trends
            avg_findings = total_findings / total_audits if total_audits > 0 else 0
            avg_high_risk = total_high_risk / total_audits if total_audits > 0 else 0
            
            # Get recent trend (last 5 audits)
            recent_findings = [audit.get("total_security_findings", 0) for audit in recent_audits[:5]]
            trend = "improving" if len(recent_findings) >= 2 and recent_findings[0] < recent_findings[-1] else "stable"
            
            return {
                "status": "success",
                "security_status": {
                    "total_audits": total_audits,
                    "total_findings": total_findings,
                    "total_high_risk_findings": total_high_risk,
                    "average_findings": round(avg_findings, 2),
                    "average_high_risk": round(avg_high_risk, 2),
                    "trend": trend,
                    "last_audit": recent_audits[0] if recent_audits else None,
                    "recent_audits": recent_audits[:5]
                },
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                "status": "error",
                "message": f"Failed to get security status: {str(e)}",
                "timestamp": datetime.now().isoformat()
            }
    
    async def _invoke_tool(self, tool_id: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Invoke a tool and return the result"""
        from mcp_server_legacy import mcp_host
        tool = mcp_host.get_tool(tool_id)
        if not tool:
            return {
                "status": "error",
                "error": f"Tool '{tool_id}' not found",
                "timestamp": datetime.now().isoformat()
            }
        
        # Execute the tool's action
        return await tool.invoke(parameters) 