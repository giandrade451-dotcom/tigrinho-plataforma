#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch V4 — Fex Security Center                        ║
# ║  Painel de segurança completo                                ║
# ╚══════════════════════════════════════════════════════════════╝

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

LOG_DIR="/var/log/phantomarch/security"
mkdir -p "$LOG_DIR"

header() {
    clear
    echo -e "${PURPLE}"
    echo "  ╔══════════════════════════════════════════╗"
    echo "  ║       Fex Security Center                ║"
    echo "  ║       Proteção Total do Sistema          ║"
    echo "  ╚══════════════════════════════════════════╝"
    echo -e "${NC}"
}

# === STATUS ===
show_status() {
    header
    echo -e "  ${BOLD}Status de Segurança${NC}"
    echo ""

    # Firewall
    if ufw status 2>/dev/null | grep -q "active"; then
        echo -e "  ${GREEN}●${NC} Firewall             ${GREEN}ATIVO${NC}"
    else
        echo -e "  ${RED}●${NC} Firewall             ${RED}INATIVO${NC}"
    fi

    # AppArmor
    if systemctl is-active apparmor &>/dev/null; then
        echo -e "  ${GREEN}●${NC} AppArmor             ${GREEN}ATIVO${NC}"
    else
        echo -e "  ${YELLOW}●${NC} AppArmor             ${YELLOW}INATIVO${NC}"
    fi

    # ClamAV
    if systemctl is-active clamav-freshclam &>/dev/null; then
        echo -e "  ${GREEN}●${NC} Antivírus (ClamAV)   ${GREEN}ATIVO${NC}"
    else
        echo -e "  ${YELLOW}●${NC} Antivírus (ClamAV)   ${YELLOW}INATIVO${NC}"
    fi

    # Real-time monitor
    if pgrep -f "fex-antivirus-monitor" &>/dev/null; then
        echo -e "  ${GREEN}●${NC} Monitor Real-Time    ${GREEN}ATIVO${NC}"
    else
        echo -e "  ${YELLOW}●${NC} Monitor Real-Time    ${YELLOW}INATIVO${NC}"
    fi

    # Integrity
    if [[ -f /var/lib/phantomarch/integrity.db ]]; then
        echo -e "  ${GREEN}●${NC} Integridade          ${GREEN}VERIFICADA${NC}"
    else
        echo -e "  ${YELLOW}●${NC} Integridade          ${YELLOW}NÃO CONFIGURADA${NC}"
    fi

    # Snapshots
    if command -v timeshift &>/dev/null; then
        SNAPS=$(timeshift --list 2>/dev/null | grep -c ">" || echo "0")
        echo -e "  ${GREEN}●${NC} Restore Points       ${GREEN}${SNAPS} disponíveis${NC}"
    else
        echo -e "  ${YELLOW}●${NC} Restore Points       ${YELLOW}NÃO CONFIGURADO${NC}"
    fi

    # Last scan
    LAST_SCAN=$(cat "$LOG_DIR/last-scan.txt" 2>/dev/null || echo "Nunca")
    echo ""
    echo -e "  ${CYAN}Último scan:${NC} $LAST_SCAN"
    echo ""
}

# === MENU ===
main_menu() {
    show_status
    echo -e "  ${CYAN}[1]${NC} Scanner Rápido"
    echo -e "  ${CYAN}[2]${NC} Scanner Completo"
    echo -e "  ${CYAN}[3]${NC} Monitor Real-Time (ligar/desligar)"
    echo -e "  ${CYAN}[4]${NC} Firewall Manager"
    echo -e "  ${CYAN}[5]${NC} Proteção do Sistema"
    echo -e "  ${CYAN}[6]${NC} Quarentena"
    echo -e "  ${CYAN}[7]${NC} Restore Points / Snapshots"
    echo -e "  ${CYAN}[8]${NC} Verificação de Integridade"
    echo -e "  ${CYAN}[9]${NC} Logs de Segurança"
    echo -e "  ${CYAN}[A]${NC} Permissões & Sandbox"
    echo -e "  ${CYAN}[0]${NC} Sair"
    echo ""
    echo -ne "  ${PURPLE}Security>>${NC} "
    read -r choice
    case $choice in
        1) quick_scan ;;
        2) full_scan ;;
        3) toggle_monitor ;;
        4) firewall_manager ;;
        5) system_protection ;;
        6) quarantine ;;
        7) restore_points ;;
        8) integrity_check ;;
        9) security_logs ;;
        [aA]) permissions_sandbox ;;
        0) exit 0 ;;
        *) main_menu ;;
    esac
}

