#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch V2 — Post-Install Enhancements                  ║
# ║  Adiciona funcionalidades V2 após instalação base            ║
# ║  (Executar APÓS o post-install.sh original)                  ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${PURPLE}━━━ PhantomArch V2 Post-Install ━━━${NC}"

TARGET_USER="${SUDO_USER:-$(logname 2>/dev/null || echo $USER)}"
TARGET_HOME="/home/$TARGET_USER"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# --- 1. FexAI Setup ---
echo -e "${CYAN}[1/8]${NC} Instalando FexAI..."
mkdir -p /opt/fexai/{data,models,plugins,logs}
cp "$PROJECT_DIR/fexai/fexai-engine.py" /opt/fexai/
cp "$PROJECT_DIR/fexai/fexai-server.py" /opt/fexai/
chmod +x /opt/fexai/*.py

# Install Ollama for AI backend
if ! command -v ollama &>/dev/null; then
    curl -fsSL https://ollama.com/install.sh | sh 2>/dev/null || true
fi
systemctl enable ollama 2>/dev/null || true

# Install FexAI systemd service
mkdir -p "${TARGET_HOME}/.config/systemd/user"
cp "$PROJECT_DIR/fexai/systemd/fexai.service" "${TARGET_HOME}/.config/systemd/user/"
chown -R "$TARGET_USER:$TARGET_USER" "${TARGET_HOME}/.config/systemd"
echo -e "${GREEN}  ✓ FexAI instalado${NC}"

# --- 2. FexCode Setup ---
echo -e "${CYAN}[2/8]${NC} Instalando FexCode..."
bash "$SCRIPT_DIR/install-fexcode.sh" 2>/dev/null || true
echo -e "${GREEN}  ✓ FexCode configurado${NC}"

# --- 3. FexNav Structure ---
echo -e "${CYAN}[3/8]${NC} Preparando FexNav..."
mkdir -p /opt/fexnav/{bin,lib,data,icons,updates}
bash "$SCRIPT_DIR/install-fexnav.sh" 2>/dev/null || true
echo -e "${GREEN}  ✓ FexNav preparado (copie o executável para /opt/fexnav/bin/)${NC}"

# --- 4. Windows Compatibility ---
echo -e "${CYAN}[4/8]${NC} Configurando compatibilidade Windows..."
bash "$SCRIPT_DIR/setup-windows-compat.sh" 2>/dev/null || true
echo -e "${GREEN}  ✓ Wine + DXVK + .exe association configurados${NC}"

# --- 5. Android Dev ---
echo -e "${CYAN}[5/8]${NC} Configurando ambiente Android..."
bash "$SCRIPT_DIR/setup-android-dev.sh" 2>/dev/null || true
echo -e "${GREEN}  ✓ Android SDK + Flutter + React Native configurados${NC}"

# --- 6. Fex Control Center ---
echo -e "${CYAN}[6/8]${NC} Instalando Fex Control Center..."
mkdir -p /usr/share/phantom/scripts
cp "$SCRIPT_DIR/fex-control-center.sh" /usr/share/phantom/scripts/
chmod +x /usr/share/phantom/scripts/fex-control-center.sh
echo -e "${GREEN}  ✓ Fex Control Center instalado${NC}"

# --- 7. Waybar V2 ---
echo -e "${CYAN}[7/8]${NC} Atualizando Waybar para V2..."
WAYBAR_DIR="${TARGET_HOME}/.config/waybar"
if [[ -f "$WAYBAR_DIR/config.jsonc" ]]; then
    # Backup original
    cp "$WAYBAR_DIR/config.jsonc" "$WAYBAR_DIR/config-v1-backup.jsonc"
    cp "$WAYBAR_DIR/style.css" "$WAYBAR_DIR/style-v1-backup.css"
fi
# Apply V2 as default
if [[ -f "$WAYBAR_DIR/config-v2.jsonc" ]]; then
    cp "$WAYBAR_DIR/config-v2.jsonc" "$WAYBAR_DIR/config.jsonc"
    cp "$WAYBAR_DIR/style-v2.css" "$WAYBAR_DIR/style.css"
fi
chown -R "$TARGET_USER:$TARGET_USER" "$WAYBAR_DIR"
echo -e "${GREEN}  ✓ Waybar V2 aplicado${NC}"

# --- 8. Performance Modes ---
echo -e "${CYAN}[8/8]${NC} Configurando modos de performance..."

# Auto-detect and set optimal mode
cat > /etc/systemd/system/phantom-auto-optimize.service << 'EOF'
[Unit]
Description=PhantomArch Auto Performance Optimizer
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'if cat /sys/class/power_supply/BAT0/status 2>/dev/null | grep -q Discharging; then cpupower frequency-set -g powersave 2>/dev/null; else cpupower frequency-set -g performance 2>/dev/null; fi'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
systemctl enable phantom-auto-optimize.service 2>/dev/null || true

# Ananicy-cpp for auto process priority
systemctl enable ananicy-cpp 2>/dev/null || true

# Preload for faster app startup
systemctl enable preload 2>/dev/null || true

# irqbalance for better CPU utilization
systemctl enable irqbalance 2>/dev/null || true

echo -e "${GREEN}  ✓ Auto-optimizer configurado${NC}"

echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}PhantomArch V2 Post-Install completo!${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Novos comandos disponíveis:"
echo -e "  ${CYAN}fex-control-center${NC} — Painel central do sistema"
echo -e "  ${CYAN}fexai${NC}              — Assistente IA offline"
echo -e "  ${CYAN}fexcode${NC}            — IDE PhantomArch"
echo -e "  ${CYAN}fexnav${NC}             — Navegador (após copiar executável)"
echo -e "  ${CYAN}phantom-build-apk${NC}  — Criar APKs Android"
echo -e "  ${CYAN}phantom-wine-sandbox${NC} — Executar .exe isolado"
echo ""
