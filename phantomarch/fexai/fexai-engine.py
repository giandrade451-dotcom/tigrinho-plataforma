#!/usr/bin/env python3
"""
FexAI — PhantomArch Integrated AI Assistant
Motor de IA offline, sem APIs externas.
Usa modelos locais via Ollama ou transformers.

Features:
- Chat interativo
- Completação de código
- Explicação de código
- Geração de projetos
- Comandos do sistema
- Filtro de conteúdo (sem +18, sem conteúdo prejudicial)

Arquitetura:
- Backend: Python + FastAPI
- Modelo: Ollama (llama3/mistral/phi3) ou fallback para regras
- Frontend: Terminal CLI + integração FexCode
"""

import os
import sys
import json
import re
import subprocess
import signal
from pathlib import Path
from datetime import datetime

# --- Constantes ---
FEXAI_VERSION = "1.0.0"
FEXAI_DIR = Path("/opt/fexai")
FEXAI_DATA = FEXAI_DIR / "data"
FEXAI_MODELS = FEXAI_DIR / "models"
FEXAI_PLUGINS = FEXAI_DIR / "plugins"
FEXAI_LOGS = FEXAI_DIR / "logs"
HISTORY_FILE = FEXAI_DATA / "chat_history.json"

# --- Filtro de Conteúdo ---
BLOCKED_PATTERNS = [
    r'\b(hack|crack|exploit|malware|virus|trojan|ransomware)\b.*\b(criar|fazer|gerar|ensinar)\b',
    r'\b(roubar|roubo|furto|sequestro|assassin)\b',
    r'\b(drogas?|cocaína|heroína|metanfetamina)\b.*\b(fazer|produzir|sintetizar)\b',
    r'\b(bomba|explosivo|arma)\b.*\b(construir|montar|fabricar)\b',
    r'\b(nud[eo]|porn|sexo|erótic)\b',
    r'\b(xing|ofens|insulto|racis|homofob)\b',
    r'\b(suicíd|automutila)\b',
    r'\b(phishing|engenharia social)\b.*\b(fazer|criar)\b',
    r'\b(deep\s?fake)\b.*\b(criar|gerar)\b',
    r'\b(pirate|piratear|crack|keygen)\b.*\b(software|jogo|programa)\b',
]

BLOCKED_RESPONSE = """⚠️ Desculpe, não posso ajudar com esse tipo de solicitação.

O FexAI tem limites de segurança para proteger os usuários. Não posso:
• Gerar conteúdo +18 ou explícito
• Ajudar com atividades ilegais
• Criar conteúdo que prejudique pessoas
• Auxiliar em hacking/cracking malicioso
• Gerar xingamentos ou ofensas

Posso ajudar com:
✓ Programação e desenvolvimento
✓ Configuração do sistema
✓ Criação de projetos
✓ Explicação de código
✓ Dúvidas técnicas
✓ Otimização de performance

Como posso ajudar de forma construtiva?"""


def is_content_blocked(text: str) -> bool:
    """Verifica se o conteúdo viola as regras de segurança."""
    text_lower = text.lower()
    for pattern in BLOCKED_PATTERNS:
        if re.search(pattern, text_lower, re.IGNORECASE):
            return True
    return False


# --- Ollama Integration ---
class OllamaBackend:
    """Backend usando Ollama para modelos locais."""

    def __init__(self, model: str = "phi3"):
        self.model = model
        self.available = self._check_ollama()

    def _check_ollama(self) -> bool:
        try:
            result = subprocess.run(
                ["ollama", "list"],
                capture_output=True, text=True, timeout=5
            )
            return result.returncode == 0
        except (FileNotFoundError, subprocess.TimeoutExpired):
            return False

    def generate(self, prompt: str, system_prompt: str = "") -> str:
        if not self.available:
            return None

        full_prompt = f"{system_prompt}\n\nUser: {prompt}\nAssistant:" if system_prompt else prompt

        try:
            result = subprocess.run(
                ["ollama", "run", self.model, full_prompt],
                capture_output=True, text=True, timeout=120
            )
            if result.returncode == 0:
                return result.stdout.strip()
        except (subprocess.TimeoutExpired, FileNotFoundError):
            pass
        return None


