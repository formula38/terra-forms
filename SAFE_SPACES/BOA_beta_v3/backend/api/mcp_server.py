#!/usr/bin/env python3
"""MCP-Enabled FastAPI Server"""

import os
import sys
import json
import asyncio
from pathlib import Path
from typing import Dict, List, Any, Optional
from datetime import datetime

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

# Correct the system path for the Docker container
# The Dockerfile copies the 'backend' directory contents to '/app'
ROOT_DIR = Path(__file__).resolve().parent.parent
sys.path.append(str(ROOT_DIR))

from mcp_server_legacy import mcp_host
from mcp_protocol import MCPRequest, MCPResponse, mcp_protocol
from mcp_tools import TerraformAnalyzerTool, ComplianceReporterTool, SecurityAuditorTool, CostAnalyzerTool, DocumentGeneratorTool
from mcp_agents import ComplianceAgent, SecurityAgent, CostAgent

# Create FastAPI app
app = FastAPI(
    title="BizOps MCP Server",
    description="Multi-Agent MCP Server for Infrastructure Analysis",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Replace with specific domains in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize MCP System
def initialize_mcp_system():
    """Initialize the MCP system with agents and tools"""
    print("🚀 Initializing MCP System...")
    
    # Register tools
    print("📦 Registering tools...")
    mcp_host.register_tool(TerraformAnalyzerTool())
    mcp_host.register_tool(ComplianceReporterTool())
    mcp_host.register_tool(SecurityAuditorTool())
    mcp_host.register_tool(CostAnalyzerTool())
    mcp_host.register_tool(DocumentGeneratorTool())
    
    # Register agents
    print("🤖 Registering agents...")
    mcp_host.register_agent(ComplianceAgent())
    mcp_host.register_agent(SecurityAgent())
    mcp_host.register_agent(CostAgent())
    
    print("✅ MCP System initialized successfully!")

# Initialize on startup
@app.on_event("startup")
async def startup_event():
    """Initialize MCP system on startup"""
    initialize_mcp_system()

# Pydantic models for API requests
class RAGRequest(BaseModel):
    """Legacy RAG request for backward compatibility"""
    plan_json: str
    output_path: str
    refdir: Optional[str] = None
    user_message: Optional[str] = None

class ComplianceViolation(BaseModel):
    """Compliance violation model"""
    type: str
    description: str
    severity: str
    resource: Optional[str] = None

class RAGResponse(BaseModel):
    """Legacy RAG response for backward compatibility"""
    message: str
    plan_json: str
    output_path: str
    refdir: Optional[str] = None
    analysis: Optional[dict] = None
    compliance_violations: Optional[List[ComplianceViolation]] = None

# API Endpoints

@app.get("/")
def root():
    """Root endpoint"""
    return {
        "message": "BizOps MCP Server is running! 🎯",
        "version": "1.0.0",
        "status": "active",
        "timestamp": datetime.now().isoformat()
    }

@app.get("/health")
def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "agents": len(mcp_host.agents),
        "tools": len(mcp_host.tools),
        "active_sessions": len(mcp_protocol.active_sessions),
        "timestamp": datetime.now().isoformat()
    }

@app.get("/system/status")
def get_system_status():
    """Get overall system status"""
    return mcp_host.get_system_status()

@app.get("/agents")
def get_agents():
    """Get list of available agents"""
    agents = []
    for agent_id, agent in mcp_host.agents.items():
        agents.append({
            "agent_id": agent_id,
            "name": agent.name,
            "status": agent.get_status(),
            "available_actions": [
                "analyze_compliance",
                "generate_report", 
                "get_compliance_status"
            ] if agent_id == "compliance_agent" else [
                "audit_security",
                "analyze_secrets",
                "check_encryption",
                "get_security_status"
            ] if agent_id == "security_agent" else [
                "analyze_costs",
                "optimize_costs", 
                "get_cost_status"
            ] if agent_id == "cost_agent" else []
        })
    return {"agents": agents}

@app.get("/tools")
def get_tools():
    """Get list of available tools"""
    tools = []
    for tool_id, tool in mcp_host.tools.items():
        tools.append({
            "tool_id": tool_id,
            "name": tool.name,
            "description": tool.description,
            "parameters": [
                {
                    "name": param.name,
                    "type": param.type,
                    "required": param.required,
                    "description": param.description
                }
                for param in tool.parameters
            ]
        })
    return {"tools": tools}

