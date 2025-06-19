from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
from fastapi.staticfiles import StaticFiles


# ✅ Create app first
app = FastAPI()
# app.mount("/", StaticFiles(directory="frontend/bizops-dashboard/dist/bizops-dashboard", html=True), name="static")

# ✅ Register middleware AFTER app is defined
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Replace with specific domains in prod
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Example request schema
class RAGRequest(BaseModel):
    plan_json: str
    output_path: str
    refdir: Optional[str] = None

@app.get("/")
def root():
    return {"message": "BizOpsAgent FastAPI is live 🎯"}

@app.post("/rag")
async def rag_handler(payload: RAGRequest):
    return {
        "message": "RAG handler received",
        "plan_json": payload.plan_json,
        "output_path": payload.output_path,
        "refdir": payload.refdir
    }

