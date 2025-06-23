# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Copy only the backend application code into the container
COPY backend/ .

# Install any needed packages specified in requirements.txt
# Using --no-cache-dir to reduce image size
RUN pip install --no-cache-dir -r requirements.txt

# Run mcp_server.py when the container launches
# Using uvicorn to run the FastAPI app
CMD ["uvicorn", "api.mcp_server:app", "--host", "0.0.0.0", "--port", "8000", "--reload"] 