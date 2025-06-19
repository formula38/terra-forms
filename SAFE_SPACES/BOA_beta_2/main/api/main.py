from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# ✅ Create app first
app = FastAPI()

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
    refdir: str | None = None

@app.get("/")
def root():
    return {"message": "BizOpsAgent FastAPI is live 🎯"}

@app.post("/rag")
def run_rag(req: RAGRequest):
    # Placeholder logic for now
    return {
        "plan_json": req.plan_json,
        "output_path": req.output_path,
        "refdir": req.refdir or "None"
    }