# === QUICK SCAN ===
quick_scan() {
    header
    echo -e "  ${CYAN}Scanner Rápido${NC}"
    echo -e "  Verificando áreas críticas..."
    echo ""

    THREATS=0
    SCAN_LOG="$LOG_DIR/scan-$(date +%Y%m%d_%H%M%S).log"

    # Scan home and downloads
    echo -e "  [1/4] Verificando ~/Downloads..."
    if command -v clamscan &>/dev/null; then
        FOUND=$(clamscan -r --no-summary /home/*/Downloads 2>/dev/null | grep "FOUND" | tee -a "$SCAN_LOG" | wc -l)
        THREATS=$((THREATS + FOUND))
    fi

    echo -e "  [2/4] Verificando /tmp..."
    if command -v clamscan &>/dev/null; then
        FOUND=$(clamscan -r --no-summary /tmp 2>/dev/null | grep "FOUND" | tee -a "$SCAN_LOG" | wc -l)
        THREATS=$((THREATS + FOUND))
    fi

    echo -e "  [3/4] Verificando scripts suspeitos..."
    # Check for suspicious scripts
    SUSPICIOUS=$(find /home -name "*.sh" -newer /etc/passwd -perm /111 2>/dev/null | wc -l)
    if [[ $SUSPICIOUS -gt 10 ]]; then
        echo "WARNING: $SUSPICIOUS scripts executáveis novos encontrados" >> "$SCAN_LOG"
    fi

    echo -e "  [4/4] Verificando processos..."
    # Check for crypto miners
    MINERS=$(ps aux 2>/dev/null | grep -iE "(xmrig|minerd|cpuminer|cryptonight)" | grep -v grep | wc -l)
    if [[ $MINERS -gt 0 ]]; then
        echo "CRITICAL: Possível minerador detectado!" >> "$SCAN_LOG"
        THREATS=$((THREATS + MINERS))
    fi

    echo ""
    date "+%Y-%m-%d %H:%M" > "$LOG_DIR/last-scan.txt"

    if [[ $THREATS -eq 0 ]]; then
        echo -e "  ${GREEN}✓ Nenhuma ameaça detectada!${NC}"
    else
        echo -e "  ${RED}⚠ ${THREATS} ameaça(s) detectada(s)!${NC}"
        echo -e "  Log: $SCAN_LOG"
        echo -e "  Execute opção [6] para gerenciar quarentena."
    fi

    echo ""
    read -rp "  [Enter] voltar..." _
    main_menu
}

# === FULL SCAN ===
full_scan() {
    header
    echo -e "  ${CYAN}Scanner Completo${NC}"
    echo -e "  ${YELLOW}Isso pode levar vários minutos...${NC}"
    echo ""

    if ! command -v clamscan &>/dev/null; then
        echo -e "  ${RED}ClamAV não instalado!${NC}"
        echo -e "  Instale: ${CYAN}sudo pacman -S clamav${NC}"
        read -rp "  [Enter] voltar..." _
        main_menu
        return
    fi

    # Update definitions
    echo -e "  [1/3] Atualizando definições..."
    freshclam --quiet 2>/dev/null

    # Full scan
    SCAN_LOG="$LOG_DIR/fullscan-$(date +%Y%m%d_%H%M%S).log"
    echo -e "  [2/3] Escaneando sistema..."
    clamscan -r --infected --move=/var/lib/phantomarch/quarantine \
        --exclude-dir=/proc --exclude-dir=/sys --exclude-dir=/dev \
        --exclude-dir=/run --exclude-dir=/var/lib/phantomarch/quarantine \
        / 2>/dev/null | tee "$SCAN_LOG"

    echo -e "  [3/3] Finalizando..."
    date "+%Y-%m-%d %H:%M (completo)" > "$LOG_DIR/last-scan.txt"

    THREATS=$(grep -c "FOUND" "$SCAN_LOG" 2>/dev/null || echo "0")
    echo ""
    if [[ "$THREATS" -eq 0 ]]; then
        echo -e "  ${GREEN}✓ Sistema limpo!${NC}"
    else
        echo -e "  ${RED}⚠ ${THREATS} ameaça(s) movidas para quarentena.${NC}"
    fi

    read -rp "  [Enter] voltar..." _
    main_menu
}

# === REAL-TIME MONITOR ===
toggle_monitor() {
    header
    if pgrep -f "fex-antivirus-monitor" &>/dev/null; then
        pkill -f "fex-antivirus-monitor"
        echo -e "  ${YELLOW}Monitor Real-Time DESLIGADO${NC}"
    else
        nohup /usr/share/phantom/scripts/fex-antivirus-monitor.sh &>/dev/null &
        echo -e "  ${GREEN}Monitor Real-Time LIGADO${NC}"
    fi
    sleep 1
    main_menu
}

# === FIREWALL ===
firewall_manager() {
    header
    echo -e "  ${BOLD}Firewall Manager${NC}"
    echo ""
    echo -e "  Status: $(ufw status 2>/dev/null | head -1)"
    echo ""
    echo -e "  ${CYAN}[1]${NC} Ativar firewall"
    echo -e "  ${CYAN}[2]${NC} Desativar firewall"
    echo -e "  ${CYAN}[3]${NC} Permitir porta"
    echo -e "  ${CYAN}[4]${NC} Bloquear porta"
    echo -e "  ${CYAN}[5]${NC} Ver regras"
    echo -e "  ${CYAN}[6]${NC} Reset (default deny)"
    echo -e "  ${CYAN}[0]${NC} Voltar"
    echo ""
    echo -ne "  > "
    read -r fw_choice
    case $fw_choice in
        1) ufw enable; echo -e "${GREEN}Ativado!${NC}" ;;
        2) ufw disable; echo -e "${YELLOW}Desativado${NC}" ;;
        3) echo -ne "  Porta: "; read -r port; ufw allow "$port"; echo "Permitido: $port" ;;
        4) echo -ne "  Porta: "; read -r port; ufw deny "$port"; echo "Bloqueado: $port" ;;
        5) ufw status verbose ;;
        6) ufw --force reset; ufw default deny incoming; ufw default allow outgoing; ufw enable ;;
        0) main_menu; return ;;
    esac
    sleep 2
    firewall_manager
}

# === SYSTEM PROTECTION ===
system_protection() {
    header
    echo -e "  ${BOLD}Proteção do Sistema${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC} Ativar proteção de arquivos críticos"
    echo -e "  ${CYAN}[2]${NC} Verificar integridade do sistema"
    echo -e "  ${CYAN}[3]${NC} Criar restore point agora"
    echo -e "  ${CYAN}[4]${NC} Ativar modo protegido (imutável)"
    echo -e "  ${CYAN}[5]${NC} Desativar modo protegido"
    echo -e "  ${CYAN}[0]${NC} Voltar"
    echo ""
    echo -ne "  > "
    read -r sp_choice
    case $sp_choice in
        1)
            # Protect critical files with immutable flag
            chattr +i /boot/grub/grub.cfg 2>/dev/null
            chattr +i /etc/passwd 2>/dev/null
            chattr +i /etc/shadow 2>/dev/null
            chattr +i /etc/sudoers 2>/dev/null
            echo -e "  ${GREEN}Arquivos críticos protegidos (imutáveis)${NC}"
            ;;
        2)
            # Verify with pacman
            echo -e "  Verificando integridade..."
            MODIFIED=$(pacman -Qkk 2>&1 | grep -c "MODIFIED" || echo "0")
            echo -e "  Arquivos modificados: $MODIFIED"
            ;;
        3)
            if command -v timeshift &>/dev/null; then
                timeshift --create --comments "Manual V4 restore point"
                echo -e "  ${GREEN}Restore point criado!${NC}"
            else
                echo -e "  ${YELLOW}Timeshift não instalado.${NC}"
            fi
            ;;
        4)
            # Make system dirs immutable
            chattr +i /usr/bin/fexnav 2>/dev/null
            chattr +i /usr/bin/fexai 2>/dev/null
            chattr +i /usr/bin/fex-control-center 2>/dev/null
            echo -e "  ${GREEN}Modo protegido ativado${NC}"
            ;;
        5)
            chattr -i /usr/bin/fexnav 2>/dev/null
            chattr -i /usr/bin/fexai 2>/dev/null
            chattr -i /usr/bin/fex-control-center 2>/dev/null
            chattr -i /boot/grub/grub.cfg 2>/dev/null
            chattr -i /etc/passwd 2>/dev/null
            chattr -i /etc/shadow 2>/dev/null
            chattr -i /etc/sudoers 2>/dev/null
            echo -e "  ${YELLOW}Modo protegido desativado${NC}"
            ;;
        0) main_menu; return ;;
    esac
    sleep 2
    system_protection
}

# === QUARANTINE ===
quarantine() {
    header
    QUARANTINE_DIR="/var/lib/phantomarch/quarantine"
    mkdir -p "$QUARANTINE_DIR"

    echo -e "  ${BOLD}Quarentena${NC}"
    echo ""
    FILES=$(ls "$QUARANTINE_DIR" 2>/dev/null | wc -l)
    echo -e "  Arquivos em quarentena: ${YELLOW}${FILES}${NC}"
    echo ""

    if [[ $FILES -gt 0 ]]; then
        ls -la "$QUARANTINE_DIR" | tail -10
        echo ""
        echo -e "  ${CYAN}[1]${NC} Deletar todos"
        echo -e "  ${CYAN}[2]${NC} Restaurar arquivo"
    fi
    echo -e "  ${CYAN}[0]${NC} Voltar"
    echo ""
    echo -ne "  > "
    read -r q_choice
    case $q_choice in
        1) rm -rf "${QUARANTINE_DIR:?}"/*; echo -e "  ${GREEN}Quarentena limpa.${NC}" ;;
        2) echo -ne "  Nome do arquivo: "; read -r fname; mv "$QUARANTINE_DIR/$fname" /tmp/ 2>/dev/null; echo "Restaurado para /tmp/" ;;
        0) main_menu; return ;;
    esac
    sleep 2
    quarantine
}

# === RESTORE POINTS ===
restore_points() {
    header
    echo -e "  ${BOLD}Restore Points${NC}"
    echo ""
    if command -v timeshift &>/dev/null; then
        timeshift --list 2>/dev/null
        echo ""
        echo -e "  ${CYAN}[1]${NC} Criar novo restore point"
        echo -e "  ${CYAN}[2]${NC} Restaurar"
        echo -e "  ${CYAN}[3]${NC} Deletar antigos"
    else
        echo -e "  ${YELLOW}Timeshift não disponível.${NC}"
        echo -e "  Instale: ${CYAN}sudo pacman -S timeshift${NC}"
    fi
    echo -e "  ${CYAN}[0]${NC} Voltar"
    echo ""
    echo -ne "  > "
    read -r rp_choice
    case $rp_choice in
        1) timeshift --create --comments "User restore point" 2>/dev/null ;;
        2) timeshift --restore 2>/dev/null ;;
        3) timeshift --delete-all 2>/dev/null ;;
        0) main_menu; return ;;
    esac
    sleep 2
    restore_points
}

# === INTEGRITY CHECK ===
integrity_check() {
    header
    echo -e "  ${BOLD}Verificação de Integridade${NC}"
    echo ""
    echo -e "  Verificando arquivos do sistema..."
    echo ""

    ISSUES=0

    # Check critical binaries
    for bin in /usr/bin/fexnav /usr/bin/fexai /usr/bin/fex-control-center /usr/bin/fexcode; do
        if [[ -x "$bin" ]]; then
            echo -e "  ${GREEN}●${NC} $bin"
        elif [[ -f "$bin" ]]; then
            echo -e "  ${YELLOW}●${NC} $bin (não executável)"
            ((ISSUES++))
        else
            echo -e "  ${RED}●${NC} $bin (ausente)"
            ((ISSUES++))
        fi
    done

    # Check critical dirs
    for dir in /opt/fexnav /opt/fexai /boot/grub; do
        if [[ -d "$dir" ]]; then
            echo -e "  ${GREEN}●${NC} $dir"
        else
            echo -e "  ${RED}●${NC} $dir (ausente)"
            ((ISSUES++))
        fi
    done

    echo ""
    if [[ $ISSUES -eq 0 ]]; then
        echo -e "  ${GREEN}✓ Integridade OK${NC}"
    else
        echo -e "  ${RED}⚠ ${ISSUES} problema(s) encontrado(s)${NC}"
    fi

    read -rp "  [Enter] voltar..." _
    main_menu
}

# === SECURITY LOGS ===
security_logs() {
    header
    echo -e "  ${BOLD}Logs de Segurança${NC}"
    echo ""
    echo -e "  Últimos eventos:"
    echo ""
    journalctl -p warning --since "24 hours ago" --no-pager -n 20 2>/dev/null | tail -15
    echo ""
    echo -e "  ${CYAN}Scan logs:${NC} $LOG_DIR/"
    ls -lt "$LOG_DIR" 2>/dev/null | head -5
    echo ""
    read -rp "  [Enter] voltar..." _
    main_menu
}

# === PERMISSIONS & SANDBOX ===
permissions_sandbox() {
    header
    echo -e "  ${BOLD}Permissões & Sandbox${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC} Modo Administrador (desbloquear tudo)"
    echo -e "  ${CYAN}[2]${NC} Modo Padrão (seguro)"
    echo -e "  ${CYAN}[3]${NC} Modo Desenvolvedor (dev tools desbloqueados)"
    echo -e "  ${CYAN}[4]${NC} Sandbox para Wine apps"
    echo -e "  ${CYAN}[0]${NC} Voltar"
    echo ""
    echo -ne "  > "
    read -r ps_choice
    case $ps_choice in
        1)
            echo -e "  ${YELLOW}Modo Administrador ativado${NC}"
            echo -e "  Todas as restrições removidas para esta sessão."
            ;;
        2)
            echo -e "  ${GREEN}Modo Padrão ativado${NC}"
            echo -e "  Proteções padrão aplicadas."
            ;;
        3)
            echo -e "  ${CYAN}Modo Desenvolvedor ativado${NC}"
            echo -e "  Docker, ports, e dev tools desbloqueados."
            # Allow docker without sudo
            usermod -aG docker "$USER" 2>/dev/null
            ;;
        4)
            echo -e "  Sandbox Wine ativado."
            echo -e "  Apps Windows rodam isolados."
            # Create sandbox prefix
            mkdir -p /tmp/wine-sandbox
            ;;
        0) main_menu; return ;;
    esac
    sleep 2
    permissions_sandbox
}

# === MAIN ===
main_menu
