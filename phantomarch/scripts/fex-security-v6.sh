#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  FexOS V6 — Enhanced Security (Auto-Delete + Notifications)  ║
# ║  Detects and auto-removes malware, trojans, ransomware       ║
# ╚══════════════════════════════════════════════════════════════╝

SECURITY_DIR="/var/lib/fexos/security"
QUARANTINE_DIR="/var/lib/fexos/quarantine"
LOG_FILE="/var/log/fexos/security.log"
RULES_DIR="/etc/fexos/security/rules"
WHITELIST="/etc/fexos/security/whitelist"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

mkdir -p "$SECURITY_DIR" "$QUARANTINE_DIR" "$(dirname "$LOG_FILE")" "$RULES_DIR" 2>/dev/null

log_event() {
    local level="$1" message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LOG_FILE"
}

notify_user() {
    local title="$1" message="$2" urgency="${3:-normal}"
    notify-send "🛡️ $title" "$message" -u "$urgency" -t 10000 2>/dev/null
    # Also log to desktop notification center
    echo "[$(date '+%H:%M')] $title: $message" >> /tmp/fexos-security-notifications
}

# ═══════════════════════════════════════════
# REAL-TIME MONITOR
# ═══════════════════════════════════════════
realtime_monitor() {
    log_event "INFO" "Real-time monitor started"
    notify_user "Segurança" "Monitor em tempo real ativado" "low"

    # Monitor Downloads and common attack vectors
    WATCH_DIRS=(
        "$HOME/Downloads"
        "$HOME/Desktop"
        "/tmp"
        "$HOME/.local/share"
    )

    # Use inotifywait if available
    if command -v inotifywait &>/dev/null; then
        inotifywait -m -r --format '%w%f' -e create -e moved_to "${WATCH_DIRS[@]}" 2>/dev/null | while read filepath; do
            scan_file "$filepath"
        done
    else
        # Fallback: periodic scan
        while true; do
            for dir in "${WATCH_DIRS[@]}"; do
                if [[ -d "$dir" ]]; then
                    find "$dir" -maxdepth 2 -newer /tmp/.fexos-last-scan -type f 2>/dev/null | while read f; do
                        scan_file "$f"
                    done
                fi
            done
            touch /tmp/.fexos-last-scan
            sleep 30
        done
    fi
}

# ═══════════════════════════════════════════
# FILE SCANNER
# ═══════════════════════════════════════════
scan_file() {
    local filepath="$1"
    [[ ! -f "$filepath" ]] && return

    # Skip whitelisted
    if [[ -f "$WHITELIST" ]] && grep -qF "$filepath" "$WHITELIST" 2>/dev/null; then
        return
    fi

    local filename=$(basename "$filepath")
    local threat_found=false
    local threat_type=""
    local threat_reason=""

    # Check 1: Known malicious patterns in scripts
    if [[ "$filename" == *.sh || "$filename" == *.py || "$filename" == *.pl ]]; then
        # Check for crypto miners
        if grep -qiE "(xmrig|minergate|coinhive|cryptonight|stratum\+tcp)" "$filepath" 2>/dev/null; then
            threat_found=true
            threat_type="Cryptominer"
            threat_reason="Script contém referências a mineração de criptomoedas"
        fi
        # Check for reverse shells
        if grep -qiE "(bash -i >& /dev/tcp|nc -e /bin|python.*socket.*connect|mkfifo.*nc)" "$filepath" 2>/dev/null; then
            threat_found=true
            threat_type="Reverse Shell"
            threat_reason="Script contém código de shell reverso (backdoor)"
        fi
        # Check for data exfiltration
        if grep -qiE "(curl.*\|.*bash|wget.*\|.*sh|eval.*\$(curl|base64.*-d.*\|.*bash)" "$filepath" 2>/dev/null; then
            threat_found=true
            threat_type="Dropper"
            threat_reason="Script baixa e executa código remoto"
        fi
        # Check for destructive commands
        if grep -qiE "(rm -rf /[^*]|dd if=/dev/zero of=/dev/sd|mkfs\.|:(){ :\|:& };:)" "$filepath" 2>/dev/null; then
            threat_found=true
            threat_type="Destructivo"
            threat_reason="Script contém comandos que podem destruir o sistema"
        fi
    fi

    # Check 2: Suspicious executables
    if [[ -x "$filepath" ]] || file "$filepath" 2>/dev/null | grep -qi "executable"; then
        # Check for packed/obfuscated binaries
        if file "$filepath" 2>/dev/null | grep -qi "UPX\|packed"; then
            threat_found=true
            threat_type="Suspeito"
            threat_reason="Executável empacotado/ofuscado detectado"
        fi
    fi

    # Check 3: ClamAV scan (if available)
    if command -v clamscan &>/dev/null && [[ "$threat_found" == false ]]; then
        local clam_result
        clam_result=$(clamscan --no-summary "$filepath" 2>/dev/null)
        if echo "$clam_result" | grep -q "FOUND"; then
            threat_found=true
            threat_type="Malware"
            threat_reason="ClamAV detectou: $(echo "$clam_result" | grep FOUND | head -1)"
        fi
    fi

    # Check 4: Ransomware patterns
    if [[ "$filename" == *.encrypted || "$filename" == *.locked || "$filename" == *ransom* ]]; then
        if file "$filepath" 2>/dev/null | grep -qi "data\|encrypted"; then
            threat_found=true
            threat_type="Ransomware"
            threat_reason="Arquivo com padrão de ransomware detectado"
        fi
    fi

    # Take action if threat found
    if [[ "$threat_found" == true ]]; then
        handle_threat "$filepath" "$threat_type" "$threat_reason"
    fi
}

