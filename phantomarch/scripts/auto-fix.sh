#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch V3 — Auto-Fix System                            ║
# ║  Detecta e corrige problemas automaticamente                 ║
# ╚══════════════════════════════════════════════════════════════╝
set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOG_DIR="/var/log/phantomarch"
LOG_FILE="${LOG_DIR}/auto-fix-$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$LOG_DIR"

FIXES=0
ERRORS=0

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"; }
fix() { ((FIXES++)); echo -e "  ${GREEN}[FIX]${NC} $1" | tee -a "$LOG_FILE"; }
err() { ((ERRORS++)); echo -e "  ${RED}[ERR]${NC} $1" | tee -a "$LOG_FILE"; }
warn() { echo -e "  ${YELLOW}[!]${NC} $1" | tee -a "$LOG_FILE"; }
ok() { echo -e "  ${GREEN}[OK]${NC} $1" | tee -a "$LOG_FILE"; }

echo -e "${PURPLE}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║     PhantomArch V3 — Auto-Fix            ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

# --- 1. Systemd Services ---
log "${CYAN}[1/12]${NC} Verificando serviços systemd..."
FAILED_SERVICES=$(systemctl --failed --no-legend 2>/dev/null | awk '{print $1}')
if [[ -n "$FAILED_SERVICES" ]]; then
    while IFS= read -r svc; do
        warn "Serviço falhou: $svc"
        systemctl restart "$svc" 2>/dev/null && fix "Reiniciado: $svc" || err "Não foi possível reiniciar: $svc"
    done <<< "$FAILED_SERVICES"
else
    ok "Todos os serviços rodando"
fi

# --- 2. Pacman/Packages ---
log "${CYAN}[2/12]${NC} Verificando pacotes..."
if pacman -Dk 2>&1 | grep -q "missing"; then
    warn "Dependências quebradas detectadas"
    pacman -Syu --noconfirm 2>/dev/null && fix "Pacotes atualizados" || err "Falha ao atualizar pacotes"
else
    ok "Pacotes íntegros"
fi

# Lock file cleanup
if [[ -f /var/lib/pacman/db.lck ]]; then
    rm -f /var/lib/pacman/db.lck
    fix "Lock do pacman removido"
fi

# --- 3. Permissions ---
log "${CYAN}[3/12]${NC} Verificando permissões..."
for dir in /tmp /var/tmp; do
    if [[ "$(stat -c '%a' $dir)" != "1777" ]]; then
        chmod 1777 "$dir"
        fix "Permissão corrigida: $dir"
    fi
done

# User home permissions
for home_dir in /home/*/; do
    user=$(basename "$home_dir")
    if [[ -d "$home_dir" && "$(stat -c '%U' "$home_dir")" != "$user" ]]; then
        chown -R "$user:$user" "$home_dir"
        fix "Home corrigido: $home_dir"
    fi
done
ok "Permissões verificadas"

# --- 4. Audio (PipeWire) ---
log "${CYAN}[4/12]${NC} Verificando áudio..."
if ! pgrep -x pipewire &>/dev/null; then
    for user_home in /home/*/; do
        user=$(basename "$user_home")
        sudo -u "$user" systemctl --user restart pipewire pipewire-pulse wireplumber 2>/dev/null && fix "PipeWire reiniciado para $user"
    done
else
    ok "PipeWire rodando"
fi

# Fix audio permissions
if [[ -e /dev/snd ]]; then
    chmod -R 660 /dev/snd/* 2>/dev/null
    chgrp -R audio /dev/snd/* 2>/dev/null
fi

# --- 5. Vulkan/OpenGL/GPU ---
log "${CYAN}[5/12]${NC} Verificando GPU/Vulkan..."
if command -v vulkaninfo &>/dev/null; then
    if ! vulkaninfo --summary &>/dev/null; then
        warn "Vulkan não funcional"
        # Try to load modules
        if lspci | grep -qi nvidia; then
            modprobe nvidia nvidia_drm nvidia_modeset 2>/dev/null && fix "Módulos NVIDIA carregados"
        elif lspci | grep -qi amd; then
            modprobe amdgpu 2>/dev/null && fix "Módulo amdgpu carregado"
        fi
    else
        ok "Vulkan funcional"
    fi
else
    warn "vulkaninfo não instalado"
fi

# NVIDIA specific fixes
if lspci | grep -qi nvidia; then
    if ! nvidia-smi &>/dev/null; then
        warn "nvidia-smi falhou"
        modprobe -r nouveau 2>/dev/null
        modprobe nvidia 2>/dev/null && fix "Driver NVIDIA recarregado" || err "NVIDIA driver falhou"
    else
        ok "NVIDIA driver OK"
    fi
fi

# --- 6. Wine ---
log "${CYAN}[6/12]${NC} Verificando Wine..."
if command -v wine &>/dev/null; then
    # Fix common Wine issues
    for user_home in /home/*/; do
        user=$(basename "$user_home")
        prefix="${user_home}.wine"
        if [[ -d "$prefix" && ! -f "$prefix/system.reg" ]]; then
            warn "Wine prefix corrompido para $user"
            sudo -u "$user" WINEPREFIX="$prefix" wineboot --init 2>/dev/null && fix "Wine prefix recriado: $user"
        fi
    done
    ok "Wine verificado"
