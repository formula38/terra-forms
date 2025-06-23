#!/usr/bin/env python3
"""Main MCP Server"""

import asyncio
from typing import Dict, Any, List, Optional

class Tool:
    """Base class for all tools"""
    def __init__(self, tool_id: str, name: str, description: str, parameters: List[Dict[str, Any]], invoke_func):
        self.tool_id = tool_id
        self.name = name
        self.description = description
        self.parameters = [ToolParameter(**p) for p in parameters]
        self.invoke_func = invoke_func

    async def invoke(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Invoke the tool"""
        return await self.invoke_func(params)

class ToolParameter:
    """Tool parameter model"""
    def __init__(self, name: str, type: str, required: bool, description: str, default: Any = None):
        self.name = name
        self.type = type
        self.required = required
        self.description = description
        self.default = default

class Agent:
    """Base class for all agents"""
    def __init__(self, agent_id: str, name: str, description: str, tools: List[Tool]):
        self.agent_id = agent_id
        self.name = name
        self.description = description
        self.tools = {t.tool_id: t for t in tools}
        self.status = "idle"

    async def execute_action(self, action: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Execute an action"""
        if action in self.tools:
            self.status = f"executing {action}"
            result = await self.tools[action].invoke(parameters)
            self.status = "idle"
            return result
        return {"error": f"Action {action} not found"}

    def get_status(self) -> str:
        """Get agent status"""
        return self.status

class MCPHost:
    """MCP Host"""
    def __init__(self):
        self.agents: Dict[str, "Agent"] = {}
        self.tools: Dict[str, "Tool"] = {}

    def register_agent(self, agent: "Agent"):
        """Register an agent"""
        self.agents[agent.agent_id] = agent
        print(f"Agent '{agent.name}' registered.")

    def register_tool(self, tool: "Tool"):
        """Register a tool"""
        self.tools[tool.tool_id] = tool
        print(f"Tool '{tool.name}' registered.")

    def get_agent(self, agent_id: str) -> "Agent":
        """Get an agent"""
        return self.agents.get(agent_id)

    def get_tool(self, tool_id: str) -> Tool:
        """Get a tool"""
        return self.tools.get(tool_id)

    def get_system_status(self) -> Dict[str, Any]:
        """Get system status"""
        return {
            "agents": {aid: a.get_status() for aid, a in self.agents.items()},
            "tools": list(self.tools.keys())
        }

mcp_host = MCPHost() 