# ═══════════════════════════════════════════
# THREAT HANDLING (AUTO-DELETE + NOTIFY)
# ═══════════════════════════════════════════
handle_threat() {
    local filepath="$1" threat_type="$2" reason="$3"
    local filename=$(basename "$filepath")
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Log the threat
    log_event "THREAT" "[$threat_type] $filepath — $reason"

    # Move to quarantine (don't delete immediately — keep evidence)
    local quarantine_name="${timestamp//[: ]/_}_${filename}"
    if mv "$filepath" "$QUARANTINE_DIR/$quarantine_name" 2>/dev/null; then
        # Remove execute permission in quarantine
        chmod 000 "$QUARANTINE_DIR/$quarantine_name" 2>/dev/null

        # Notify user
        notify_user "⚠️ Ameaça Detectada" \
            "Tipo: $threat_type\nArquivo: $filename\nMotivo: $reason\n\nO arquivo foi removido automaticamente e movido para quarentena." \
            "critical"

        log_event "ACTION" "Arquivo movido para quarentena: $quarantine_name"

        # Show desktop notification with details
        echo -e "${RED}[SEGURANÇA] Ameaça detectada e removida!${NC}"
        echo -e "  ${BOLD}Tipo:${NC}    $threat_type"
        echo -e "  ${BOLD}Arquivo:${NC} $filename"
        echo -e "  ${BOLD}Motivo:${NC}  $reason"
        echo -e "  ${BOLD}Ação:${NC}    Movido para quarentena"
    else
        # If can't move, try to make it non-executable
        chmod -x "$filepath" 2>/dev/null
        notify_user "⚠️ Ameaça Detectada" \
            "Tipo: $threat_type\nArquivo: $filename\nAção: Permissões removidas (não foi possível mover)" \
            "critical"
        log_event "WARN" "Não foi possível mover para quarentena: $filepath"
    fi
}

# ═══════════════════════════════════════════
# FULL SYSTEM SCAN
# ═══════════════════════════════════════════
full_scan() {
    echo -e "${PURPLE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║   🛡️ FexOS — Scan Completo de Segurança  ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════╝${NC}"
    echo ""

    local threats=0
    local scanned=0
    local scan_dirs=("$HOME" "/tmp" "/var/tmp")

    for dir in "${scan_dirs[@]}"; do
        [[ ! -d "$dir" ]] && continue
        echo -e "${CYAN}Escaneando: $dir${NC}"

        find "$dir" -maxdepth 4 -type f -size +0 -size -100M 2>/dev/null | while read f; do
            ((scanned++))
            scan_file "$f"
        done
    done

    # ClamAV scan if available
    if command -v clamscan &>/dev/null; then
        echo -e "\n${CYAN}ClamAV scan...${NC}"
        clamscan -r --quiet --bell "$HOME" 2>/dev/null
    fi

    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  Scan completo. Verifique notificações para ameaças."
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    notify_user "Scan Completo" "Verificação de segurança finalizada" "low"
}

# ═══════════════════════════════════════════
# QUARANTINE MANAGEMENT
# ═══════════════════════════════════════════
show_quarantine() {
    echo -e "${CYAN}━━━ Quarentena ━━━${NC}"
    if [[ -d "$QUARANTINE_DIR" ]] && ls "$QUARANTINE_DIR"/* &>/dev/null 2>&1; then
        ls -la "$QUARANTINE_DIR" | tail -n +2
        echo ""
        echo -e "  ${YELLOW}Estes arquivos foram detectados como ameaças.${NC}"
        echo -e "  Para deletar permanentemente: ${BOLD}fex-security purge${NC}"
    else
        echo -e "  ${GREEN}Quarentena vazia — nenhuma ameaça encontrada${NC}"
    fi
}

purge_quarantine() {
    if [[ -d "$QUARANTINE_DIR" ]]; then
        rm -rf "$QUARANTINE_DIR"/*
        echo -e "${GREEN}✓ Quarentena limpa${NC}"
        log_event "INFO" "Quarantine purged"
    fi
}

# Main
case "${1:-}" in
    monitor|--monitor)
        realtime_monitor
        ;;
    scan|--scan)
        full_scan
        ;;
    quarantine)
        show_quarantine
        ;;
    purge)
        purge_quarantine
        ;;
    status)
        echo -e "${CYAN}FexOS Security V6${NC}"
        echo -e "  Log: $LOG_FILE"
        echo -e "  Quarentena: $(ls "$QUARANTINE_DIR" 2>/dev/null | wc -l) itens"
        echo -e "  ClamAV: $(command -v clamscan &>/dev/null && echo "✓ Instalado" || echo "✗ Não instalado")"
        echo -e "  inotify: $(command -v inotifywait &>/dev/null && echo "✓ Disponível" || echo "✗ Não disponível")"
        ;;
    *)
        echo "FexOS Security V6"
        echo ""
        echo "Uso: fex-security [comando]"
        echo ""
        echo "  monitor    Monitor em tempo real (auto-delete + notificação)"
        echo "  scan       Scan completo do sistema"
        echo "  quarantine Ver arquivos em quarentena"
        echo "  purge      Limpar quarentena"
        echo "  status     Status do sistema de segurança"
        ;;
esac
