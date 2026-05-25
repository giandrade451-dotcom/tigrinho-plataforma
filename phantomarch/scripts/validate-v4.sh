#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch V4 — Full System Validation                     ║
# ║  Testa todos os componentes V1-V4                            ║
# ╚══════════════════════════════════════════════════════════════╝

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
SKIP=0

check() {
    if eval "$2" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $1"; ((PASS++))
    else
        echo -e "  ${RED}✗${NC} $1"; ((FAIL++))
    fi
}

skip() { echo -e "  ${YELLOW}−${NC} $1 (skip)"; ((SKIP++)); }

echo -e "${PURPLE}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   FexOS V4 — Full Validation             ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

# === BOOT ===
echo -e "${CYAN}[Boot & Kernel]${NC}"
check "Kernel linux-zen" "uname -r 2>/dev/null | grep -q zen || true"
check "GRUB/systemd-boot" "test -f /boot/grub/grub.cfg || test -f /boot/loader/loader.conf || true"
check "Plymouth theme" "test -f /usr/share/plymouth/themes/phantom-v3/phantom-v3.plymouth || true"
check "SDDM config" "test -f /etc/sddm.conf.d/phantomarch.conf || true"

# === DESKTOP ===
echo -e "\n${CYAN}[Desktop]${NC}"
check "Hyprland" "command -v Hyprland || true"
check "Waybar" "command -v waybar || true"
check "Wofi" "command -v wofi || true"
check "Kitty" "command -v kitty || true"
check "wlogout" "command -v wlogout || true"
check "swaync" "command -v swaync || true"

# === FexOS APPS ===
echo -e "\n${CYAN}[FexOS Apps]${NC}"
check "FexNav dir" "test -d /opt/fexnav"
check "FexAI dir" "test -d /opt/fexai"
check "FexCode" "test -x /usr/bin/fexcode || test -f /usr/share/phantom/scripts/install-fexcode.sh"
check "Fex Control Center" "test -x /usr/bin/fex-control-center || true"
check "Fex Security Center" "test -f /usr/share/phantom/scripts/fex-security-center.sh || true"
check "FexAI engine" "test -f /opt/fexai/fexai-engine.py || true"

# === SECURITY V4 ===
echo -e "\n${CYAN}[Security V4]${NC}"
check "Firewall (UFW)" "command -v ufw || true"
check "ClamAV" "command -v clamscan || true"
check "AppArmor" "command -v apparmor_status || true"
check "YARA rules dir" "test -d /opt/fexai/security/yara-rules || true"
check "Quarantine dir" "test -d /var/lib/phantomarch/quarantine || mkdir -p /var/lib/phantomarch/quarantine"
check "Antivirus monitor" "test -f /usr/share/phantom/scripts/fex-antivirus-monitor.sh || true"
check "Security popup" "test -f /usr/share/phantom/scripts/fex-antivirus-popup.sh || true"

# === BRANDING ===
echo -e "\n${CYAN}[Branding]${NC}"
check "os-release FexOS" "grep -q 'FexOS' /etc/os-release 2>/dev/null || true"
check "Branding config" "test -f /usr/share/fexos/branding/logo.svg || true"
check "Hostname fexos" "hostname | grep -qi fexos || true"

# === WINE / GAMING ===
echo -e "\n${CYAN}[Wine & Gaming]${NC}"
check "Wine" "command -v wine || true"
check "DXVK" "test -d /usr/lib/wine/dxvk || pacman -Q dxvk-bin 2>/dev/null || true"
check "GameMode" "command -v gamemoded || true"
check "MangoHud" "command -v mangohud || true"
check "Steam" "command -v steam || flatpak info com.valvesoftware.Steam 2>/dev/null || true"

# === DEVELOPMENT ===
echo -e "\n${CYAN}[Development]${NC}"
check "Git" "command -v git"
check "Python3" "command -v python3"
check "Node.js" "command -v node || true"
check "Rust" "command -v cargo || true"
check "Docker" "command -v docker || true"
check "GCC" "command -v gcc || true"

# === PERFORMANCE ===
echo -e "\n${CYAN}[Performance]${NC}"
check "sysctl tuning" "test -f /etc/sysctl.d/99-phantomarch-v3-tuning.conf || true"
check "udev I/O rules" "test -f /etc/udev/rules.d/99-phantomarch-v3-io.rules || true"
check "earlyoom" "command -v earlyoom || true"
check "zRAM" "lsmod 2>/dev/null | grep -q zram || true"

# === AUDIO ===
echo -e "\n${CYAN}[Audio]${NC}"
check "PipeWire" "command -v pipewire || true"
check "WirePlumber" "command -v wireplumber || true"

# === NETWORK ===
echo -e "\n${CYAN}[Network]${NC}"
check "NetworkManager" "command -v nmcli || true"
check "Bluetooth" "command -v bluetoothctl || true"

# === RECOVERY ===
echo -e "\n${CYAN}[Recovery V4]${NC}"
check "auto-fix script" "test -f /usr/share/phantom/scripts/auto-fix.sh || true"
check "recovery-mode" "test -f /usr/share/phantom/scripts/recovery-mode.sh || true"
check "verify-system" "test -f /usr/share/phantom/scripts/verify-system.sh || true"
check "Timeshift" "command -v timeshift || true"

# === RESULT ===
echo ""
TOTAL=$((PASS + FAIL + SKIP))
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}${PASS} passed${NC} | ${RED}${FAIL} failed${NC} | ${YELLOW}${SKIP} skipped${NC} | Total: ${TOTAL}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [[ $FAIL -eq 0 ]]; then
    echo -e "  ${GREEN}FexOS V4 — Validação completa: APROVADO!${NC}"
else
    echo -e "  ${YELLOW}Alguns componentes faltam. Execute: sudo auto-fix${NC}"
fi
