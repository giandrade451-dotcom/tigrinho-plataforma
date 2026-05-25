#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch Optimizer — Ferramenta de Tuning Avançado       ║
# ║  Ajuste fino de performance para gaming e desenvolvimento    ║
# ╚══════════════════════════════════════════════════════════════╝

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_menu() {
    clear
    echo -e "${PURPLE}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║        👻 PhantomArch Optimizer v1.0                 ║"
    echo "  ║        Sistema de Tuning Avançado                    ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC} 🎮 Aplicar perfil GAMING (max performance)"
    echo -e "  ${CYAN}[2]${NC} 💻 Aplicar perfil DEVELOPMENT (balanced)"
    echo -e "  ${CYAN}[3]${NC} 🔋 Aplicar perfil BATTERY SAVER (laptop)"
    echo -e "  ${CYAN}[4]${NC} ⚡ Otimizar GPU (auto-detect)"
    echo -e "  ${CYAN}[5]${NC} 🧹 Limpar sistema (cache, logs, orphans)"
    echo -e "  ${CYAN}[6]${NC} 📊 Benchmark rápido"
    echo -e "  ${CYAN}[7]${NC} 🔄 Atualizar sistema completo"
    echo -e "  ${CYAN}[8]${NC} 🛡️  Hardening de segurança"
    echo -e "  ${CYAN}[9]${NC} 📋 Informações do sistema"
    echo -e "  ${CYAN}[0]${NC} 🚪 Sair"
    echo ""
    echo -ne "  ${PURPLE}Escolha [0-9]:${NC} "
}

profile_gaming() {
    echo -e "\n${CYAN}Aplicando perfil GAMING...${NC}\n"

    # CPU Governor
    if command -v cpupower &>/dev/null; then
        sudo cpupower frequency-set -g performance 2>/dev/null
        echo -e "  ${GREEN}✓${NC} CPU Governor: performance"
    fi

    # GameMode
    if command -v gamemoded &>/dev/null; then
        gamemoded -d 2>/dev/null
        echo -e "  ${GREEN}✓${NC} GameMode: ativado"
    fi

    # Disable compositing effects (save GPU for games)
    if command -v hyprctl &>/dev/null; then
        hyprctl keyword decoration:blur:enabled false 2>/dev/null
        hyprctl keyword animations:enabled false 2>/dev/null
        echo -e "  ${GREEN}✓${NC} Blur e animações: desativados"
    fi

    # I/O Scheduler
    for disk in /sys/block/sd*/queue/scheduler /sys/block/nvme*/queue/scheduler; do
        [[ -f "$disk" ]] && echo "none" | sudo tee "$disk" >/dev/null 2>&1
    done
    echo -e "  ${GREEN}✓${NC} I/O Scheduler: none (mínima latência)"

    # Disable power management
    echo -e "  ${GREEN}✓${NC} Perfil GAMING aplicado!"
    echo -e "  ${YELLOW}Nota: Reinicie o jogo para aplicar todas as mudanças${NC}"
}

profile_development() {
    echo -e "\n${CYAN}Aplicando perfil DEVELOPMENT...${NC}\n"

    # CPU Governor balanced
    if command -v cpupower &>/dev/null; then
        sudo cpupower frequency-set -g schedutil 2>/dev/null
        echo -e "  ${GREEN}✓${NC} CPU Governor: schedutil (balanced)"
    fi

    # GameMode off
    if command -v gamemoded &>/dev/null; then
        gamemoded -r 2>/dev/null
        echo -e "  ${GREEN}✓${NC} GameMode: desativado"
    fi

    # Re-enable compositing
    if command -v hyprctl &>/dev/null; then
        hyprctl keyword decoration:blur:enabled true 2>/dev/null
        hyprctl keyword animations:enabled true 2>/dev/null
        echo -e "  ${GREEN}✓${NC} Blur e animações: reativados"
    fi

    echo -e "  ${GREEN}✓${NC} Perfil DEVELOPMENT aplicado!"
}

