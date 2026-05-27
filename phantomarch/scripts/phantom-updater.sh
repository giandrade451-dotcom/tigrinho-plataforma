#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  FexOS V5 — PhantomUpdater                                   ║
# ║  Sistema de atualização automática com rollback               ║
# ╚══════════════════════════════════════════════════════════════╝

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

UPDATE_LOG="/var/log/phantomarch/updates.log"
ROLLBACK_DIR="/var/lib/phantomarch/rollback"
UPDATE_CACHE="/var/cache/phantomarch/updates"
LOCK_FILE="/tmp/phantom-updater.lock"

mkdir -p "$(dirname "$UPDATE_LOG")" "$ROLLBACK_DIR" "$UPDATE_CACHE"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$UPDATE_LOG"; }

# Lock to prevent concurrent updates
acquire_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        PID=$(cat "$LOCK_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            echo -e "${RED}Atualização já em andamento (PID: $PID)${NC}"
            exit 1
        fi
    fi
    echo $$ > "$LOCK_FILE"
}

release_lock() { rm -f "$LOCK_FILE"; }
trap release_lock EXIT

# === Check for updates ===
check_updates() {
    echo -e "${CYAN}Verificando atualizações...${NC}"
    log "CHECK: Starting update check"

    if ! ping -c 1 -W 3 8.8.8.8 &>/dev/null; then
        echo -e "${YELLOW}Sem conexão com internet.${NC}"
        log "CHECK: No internet connection"
        return 1
    fi

    # Sync pacman database
    pacman -Sy --noconfirm &>/dev/null

    # Count available updates
    UPDATES=$(pacman -Qu 2>/dev/null | wc -l)

    if [[ $UPDATES -eq 0 ]]; then
        echo -e "${GREEN}✓ Sistema atualizado! Nenhuma atualização disponível.${NC}"
        log "CHECK: System up to date"
        return 1
    fi

    echo -e "${GREEN}$UPDATES atualizações disponíveis.${NC}"
    log "CHECK: $UPDATES updates available"
    return 0
}

# === List updates ===
list_updates() {
    echo -e "\n${CYAN}Pacotes para atualizar:${NC}"
    echo ""
    pacman -Qu 2>/dev/null | head -30
    TOTAL=$(pacman -Qu 2>/dev/null | wc -l)
    if [[ $TOTAL -gt 30 ]]; then
        echo "  ... e mais $((TOTAL - 30)) pacotes"
    fi
    echo ""
}

# === Create rollback point ===
create_rollback() {
    echo -e "${CYAN}Criando ponto de restauração...${NC}"
    ROLLBACK_FILE="$ROLLBACK_DIR/rollback-$(date +%Y%m%d_%H%M%S).txt"

    # Save current package list with versions
    pacman -Q > "$ROLLBACK_FILE"
    log "ROLLBACK: Created $ROLLBACK_FILE"
    echo -e "${GREEN}✓ Ponto de restauração criado${NC}"
}

# === Install updates ===
install_updates() {
    acquire_lock
    echo -e "\n${PURPLE}━━━ Instalando atualizações ━━━${NC}"

    # Create rollback first
    create_rollback

    log "UPDATE: Starting installation"

    # Download first
    echo -e "${CYAN}Baixando pacotes...${NC}"
    if ! pacman -Syuw --noconfirm 2>&1 | tee -a "$UPDATE_LOG"; then
        echo -e "${RED}Erro ao baixar pacotes.${NC}"
        log "UPDATE: Download failed"
        release_lock
        return 1
    fi

    # Install
    echo -e "${CYAN}Instalando...${NC}"
    if pacman -Su --noconfirm 2>&1 | tee -a "$UPDATE_LOG"; then
        echo -e "${GREEN}✓ Atualizações instaladas com sucesso!${NC}"
        log "UPDATE: Success"

        # Notify user
        notify-send "PhantomUpdater" "Atualizações instaladas com sucesso!" --icon=system-software-update 2>/dev/null || true
    else
        echo -e "${RED}Erro durante instalação. Iniciando rollback...${NC}"
        log "UPDATE: Installation failed, attempting rollback"
        rollback_update
    fi

    release_lock
}

