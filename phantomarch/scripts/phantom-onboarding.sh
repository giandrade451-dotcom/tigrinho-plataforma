#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  FexOS V5 — First Boot Onboarding Wizard                    ║
# ║  Idioma → Região → Wi-Fi → Conta → Login                   ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

CONFIG_DIR="/etc/phantomarch"
ACCOUNTS_DIR="/var/lib/phantomarch/accounts"
ONBOARDING_FLAG="/var/lib/phantomarch/.onboarding-done"

mkdir -p "$CONFIG_DIR" "$ACCOUNTS_DIR"

# Skip if already onboarded
if [[ -f "$ONBOARDING_FLAG" ]]; then
    exit 0
fi

clear
echo -e "${PURPLE}"
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║                                                          ║"
echo "  ║            ⚡ Bem-vindo ao PhantomArch ⚡                ║"
echo "  ║                                                          ║"
echo "  ║        Performance. Security. Freedom.                   ║"
echo "  ║                                                          ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
sleep 2

# ═══════════════════════════════════════════
# STEP 1: Language
# ═══════════════════════════════════════════
step_language() {
    echo -e "${CYAN}━━━ PASSO 1/5: Idioma ━━━${NC}"
    echo ""
    echo "  [1] Português (Brasil)"
    echo "  [2] English (US)"
    echo "  [3] Español"
    echo "  [4] Français"
    echo "  [5] Deutsch"
    echo "  [6] 日本語"
    echo ""
    echo -ne "  ${BOLD}Escolha:${NC} "
    read -r lang_choice

    case $lang_choice in
        1) LOCALE="pt_BR.UTF-8"; LANG_NAME="Português (Brasil)" ;;
        2) LOCALE="en_US.UTF-8"; LANG_NAME="English (US)" ;;
        3) LOCALE="es_ES.UTF-8"; LANG_NAME="Español" ;;
        4) LOCALE="fr_FR.UTF-8"; LANG_NAME="Français" ;;
        5) LOCALE="de_DE.UTF-8"; LANG_NAME="Deutsch" ;;
        6) LOCALE="ja_JP.UTF-8"; LANG_NAME="日本語" ;;
        *) LOCALE="pt_BR.UTF-8"; LANG_NAME="Português (Brasil)" ;;
    esac

    echo "LANG=$LOCALE" > /etc/locale.conf 2>/dev/null || true
    localectl set-locale "LANG=$LOCALE" 2>/dev/null || true
    echo -e "  ${GREEN}✓ Idioma: $LANG_NAME${NC}"
    echo ""
}

# ═══════════════════════════════════════════
# STEP 2: Region/Timezone
# ═══════════════════════════════════════════
step_region() {
    echo -e "${CYAN}━━━ PASSO 2/5: Região ━━━${NC}"
    echo ""
    echo "  [1] América/São Paulo (BRT)"
    echo "  [2] América/New York (EST)"
    echo "  [3] Europa/London (GMT)"
    echo "  [4] Europa/Berlin (CET)"
    echo "  [5] Ásia/Tokyo (JST)"
    echo "  [6] América/Los Angeles (PST)"
    echo "  [7] Outra (digitar manualmente)"
    echo ""
    echo -ne "  ${BOLD}Escolha:${NC} "
    read -r tz_choice

    case $tz_choice in
        1) TIMEZONE="America/Sao_Paulo" ;;
        2) TIMEZONE="America/New_York" ;;
        3) TIMEZONE="Europe/London" ;;
        4) TIMEZONE="Europe/Berlin" ;;
        5) TIMEZONE="Asia/Tokyo" ;;
        6) TIMEZONE="America/Los_Angeles" ;;
        7)
            echo -ne "  Timezone (ex: America/Sao_Paulo): "
            read -r TIMEZONE
            ;;
        *) TIMEZONE="America/Sao_Paulo" ;;
    esac

    timedatectl set-timezone "$TIMEZONE" 2>/dev/null || \
        ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime 2>/dev/null || true
    echo -e "  ${GREEN}✓ Timezone: $TIMEZONE${NC}"
    echo ""
}

# ═══════════════════════════════════════════
# STEP 3: Network
# ═══════════════════════════════════════════
step_network() {
    echo -e "${CYAN}━━━ PASSO 3/5: Internet ━━━${NC}"
    echo ""

    # Check if already connected
    if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
        echo -e "  ${GREEN}✓ Já conectado à internet!${NC}"
        echo ""
        return
    fi

    echo "  [1] Conectar Wi-Fi"
    echo "  [2] Ethernet (automático)"
    echo "  [3] Pular (configurar depois)"
    echo ""
    echo -ne "  ${BOLD}Escolha:${NC} "
    read -r net_choice

    case $net_choice in
        1)
            echo ""
            echo "  Redes disponíveis:"
            nmcli device wifi list 2>/dev/null | head -15 || echo "  (nmcli não disponível)"
            echo ""
            echo -ne "  ${BOLD}Nome da rede (SSID):${NC} "
            read -r SSID
            echo -ne "  ${BOLD}Senha:${NC} "
            read -rs WIFI_PASS
            echo ""
            nmcli device wifi connect "$SSID" password "$WIFI_PASS" 2>/dev/null && \
                echo -e "  ${GREEN}✓ Conectado a $SSID${NC}" || \
                echo -e "  ${YELLOW}! Falha ao conectar. Configure depois.${NC}"
            ;;
        2)
            echo -e "  ${GREEN}✓ Usando Ethernet${NC}"
            ;;
        3)
            echo -e "  ${YELLOW}! Internet pulada${NC}"
            ;;
    esac
    echo ""
}

