#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch V3 — FexNav Full Integration                    ║
# ║  Auto-instalação do FexNav a partir de .zip/.exe             ║
# ║  Integração completa: dock, barra, navegador padrão          ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

FEXNAV_DIR="/opt/fexnav"
FEXNAV_BIN="${FEXNAV_DIR}/bin"
FEXNAV_DATA="${FEXNAV_DIR}/data"
FEXNAV_CACHE="${FEXNAV_DIR}/cache"
FEXNAV_USERDATA="${FEXNAV_DIR}/userdata"
FEXNAV_CONFIGS="${FEXNAV_DIR}/configs"
FEXNAV_LOGS="${FEXNAV_DIR}/logs"

echo -e "${PURPLE}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   FexNav V3 — Full Installation          ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

# --- Criar estrutura ---
echo -e "${CYAN}[1/8]${NC} Criando estrutura..."
mkdir -p "$FEXNAV_BIN" "$FEXNAV_DATA" "$FEXNAV_CACHE" "$FEXNAV_USERDATA" "$FEXNAV_CONFIGS" "$FEXNAV_LOGS"
mkdir -p "${FEXNAV_DIR}/icons" "${FEXNAV_DIR}/updates" "${FEXNAV_DIR}/assets"
echo -e "${GREEN}  ✓ Estrutura criada${NC}"

# --- Detectar e instalar FexNav ---
echo -e "${CYAN}[2/8]${NC} Procurando FexNav..."

FEXNAV_SOURCE=""

