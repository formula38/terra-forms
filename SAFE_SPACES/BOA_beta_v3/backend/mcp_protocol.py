#!/usr/bin/env python3
"""MCP Protocol Implementation"""

import json
import asyncio
from datetime import datetime
from typing import Dict, List, Any, Optional
from pydantic import BaseModel, Field

from backend.mcp_server_legacy import mcp_host

class MCPRequest(BaseModel):
    """MCP Request model"""
    agent_id: str = Field(..., description="ID of the agent to execute the action")
    action: str = Field(..., description="Action to execute")
    parameters: Dict[str, Any] = Field(default_factory=dict, description="Parameters for the action")
    session_id: Optional[str] = Field(None, description="Session ID for tracking")
    request_id: Optional[str] = Field(None, description="Unique request ID")

class MCPResponse(BaseModel):
    """MCP Response model"""
    status: str = Field(..., description="Status of the response (success/error)")
    data: Dict[str, Any] = Field(default_factory=dict, description="Response data")
    agent_id: str = Field(..., description="ID of the agent that processed the request")
    session_id: str = Field(..., description="Session ID")
    request_id: Optional[str] = Field(None, description="Request ID for correlation")
    timestamp: str = Field(..., description="Timestamp of the response")
    error: Optional[str] = Field(None, description="Error message if status is error")

class MCPProtocol:
    """Handles MCP communication between frontend and agents"""
    
    def __init__(self):
        self.active_sessions: Dict[str, Dict[str, Any]] = {}
        self.request_counter = 0
    
    async def handle_request(self, request: MCPRequest) -> MCPResponse:
        """Handle MCP request and route to appropriate agent"""
        
        # Generate request ID if not provided
        if not request.request_id:
            request.request_id = f"req_{self.request_counter}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
            self.request_counter += 1
        
        # Get or create session
        session_id = request.session_id or "default"
        if session_id not in self.active_sessions:
            self.active_sessions[session_id] = {
                "created_at": datetime.now().isoformat(),
                "requests": [],
                "agents_used": set()
            }
        
        # Track request in session
        self.active_sessions[session_id]["requests"].append({
            "request_id": request.request_id,
            "agent_id": request.agent_id,
            "action": request.action,
            "timestamp": datetime.now().isoformat()
        })
        self.active_sessions[session_id]["agents_used"].add(request.agent_id)
        
        try:
            # Get the agent
            agent = mcp_host.get_agent(request.agent_id)
            if not agent:
                return MCPResponse(
                    status="error",
                    data={},
                    agent_id=request.agent_id,
                    session_id=session_id,
                    request_id=request.request_id,
                    timestamp=datetime.now().isoformat(),
                    error=f"Agent {request.agent_id} not found"
                )
            
            # Execute the action
            result = await agent.execute_action(request.action, request.parameters)
            
            return MCPResponse(
                status="success",
                data=result,
                agent_id=request.agent_id,
                session_id=session_id,
                request_id=request.request_id,
                timestamp=datetime.now().isoformat()
            )
            
        except Exception as e:
            return MCPResponse(
                status="error",
                data={},
                agent_id=request.agent_id,
                session_id=session_id,
                request_id=request.request_id,
                timestamp=datetime.now().isoformat(),
                error=str(e)
            )
    
    def get_session_info(self, session_id: str) -> Optional[Dict[str, Any]]:
        """Get information about a session"""
        if session_id in self.active_sessions:
            session = self.active_sessions[session_id].copy()
            session["agents_used"] = list(session["agents_used"])
            return session
        return None
    
    def get_all_sessions(self) -> Dict[str, Dict[str, Any]]:
        """Get information about all active sessions"""
        sessions = {}
        for session_id, session_data in self.active_sessions.items():
            sessions[session_id] = session_data.copy()
            sessions[session_id]["agents_used"] = list(session_data["agents_used"])
        return sessions
    
    def cleanup_session(self, session_id: str) -> bool:
        """Clean up a session"""
        if session_id in self.active_sessions:
            del self.active_sessions[session_id]
            return True
        return False

# Global MCP Protocol instance
mcp_protocol = MCPProtocol() 