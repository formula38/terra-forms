#!/usr/bin/env python3
"""Compliance Agent for MCP System"""

import asyncio
import json
from pathlib import Path
from typing import Dict, List, Any, Optional
from datetime import datetime

from backend.mcp_server import Agent

class ComplianceAgent(Agent):
    """Agent specialized in compliance analysis and reporting"""
    
    def __init__(self):
        super().__init__(
            agent_id="compliance_agent",
            name="Compliance Analysis Agent",
            system_prompt="""
            You are a compliance analysis agent specializing in infrastructure compliance.
            
            Your primary goals:
            1. Analyze Terraform configurations for compliance violations
            2. Generate detailed compliance reports
            3. Provide actionable remediation recommendations
            4. Maintain audit trails of all analyses
            5. Ensure adherence to CMMC, CIS, NIST, and other compliance frameworks
            
            Your responsibilities:
            - Perform comprehensive compliance analysis using RAG
            - Generate executive summaries and technical reports
            - Identify security and compliance gaps
            - Provide remediation guidance
            - Track compliance trends over time
            
            Available tools: terraform_analyzer, compliance_reporter, document_generator
            
            Always prioritize high-severity violations and provide clear, actionable recommendations.
            """,
            tools=["terraform_analyzer", "compliance_reporter", "document_generator"]
        )
    
    async def _execute_action_impl(self, action: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Implementation of compliance agent actions"""
        
        if action == "analyze_compliance":
            return await self._analyze_compliance(parameters)
        elif action == "generate_report":
            return await self._generate_report(parameters)
        elif action == "generate_executive_summary":
            return await self._generate_executive_summary(parameters)
        elif action == "get_compliance_status":
            return await self._get_compliance_status(parameters)
        else:
            raise ValueError(f"Unknown action: {action}")
    
    async def _analyze_compliance(self, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Perform comprehensive compliance analysis"""
        try:
            plan_json = parameters["plan_json"]
            user_message = parameters.get("user_message", "Analyze compliance")
            output_path = parameters.get("output_path", f"output/compliance_analysis_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json")
            
            # Step 1: Run Terraform analysis
            self.state.update_progress(0.2)
            terraform_result = await self._invoke_tool("terraform_analyzer", {
                "plan_json": plan_json,
                "output_path": output_path,
                "user_message": user_message
            })
            
            if terraform_result.get("status") == "error":
                return {
                    "status": "error",
                    "message": f"Terraform analysis failed: {terraform_result.get('error')}",
                    "timestamp": datetime.now().isoformat()
                }
            
            # Step 2: Generate compliance report
            self.state.update_progress(0.6)
            report_result = await self._invoke_tool("compliance_reporter", {
                "analysis_file": output_path,
                "report_format": "html",
                "include_recommendations": True
            })
            
            # Step 3: Generate executive summary
            self.state.update_progress(0.8)
            summary_result = await self._invoke_tool("document_generator", {
                "analysis_file": output_path,
                "document_type": "executive_summary",
                "output_format": "html"
            })
            
            # Store analysis in memory
            analysis_summary = {
                "plan_json": plan_json,
                "output_path": output_path,
                "user_message": user_message,
                "analysis_timestamp": datetime.now().isoformat(),
                "total_violations": self._count_violations(output_path),
                "report_file": report_result.get("result", {}).get("report_file"),
                "summary_file": summary_result.get("result", {}).get("document_file")
            }
            
            self.memory.store_long_term(f"analysis_{datetime.now().strftime('%Y%m%d_%H%M%S')}", analysis_summary)
            
            return {
                "status": "success",
                "message": "Compliance analysis completed successfully",
                "analysis_file": output_path,
                "report_file": report_result.get("result", {}).get("report_file"),
                "summary_file": summary_result.get("result", {}).get("document_file"),
                "total_violations": analysis_summary["total_violations"],
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                "status": "error",
                "message": f"Compliance analysis failed: {str(e)}",
                "timestamp": datetime.now().isoformat()
            }
    
    async def _generate_report(self, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Generate specific type of compliance report"""
        try:
            analysis_file = parameters["analysis_file"]
            report_type = parameters.get("report_type", "compliance_report")
            output_format = parameters.get("output_format", "html")
            
            result = await self._invoke_tool("document_generator", {
                "analysis_file": analysis_file,
                "document_type": report_type,
                "output_format": output_format,
                "include_charts": True
            })
            
            return {
                "status": "success",
                "message": f"{report_type} generated successfully",
                "report_file": result.get("result", {}).get("document_file"),
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                "status": "error",
                "message": f"Report generation failed: {str(e)}",
                "timestamp": datetime.now().isoformat()
            }
    
    async def _generate_executive_summary(self, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Generate executive summary from analysis results"""
        try:
            analysis_file = parameters["analysis_file"]
            
            result = await self._invoke_tool("document_generator", {
                "analysis_file": analysis_file,
                "document_type": "executive_summary",
                "output_format": "html",
                "include_charts": True
            })
            
            return {
                "status": "success",
                "message": "Executive summary generated successfully",
                "summary_file": result.get("result", {}).get("document_file"),
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                "status": "error",
                "message": f"Executive summary generation failed: {str(e)}",
                "timestamp": datetime.now().isoformat()
            }
    
    async def _get_compliance_status(self, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Get current compliance status and trends"""
        try:
            # Retrieve recent analyses from memory
            recent_analyses = []
            for key, value in self.memory.long_term.items():
                if key.startswith("analysis_"):
                    recent_analyses.append(value["value"])
            
            # Sort by timestamp
            recent_analyses.sort(key=lambda x: x.get("analysis_timestamp", ""), reverse=True)
            
            # Calculate trends
            total_analyses = len(recent_analyses)
            total_violations = sum(analysis.get("total_violations", 0) for analysis in recent_analyses)
            avg_violations = total_violations / total_analyses if total_analyses > 0 else 0
            
            # Get recent trend (last 5 analyses)
            recent_violations = [analysis.get("total_violations", 0) for analysis in recent_analyses[:5]]
            trend = "improving" if len(recent_violations) >= 2 and recent_violations[0] < recent_violations[-1] else "stable"
            
            return {
                "status": "success",
                "compliance_status": {
                    "total_analyses": total_analyses,
                    "total_violations": total_violations,
                    "average_violations": round(avg_violations, 2),
                    "trend": trend,
                    "last_analysis": recent_analyses[0] if recent_analyses else None,
                    "recent_analyses": recent_analyses[:5]
                },
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                "status": "error",
                "message": f"Failed to get compliance status: {str(e)}",
                "timestamp": datetime.now().isoformat()
            }
    
    async def _invoke_tool(self, tool_id: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Invoke a tool through the MCP host"""
        # This would be implemented to work with the MCP host
        # For now, we'll simulate tool invocation
        from backend.mcp_server import mcp_host
        
        tool = mcp_host.get_tool(tool_id)
        if tool:
            return await tool.invoke(parameters)
        else:
            return {
                "status": "error",
                "error": f"Tool {tool_id} not found"
            }
    
    def _count_violations(self, analysis_file: str) -> int:
        """Count violations in analysis file"""
        try:
            if Path(analysis_file).exists():
                with open(analysis_file, 'r') as f:
                    data = json.load(f)
                    violations = data.get("compliance_violations", [])
                    return len(violations)
            return 0
        except Exception:
            return 0 