else
    warn "Wine não instalado"
fi

# --- 7. FexNav ---
log "${CYAN}[7/12]${NC} Verificando FexNav..."
if [[ -d /opt/fexnav ]]; then
    # Fix permissions
    chmod -R 755 /opt/fexnav/bin 2>/dev/null
    # Check if executable exists
    if ls /opt/fexnav/bin/FexNav* &>/dev/null || ls /opt/fexnav/bin/fexnav* &>/dev/null; then
        ok "FexNav executável encontrado"
    else
        warn "FexNav: executável não encontrado em /opt/fexnav/bin/"
    fi
else
    mkdir -p /opt/fexnav/{bin,lib,data,icons,updates,cache,userdata,configs,logs}
    fix "Estrutura FexNav criada"
fi

# --- 8. FexCode ---
log "${CYAN}[8/12]${NC} Verificando FexCode..."
if [[ -f /usr/bin/fexcode ]]; then
    chmod +x /usr/bin/fexcode
    ok "FexCode launcher OK"
else
    warn "FexCode não instalado"
fi

# --- 9. GRUB ---
log "${CYAN}[9/12]${NC} Verificando GRUB..."
if [[ -f /boot/grub/grub.cfg ]]; then
    if ! grep -q "PhantomArch" /boot/grub/grub.cfg; then
        grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null && fix "GRUB regenerado"
    else
        ok "GRUB configurado"
    fi
fi

# --- 10. Network ---
log "${CYAN}[10/12]${NC} Verificando rede..."
if ! systemctl is-active NetworkManager &>/dev/null; then
    systemctl enable --now NetworkManager 2>/dev/null && fix "NetworkManager ativado"
else
    ok "NetworkManager ativo"
fi

# DNS fix
if ! host google.com &>/dev/null 2>&1; then
    if [[ -f /etc/resolv.conf ]]; then
        if ! grep -q "nameserver" /etc/resolv.conf; then
            echo -e "nameserver 1.1.1.1\nnameserver 8.8.8.8" >> /etc/resolv.conf
            fix "DNS configurado"
        fi
    fi
fi

# --- 11. Display/Session ---
log "${CYAN}[11/12]${NC} Verificando sessão gráfica..."
if [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
    ok "Sessão gráfica ativa"
else
    # Enable SDDM if not running
    if ! systemctl is-active sddm &>/dev/null; then
        systemctl enable sddm 2>/dev/null && fix "SDDM habilitado"
    fi
fi

# --- 12. Memory/Swap ---
log "${CYAN}[12/12]${NC} Verificando memória..."
# zRAM check
if ! lsmod | grep -q zram; then
    modprobe zram 2>/dev/null
    if [[ -f /sys/block/zram0/disksize ]]; then
        RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        ZRAM_SIZE=$((RAM_KB * 1024 / 2))  # 50% of RAM
        echo "$ZRAM_SIZE" > /sys/block/zram0/disksize 2>/dev/null
        mkswap /dev/zram0 2>/dev/null
        swapon -p 100 /dev/zram0 2>/dev/null && fix "zRAM ativado"
    fi
else
    ok "zRAM ativo"
fi

# earlyoom
if ! pgrep -x earlyoom &>/dev/null; then
    systemctl enable --now earlyoom 2>/dev/null && fix "earlyoom ativado"
fi

# --- Report ---
echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}Correções: ${FIXES}${NC} | ${RED}Erros não resolvidos: ${ERRORS}${NC}"
echo -e "  Log: ${LOG_FILE}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [[ $ERRORS -eq 0 ]]; then
    echo -e "  ${GREEN}Sistema saudável!${NC}"
else
    echo -e "  ${YELLOW}Verifique o log para erros não resolvidos.${NC}"
    echo -e "  Execute: ${CYAN}debug-v3${NC} para diagnóstico detalhado"
fi