profile_battery() {
    echo -e "\n${CYAN}Aplicando perfil BATTERY SAVER...${NC}\n"

    if command -v cpupower &>/dev/null; then
        sudo cpupower frequency-set -g powersave 2>/dev/null
        echo -e "  ${GREEN}✓${NC} CPU Governor: powersave"
    fi

    if command -v gamemoded &>/dev/null; then
        gamemoded -r 2>/dev/null
    fi

    # Reduce screen brightness
    if command -v brightnessctl &>/dev/null; then
        brightnessctl set 40% 2>/dev/null
        echo -e "  ${GREEN}✓${NC} Brilho: 40%"
    fi

    echo -e "  ${GREEN}✓${NC} Perfil BATTERY SAVER aplicado!"
}

optimize_gpu() {
    echo -e "\n${CYAN}Otimizando GPU...${NC}\n"

    if lspci | grep -qi nvidia; then
        echo -e "  ${PURPLE}GPU NVIDIA detectada${NC}"
        if command -v nvidia-smi &>/dev/null; then
            # Set performance mode
            sudo nvidia-smi -pm 1 2>/dev/null
            sudo nvidia-smi --auto-boost-default=ENABLED 2>/dev/null
            nvidia-smi --query-gpu=name,temperature.gpu,power.draw,clocks.gr,clocks.mem --format=csv,noheader 2>/dev/null
            echo -e "  ${GREEN}✓${NC} NVIDIA otimizada"
        fi
    fi

    if lspci | grep -qi "amd.*radeon\|amd.*vga"; then
        echo -e "  ${PURPLE}GPU AMD detectada${NC}"
        # Set high performance
        for card in /sys/class/drm/card*/device/power_dpm_force_performance_level; do
            [[ -f "$card" ]] && echo "high" | sudo tee "$card" >/dev/null 2>&1
        done
        echo -e "  ${GREEN}✓${NC} AMD GPU: performance level high"
    fi
}