# --- Fallback Rule Engine ---
class RuleEngine:
    """Respostas baseadas em regras quando modelo IA não está disponível."""

    RESPONSES = {
        "olá|oi|hey|hello": "Olá! Sou o FexAI, assistente do PhantomArch. Como posso ajudar?",
        "quem.*você|sobre.*você": f"Sou o FexAI v{FEXAI_VERSION}, a IA integrada do PhantomArch. Funciono 100% offline e posso ajudar com programação, sistema, e muito mais!",
        "ajuda|help|comandos": """Posso ajudar com:
• /code <linguagem> - Gerar template de código
• /explain <código> - Explicar código
• /project <tipo> - Criar estrutura de projeto
• /system <comando> - Info sobre comandos do sistema
• /optimize - Dicas de otimização
• /exit - Sair""",
        "python|pip": "Python dicas: use `pyenv` para versões, `pip install` para pacotes, `python -m venv` para ambientes virtuais.",
        "rust|cargo": "Rust dicas: `rustup update`, `cargo new projeto`, `cargo build --release` para otimização.",
        "docker|container": "Docker dicas: `docker run -it`, `docker compose up -d`, `docker ps` para ver containers.",
        "git": "Git dicas: `git init`, `git add .`, `git commit -m 'msg'`, `git push origin main`.",
        "linux|arch|pacman": "Arch dicas: `pacman -Syu` atualizar, `pacman -Ss` buscar, `pacman -Rns` remover.",
        "otimiz|performance|rápido": "Use `fex-control-center` para modos Turbo/Game/Dev. Kernel zen + gamemode = max FPS!",
        "jogo|game|steam": "Gaming: SUPER+G para GameMode, `mangohud` para overlay, `gamescope` para compositor.",
    }

    def generate(self, prompt: str) -> str:
        prompt_lower = prompt.lower()
        for pattern, response in self.RESPONSES.items():
            if re.search(pattern, prompt_lower):
                return response
        return "Hmm, não tenho certeza sobre isso. Tente reformular ou use /help para ver comandos disponíveis. Para respostas mais avançadas, instale um modelo: `ollama pull phi3`"


