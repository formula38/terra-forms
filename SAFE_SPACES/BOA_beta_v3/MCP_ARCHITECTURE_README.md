# BizOps MCP (Model-Context-Protocol) Architecture

## 🎯 Overview

This project has been refactored to follow a modern MCP (Model-Context-Protocol) architecture, transforming the monolithic RAG system into a flexible, multi-agent platform for infrastructure analysis.

## 🏗️ Architecture Components

### 1. MCP Server (`backend/mcp_server.py`)
The core MCP infrastructure providing:
- **MCPHost**: Central coordinator managing agents, tools, and sessions
- **Agent**: Individual agents with environment, memory, and state management
- **Tool**: Standardized interface for functionality
- **Environment**: Context and state management
- **Memory**: Short-term and long-term memory for agents

### 2. MCP Tools (`backend/mcp_tools/`)
Specialized tools that wrap existing functionality:

#### RAG Tools (`rag_tools.py`)
- **TerraformAnalyzerTool**: Wraps existing RAG inspector functionality
- **ComplianceReporterTool**: Generates compliance reports and summaries
- **SecurityAuditorTool**: Performs security-focused analysis

#### Cost Tools (`cost_tools.py`)
- **CostAnalyzerTool**: Analyzes infrastructure costs and provides estimates

#### Document Tools (`document_tools.py`)
- **DocumentGeneratorTool**: Generates various types of documentation

### 3. MCP Agents (`backend/mcp_agents/`)
Specialized agents for different analysis types:

#### Compliance Agent (`compliance_agent.py`)
- Analyzes Terraform configurations for compliance violations
- Generates compliance reports and executive summaries
- Tracks compliance trends over time
- Actions: `analyze_compliance`, `generate_report`, `get_compliance_status`

#### Security Agent (`security_agent.py`)
- Performs security audits and vulnerability assessments
- Analyzes for hardcoded secrets and encryption issues
- Monitors security posture against industry standards
- Actions: `audit_security`, `analyze_secrets`, `check_encryption`, `get_security_status`

#### Cost Agent (`cost_agent.py`)
- Analyzes infrastructure costs and provides optimization recommendations
- Tracks cost trends and identifies savings opportunities
- Actions: `analyze_costs`, `optimize_costs`, `get_cost_status`

### 4. MCP Protocol (`backend/mcp_protocol.py`)
Handles communication between frontend and agents:
- Request/response handling
- Session management
- Error handling and validation

### 5. FastAPI Server (`backend/api/mcp_server.py`)
The main API server that:
- Initializes the MCP system
- Provides REST endpoints for agent interactions
- Supports WebSocket connections for real-time communication
- Maintains backward compatibility with legacy RAG endpoints

## 🚀 Getting Started

### Prerequisites
- Python 3.8+
- Node.js 16+ (for frontend)
- Virtual environment

### Installation

1. **Clone and setup environment:**
```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r backend/requirements.txt
```

2. **Start the MCP Server:**
```bash
# Make the startup script executable (if not already done)
chmod +x backend/run_mcp_server.sh

# Start the server
./backend/run_mcp_server.sh
```

3. **Start the Frontend:**
```bash
cd frontend/bizops-dashboard
npm install
ng serve
```

### Server Endpoints

The MCP server provides the following endpoints:

#### System Information
- `GET /` - Server status
- `GET /health` - Health check
- `GET /system/status` - Overall system status
- `GET /agents` - List available agents
- `GET /tools` - List available tools

#### MCP Protocol
- `POST /mcp/request` - Send MCP requests
- `GET /sessions` - List active sessions
- `GET /sessions/{session_id}` - Get session info
- `DELETE /sessions/{session_id}` - Clean up session
- `WS /mcp/ws/{session_id}` - WebSocket for real-time communication

#### Convenience Endpoints
- `POST /compliance/analyze` - Compliance analysis
- `POST /security/audit` - Security audit
- `POST /costs/analyze` - Cost analysis

#### Legacy Compatibility
- `POST /rag` - Legacy RAG endpoint (routes through MCP)

## 🔧 Usage Examples

### Using the MCP Service (Frontend)

```typescript
import { MCPService } from './services/mcp.service';

// Initialize service
const mcpService = new MCPService();

// Compliance analysis
mcpService.analyzeCompliance('path/to/plan.json', 'Analyze compliance')
  .subscribe(response => {
    console.log('Compliance analysis:', response);
  });

// Security audit
mcpService.auditSecurity('path/to/plan.json', 'CIS')
  .subscribe(response => {
    console.log('Security audit:', response);
  });

// Cost analysis
mcpService.analyzeCosts('path/to/plan.json', 'us-east-1')
  .subscribe(response => {
    console.log('Cost analysis:', response);
  });

// Real-time WebSocket communication
mcpService.connectWebSocket().subscribe(response => {
  console.log('Real-time update:', response);
});
```

### Direct API Calls

```bash
# Compliance analysis
curl -X POST "http://localhost:8000/mcp/request" \
  -H "Content-Type: application/json" \
  -d '{
    "agent_id": "compliance_agent",
    "action": "analyze_compliance",
    "parameters": {
      "plan_json": "infra/terraform/tfplan.json",
      "user_message": "Analyze compliance"
    }
  }'

# Security audit
curl -X POST "http://localhost:8000/mcp/request" \
  -H "Content-Type: application/json" \
  -d '{
    "agent_id": "security_agent",
    "action": "audit_security",
    "parameters": {
      "plan_json": "infra/terraform/tfplan.json",
      "security_framework": "CIS"
    }
  }'

# Cost analysis
curl -X POST "http://localhost:8000/mcp/request" \
  -H "Content-Type: application/json" \
  -d '{
    "agent_id": "cost_agent",
    "action": "analyze_costs",
    "parameters": {
      "plan_json": "infra/terraform/tfplan.json",
      "region": "us-east-1"
    }
  }'
```

