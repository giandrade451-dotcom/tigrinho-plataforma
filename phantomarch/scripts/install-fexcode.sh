#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch V2 — FexCode IDE Setup                          ║
# ║  VS Code OSS customizado com FexAI e tema Phantom            ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}━━━ FexCode IDE Setup ━━━${NC}"

TARGET_USER="${SUDO_USER:-$(logname 2>/dev/null || echo $USER)}"
TARGET_HOME="/home/$TARGET_USER"
FEXCODE_DIR="/opt/fexcode"
FEXCODE_CONFIG="${TARGET_HOME}/.config/FexCode"

# --- Instalar Code-OSS como base ---
echo -e "${CYAN}[1/6]${NC} Instalando Code-OSS (base)..."
if ! command -v code-oss &>/dev/null && ! command -v code &>/dev/null; then
    pacman -S --noconfirm code 2>/dev/null || true
fi
echo -e "${GREEN}  ✓ Code-OSS instalado${NC}"

# --- Criar diretórios FexCode ---
echo -e "${CYAN}[2/6]${NC} Criando estrutura FexCode..."
mkdir -p "$FEXCODE_DIR"/{themes,extensions,settings}
sudo -u "$TARGET_USER" mkdir -p "$FEXCODE_CONFIG/User"
echo -e "${GREEN}  ✓ Diretórios criados${NC}"

# --- Copiar configurações ---
echo -e "${CYAN}[3/6]${NC} Aplicando configurações..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "$SCRIPT_DIR/fexcode/settings/settings.json" ]]; then
    cp "$SCRIPT_DIR/fexcode/settings/settings.json" "$FEXCODE_CONFIG/User/settings.json"
fi
if [[ -f "$SCRIPT_DIR/fexcode/settings/keybindings.json" ]]; then
    cp "$SCRIPT_DIR/fexcode/settings/keybindings.json" "$FEXCODE_CONFIG/User/keybindings.json"
fi
chown -R "$TARGET_USER:$TARGET_USER" "$FEXCODE_CONFIG"
echo -e "${GREEN}  ✓ Settings aplicados${NC}"

# --- Instalar tema Phantom ---
echo -e "${CYAN}[4/6]${NC} Instalando tema Phantom Neon..."
THEME_DIR="$FEXCODE_CONFIG/User/extensions/phantom-neon-theme"
sudo -u "$TARGET_USER" mkdir -p "$THEME_DIR/themes"

if [[ -f "$SCRIPT_DIR/fexcode/theme/phantom-neon-theme.json" ]]; then
    cp "$SCRIPT_DIR/fexcode/theme/phantom-neon-theme.json" "$THEME_DIR/themes/"
fi

cat > "$THEME_DIR/package.json" << 'EOF'
{
  "name": "phantom-neon-theme",
  "displayName": "Phantom Neon",
  "description": "PhantomArch cyberpunk neon theme",
  "version": "1.0.0",
  "publisher": "phantomarch",
  "engines": {"vscode": "^1.80.0"},
  "categories": ["Themes"],
  "contributes": {
    "themes": [{
      "label": "Phantom Neon",
      "uiTheme": "vs-dark",
      "path": "./themes/phantom-neon-theme.json"
    }]
  }
}
EOF

chown -R "$TARGET_USER:$TARGET_USER" "$THEME_DIR"
echo -e "${GREEN}  ✓ Tema Phantom Neon instalado${NC}"

# --- Instalar extensões ---
echo -e "${CYAN}[5/6]${NC} Instalando extensões..."
if [[ -f "$SCRIPT_DIR/fexcode/extensions.txt" ]]; then
    while IFS= read -r ext; do
        [[ "$ext" =~ ^#.*$ || -z "$ext" ]] && continue
        sudo -u "$TARGET_USER" code --install-extension "$ext" --force 2>/dev/null || true
    done < "$SCRIPT_DIR/fexcode/extensions.txt"
fi
echo -e "${GREEN}  ✓ Extensões instaladas${NC}"

# --- Criar launcher FexCode ---
echo -e "${CYAN}[6/6]${NC} Criando launcher FexCode..."

cat > /usr/bin/fexcode << 'SCRIPT'
#!/bin/bash
# FexCode — PhantomArch IDE
# Wrapper para Code-OSS com config PhantomArch

export FEXAI_ENABLED=1
export FEXAI_ENDPOINT="http://localhost:7860"

if command -v code-oss &>/dev/null; then
    exec code-oss --user-data-dir="$HOME/.config/FexCode" "$@"
elif command -v code &>/dev/null; then
    exec code --user-data-dir="$HOME/.config/FexCode" "$@"
else
    echo "FexCode: Code-OSS não encontrado. Instale: pacman -S code"
    exit 1
fi
SCRIPT
chmod +x /usr/bin/fexcode

cat > /usr/share/applications/fexcode.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=FexCode
GenericName=Code Editor
Comment=FexCode IDE — PhantomArch Development Environment
Exec=fexcode %F
Icon=visual-studio-code
Terminal=false
Categories=Development;IDE;TextEditor;
MimeType=text/plain;application/x-code-workspace;
StartupNotify=true
Keywords=code;editor;ide;fexcode;development;
Actions=new-window;

[Desktop Action new-window]
Name=Nova Janela
Exec=fexcode --new-window
EOF

echo -e "${GREEN}  ✓ FexCode launcher criado${NC}"
echo ""
echo -e "${PURPLE}━━━ FexCode IDE pronto! ━━━${NC}"
echo -e "  Execute: ${GREEN}fexcode${NC}"
echo -e "  FexAI: ${GREEN}Ctrl+Shift+A${NC} (chat) | ${GREEN}Ctrl+Shift+I${NC} (completar)"
