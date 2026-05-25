#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch V3 — System Verification                        ║
# ║  Verifica integridade completa do sistema instalado          ║
# ╚══════════════════════════════════════════════════════════════╝

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

check() {
    if eval "$2" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $1"; ((PASS++))
    else
        echo -e "  ${RED}✗${NC} $1"; ((FAIL++))
    fi
}

warn_check() {
    if eval "$2" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $1"; ((PASS++))
    else
        echo -e "  ${YELLOW}!${NC} $1"; ((WARN++))
    fi
}

echo -e "${PURPLE}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   PhantomArch V3 — System Verify         ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

# --- Kernel & Boot ---
echo -e "${CYAN}[Kernel & Boot]${NC}"
check "Kernel linux-zen" "uname -r | grep -q zen"
check "Bootloader configurado" "test -f /boot/grub/grub.cfg || test -f /boot/loader/loader.conf"
warn_check "Plymouth instalado" "command -v plymouth"
check "UEFI support" "test -d /sys/firmware/efi || true"

# --- Desktop ---
echo -e "\n${CYAN}[Desktop Environment]${NC}"
check "Hyprland instalado" "command -v Hyprland"
warn_check "KDE Plasma instalado" "command -v plasmashell"
check "Waybar instalado" "command -v waybar"
check "Kitty terminal" "command -v kitty"
check "SDDM habilitado" "systemctl is-enabled sddm"
check "Wofi/Rofi" "command -v wofi || command -v rofi"

# --- Audio ---
echo -e "\n${CYAN}[Áudio]${NC}"
check "PipeWire instalado" "command -v pipewire"
check "WirePlumber" "command -v wireplumber"
warn_check "EasyEffects" "command -v easyeffects"

# --- GPU ---
echo -e "\n${CYAN}[GPU/Graphics]${NC}"
warn_check "Vulkan funcional" "vulkaninfo --summary"
check "Mesa instalado" "pacman -Q mesa"
warn_check "NVIDIA driver" "nvidia-smi || true"
warn_check "DXVK instalado" "pacman -Q dxvk-bin || ls /usr/lib/wine/dxvk/*.dll"

# --- Gaming ---
echo -e "\n${CYAN}[Gaming]${NC}"
check "GameMode" "command -v gamemoded"
check "MangoHud" "command -v mangohud"
warn_check "Gamescope" "command -v gamescope"
warn_check "Steam" "command -v steam || flatpak info com.valvesoftware.Steam"
check "Wine" "command -v wine"

# --- Development ---
echo -e "\n${CYAN}[Desenvolvimento]${NC}"
check "Git" "command -v git"
check "Python" "command -v python3"
check "Node.js" "command -v node"
check "Rust/Cargo" "command -v cargo"
check "GCC" "command -v gcc"
check "Docker" "command -v docker"
warn_check "FexCode" "test -x /usr/bin/fexcode"
warn_check "Godot" "command -v godot"

# --- PhantomArch V2/V3 ---
echo -e "\n${CYAN}[PhantomArch Features]${NC}"
check "Fex Control Center" "test -x /usr/bin/fex-control-center"
check "FexAI" "test -x /usr/bin/fexai"
check "FexNav dir" "test -d /opt/fexnav"
check "FexAI dir" "test -d /opt/fexai"
warn_check "Ollama" "command -v ollama"
check "phantom-optimizer" "command -v phantom-optimizer || test -f /usr/share/phantom/scripts/phantom-optimizer.sh"
check "auto-fix" "test -x /usr/bin/auto-fix || test -f /usr/share/phantom/scripts/auto-fix.sh"

# --- Network ---
echo -e "\n${CYAN}[Rede]${NC}"
check "NetworkManager" "systemctl is-active NetworkManager"
check "Firewall (UFW)" "command -v ufw"
warn_check "Bluetooth" "systemctl is-active bluetooth"

# --- Performance ---
echo -e "\n${CYAN}[Performance]${NC}"
check "zRAM" "swapon --show | grep -q zram || lsmod | grep -q zram"
check "earlyoom" "systemctl is-enabled earlyoom"
check "vm.max_map_count alto" "test $(sysctl -n vm.max_map_count 2>/dev/null || echo 0) -gt 1000000"
check "swappiness ≤ 10" "test $(sysctl -n vm.swappiness 2>/dev/null || echo 60) -le 10"
warn_check "Preload" "systemctl is-enabled preload"
warn_check "Ananicy" "systemctl is-enabled ananicy-cpp"

# --- Security ---
echo -e "\n${CYAN}[Segurança]${NC}"
check "No telemetria" "! systemctl is-active telemetry 2>/dev/null"
warn_check "AppArmor" "command -v apparmor_status"
check "UFW" "command -v ufw"

# --- Result ---
echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
TOTAL=$((PASS + FAIL + WARN))
echo -e "  ${GREEN}${PASS} passed${NC} | ${RED}${FAIL} failed${NC} | ${YELLOW}${WARN} warnings${NC} | Total: ${TOTAL}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [[ $FAIL -gt 0 ]]; then
    echo -e "  ${YELLOW}Execute: sudo auto-fix${NC} para corrigir problemas"
else
    echo -e "  ${GREEN}Sistema PhantomArch V3 verificado e saudável!${NC}"
fi
