#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  FexOS — Task Manager (Monitor de Sistema)                   ║
# ║  RAM, CPU, GPU, processos, I/O, rede                         ║
# ╚══════════════════════════════════════════════════════════════╝

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

show_header() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║            ⚡ FexOS Task Manager ⚡                          ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_cpu() {
    echo -e "${CYAN}━━━ CPU ━━━${NC}"
    # CPU usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' 2>/dev/null || echo "N/A")
    cpu_model=$(lscpu 2>/dev/null | grep "Model name" | cut -d: -f2 | xargs || echo "Unknown")
    cpu_cores=$(nproc 2>/dev/null || echo "?")
    cpu_freq=$(lscpu 2>/dev/null | grep "MHz" | head -1 | awk '{print $NF}' || echo "?")

    echo -e "  ${BOLD}Modelo:${NC}  $cpu_model"
    echo -e "  ${BOLD}Cores:${NC}   $cpu_cores"
    echo -e "  ${BOLD}Freq:${NC}    ${cpu_freq} MHz"
    echo -e "  ${BOLD}Uso:${NC}     ${GREEN}${cpu_usage}%${NC}"

    # CPU temperature
    if command -v sensors &>/dev/null; then
        temp=$(sensors 2>/dev/null | grep -i "package\|tctl\|cpu" | head -1 | grep -oP '\+\d+\.\d+' | head -1)
        if [[ -n "$temp" ]]; then
            echo -e "  ${BOLD}Temp:${NC}    ${temp}°C"
        fi
    fi
    echo ""
}

show_ram() {
    echo -e "${CYAN}━━━ RAM ━━━${NC}"
    mem_total=$(free -h | awk '/Mem:/ {print $2}')
    mem_used=$(free -h | awk '/Mem:/ {print $3}')
    mem_free=$(free -h | awk '/Mem:/ {print $4}')
    mem_percent=$(free | awk '/Mem:/ {printf "%.1f", $3/$2*100}')
    swap_total=$(free -h | awk '/Swap:/ {print $2}')
    swap_used=$(free -h | awk '/Swap:/ {print $3}')

    echo -e "  ${BOLD}Total:${NC}   $mem_total"
    echo -e "  ${BOLD}Usado:${NC}   $mem_used (${mem_percent}%)"
    echo -e "  ${BOLD}Livre:${NC}   $mem_free"
    echo -e "  ${BOLD}Swap:${NC}    $swap_used / $swap_total"

    # RAM bar
    bar_width=40
    filled=$(echo "$mem_percent $bar_width" | awk '{printf "%d", $1/100*$2}')
    bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=filled; i<bar_width; i++)); do bar+="░"; done

    if (( $(echo "$mem_percent > 80" | bc -l 2>/dev/null || echo 0) )); then
        echo -e "  [${RED}${bar}${NC}]"
    elif (( $(echo "$mem_percent > 60" | bc -l 2>/dev/null || echo 0) )); then
        echo -e "  [${YELLOW}${bar}${NC}]"
    else
        echo -e "  [${GREEN}${bar}${NC}]"
    fi
    echo ""
}

show_gpu() {
    echo -e "${CYAN}━━━ GPU ━━━${NC}"
    if command -v nvidia-smi &>/dev/null; then
        gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
        gpu_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader 2>/dev/null | head -1)
        gpu_mem=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader 2>/dev/null | head -1)
        gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null | head -1)
        echo -e "  ${BOLD}GPU:${NC}     $gpu_name"
        echo -e "  ${BOLD}Uso:${NC}     $gpu_usage"
        echo -e "  ${BOLD}VRAM:${NC}    $gpu_mem"
        echo -e "  ${BOLD}Temp:${NC}    ${gpu_temp}°C"
    elif [[ -d /sys/class/drm/card0 ]]; then
        gpu_name=$(lspci 2>/dev/null | grep -i "vga\|3d\|display" | head -1 | cut -d: -f3 | xargs || echo "Unknown GPU")
        echo -e "  ${BOLD}GPU:${NC}     $gpu_name"
        if [[ -f /sys/class/drm/card0/device/gpu_busy_percent ]]; then
            gpu_busy=$(cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null)
            echo -e "  ${BOLD}Uso:${NC}     ${gpu_busy}%"
        fi
    else
        echo -e "  ${YELLOW}GPU info não disponível${NC}"
    fi
    echo ""
}

