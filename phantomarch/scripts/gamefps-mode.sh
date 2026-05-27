#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  FexOS — GameFPS Mode                                        ║
# ║  Foco TOTAL em FPS: elimina background, volta ao normal      ║
# ╚══════════════════════════════════════════════════════════════╝

STATE_FILE="/tmp/fexos-gamefps-active"
SAVED_PROCS="/tmp/fexos-gamefps-saved-procs"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Services to stop during gaming
STOP_SERVICES=(
    "bluetooth.service"
    "cups.service"
    "ModemManager.service"
    "NetworkManager-wait-online.service"
    "fstrim.timer"
    "man-db.timer"
    "phantom-updater.service"
)

# Processes to pause (SIGSTOP) during gaming
PAUSE_PROCS=(
    "tracker-miner"
    "baloo_file"
    "evolution-data"
    "gvfsd-metadata"
    "packagekitd"
    "fwupd"
    "snapd"
)

activate_gamefps() {
    if [[ -f "$STATE_FILE" ]]; then
        echo -e "${YELLOW}[GameFPS] Já está ativo!${NC}"
        return
    fi

    echo -e "${PURPLE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     ⚡ GameFPS Mode — ATIVANDO ⚡       ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════╝${NC}"
    echo ""

    # Save current state
    echo -n "" > "$SAVED_PROCS"

    # 1. Set CPU governor to performance
    echo -e "${CYAN}[1/8] CPU → Performance${NC}"
    for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "performance" | sudo tee "$gov" > /dev/null 2>&1
    done
    echo -e "  ${GREEN}✓${NC}"

    # 2. GPU performance mode
    echo -e "${CYAN}[2/8] GPU → Performance${NC}"
    # NVIDIA
    if command -v nvidia-smi &>/dev/null; then
        sudo nvidia-smi -pm 1 2>/dev/null
        sudo nvidia-smi --power-limit=300 2>/dev/null
        nvidia-settings -a "[gpu:0]/GPUPowerMizerMode=1" 2>/dev/null
    fi
    # AMD
    if [[ -f /sys/class/drm/card0/device/power_dpm_force_performance_level ]]; then
        echo "high" | sudo tee /sys/class/drm/card0/device/power_dpm_force_performance_level > /dev/null 2>&1
    fi
    echo -e "  ${GREEN}✓${NC}"

    # 3. Stop unnecessary services
    echo -e "${CYAN}[3/8] Parando serviços não-essenciais${NC}"
    for svc in "${STOP_SERVICES[@]}"; do
        sudo systemctl stop "$svc" 2>/dev/null && echo "  stopped: $svc" >> "$SAVED_PROCS"
    done
    echo -e "  ${GREEN}✓${NC}"

    # 4. Pause background processes
    echo -e "${CYAN}[4/8] Pausando processos background${NC}"
    for proc in "${PAUSE_PROCS[@]}"; do
        pids=$(pgrep -f "$proc" 2>/dev/null)
        if [[ -n "$pids" ]]; then
            echo "$pids" | while read pid; do
                sudo kill -STOP "$pid" 2>/dev/null && echo "paused:$pid:$proc" >> "$SAVED_PROCS"
            done
        fi
    done
    echo -e "  ${GREEN}✓${NC}"

    # 5. I/O scheduler optimization
    echo -e "${CYAN}[5/8] I/O → Gaming${NC}"
    for disk in /sys/block/sd*/queue/scheduler /sys/block/nvme*/queue/scheduler; do
        echo "none" | sudo tee "$disk" > /dev/null 2>&1
    done
    # Reduce swappiness
    sudo sysctl -w vm.swappiness=1 > /dev/null 2>&1
    sudo sysctl -w vm.vfs_cache_pressure=50 > /dev/null 2>&1
    echo -e "  ${GREEN}✓${NC}"

    # 6. Network optimization
    echo -e "${CYAN}[6/8] Rede → Low Latency${NC}"
    sudo sysctl -w net.ipv4.tcp_low_latency=1 > /dev/null 2>&1
    sudo sysctl -w net.ipv4.tcp_nodelay=1 > /dev/null 2>&1 || true
    echo -e "  ${GREEN}✓${NC}"

    # 7. Compositor tuning (reduce effects)
    echo -e "${CYAN}[7/8] Compositor → Gaming${NC}"
    if pgrep -x "hyprctl" &>/dev/null || pgrep -x "Hyprland" &>/dev/null; then
        hyprctl keyword animations:enabled false 2>/dev/null
        hyprctl keyword decoration:blur:enabled false 2>/dev/null
        hyprctl keyword decoration:shadow:enabled false 2>/dev/null
    fi
    echo -e "  ${GREEN}✓${NC}"

    # 8. Enable GameMode
    echo -e "${CYAN}[8/8] GameMode ON${NC}"
    gamemoded -d 2>/dev/null &
    echo -e "  ${GREEN}✓${NC}"

    # Mark active
    echo "$(date +%s)" > "$STATE_FILE"

    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ⚡ GameFPS Mode ATIVO — Máxima Performance ⚡${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  Para desativar: ${CYAN}gamefps-mode off${NC}"

    notify-send "⚡ GameFPS Mode" "Ativado — Performance máxima" -u normal 2>/dev/null
}

deactivate_gamefps() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo -e "${YELLOW}[GameFPS] Não está ativo${NC}"
        return
    fi

    echo -e "${PURPLE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║   ⚡ GameFPS Mode — DESATIVANDO ⚡      ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════╝${NC}"
    echo ""

    # 1. CPU back to powersave/schedutil
    echo -e "${CYAN}[1/6] CPU → Balanced${NC}"
    for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "schedutil" | sudo tee "$gov" > /dev/null 2>&1 || \
        echo "powersave" | sudo tee "$gov" > /dev/null 2>&1
    done
    echo -e "  ${GREEN}✓${NC}"

    # 2. GPU back to auto
    echo -e "${CYAN}[2/6] GPU → Auto${NC}"
    if [[ -f /sys/class/drm/card0/device/power_dpm_force_performance_level ]]; then
        echo "auto" | sudo tee /sys/class/drm/card0/device/power_dpm_force_performance_level > /dev/null 2>&1
    fi
    echo -e "  ${GREEN}✓${NC}"

    # 3. Restart services
    echo -e "${CYAN}[3/6] Reiniciando serviços${NC}"
    if [[ -f "$SAVED_PROCS" ]]; then
        grep "^  stopped:" "$SAVED_PROCS" | cut -d: -f2 | while read svc; do
            sudo systemctl start "$svc" 2>/dev/null
        done
    fi
    echo -e "  ${GREEN}✓${NC}"

    # 4. Resume paused processes
    echo -e "${CYAN}[4/6] Resumindo processos${NC}"
    if [[ -f "$SAVED_PROCS" ]]; then
        grep "^paused:" "$SAVED_PROCS" | cut -d: -f2 | while read pid; do
            sudo kill -CONT "$pid" 2>/dev/null
        done
    fi
    echo -e "  ${GREEN}✓${NC}"

    # 5. Restore sysctl
    echo -e "${CYAN}[5/6] Restaurando sysctl${NC}"
    sudo sysctl -w vm.swappiness=10 > /dev/null 2>&1
    sudo sysctl -w vm.vfs_cache_pressure=100 > /dev/null 2>&1
    echo -e "  ${GREEN}✓${NC}"

    # 6. Restore compositor
    echo -e "${CYAN}[6/6] Compositor → Normal${NC}"
    if pgrep -x "Hyprland" &>/dev/null; then
        hyprctl keyword animations:enabled true 2>/dev/null
        hyprctl keyword decoration:blur:enabled true 2>/dev/null
        hyprctl keyword decoration:shadow:enabled true 2>/dev/null
    fi
    echo -e "  ${GREEN}✓${NC}"

    # Kill gamemode
    killall gamemoded 2>/dev/null

    # Cleanup
    rm -f "$STATE_FILE" "$SAVED_PROCS"

    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  Sistema restaurado ao modo normal${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    notify-send "⚡ GameFPS Mode" "Desativado — Sistema restaurado" -u normal 2>/dev/null
}

status_gamefps() {
    if [[ -f "$STATE_FILE" ]]; then
        start_time=$(cat "$STATE_FILE")
        current_time=$(date +%s)
        elapsed=$(( (current_time - start_time) / 60 ))
        echo -e "${GREEN}⚡ GameFPS Mode: ATIVO (${elapsed}min)${NC}"
    else
        echo -e "${YELLOW}GameFPS Mode: Inativo${NC}"
    fi
}

# Main
case "${1:-}" in
    on|activate|start)
        activate_gamefps
        ;;
    off|deactivate|stop)
        deactivate_gamefps
        ;;
    status)
        status_gamefps
        ;;
    toggle)
        if [[ -f "$STATE_FILE" ]]; then
            deactivate_gamefps
        else
            activate_gamefps
        fi
        ;;
    *)
        echo "FexOS — GameFPS Mode"
        echo ""
        echo "Uso: gamefps-mode [on|off|toggle|status]"
        echo ""
        echo "  on      Ativar (máxima performance)"
        echo "  off     Desativar (restaurar normal)"
        echo "  toggle  Alternar"
        echo "  status  Verificar estado"
        ;;
esac
