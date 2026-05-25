#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch Welcome — Checklist de Performance              ║
# ╚══════════════════════════════════════════════════════════════╝

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

clear
echo -e "${PURPLE}"
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║                                                      ║"
echo "  ║          👻 Welcome to PhantomArch 1.0               ║"
echo "  ║     Ghost in the Machine — Máxima Performance        ║"
echo "  ║                                                      ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

check_pass() { echo -e "  ${GREEN}[✓]${NC} $1"; }
check_fail() { echo -e "  ${RED}[✗]${NC} $1 — ${YELLOW}$2${NC}"; }
check_warn() { echo -e "  ${YELLOW}[!]${NC} $1"; }

echo -e "${CYAN}━━━ Checklist de Performance ━━━${NC}"
echo ""

# 1. Kernel
echo -e "${PURPLE}▸ Kernel${NC}"
KERNEL=$(uname -r)
if echo "$KERNEL" | grep -qi "zen"; then
    check_pass "Kernel Linux Zen: $KERNEL"
elif echo "$KERNEL" | grep -qi "xanmod"; then
    check_pass "Kernel XanMod: $KERNEL"
else
    check_warn "Kernel padrão: $KERNEL (considere linux-zen ou linux-xanmod)"
fi

# 2. GPU
echo ""
echo -e "${PURPLE}▸ GPU${NC}"
if lspci | grep -qi nvidia; then
    if command -v nvidia-smi &>/dev/null; then
        NVIDIA_VER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1)
        check_pass "NVIDIA Driver: $NVIDIA_VER"
    else
        check_fail "NVIDIA detectada mas driver não instalado" "sudo pacman -S nvidia-dkms"
    fi
fi
if lspci | grep -qi "amd.*radeon\|amd.*vga"; then
    if vulkaninfo 2>/dev/null | grep -qi "radv"; then
        check_pass "AMD GPU: Mesa RADV Vulkan OK"
    else
        check_warn "AMD GPU detectada — verificar drivers Vulkan"
    fi
fi

# 3. Vulkan
echo ""
echo -e "${PURPLE}▸ Vulkan${NC}"
if command -v vulkaninfo &>/dev/null; then
    VK_GPU=$(vulkaninfo --summary 2>/dev/null | grep "deviceName" | head -1 | awk -F'= ' '{print $2}')
    if [[ -n "$VK_GPU" ]]; then
        check_pass "Vulkan: $VK_GPU"
    else
        check_fail "Vulkan não funcional" "verificar drivers GPU"
    fi
else
    check_fail "vulkaninfo não encontrado" "sudo pacman -S vulkan-tools"
fi

# 4. Gaming Tools
echo ""
echo -e "${PURPLE}▸ Gaming${NC}"
command -v gamemoded &>/dev/null && check_pass "GameMode instalado" || check_fail "GameMode" "sudo pacman -S gamemode"
command -v gamescope &>/dev/null && check_pass "Gamescope instalado" || check_fail "Gamescope" "sudo pacman -S gamescope"
command -v mangohud &>/dev/null && check_pass "MangoHud instalado" || check_fail "MangoHud" "sudo pacman -S mangohud"
command -v steam &>/dev/null && check_pass "Steam instalado" || check_warn "Steam não encontrado"
command -v lutris &>/dev/null && check_pass "Lutris instalado" || check_warn "Lutris não encontrado"

# 5. System
echo ""
echo -e "${PURPLE}▸ Sistema${NC}"

# vm.max_map_count
MAP_COUNT=$(sysctl -n vm.max_map_count 2>/dev/null)
if [[ "$MAP_COUNT" -ge 1048576 ]]; then
    check_pass "vm.max_map_count = $MAP_COUNT"
else
    check_fail "vm.max_map_count = $MAP_COUNT (baixo)" "echo 'vm.max_map_count=2147483642' | sudo tee /etc/sysctl.d/99-gaming.conf"
fi

# Swappiness
SWAPPINESS=$(sysctl -n vm.swappiness 2>/dev/null)
if [[ "$SWAPPINESS" -le 20 ]]; then
    check_pass "vm.swappiness = $SWAPPINESS"
else
    check_warn "vm.swappiness = $SWAPPINESS (considere reduzir para 10)"
fi

# ZRAM
if swapon --show | grep -q "zram"; then
    ZRAM_SIZE=$(swapon --show | grep zram | awk '{print $3}')
    check_pass "ZRAM ativo: $ZRAM_SIZE"
else
    check_warn "ZRAM não ativo"
fi

# 6. Audio
echo ""
echo -e "${PURPLE}▸ Áudio${NC}"
if pgrep -x pipewire &>/dev/null; then
    check_pass "PipeWire ativo"
else
    check_fail "PipeWire não está rodando" "systemctl --user start pipewire"
fi
if pgrep -x wireplumber &>/dev/null; then
    check_pass "WirePlumber ativo"
else
    check_warn "WirePlumber não está rodando"
fi

# 7. Network
echo ""
echo -e "${PURPLE}▸ Rede${NC}"
TCP_CONGESTION=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
check_pass "TCP Congestion: $TCP_CONGESTION"

if ping -c 1 -W 2 archlinux.org &>/dev/null; then
    check_pass "Internet: conectado"
else
    check_warn "Sem acesso à internet"
fi

# 8. Desktop
echo ""
echo -e "${PURPLE}▸ Desktop${NC}"
if [[ "$XDG_CURRENT_DESKTOP" == "Hyprland" ]]; then
    check_pass "Desktop: Hyprland (Wayland)"
elif [[ "$XDG_CURRENT_DESKTOP" == "KDE" ]]; then
    check_pass "Desktop: KDE Plasma"
else
    check_warn "Desktop: ${XDG_CURRENT_DESKTOP:-desconhecido}"
fi

# Summary
echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${CYAN}Dicas:${NC}"
echo -e "  • Execute ${GREEN}phantom-optimizer${NC} para tuning avançado"
echo -e "  • Use ${GREEN}SUPER+G${NC} para toggle GameMode"
echo -e "  • Use ${GREEN}SUPER+SPACE${NC} para o launcher"
echo -e "  • Use ${GREEN}SUPER+RETURN${NC} para terminal"
echo ""
echo -e "  ${PURPLE}👻 Happy Gaming & Coding!${NC}"
echo ""
