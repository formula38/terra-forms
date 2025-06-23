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

from mcp_server_legacy import mcp_host, Agent, Tool
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
class MCPRequest(BaseModel):
    """MCP Request model"""
    agent_id: str
    action: str
    parameters: Dict[str, Any] = {}
    session_id: Optional[str] = None

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

@app.post("/compliance/analyze")
async def analyze_compliance(request: MCPRequest):
    """Convenience endpoint for compliance analysis"""
    agent = mcp_host.get_agent("compliance_agent")
    if not agent:
        raise HTTPException(status_code=404, detail="Compliance agent not found")
    return await agent.execute_action(request.action, request.parameters)

@app.post("/security/audit")
async def audit_security(request: MCPRequest):
    """Convenience endpoint for security audit"""
    agent = mcp_host.get_agent("security_agent")
    if not agent:
        raise HTTPException(status_code=404, detail="Security agent not found")
    return await agent.execute_action(request.action, request.parameters)

@app.post("/costs/analyze")
async def analyze_costs(request: MCPRequest):
    """Convenience endpoint for cost analysis"""
    agent = mcp_host.get_agent("cost_agent")
    if not agent:
        raise HTTPException(status_code=404, detail="Cost agent not found")
    return await agent.execute_action(request.action, request.parameters)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("api.mcp_server:app", reload=True) 