# Procurar .zip primeiro
for search_dir in /home/*/Downloads /home/*/Desktop /home/* /tmp /root; do
    found=$(find "$search_dir" -maxdepth 2 -iname "*fexnav*.zip" -type f 2>/dev/null | head -1)
    if [[ -n "$found" ]]; then
        FEXNAV_SOURCE="$found"
        break
    fi
done

# Se não encontrou .zip, procurar .exe direto
if [[ -z "$FEXNAV_SOURCE" ]]; then
    for search_dir in /home/*/Downloads /home/*/Desktop /home/* /tmp /root /opt/fexnav/bin; do
        found=$(find "$search_dir" -maxdepth 2 -iname "*fexnav*.exe" -type f 2>/dev/null | head -1)
        if [[ -n "$found" ]]; then
            FEXNAV_SOURCE="$found"
            break
        fi
    done
fi

if [[ -n "$FEXNAV_SOURCE" ]]; then
    echo -e "${GREEN}  ✓ Encontrado: $FEXNAV_SOURCE${NC}"

    if [[ "$FEXNAV_SOURCE" == *.zip ]]; then
        echo -e "  Extraindo .zip..."
        unzip -o "$FEXNAV_SOURCE" -d "$FEXNAV_BIN/" 2>/dev/null
        echo -e "${GREEN}  ✓ ZIP extraído para $FEXNAV_BIN/${NC}"
    elif [[ "$FEXNAV_SOURCE" == *.exe ]]; then
        cp "$FEXNAV_SOURCE" "$FEXNAV_BIN/"
        echo -e "${GREEN}  ✓ EXE copiado para $FEXNAV_BIN/${NC}"
    fi
else
    echo -e "${YELLOW}  ! FexNav não encontrado automaticamente.${NC}"
    echo -e "  Copie o arquivo para: ${CYAN}$FEXNAV_BIN/${NC}"
    echo -e "  Formatos aceitos: .zip, .exe, binário Linux"
    echo -e "  Depois execute este script novamente."
fi

# --- Configurar Wine para FexNav ---
echo -e "${CYAN}[3/8]${NC} Configurando Wine otimizado para FexNav..."
FEXNAV_WINE_PREFIX="${FEXNAV_DIR}/wine-prefix"
mkdir -p "$FEXNAV_WINE_PREFIX"

# Wine optimized config
cat > "$FEXNAV_CONFIGS/wine.conf" << 'EOF'
# FexNav Wine Configuration
# Otimizado para performance do navegador
WINEPREFIX=/opt/fexnav/wine-prefix
WINEARCH=win64
WINE_LARGE_ADDRESS_AWARE=1
DXVK_ASYNC=1
STAGING_SHARED_MEMORY=1
__GL_SHADER_DISK_CACHE=1
__GL_SHADER_DISK_CACHE_SIZE=1073741824
mesa_glthread=true
WINE_FULLSCREEN_FSR=1
EOF

echo -e "${GREEN}  ✓ Wine otimizado configurado${NC}"

# --- Criar launcher principal ---
echo -e "${CYAN}[4/8]${NC} Criando launcher FexNav..."

cat > /usr/bin/fexnav << 'SCRIPT'
#!/bin/bash
# FexNav — PhantomArch Browser Launcher V3
# Executa FexNav.exe via Wine otimizado

FEXNAV_DIR="/opt/fexnav"
FEXNAV_BIN="$FEXNAV_DIR/bin"
LOG="$FEXNAV_DIR/logs/fexnav-$(date +%Y%m%d).log"

# Source Wine config
source "$FEXNAV_DIR/configs/wine.conf" 2>/dev/null

export WINEPREFIX="${WINEPREFIX:-$FEXNAV_DIR/wine-prefix}"
export WINEARCH=win64
export DXVK_ASYNC=1
export STAGING_SHARED_MEMORY=1

# Detect FexNav executable
FEXNAV_EXE=""

# Priority: Linux binary > AppImage > .exe
if [[ -x "$FEXNAV_BIN/fexnav" ]]; then
    FEXNAV_EXE="$FEXNAV_BIN/fexnav"
    exec "$FEXNAV_EXE" "$@" >> "$LOG" 2>&1
elif ls "$FEXNAV_BIN"/*.AppImage &>/dev/null; then
    FEXNAV_EXE=$(ls "$FEXNAV_BIN"/*.AppImage | head -1)
    chmod +x "$FEXNAV_EXE"
    exec "$FEXNAV_EXE" "$@" >> "$LOG" 2>&1
elif ls "$FEXNAV_BIN"/FexNav*.exe "$FEXNAV_BIN"/fexnav*.exe 2>/dev/null | head -1 > /tmp/.fexnav_exe; then
    FEXNAV_EXE=$(cat /tmp/.fexnav_exe)
    rm -f /tmp/.fexnav_exe

    # Initialize Wine prefix if needed
    if [[ ! -f "$WINEPREFIX/system.reg" ]]; then
        echo "Inicializando Wine para FexNav (primeira vez)..."
        wineboot --init 2>/dev/null
        # Install DXVK for better graphics
        setup_dxvk install 2>/dev/null || true
    fi

    # Run with Wine
    exec wine "$FEXNAV_EXE" "$@" >> "$LOG" 2>&1
else
    # Fallback: show help
    echo "FexNav não encontrado em $FEXNAV_BIN/"
    echo ""
    echo "Para instalar:"
    echo "  1. Copie o FexNav.zip ou FexNav.exe para ~/Downloads/"
    echo "  2. Execute: sudo install-fexnav-v3"
    echo ""
    echo "  Ou manualmente:"
    echo "  sudo cp FexNav.exe $FEXNAV_BIN/"
    echo "  sudo chmod +x $FEXNAV_BIN/FexNav.exe"
    echo ""
    echo "Abrindo Firefox como fallback..."
    exec firefox "$@" 2>/dev/null || exec chromium "$@" 2>/dev/null
fi
SCRIPT
chmod +x /usr/bin/fexnav

echo -e "${GREEN}  ✓ Launcher criado (/usr/bin/fexnav)${NC}"

# --- Desktop entry ---
echo -e "${CYAN}[5/8]${NC} Criando entrada desktop..."

cat > /usr/share/applications/fexnav.desktop << 'EOF'
[Desktop Entry]
Type=Application
Version=1.0
Name=FexNav
GenericName=Web Browser
Comment=FexNav — PhantomArch Web Browser
Exec=fexnav %U
Icon=/opt/fexnav/icons/fexnav.svg
Terminal=false
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/vnd.mozilla.xul+xml;application/rss+xml;application/rdf+xml;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;
StartupNotify=true
StartupWMClass=fexnav
Keywords=browser;internet;web;fexnav;navegador;
Actions=new-window;new-private-window;

[Desktop Action new-window]
Name=Nova Janela
Exec=fexnav --new-window

[Desktop Action new-private-window]
Name=Janela Privada
Exec=fexnav --private
EOF

# Create SVG icon
cat > /opt/fexnav/icons/fexnav.svg << 'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
  <defs>
    <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#bd93f9"/>
      <stop offset="50%" style="stop-color:#00fff7"/>
      <stop offset="100%" style="stop-color:#ff79c6"/>
    </linearGradient>
    <filter id="glow">
      <feGaussianBlur stdDeviation="2" result="blur"/>
      <feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
  </defs>
  <circle cx="64" cy="64" r="58" fill="#0a0a12" stroke="url(#grad)" stroke-width="4"/>
  <path d="M40 48 L64 32 L88 48 L88 80 L64 96 L40 80 Z" fill="none" stroke="url(#grad)" stroke-width="3" filter="url(#glow)"/>
  <text x="64" y="72" font-family="monospace" font-size="24" font-weight="bold" fill="url(#grad)" text-anchor="middle">FN</text>
</svg>
SVG

echo -e "${GREEN}  ✓ Desktop entry e ícone criados${NC}"

# --- Definir como navegador padrão ---
echo -e "${CYAN}[6/8]${NC} Definindo como navegador padrão..."

xdg-settings set default-web-browser fexnav.desktop 2>/dev/null || true
xdg-mime default fexnav.desktop x-scheme-handler/http 2>/dev/null || true
xdg-mime default fexnav.desktop x-scheme-handler/https 2>/dev/null || true
xdg-mime default fexnav.desktop text/html 2>/dev/null || true

# KDE specific
if [[ -f /usr/bin/kwriteconfig5 ]]; then
    kwriteconfig5 --file kdeglobals --group General --key BrowserApplication "fexnav.desktop" 2>/dev/null || true
fi

echo -e "${GREEN}  ✓ FexNav definido como navegador padrão${NC}"

# --- Adicionar à barra/dock ---
echo -e "${CYAN}[7/8]${NC} Adicionando à barra e dock..."

# Hyprland autostart / keybind
HYPR_CONF="/etc/skel/.config/hypr/hyprland.conf"
if [[ -f "$HYPR_CONF" ]] && ! grep -q "fexnav" "$HYPR_CONF"; then
    echo "" >> "$HYPR_CONF"
    echo "# FexNav browser" >> "$HYPR_CONF"
    echo 'bind = $mainMod, W, exec, fexnav' >> "$HYPR_CONF"
fi

# Add to Waybar favorites / launcher
# Create quick-launch script
cat > /usr/bin/phantom-quick-apps << 'SCRIPT'
#!/bin/bash
# Quick apps launcher for taskbar
case "$1" in
    browser|fexnav) fexnav & ;;
    files) dolphin & ;;
    terminal) kitty & ;;
    code) fexcode & ;;
    steam) steam & ;;
    settings) fex-control-center & ;;
    *) echo "Usage: phantom-quick-apps [browser|files|terminal|code|steam|settings]" ;;
esac
SCRIPT
chmod +x /usr/bin/phantom-quick-apps

# For user home dirs that exist
for user_home in /home/*/; do
    user=$(basename "$user_home")
    # Add to KDE taskbar favorites
    favorites_file="${user_home}.config/plasma-org.kde.plasma.desktop-appletsrc"
    if [[ -f "$favorites_file" ]] && ! grep -q "fexnav" "$favorites_file"; then
        sed -i 's/favorites=.*/&,fexnav.desktop/' "$favorites_file" 2>/dev/null || true
    fi
    chown -R "$user:$user" "$user_home/.config" 2>/dev/null || true