@app.post("/mcp/request")
async def mcp_request(request: MCPRequest) -> MCPResponse:
    """Handle MCP requests"""
    return await mcp_protocol.handle_request(request)

@app.get("/sessions")
def get_sessions():
    """Get all active sessions"""
    return mcp_protocol.get_all_sessions()

@app.get("/sessions/{session_id}")
def get_session(session_id: str):
    """Get specific session information"""
    session = mcp_protocol.get_session_info(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    return session

@app.delete("/sessions/{session_id}")
def cleanup_session(session_id: str):
    """Clean up a session"""
    success = mcp_protocol.cleanup_session(session_id)
    if not success:
        raise HTTPException(status_code=404, detail="Session not found")
    return {"message": f"Session {session_id} cleaned up successfully"}

# WebSocket endpoint for real-time communication
@app.websocket("/mcp/ws/{session_id}")
async def websocket_endpoint(websocket: WebSocket, session_id: str):
    """WebSocket endpoint for real-time MCP communication"""
    await websocket.accept()
    
    try:
        while True:
            # Receive message from client
            data = await websocket.receive_json()
            
            # Parse as MCP request
            try:
                request = MCPRequest(**data, session_id=session_id)
            except Exception as e:
                await websocket.send_json({
                    "status": "error",
                    "error": f"Invalid request format: {str(e)}",
                    "timestamp": datetime.now().isoformat()
                })
                continue
            
            # Handle the request
            response = await mcp_protocol.handle_request(request)
            
            # Send response back to client
            await websocket.send_json(response.dict())
            
    except WebSocketDisconnect:
        print(f"WebSocket disconnected: {session_id}")
    except Exception as e:
        print(f"WebSocket error: {str(e)}")
        try:
            await websocket.send_json({
                "status": "error",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            })
        except:
            pass

# Legacy endpoints for backward compatibility

@app.post("/rag")
async def rag_handler(payload: RAGRequest):
    """Legacy RAG endpoint - now routes through MCP compliance agent"""
    try:
        # Convert legacy request to MCP request
        mcp_request = MCPRequest(
            agent_id="compliance_agent",
            action="analyze_compliance",
            parameters={
                "plan_json": payload.plan_json,
                "output_path": payload.output_path,
                "refdir": payload.refdir,
                "user_message": payload.user_message
            },
            session_id="legacy_session"
        )
        
        # Handle through MCP protocol
        response = await mcp_protocol.handle_request(mcp_request)
        
        if response.status == "error":
            raise HTTPException(status_code=500, detail=response.error)
        
        # Convert MCP response to legacy format
        result_data = response.data.get("result", {})
        
        # Generate mock compliance violations for backward compatibility
        mock_violations = generate_mock_violations(payload.user_message or "Analyze compliance")
        
        return RAGResponse(
            message=result_data.get("message", "Analysis completed successfully"),
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
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def generate_mock_violations(user_message: str) -> List[ComplianceViolation]:
    """Generate mock compliance violations for backward compatibility"""
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

# Convenience endpoints for common operations

@app.post("/compliance/analyze")
async def analyze_compliance(plan_json: str, user_message: str = None):
    """Convenience endpoint for compliance analysis"""
    request = MCPRequest(
        agent_id="compliance_agent",
        action="analyze_compliance",
        parameters={
            "plan_json": plan_json,
            "user_message": user_message or "Analyze compliance"
        }
    )
    return await mcp_protocol.handle_request(request)

@app.post("/security/audit")
async def audit_security(plan_json: str, security_framework: str = "CIS"):
    """Convenience endpoint for security audit"""
    request = MCPRequest(
        agent_id="security_agent",
        action="audit_security",
        parameters={
            "plan_json": plan_json,
            "security_framework": security_framework
        }
    )
    return await mcp_protocol.handle_request(request)

@app.post("/costs/analyze")
async def analyze_costs(plan_json: str, region: str = "us-east-1"):
    """Convenience endpoint for cost analysis"""
    request = MCPRequest(
        agent_id="cost_agent",
        action="analyze_costs",
        parameters={
            "plan_json": plan_json,
            "region": region
        }
    )
    return await mcp_protocol.handle_request(request)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000) 