show_processes() {
    echo -e "${CYAN}━━━ TOP PROCESSOS (por RAM) ━━━${NC}"
    echo -e "  ${BOLD}PID      RAM%   CPU%   PROCESSO${NC}"
    echo -e "  ─────────────────────────────────────────"
    ps aux --sort=-%mem 2>/dev/null | awk 'NR>1 && NR<=11 {printf "  %-8s %-6s %-6s %s\n", $2, $4"%", $3"%", $11}' || \
        echo "  (erro ao listar processos)"
    echo ""
}

show_disk() {
    echo -e "${CYAN}━━━ DISCO ━━━${NC}"
    df -h / /home 2>/dev/null | awk 'NR>1 {printf "  %-12s %s usado de %s (%s)\n", $6, $3, $2, $5}'
    echo ""
}

show_network() {
    echo -e "${CYAN}━━━ REDE ━━━${NC}"
    # Active interface
    iface=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $5; exit}' || echo "")
    if [[ -n "$iface" ]]; then
        ip_addr=$(ip -4 addr show "$iface" 2>/dev/null | grep inet | awk '{print $2}')
        echo -e "  ${BOLD}Interface:${NC} $iface"
        echo -e "  ${BOLD}IP:${NC}        $ip_addr"
    fi
    # Connection speed test (if available)
    if command -v iwconfig &>/dev/null && [[ "$iface" == wl* ]]; then
        wifi_speed=$(iwconfig "$iface" 2>/dev/null | grep "Bit Rate" | awk -F: '{print $2}' | awk '{print $1, $2}')
        if [[ -n "$wifi_speed" ]]; then
            echo -e "  ${BOLD}Wi-Fi:${NC}     $wifi_speed"
        fi
    fi
    echo ""
}

kill_process() {
    echo -ne "  ${BOLD}PID para encerrar:${NC} "
    read -r pid
    if [[ -n "$pid" ]]; then
        kill "$pid" 2>/dev/null && echo -e "  ${GREEN}✓ Processo $pid encerrado${NC}" || \
            echo -e "  ${RED}✗ Erro ao encerrar $pid${NC}"
    fi
}

# Main menu
interactive_mode() {
    while true; do
        show_header
        show_cpu
        show_ram
        show_gpu
        show_processes
        show_disk
        show_network

        echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "  [${CYAN}r${NC}] Atualizar  [${CYAN}k${NC}] Matar processo  [${CYAN}g${NC}] GameFPS  [${CYAN}q${NC}] Sair"
        echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -ne "  > "

        read -r -t 5 choice || choice="r"

        case "$choice" in
            q|Q) exit 0 ;;
            k|K) kill_process; sleep 1 ;;
            g|G) gamefps-mode toggle 2>/dev/null; sleep 2 ;;
            *) continue ;;
        esac
    done
}

# Entry points
case "${1:-}" in
    --once)
        show_header
        show_cpu
        show_ram
        show_gpu
        show_processes
        show_disk
        show_network
        ;;
    --json)
        echo "{"
        echo "  \"cpu_percent\": $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' 2>/dev/null || echo 0),"
        echo "  \"ram_percent\": $(free | awk '/Mem:/ {printf "%.1f", $3/$2*100}'),"
        echo "  \"ram_used_mb\": $(free -m | awk '/Mem:/ {print $3}'),"
        echo "  \"ram_total_mb\": $(free -m | awk '/Mem:/ {print $2}'),"
        echo "  \"uptime\": \"$(uptime -p 2>/dev/null || echo unknown)\""
        echo "}"
        ;;
    *)
        interactive_mode
        ;;
esac