done

echo -e "${GREEN}  ✓ FexNav adicionado à barra (SUPER+W para abrir)${NC}"

# --- Criar scripts auxiliares ---
echo -e "${CYAN}[8/8]${NC} Criando scripts auxiliares..."

# repair-fexnav.sh
cat > /usr/bin/repair-fexnav << 'SCRIPT'
#!/bin/bash
echo "Reparando FexNav..."
# Kill stuck processes
pkill -f fexnav 2>/dev/null
pkill -f "wine.*FexNav" 2>/dev/null
sleep 1
# Clear cache
rm -rf /opt/fexnav/cache/* 2>/dev/null
# Reinitialize Wine prefix
rm -rf /opt/fexnav/wine-prefix 2>/dev/null
mkdir -p /opt/fexnav/wine-prefix
WINEPREFIX=/opt/fexnav/wine-prefix wineboot --init 2>/dev/null
echo "FexNav reparado. Execute: fexnav"
SCRIPT
chmod +x /usr/bin/repair-fexnav

# update-fexnav.sh
cat > /usr/bin/update-fexnav << 'SCRIPT'
#!/bin/bash
echo "Atualizando FexNav..."
echo "Procurando nova versão em ~/Downloads..."
NEW=$(find /home/*/Downloads -maxdepth 1 -iname "*fexnav*" -newer /opt/fexnav/bin -type f 2>/dev/null | head -1)
if [[ -n "$NEW" ]]; then
    echo "Nova versão encontrada: $NEW"
    if [[ "$NEW" == *.zip ]]; then
        unzip -o "$NEW" -d /opt/fexnav/bin/
    else
        cp "$NEW" /opt/fexnav/bin/
    fi
    chmod +x /opt/fexnav/bin/*
    echo "FexNav atualizado!"
else
    echo "Nenhuma versão mais nova encontrada."
    echo "Coloque o novo FexNav.zip em ~/Downloads/ e execute novamente."
fi
SCRIPT
chmod +x /usr/bin/update-fexnav

echo -e "${GREEN}  ✓ Scripts auxiliares criados${NC}"

# --- Resultado ---
echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}FexNav V3 instalado com sucesso!${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${CYAN}Comandos:${NC}"
echo -e "    fexnav          — Abrir navegador"
echo -e "    repair-fexnav   — Reparar problemas"
echo -e "    update-fexnav   — Atualizar versão"
echo -e "    SUPER+W         — Atalho rápido"
echo ""
echo -e "  ${YELLOW}Para instalar o FexNav.exe:${NC}"
echo -e "    1. Copie FexNav.zip para ~/Downloads/"
echo -e "    2. Execute: ${CYAN}sudo install-fexnav-v3${NC}"
echo -e "    Ou manualmente: ${CYAN}sudo cp FexNav.exe /opt/fexnav/bin/${NC}"
echo ""
