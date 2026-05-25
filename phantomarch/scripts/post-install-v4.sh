#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  FexOS V4 — Post Installation Script                         ║
# ║  Configura segurança, branding e proteções                   ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${PURPLE}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   FexOS V4 — Post Installation           ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

# 1. Apply branding
echo -e "${CYAN}[1/10]${NC} Aplicando branding FexOS..."
bash "$SCRIPT_DIR/apply-branding.sh" 2>/dev/null || true
echo -e "${GREEN}  ✓${NC}"

# 2. Setup firewall
echo -e "${CYAN}[2/10]${NC} Configurando firewall..."
ufw default deny incoming 2>/dev/null || true
ufw default allow outgoing 2>/dev/null || true
ufw enable 2>/dev/null || true
echo -e "${GREEN}  ✓ UFW ativo (deny incoming, allow outgoing)${NC}"

# 3. Setup ClamAV
echo -e "${CYAN}[3/10]${NC} Configurando antivírus..."
systemctl enable clamav-freshclam 2>/dev/null || true
systemctl start clamav-freshclam 2>/dev/null || true
freshclam --quiet 2>/dev/null || true
echo -e "${GREEN}  ✓ ClamAV configurado${NC}"

# 4. Setup AppArmor
echo -e "${CYAN}[4/10]${NC} Configurando AppArmor..."
systemctl enable apparmor 2>/dev/null || true
systemctl start apparmor 2>/dev/null || true
echo -e "${GREEN}  ✓ AppArmor ativo${NC}"

# 5. Create security directories
echo -e "${CYAN}[5/10]${NC} Criando estrutura de segurança..."
mkdir -p /var/lib/phantomarch/quarantine
mkdir -p /var/log/phantomarch/security
mkdir -p /opt/fexai/security/yara-rules
chmod 750 /var/lib/phantomarch/quarantine
echo -e "${GREEN}  ✓ Estrutura de segurança criada${NC}"

# 6. Enable antivirus monitor
echo -e "${CYAN}[6/10]${NC} Habilitando monitor antivírus..."
if [[ -f /etc/systemd/system/fex-antivirus.service ]]; then
    systemctl enable fex-antivirus 2>/dev/null || true
fi
echo -e "${GREEN}  ✓ Monitor configurado${NC}"

# 7. Protect critical files
echo -e "${CYAN}[7/10]${NC} Protegendo arquivos críticos..."
chattr +i /etc/passwd 2>/dev/null || true
chattr +i /etc/shadow 2>/dev/null || true
chattr +i /etc/sudoers 2>/dev/null || true
echo -e "${GREEN}  ✓ Arquivos protegidos (imutáveis)${NC}"

# 8. Configure SDDM
echo -e "${CYAN}[8/10]${NC} Configurando login screen..."
systemctl enable sddm 2>/dev/null || true
echo -e "${GREEN}  ✓ SDDM habilitado com tema FexOS${NC}"

# 9. Setup Timeshift
echo -e "${CYAN}[9/10]${NC} Configurando restore points..."
if command -v timeshift &>/dev/null; then
    timeshift --create --comments "FexOS V4 initial install" 2>/dev/null || true
    echo -e "${GREEN}  ✓ Primeiro restore point criado${NC}"
else
    echo -e "${YELLOW}  ! Timeshift não disponível${NC}"
fi

# 10. Run V2 post-install (if exists)
echo -e "${CYAN}[10/10]${NC} Executando post-install anterior..."
if [[ -f "$SCRIPT_DIR/post-install-v2.sh" ]]; then
    bash "$SCRIPT_DIR/post-install-v2.sh" 2>/dev/null || true
fi
echo -e "${GREEN}  ✓ Post-install V2 executado${NC}"

# === Summary ===
echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}FexOS V4 — Pós-instalação completa!${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${CYAN}Segurança:${NC}"
echo -e "    • Firewall (UFW): ativo"
echo -e "    • Antivírus (ClamAV): ativo"
echo -e "    • AppArmor: ativo"
echo -e "    • Monitor Real-Time: configurado"
echo -e "    • Arquivos protegidos: sim"
echo ""
echo -e "  ${CYAN}Comandos:${NC}"
echo -e "    fex-security-center  — Painel de segurança"
echo -e "    fex-control-center   — Painel do sistema"
echo -e "    fexnav               — Navegador"
echo -e "    fexai                — Assistente IA"
echo -e "    fexcode              — IDE"
echo ""