# === Rollback ===
rollback_update() {
    echo -e "${YELLOW}Iniciando rollback...${NC}"

    LATEST_ROLLBACK=$(ls -t "$ROLLBACK_DIR"/rollback-*.txt 2>/dev/null | head -1)
    if [[ -z "$LATEST_ROLLBACK" ]]; then
        echo -e "${RED}Nenhum ponto de restauração encontrado.${NC}"
        return 1
    fi

    echo -e "  Restaurando para: $(basename "$LATEST_ROLLBACK")"
    log "ROLLBACK: Attempting from $LATEST_ROLLBACK"

    # Downgrade packages that changed
    while IFS=' ' read -r pkg ver; do
        CURRENT_VER=$(pacman -Q "$pkg" 2>/dev/null | awk '{print $2}')
        if [[ "$CURRENT_VER" != "$ver" ]] && [[ -n "$CURRENT_VER" ]]; then
            # Try to downgrade from cache
            CACHE_FILE="/var/cache/pacman/pkg/${pkg}-${ver}-*.pkg.tar.*"
            if ls $CACHE_FILE &>/dev/null; then
                pacman -U --noconfirm $CACHE_FILE 2>/dev/null || true
            fi
        fi
    done < "$LATEST_ROLLBACK"

    echo -e "${GREEN}✓ Rollback concluído.${NC}"
    log "ROLLBACK: Completed"
}

# === Update history ===
show_history() {
    echo -e "\n${CYAN}Histórico de atualizações:${NC}"
    echo ""
    if [[ -f "$UPDATE_LOG" ]]; then
        grep -E "^\\[" "$UPDATE_LOG" | tail -20
    else
        echo "  Nenhum histórico."
    fi
    echo ""
}

# === Auto-update daemon mode ===
daemon_mode() {
    log "DAEMON: Started"
    while true; do
        # Check every 6 hours
        sleep 21600

        if check_updates &>/dev/null; then
            UPDATES=$(pacman -Qu 2>/dev/null | wc -l)
            notify-send "PhantomUpdater" "$UPDATES atualizações disponíveis" --icon=system-software-update 2>/dev/null || true
            log "DAEMON: $UPDATES updates available (notification sent)"
        fi
    done
}

# === MAIN MENU ===
main_menu() {
    echo -e "${PURPLE}"
    echo "  ╔══════════════════════════════════════════╗"
    echo "  ║     PhantomUpdater — FexOS V5            ║"
    echo "  ╚══════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC} Verificar atualizações"
    echo -e "  ${CYAN}[2]${NC} Listar atualizações disponíveis"
    echo -e "  ${CYAN}[3]${NC} Instalar atualizações"
    echo -e "  ${CYAN}[4]${NC} Rollback (restaurar versão anterior)"
    echo -e "  ${CYAN}[5]${NC} Histórico de atualizações"
    echo -e "  ${CYAN}[6]${NC} Criar ponto de restauração"
    echo -e "  ${CYAN}[0]${NC} Sair"
    echo ""
    echo -ne "  ${BOLD}Escolha:${NC} "
    read -r choice

    case $choice in
        1) check_updates ;;
        2) list_updates ;;
        3)
            if check_updates; then
                list_updates
                echo -ne "  ${YELLOW}Instalar agora? [y/N]:${NC} "
                read -r confirm
                [[ "$confirm" == "y" || "$confirm" == "Y" ]] && install_updates
            fi
            ;;
        4) rollback_update ;;
        5) show_history ;;
        6) create_rollback ;;
        0) exit 0 ;;
    esac
}

# === Entry Point ===
case "${1:-}" in
    --check) check_updates ;;
    --install) install_updates ;;
    --rollback) rollback_update ;;
    --daemon) daemon_mode ;;
    --history) show_history ;;
    *) main_menu ;;
esac
