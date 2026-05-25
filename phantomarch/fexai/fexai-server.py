#!/usr/bin/env python3
"""
FexAI Server — API local para integração com FexCode e outros apps.
Roda em localhost:7860
"""

import json
import sys
from pathlib import Path

# Add parent to path
sys.path.insert(0, str(Path(__file__).parent))

try:
    from fastapi import FastAPI, HTTPException
    from fastapi.middleware.cors import CORSMiddleware
    from pydantic import BaseModel
    import uvicorn
    HAS_FASTAPI = True
except ImportError:
    HAS_FASTAPI = False

from fexai_engine import FexAI, is_content_blocked, FEXAI_VERSION

app = FastAPI(
    title="FexAI Server",
    description="PhantomArch AI Assistant API",
    version=FEXAI_VERSION
) if HAS_FASTAPI else None

if HAS_FASTAPI:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    ai = FexAI()

    class ChatRequest(BaseModel):
        message: str
        context: str = ""

    class ChatResponse(BaseModel):
        response: str
        blocked: bool = False
        backend: str = ""

    class CodeRequest(BaseModel):
        code: str
        action: str = "explain"  # explain, complete, fix, optimize
        language: str = ""

    @app.get("/")
    def root():
        return {
            "name": "FexAI",
            "version": FEXAI_VERSION,
            "status": "running",
            "backend": "ollama" if ai.ollama.available else "rules",
            "endpoints": ["/chat", "/code", "/health", "/models"]
        }

    @app.get("/health")
    def health():
        return {"status": "ok", "ollama": ai.ollama.available}

    @app.get("/models")
    def models():
        import subprocess
        try:
            result = subprocess.run(["ollama", "list"], capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                return {"models": result.stdout.strip().split("\n")}
        except (FileNotFoundError, subprocess.TimeoutExpired):
            pass
        return {"models": [], "note": "Ollama não disponível. Instale: curl -fsSL https://ollama.com/install.sh | sh"}

    @app.post("/chat", response_model=ChatResponse)
    def chat(req: ChatRequest):
        if is_content_blocked(req.message):
            return ChatResponse(
                response="⚠️ Conteúdo bloqueado pelo filtro de segurança.",
                blocked=True,
                backend="filter"
            )

        response = ai.chat(req.message)
        return ChatResponse(
            response=response,
            blocked=False,
            backend="ollama" if ai.ollama.available else "rules"
        )

    @app.post("/code")
    def code_assist(req: CodeRequest):
        if is_content_blocked(req.code):
            raise HTTPException(status_code=403, detail="Conteúdo bloqueado")

        prompt = f"/{req.action} {req.language}\n```\n{req.code}\n```"
        response = ai.chat(prompt)
        return {"result": response, "action": req.action}


def main():
    if not HAS_FASTAPI:
        print("FastAPI não instalado. Instale: pip install fastapi uvicorn")
        print("Ou use o FexAI CLI: python fexai-engine.py")
        sys.exit(1)

    print(f"\n🤖 FexAI Server v{FEXAI_VERSION}")
    print(f"   http://localhost:7860")
    print(f"   Backend: {'Ollama' if ai.ollama.available else 'Rule Engine'}")
    print()

    uvicorn.run(app, host="0.0.0.0", port=7860, log_level="info")


if __name__ == "__main__":
    main()
