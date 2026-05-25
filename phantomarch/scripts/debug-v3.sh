#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch V3 — Debug & Diagnostic Tool                    ║
# ║  Diagnóstico completo do sistema                             ║
# ╚══════════════════════════════════════════════════════════════╝

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPORT="/tmp/phantomarch-debug-$(date +%Y%m%d_%H%M%S).txt"

section() {
    echo "" | tee -a "$REPORT"
    echo "══════════════════════════════════════" | tee -a "$REPORT"
    echo " $1" | tee -a "$REPORT"
    echo "══════════════════════════════════════" | tee -a "$REPORT"
}

info() { echo "  $1" | tee -a "$REPORT"; }

echo -e "${PURPLE}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   PhantomArch V3 — Debug & Diagnostic    ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

echo "Gerando relatório de diagnóstico..."
echo "PhantomArch Debug Report — $(date)" > "$REPORT"

# --- System Info ---
section "SISTEMA"
info "Kernel: $(uname -r)"
info "Arch: $(uname -m)"
info "Uptime: $(uptime -p)"
info "Hostname: $(hostname)"
info "User: $(whoami)"

# --- Hardware ---
section "HARDWARE"
info "CPU: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
info "Cores: $(nproc)"
info "RAM: $(free -h | awk 'NR==2{printf "%s / %s (%.0f%% usado)", $3, $2, $3/$2*100}')"
info "Swap: $(free -h | awk 'NR==3{print $3, "/", $2}')"
info "Disk: $(df -h / | awk 'NR==2{printf "%s / %s (%s usado)", $3, $2, $5}')"

# --- GPU ---
section "GPU"
if lspci | grep -qi nvidia; then
    info "GPU: NVIDIA"
    nvidia-smi --query-gpu=name,driver_version,temperature.gpu,utilization.gpu --format=csv,noheader 2>/dev/null | while read -r line; do
        info "  $line"
    done
    info "NVIDIA modules: $(lsmod | grep nvidia | awk '{print $1}' | tr '\n' ' ')"
elif lspci | grep -qi amd; then
    info "GPU: AMD"
    info "  Driver: $(lspci -k | grep -A2 VGA | grep 'Kernel driver' | awk '{print $NF}')"
else
    info "GPU: Intel/Other"
fi
info "Vulkan: $(vulkaninfo --summary 2>/dev/null | grep 'deviceName' | cut -d= -f2 | xargs || echo 'NÃO DISPONÍVEL')"
info "OpenGL: $(glxinfo 2>/dev/null | grep 'OpenGL renderer' | cut -d: -f2 | xargs || echo 'N/A')"

# --- Audio ---
section "ÁUDIO"
info "PipeWire: $(systemctl --user is-active pipewire 2>/dev/null || echo 'inativo')"
info "WirePlumber: $(systemctl --user is-active wireplumber 2>/dev/null || echo 'inativo')"
info "Dispositivos: $(pactl list sinks short 2>/dev/null | wc -l) sinks"
pactl list sinks short 2>/dev/null | while read -r line; do
    info "  $line"
done

# --- Network ---
section "REDE"
info "NetworkManager: $(systemctl is-active NetworkManager 2>/dev/null)"
info "IP: $(hostname -I 2>/dev/null | awk '{print $1}')"
info "DNS: $(grep nameserver /etc/resolv.conf 2>/dev/null | head -2 | awk '{print $2}' | tr '\n' ' ')"
info "Internet: $(ping -c1 -W2 1.1.1.1 &>/dev/null && echo 'OK' || echo 'SEM CONEXÃO')"

# --- Services ---
section "SERVIÇOS"
info "Failed services:"
systemctl --failed --no-legend 2>/dev/null | while read -r line; do
    info "  ⚠ $line"
done
if [[ -z "$(systemctl --failed --no-legend 2>/dev/null)" ]]; then
    info "  Nenhum serviço falhou"
fi

# --- Desktop ---
section "DESKTOP"
info "Session: ${XDG_SESSION_TYPE:-unknown}"
info "Desktop: ${XDG_CURRENT_DESKTOP:-unknown}"
info "Display: ${DISPLAY:-}${WAYLAND_DISPLAY:+ (Wayland: $WAYLAND_DISPLAY)}"
info "SDDM: $(systemctl is-active sddm 2>/dev/null || echo 'inativo')"
info "Hyprland: $(pgrep -x Hyprland &>/dev/null && echo 'rodando' || echo 'não rodando')"
info "KDE: $(pgrep -x plasmashell &>/dev/null && echo 'rodando' || echo 'não rodando')"

# --- Wine ---
section "WINE"
info "Wine: $(wine --version 2>/dev/null || echo 'não instalado')"
info "DXVK: $(ls /usr/lib/wine/dxvk/*.dll 2>/dev/null | wc -l) DLLs"
info "Wine prefix: $(ls -d /home/*/.wine 2>/dev/null | tr '\n' ' ' || echo 'nenhum')"

# --- FexNav ---
section "FEXNAV"
if [[ -d /opt/fexnav ]]; then
    info "Diretório: OK"
    info "Executável: $(ls /opt/fexnav/bin/FexNav* /opt/fexnav/bin/fexnav* 2>/dev/null | head -1 || echo 'NÃO ENCONTRADO')"
    info "Espaço: $(du -sh /opt/fexnav 2>/dev/null | awk '{print $1}')"
else
    info "FexNav: NÃO INSTALADO"
fi

# --- FexAI ---
section "FEXAI"
info "Ollama: $(systemctl is-active ollama 2>/dev/null || echo 'inativo')"
info "Modelos: $(ollama list 2>/dev/null | tail -n+2 | awk '{print $1}' | tr '\n' ' ' || echo 'nenhum')"
info "FexAI server: $(curl -s http://localhost:7860/health 2>/dev/null | grep -o '"status":"[^"]*"' || echo 'offline')"

# --- FexCode ---
section "FEXCODE"
info "Launcher: $(test -x /usr/bin/fexcode && echo 'OK' || echo 'NÃO ENCONTRADO')"
info "Code-OSS: $(code --version 2>/dev/null | head -1 || echo 'não instalado')"

# --- Boot ---
section "BOOT"
info "Bootloader: $(test -d /boot/grub && echo 'GRUB' || echo 'systemd-boot ou outro')"
info "Kernel cmdline: $(cat /proc/cmdline 2>/dev/null)"
info "Plymouth: $(plymouth --ping 2>/dev/null && echo 'ativo' || echo 'inativo')"
info "Boot errors (últimos):"
journalctl -b -p err --no-pager -n 10 2>/dev/null | tail -8 | while read -r line; do
    info "  $line"
done

# --- Performance ---
section "PERFORMANCE"
info "Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'N/A')"
info "GameMode: $(gamemoded -s 2>/dev/null && echo 'disponível' || echo 'indisponível')"
info "zRAM: $(swapon --show=NAME,SIZE 2>/dev/null | grep zram || echo 'inativo')"
info "earlyoom: $(systemctl is-active earlyoom 2>/dev/null || echo 'inativo')"
info "vm.swappiness: $(sysctl -n vm.swappiness 2>/dev/null)"
info "vm.max_map_count: $(sysctl -n vm.max_map_count 2>/dev/null)"

# --- Summary ---
section "RESUMO"
ERRORS_COUNT=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
info "Serviços com falha: $ERRORS_COUNT"
info "Relatório salvo em: $REPORT"

echo ""
echo -e "${GREEN}Relatório completo salvo em:${NC} $REPORT"
echo -e "Para corrigir automaticamente: ${CYAN}sudo auto-fix${NC}"