# --- FexAI Main Class ---
class FexAI:
    def __init__(self):
        self._setup_dirs()
        self.ollama = OllamaBackend()
        self.rules = RuleEngine()
        self.history = self._load_history()
        self.system_prompt = """Você é FexAI, o assistente de IA do PhantomArch Linux.
Seja útil, conciso e técnico. Foque em:
- Programação (todas linguagens)
- Linux/Arch Linux
- Gaming/Performance
- DevOps/Containers
- Criação de projetos

Regras:
- NUNCA gere conteúdo +18
- NUNCA ajude com atividades ilegais
- NUNCA crie conteúdo prejudicial
- Seja respeitoso e profissional
- Responda em português quando perguntado em português"""

    def _setup_dirs(self):
        for d in [FEXAI_DATA, FEXAI_MODELS, FEXAI_PLUGINS, FEXAI_LOGS]:
            d.mkdir(parents=True, exist_ok=True)

    def _load_history(self) -> list:
        if HISTORY_FILE.exists():
            try:
                return json.loads(HISTORY_FILE.read_text())[-100:]  # Keep last 100
            except json.JSONDecodeError:
                pass
        return []

    def _save_history(self):
        HISTORY_FILE.write_text(json.dumps(self.history[-100:], ensure_ascii=False, indent=2))

    def process_command(self, text: str) -> str:
        """Processa comandos especiais /command."""
        if text.startswith("/code"):
            lang = text.replace("/code", "").strip() or "python"
            return self._generate_template(lang)
        elif text.startswith("/project"):
            ptype = text.replace("/project", "").strip() or "web"
            return self._generate_project(ptype)
        elif text.startswith("/system"):
            cmd = text.replace("/system", "").strip()
            return self._system_info(cmd)
        elif text.startswith("/optimize"):
            return self._optimize_tips()
        elif text.startswith("/explain"):
            code = text.replace("/explain", "").strip()
            return f"Para explicar código, cole-o aqui e pergunte especificamente o que deseja entender."
        return None

    def _generate_template(self, lang: str) -> str:
        templates = {
            "python": '''# PhantomArch Python Template
def main():
    print("Hello from PhantomArch!")

if __name__ == "__main__":
    main()''',
            "rust": '''// PhantomArch Rust Template
fn main() {
    println!("Hello from PhantomArch!");
}''',
            "c": '''// PhantomArch C Template
#include <stdio.h>

int main() {
    printf("Hello from PhantomArch!\\n");
    return 0;
}''',
            "javascript": '''// PhantomArch JavaScript Template
console.log("Hello from PhantomArch!");''',
            "go": '''// PhantomArch Go Template
package main

import "fmt"

func main() {
    fmt.Println("Hello from PhantomArch!")
}''',
        }
        return templates.get(lang.lower(), f"Template para '{lang}' não disponível. Linguagens: python, rust, c, javascript, go")

    def _generate_project(self, ptype: str) -> str:
        projects = {
            "web": "mkdir -p myproject/{src,public,styles} && touch myproject/{index.html,src/app.js,styles/main.css,package.json}",
            "python": "mkdir -p myproject/{src,tests,docs} && touch myproject/{pyproject.toml,README.md,src/__init__.py,src/main.py,tests/test_main.py}",
            "rust": "cargo new myproject",
            "flutter": "flutter create myproject",
            "godot": "Abra Godot e crie um novo projeto pela interface.",
            "react": "npx create-react-app myproject",
        }
        return f"Criando projeto {ptype}:\n\n```bash\n{projects.get(ptype.lower(), 'mkdir -p myproject && cd myproject')}\n```"

    def _system_info(self, cmd: str) -> str:
        safe_commands = ["uname", "lscpu", "free", "df", "uptime", "whoami", "ls", "cat", "echo"]
        if cmd and cmd.split()[0] in safe_commands:
            try:
                result = subprocess.run(cmd.split(), capture_output=True, text=True, timeout=10)
                return f"```\n{result.stdout}\n```"
            except (subprocess.TimeoutExpired, FileNotFoundError):
                return "Erro ao executar comando."
        return "Comandos seguros: uname, lscpu, free, df, uptime, whoami"

    def _optimize_tips(self) -> str:
        return """⚡ Dicas de Otimização PhantomArch:

1. Use `fex-control-center` → Turbo Mode para max performance
2. GameMode: SUPER+G antes de jogar
3. Kernel zen já está otimizado para gaming
4. zRAM ativo — sem swap lento em disco
5. Compile com `MAKEFLAGS="-j$(nproc)"` para usar todos os cores
6. Use NVMe + Btrfs com compress=zstd para I/O rápido
7. MangoHud para monitorar FPS em tempo real
8. Gamescope para isolamento de jogos"""

    def chat(self, user_input: str) -> str:
        """Processa input do usuário e retorna resposta."""
        # Content filter
        if is_content_blocked(user_input):
            return BLOCKED_RESPONSE

        # Commands
        cmd_response = self.process_command(user_input)
        if cmd_response:
            return cmd_response

        # Try Ollama first
        if self.ollama.available:
            response = self.ollama.generate(user_input, self.system_prompt)
            if response:
                # Filter response too
                if is_content_blocked(response):
                    return "Não posso gerar essa resposta. Tente outra pergunta."
                self.history.append({"user": user_input, "ai": response, "ts": datetime.now().isoformat()})
                self._save_history()
                return response

        # Fallback to rules
        response = self.rules.generate(user_input)
        self.history.append({"user": user_input, "ai": response, "ts": datetime.now().isoformat()})
        self._save_history()
        return response


# --- CLI Interface ---
def main():
    ai = FexAI()

    print(f"\033[0;35m")
    print(f"  ╔═══════════════════════════════════════╗")
    print(f"  ║   🤖 FexAI v{FEXAI_VERSION}                     ║")
    print(f"  ║   PhantomArch AI Assistant             ║")
    print(f"  ╚═══════════════════════════════════════╝")
    print(f"\033[0m")

    backend = "Ollama" if ai.ollama.available else "Rule Engine (instale ollama para IA avançada)"
    print(f"  Backend: {backend}")
    print(f"  Comandos: /help, /code, /project, /system, /optimize, /exit")
    print()

    def signal_handler(sig, frame):
        print("\n\n\033[0;35m  Até mais! 👻\033[0m\n")
        sys.exit(0)

    signal.signal(signal.SIGINT, signal_handler)

    while True:
        try:
            user_input = input("\033[0;36m  Você>\033[0m ").strip()
        except EOFError:
            break

        if not user_input:
            continue
        if user_input.lower() in ["/exit", "/quit", "/sair", "exit", "quit"]:
            print("\n\033[0;35m  Até mais! 👻\033[0m\n")
            break

        response = ai.chat(user_input)
        print(f"\n\033[0;35m  FexAI>\033[0m {response}\n")


if __name__ == "__main__":
    main()