clean_system() {
    echo -e "\n${CYAN}Limpando sistema...${NC}\n"

    # Package cache
    echo -e "  Limpando cache de pacotes..."
    sudo pacman -Sc --noconfirm 2>/dev/null
    echo -e "  ${GREEN}✓${NC} Cache do pacman limpo"

    # Orphan packages
    ORPHANS=$(pacman -Qdtq 2>/dev/null)
    if [[ -n "$ORPHANS" ]]; then
        echo "$ORPHANS" | sudo pacman -Rns --noconfirm - 2>/dev/null
        echo -e "  ${GREEN}✓${NC} Pacotes órfãos removidos"
    else
        echo -e "  ${GREEN}✓${NC} Sem pacotes órfãos"
    fi

    # Journal logs (keep last 3 days)
    sudo journalctl --vacuum-time=3d 2>/dev/null
    echo -e "  ${GREEN}✓${NC} Logs do journal limpos (3 dias)"

    # Tmp files
    sudo rm -rf /tmp/* 2>/dev/null
    echo -e "  ${GREEN}✓${NC} Arquivos temporários removidos"

    # Trash
    rm -rf ~/.local/share/Trash/* 2>/dev/null
    echo -e "  ${GREEN}✓${NC} Lixeira limpa"

    # Show space saved
    echo ""
    df -h / | awk 'NR==2 {printf "  Espaço disponível: %s de %s (%s usado)\n", $4, $2, $5}'
}

quick_benchmark() {
    echo -e "\n${CYAN}Benchmark rápido do sistema...${NC}\n"

    # CPU
    echo -e "  ${PURPLE}CPU:${NC}"
    echo -n "    Cores: "; nproc
    echo -n "    Modelo: "; grep "model name" /proc/cpuinfo | head -1 | awk -F': ' '{print $2}'
    echo -n "    Freq atual: "; cat /proc/cpuinfo | grep "cpu MHz" | head -1 | awk -F': ' '{printf "%.0f MHz\n", $2}'

    # RAM
    echo -e "\n  ${PURPLE}RAM:${NC}"
    free -h | awk 'NR==2 {printf "    Total: %s | Usada: %s | Livre: %s\n", $2, $3, $4}'

    # Disk
    echo -e "\n  ${PURPLE}Disco:${NC}"
    echo -n "    Speed test (write): "
    dd if=/dev/zero of=/tmp/bench_test bs=1M count=256 conv=fdatasync 2>&1 | grep -oP '[\d.]+ [GMKT]B/s'
    rm -f /tmp/bench_test

    # GPU
    echo -e "\n  ${PURPLE}GPU:${NC}"
    if command -v vulkaninfo &>/dev/null; then
        vulkaninfo --summary 2>/dev/null | grep -E "deviceName|driverInfo" | awk -F'= ' '{print "    " $2}'
    fi

    # Network
    echo -e "\n  ${PURPLE}Rede:${NC}"
    echo -n "    Latência (archlinux.org): "
    ping -c 3 archlinux.org 2>/dev/null | tail -1 | awk -F'/' '{print $5 " ms"}'
}

update_system() {
    echo -e "\n${CYAN}Atualizando sistema completo...${NC}\n"

    echo -e "  ${PURPLE}[1/3]${NC} Atualizando mirrors..."
    sudo reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist 2>/dev/null

    echo -e "  ${PURPLE}[2/3]${NC} Atualizando pacotes oficiais..."
    sudo pacman -Syu --noconfirm

    echo -e "  ${PURPLE}[3/3]${NC} Atualizando AUR..."
    if command -v paru &>/dev/null; then
        paru -Sua --noconfirm 2>/dev/null
    elif command -v yay &>/dev/null; then
        yay -Sua --noconfirm 2>/dev/null
    fi

    echo -e "\n  ${GREEN}✓${NC} Sistema atualizado!"
}

harden_system() {
    echo -e "\n${CYAN}Aplicando hardening de segurança...${NC}\n"

    # Firewall
    if command -v ufw &>/dev/null; then
        sudo ufw default deny incoming 2>/dev/null
        sudo ufw default allow outgoing 2>/dev/null
        sudo ufw enable 2>/dev/null
        echo -e "  ${GREEN}✓${NC} Firewall UFW: ativado (deny incoming)"
    fi

    # Fail2ban style protection
    echo -e "  ${GREEN}✓${NC} AppArmor: $(aa-status 2>/dev/null | head -1 || echo 'verificar')"

    # DNS privacy
    echo -e "  ${YELLOW}!${NC} Considere configurar DNS over HTTPS (DoH)"
    echo -e "  ${YELLOW}!${NC} Recomendado: Quad9 (9.9.9.9) ou Cloudflare (1.1.1.1)"

    echo -e "\n  ${GREEN}✓${NC} Hardening básico aplicado!"
}

system_info() {
    echo -e "\n${CYAN}Informações do Sistema PhantomArch${NC}\n"
    echo -e "  ${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    echo -e "  ${CYAN}OS:${NC}      PhantomArch 1.0 Phantom"
    echo -e "  ${CYAN}Kernel:${NC}  $(uname -r)"
    echo -e "  ${CYAN}Arch:${NC}    $(uname -m)"
    echo -e "  ${CYAN}Uptime:${NC}  $(uptime -p)"
    echo -e "  ${CYAN}Shell:${NC}   $SHELL"
    echo -e "  ${CYAN}DE:${NC}      ${XDG_CURRENT_DESKTOP:-N/A}"
    echo -e "  ${CYAN}CPU:${NC}     $(grep 'model name' /proc/cpuinfo | head -1 | awk -F': ' '{print $2}')"
    echo -e "  ${CYAN}RAM:${NC}     $(free -h | awk 'NR==2{print $2}')"
    echo -e "  ${CYAN}GPU:${NC}     $(lspci | grep -i 'vga\|3d' | awk -F': ' '{print $2}' | head -1)"
    echo -e "  ${CYAN}Disk:${NC}    $(df -h / | awk 'NR==2{printf "%s / %s (%s)", $3, $2, $5}')"

    echo -e "\n  ${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Main loop
while true; do
    show_menu
    read -r choice
    case $choice in
        1) profile_gaming ;;
        2) profile_development ;;
        3) profile_battery ;;
        4) optimize_gpu ;;
        5) clean_system ;;
        6) quick_benchmark ;;
        7) update_system ;;
        8) harden_system ;;
        9) system_info ;;
        0) echo -e "\n${PURPLE}👻 Até mais!${NC}\n"; exit 0 ;;
        *) echo -e "\n${RED}Opção inválida!${NC}" ;;
    esac
    echo ""
    echo -ne "  ${CYAN}Pressione ENTER para continuar...${NC}"
    read -r
done