## 🔄 Migration from Legacy System

### What Changed

1. **Architecture**: Monolithic RAG → Multi-agent MCP system
2. **Communication**: Simple HTTP → MCP protocol with WebSocket support
3. **Functionality**: Single analysis → Multiple specialized agents
4. **Memory**: Stateless → Stateful with memory and learning

### Backward Compatibility

The legacy `/rag` endpoint is still available and routes through the MCP compliance agent:

```typescript
// Old way (still works)
ragService.callRAG(payload).subscribe(response => {
  console.log(response);
});

// New way (recommended)
mcpService.analyzeCompliance(planJson, userMessage).subscribe(response => {
  console.log(response);
});
```

### Enhanced Features

1. **Multiple Analysis Types**: Compliance, Security, Cost analysis
2. **Real-time Communication**: WebSocket support for live updates
3. **Session Management**: Track analysis history and trends
4. **Memory & Learning**: Agents remember past interactions
5. **Modular Design**: Easy to add new agents and tools

## 🛠️ Development

### Adding New Agents

1. Create a new agent class in `backend/mcp_agents/`:
```python
from backend.mcp_server import Agent

class NewAgent(Agent):
    def __init__(self):
        super().__init__(
            agent_id="new_agent",
            name="New Analysis Agent",
            system_prompt="Your agent description...",
            tools=["tool1", "tool2"]
        )
    
    async def _execute_action_impl(self, action: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        # Implement your actions here
        pass
```

2. Register the agent in `backend/api/mcp_server.py`:
```python
from backend.mcp_agents.new_agent import NewAgent

def initialize_mcp_system():
    # ... existing code ...
    mcp_host.register_agent(NewAgent())
```

### Adding New Tools

1. Create a new tool class in `backend/mcp_tools/`:
```python
from backend.mcp_server import Tool, ToolParameter

class NewTool(Tool):
    def __init__(self):
        super().__init__(
            tool_id="new_tool",
            name="New Tool",
            description="Tool description",
            parameters=[
                ToolParameter("param1", "string", True, "Parameter description")
            ],
            invoke_func=self._invoke_tool
        )
    
    async def _invoke_tool(self, params: Dict[str, Any]) -> Dict[str, Any]:
        # Implement tool functionality
        pass
```

2. Register the tool in `backend/api/mcp_server.py`:
```python
from backend.mcp_tools.new_tool import NewTool

def initialize_mcp_system():
    # ... existing code ...
    mcp_host.register_tool(NewTool())
```

## 📊 Monitoring and Debugging

### System Status
```bash
# Check system health
curl http://localhost:8000/health

# Get detailed system status
curl http://localhost:8000/system/status

# List active sessions
curl http://localhost:8000/sessions
```

### Agent Status
```bash
# Get agent information
curl http://localhost:8000/agents

# Get tool information
curl http://localhost:8000/tools
```

### Logs
The server provides detailed logging for debugging:
- Agent registration and initialization
- Tool invocations and results
- Session management
- Error handling

## 🔒 Security Considerations

1. **CORS**: Configure allowed origins in production
2. **Authentication**: Add authentication middleware for production use
3. **Rate Limiting**: Implement rate limiting for API endpoints
4. **Input Validation**: All inputs are validated through Pydantic models
5. **Session Management**: Sessions are tracked and can be cleaned up

## 🚀 Production Deployment

### Environment Variables
```bash
export MCP_ENV=production
export MCP_LOG_LEVEL=INFO
export MCP_MAX_SESSIONS=1000
```

### Docker Deployment
```dockerfile
FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY backend/ ./backend/
COPY infra/ ./infra/

EXPOSE 8000
CMD ["python3", "backend/api/mcp_server.py"]
```

### Load Balancing
For production, consider:
- Multiple MCP server instances
- Load balancer (nginx, HAProxy)
- Redis for session storage
- Database for persistent memory

## 📈 Performance Optimization

1. **Async Operations**: All operations are async for better performance
2. **Memory Management**: Agents have configurable memory limits
3. **Session Cleanup**: Automatic cleanup of old sessions
4. **Tool Caching**: Tools can implement caching for expensive operations
5. **Connection Pooling**: WebSocket connections are managed efficiently

## 🤝 Contributing

1. Follow the MCP architecture patterns
2. Add comprehensive tests for new agents and tools
3. Update documentation for new features
4. Maintain backward compatibility when possible
5. Use type hints and follow PEP 8

## 📚 API Documentation

Once the server is running, visit:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## 🆘 Troubleshooting

### Common Issues

1. **Import Errors**: Ensure PYTHONPATH includes the project root
2. **Tool Not Found**: Check that tools are properly registered
3. **Agent Not Found**: Verify agent registration in startup
4. **WebSocket Issues**: Check CORS configuration
5. **Memory Issues**: Monitor agent memory usage

### Debug Mode
```bash
export MCP_DEBUG=true
export MCP_LOG_LEVEL=DEBUG
```

## 📞 Support

For issues and questions:
1. Check the logs for error details
2. Verify system status endpoints
3. Test with simple API calls first
4. Review the MCP architecture documentation

---

**🎉 Congratulations!** You've successfully migrated to a modern, scalable MCP architecture that provides enhanced functionality while maintaining backward compatibility. 