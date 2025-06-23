#!/usr/bin/env python3
"""Main MCP Server"""

import asyncio
import os
from pathlib import Path
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
    def __init__(self, agent_id: str, name: str, description: str, tools: List, system_prompt: Optional[str] = None):
        self.agent_id = agent_id
        self.name = name
        self.description = description
        # Handle both Tool objects and tool IDs
        self.tool_ids = []
        self.tools = {}
        
        for tool in tools:
            if isinstance(tool, Tool):
                self.tools[tool.tool_id] = tool
                self.tool_ids.append(tool.tool_id)
            elif isinstance(tool, str):
                self.tool_ids.append(tool)
            else:
                raise ValueError(f"Invalid tool type: {type(tool)}")
        
        self.system_prompt: Optional[str] = system_prompt
        self.status = "idle"

    def load_system_prompt(self, prompt_file: Optional[str] = None) -> str:
        """Load system prompt from file"""
        if prompt_file is None:
            prompt_file = f"{self.agent_id}_prompt.txt"
        
        # Try to load from the prompts directory
        prompt_paths = [
            Path("coldrag/train/prompts/shared") / str(prompt_file),
            Path("backend/coldrag/train/prompts/shared") / str(prompt_file),
            Path("/app/coldrag/train/prompts/shared") / str(prompt_file),
        ]
        
        for prompt_path in prompt_paths:
            if prompt_path.exists():
                try:
                    with open(prompt_path, 'r', encoding='utf-8') as f:
                        self.system_prompt = f.read().strip()
                    return self.system_prompt
                except Exception as e:
                    print(f"Warning: Could not load prompt from {prompt_path}: {e}")
        
        # Fallback to default prompt
        if self.system_prompt is None:
            self.system_prompt = f"You are {self.name}. {self.description}"
        
        return self.system_prompt

    async def execute_action(self, action: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Execute an action"""
        # First check if we have the tool directly
        if action in self.tools:
            self.status = f"executing {action}"
            result = await self.tools[action].invoke(parameters)
            self.status = "idle"
            return result
        
        # If not, try to get it from the MCP host
        tool = mcp_host.get_tool(action)
        if tool:
            self.status = f"executing {action}"
            result = await tool.invoke(parameters)
            self.status = "idle"
            return result
            
        return {"error": f"Action {action} not found"}

    def get_status(self) -> str:
        """Get agent status"""
        return self.status

    def get_system_prompt(self) -> str:
        """Get the agent's system prompt"""
        if self.system_prompt is None:
            return self.load_system_prompt()
        return self.system_prompt

class MCPHost:
    """MCP Host"""
    def __init__(self):
        self.agents: Dict[str, "Agent"] = {}
        self.tools: Dict[str, "Tool"] = {}

    def register_agent(self, agent: "Agent"):
        """Register an agent"""
        self.agents[agent.agent_id] = agent
        
        # Link agent's tool IDs with registered tools
        for tool_id in agent.tool_ids:
            if tool_id in self.tools and tool_id not in agent.tools:
                agent.tools[tool_id] = self.tools[tool_id]
        
        # Load system prompt if not already loaded
        if agent.system_prompt is None:
            agent.load_system_prompt()
        print(f"Agent '{agent.name}' registered.")

    def register_tool(self, tool: "Tool"):
        """Register a tool"""
        self.tools[tool.tool_id] = tool
        print(f"Tool '{tool.name}' registered.")

    def get_agent(self, agent_id: str) -> Optional["Agent"]:
        """Get an agent"""
        return self.agents.get(agent_id)

    def get_tool(self, tool_id: str) -> Optional["Tool"]:
        """Get a tool"""
        return self.tools.get(tool_id)

    def get_system_status(self) -> Dict[str, Any]:
        """Get system status"""
        return {
            "agents": {aid: a.get_status() for aid, a in self.agents.items()},
            "tools": list(self.tools.keys())
        }

mcp_host = MCPHost() 