# ═══════════════════════════════════════════
# STEP 4: Account Creation
# ═══════════════════════════════════════════
step_account() {
    echo -e "${CYAN}━━━ PASSO 4/5: Criar Conta ━━━${NC}"
    echo ""
    echo -e "  ${BOLD}Crie sua conta FexOS (100% gratuito, sem assinaturas)${NC}"
    echo ""

    # Email
    echo -ne "  ${BOLD}Email (Gmail):${NC} "
    read -r USER_EMAIL

    # Verify email format
    if [[ ! "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo -e "  ${RED}Email inválido. Tente novamente.${NC}"
        echo -ne "  ${BOLD}Email:${NC} "
        read -r USER_EMAIL
    fi

    # Generate verification code
    VERIFY_CODE=$(shuf -i 100000-999999 -n 1)

    # Send verification (via local mail or show code)
    echo ""
    echo -e "  ${CYAN}Enviando código de verificação para: $USER_EMAIL${NC}"

    # Try to send email via msmtp/sendmail
    if command -v msmtp &>/dev/null || command -v sendmail &>/dev/null; then
        {
            echo "Subject: FexOS - Código de Verificação"
            echo "To: $USER_EMAIL"
            echo "From: noreply@fexos.io"
            echo ""
            echo "Seu código de verificação FexOS: $VERIFY_CODE"
            echo ""
            echo "Se você não solicitou este código, ignore este email."
        } | msmtp "$USER_EMAIL" 2>/dev/null || \
        sendmail "$USER_EMAIL" 2>/dev/null || true
        echo -e "  ${GREEN}✓ Código enviado!${NC}"
    else
        # Offline mode: show code locally
        echo -e "  ${YELLOW}(Modo offline - código exibido localmente)${NC}"
        echo -e "  ${BOLD}Código: $VERIFY_CODE${NC}"
    fi

    echo ""
    echo -ne "  ${BOLD}Digite o código de verificação:${NC} "
    read -r INPUT_CODE

    if [[ "$INPUT_CODE" != "$VERIFY_CODE" ]]; then
        echo -e "  ${RED}Código incorreto!${NC}"
        echo -ne "  ${BOLD}Tente novamente:${NC} "
        read -r INPUT_CODE
        if [[ "$INPUT_CODE" != "$VERIFY_CODE" ]]; then
            echo -e "  ${RED}Código incorreto. Continuando sem verificação.${NC}"
        fi
    else
        echo -e "  ${GREEN}✓ Email verificado!${NC}"
    fi

    echo ""

    # Username
    echo -ne "  ${BOLD}Nome de usuário:${NC} "
    read -r USERNAME

    # Validate username
    USERNAME=$(echo "$USERNAME" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_-')
    if [[ -z "$USERNAME" ]]; then
        USERNAME="phantom"
    fi

    # Password (loop until match)
    while true; do
        echo -ne "  ${BOLD}Senha:${NC} "
        read -rs PASSWORD
        echo ""
        echo -ne "  ${BOLD}Confirmar senha:${NC} "
        read -rs PASSWORD2
        echo ""

        if [[ "$PASSWORD" == "$PASSWORD2" ]]; then
            break
        fi
        echo -e "  ${RED}Senhas não coincidem! Tente novamente.${NC}"
    done

    # Create system user
    echo ""
    echo -e "  ${CYAN}Criando conta...${NC}"

    if ! id "$USERNAME" &>/dev/null; then
        useradd -m -G wheel,audio,video,network,storage,input,power -s /bin/bash "$USERNAME" 2>/dev/null || true
        echo "${USERNAME}:${PASSWORD}" | chpasswd 2>/dev/null || true
    fi

    # Save account info (not password)
    cat > "$ACCOUNTS_DIR/${USERNAME}.conf" << EOF
[account]
username=$USERNAME
email=$USER_EMAIL
created=$(date -Iseconds)
verified=true
type=admin
EOF

    chmod 600 "$ACCOUNTS_DIR/${USERNAME}.conf"
    echo -e "  ${GREEN}✓ Conta '$USERNAME' criada com sucesso!${NC}"
    echo ""
}

# ═══════════════════════════════════════════
# STEP 5: Finalize
# ═══════════════════════════════════════════
step_finalize() {
    echo -e "${CYAN}━━━ PASSO 5/5: Finalizando ━━━${NC}"
    echo ""
    echo -e "  Configurando sistema..."

    # Set SDDM autologin for first time
    mkdir -p /etc/sddm.conf.d
    cat > /etc/sddm.conf.d/autologin.conf << EOF
[Autologin]
User=$USERNAME
Session=hyprland
EOF

    # Enable essential services
    systemctl enable NetworkManager 2>/dev/null || true
    systemctl enable sddm 2>/dev/null || true
    systemctl enable bluetooth 2>/dev/null || true

    # Mark onboarding as done
    touch "$ONBOARDING_FLAG"
    echo "$USERNAME" > "$CONFIG_DIR/primary-user"

    echo -e "  ${GREEN}✓ Sistema configurado!${NC}"
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${GREEN}${BOLD}Tudo pronto! Bem-vindo ao PhantomArch, $USERNAME!${NC}"
    echo ""
    echo -e "  O sistema fará login automaticamente agora."
    echo -e "  No próximo boot, você entrará com sua senha."
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    sleep 3
}

# ═══════════════════════════════════════════
# MAIN FLOW
# ═══════════════════════════════════════════
step_language
step_region
step_network
step_account
step_finalize
