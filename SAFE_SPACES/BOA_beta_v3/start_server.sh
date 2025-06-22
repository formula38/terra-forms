#!/bin/bash
# Corrected MCP Server Startup Script

echo "🚀 Starting BizOps MCP Server..."

# Set environment variables
export PYTHONPATH="${PYTHONPATH}:$(pwd)"

# Check if virtual environment exists and create if needed
if [ ! -d "venv" ]; then
    echo "🔧 Virtual environment not found. Creating one..."
    python3 -m venv venv
    echo "✅ Virtual environment created successfully!"
fi

# Activate virtual environment
source venv/bin/activate

# Check if required packages are installed
echo "📦 Checking dependencies..."
python3 -c "import fastapi, uvicorn, pydantic" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "❌ Missing required packages. Installing from backend/requirements.txt..."
    pip install -r backend/requirements.txt
fi

# Create output directories if they don't exist
mkdir -p output/compliance_analysis
mkdir -p output/security_audits
mkdir -p output/cost_analysis
mkdir -p output/reports

echo "✅ Starting MCP Server on http://localhost:8000"
echo "📚 API Documentation: http://localhost:8000/docs"
echo "🔍 Health Check: http://localhost:8000/health"
echo "🤖 Agents: http://localhost:8000/agents"
echo "📦 Tools: http://localhost:8000/tools"

# Start the MCP server
cd backend/api
python3 mcp_server.py 