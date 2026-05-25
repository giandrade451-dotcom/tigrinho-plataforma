#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch V2 — FexNav Browser Integration                 ║
# ║  Detecta e integra FexNav automaticamente                    ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

FEXNAV_DIR="/opt/fexnav"
FEXNAV_BIN=""

echo -e "${PURPLE}━━━ FexNav Browser Integration ━━━${NC}"
echo ""

# --- Criar estrutura ---
echo -e "${CYAN}[1/5]${NC} Criando estrutura FexNav..."
mkdir -p "$FEXNAV_DIR"/{bin,lib,data,icons,updates}
echo -e "${GREEN}  ✓ /opt/fexnav/ criado${NC}"

# --- Auto-detectar FexNav ---
echo -e "${CYAN}[2/5]${NC} Detectando FexNav..."

detect_fexnav() {
    # Buscar em locais comuns
    local search_paths=(
        "/opt/fexnav/bin/fexnav"
        "/opt/fexnav/FexNav"
        "/opt/fexnav/fexnav"
        "/usr/bin/fexnav"
        "/usr/local/bin/fexnav"
        "$HOME/FexNav"
        "$HOME/Downloads/FexNav"
        "$HOME/Downloads/fexnav"
    )

    for path in "${search_paths[@]}"; do
        if [[ -f "$path" ]]; then
            FEXNAV_BIN="$path"
            echo -e "${GREEN}  ✓ FexNav encontrado: $path${NC}"
            return 0
        fi
    done

    # Buscar AppImage
    local appimage=$(find /opt/fexnav "$HOME" -maxdepth 2 -name "FexNav*.AppImage" -o -name "fexnav*.AppImage" 2>/dev/null | head -1)
    if [[ -n "$appimage" ]]; then
        FEXNAV_BIN="$appimage"
        echo -e "${GREEN}  ✓ FexNav AppImage encontrado: $appimage${NC}"
        return 0
    fi

    # Buscar .exe (via Wine)
    local exe=$(find /opt/fexnav "$HOME" -maxdepth 2 -name "FexNav*.exe" -o -name "fexnav*.exe" 2>/dev/null | head -1)
    if [[ -n "$exe" ]]; then
        FEXNAV_BIN="wine:$exe"
        echo -e "${GREEN}  ✓ FexNav.exe encontrado: $exe (via Wine)${NC}"
        return 0
    fi

    echo -e "${YELLOW}  ! FexNav não detectado automaticamente${NC}"
    echo -e "  Copie o executável para /opt/fexnav/bin/ e execute este script novamente"
    return 1
}

detect_fexnav || true

# --- Criar launcher script ---
echo -e "${CYAN}[3/5]${NC} Criando launcher..."

cat > /usr/bin/fexnav << 'SCRIPT'
#!/bin/bash
# FexNav Launcher — Auto-detect and run
FEXNAV_DIR="/opt/fexnav"

# Priority order: Linux binary > AppImage > Wine .exe
if [[ -x "$FEXNAV_DIR/bin/fexnav" ]]; then
    exec "$FEXNAV_DIR/bin/fexnav" "$@"
elif [[ -x "$FEXNAV_DIR/bin/FexNav" ]]; then
    exec "$FEXNAV_DIR/bin/FexNav" "$@"
elif ls "$FEXNAV_DIR/bin/"*.AppImage &>/dev/null 2>&1; then
    APPIMAGE=$(ls "$FEXNAV_DIR/bin/"*.AppImage | head -1)
    chmod +x "$APPIMAGE"
    exec "$APPIMAGE" "$@"
elif ls "$FEXNAV_DIR/bin/"*.exe &>/dev/null 2>&1; then
    EXE=$(ls "$FEXNAV_DIR/bin/"*.exe | head -1)
    exec wine "$EXE" "$@"
else
    echo "FexNav não encontrado em $FEXNAV_DIR/bin/"
    echo "Copie o executável do FexNav para: $FEXNAV_DIR/bin/"
    echo ""
    echo "Formatos suportados:"
    echo "  - Linux binary (fexnav ou FexNav)"
    echo "  - AppImage (FexNav-*.AppImage)"
    echo "  - Windows exe (FexNav.exe — executado via Wine)"
    echo ""
    echo "Enquanto isso, abrindo Firefox como fallback..."
    exec firefox "$@"
fi
SCRIPT
chmod +x /usr/bin/fexnav

echo -e "${GREEN}  ✓ /usr/bin/fexnav launcher criado${NC}"

# --- Desktop Entry ---
echo -e "${CYAN}[4/5]${NC} Criando entrada desktop..."

cat > /usr/share/applications/fexnav.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=FexNav
GenericName=Web Browser
Comment=FexNav — Navegador PhantomArch
Exec=fexnav %u
Icon=fexnav
Terminal=false
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/vnd.mozilla.xul+xml;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
Keywords=internet;browser;web;navegador;fexnav;
Actions=new-window;new-private-window;

[Desktop Action new-window]
Name=Nova Janela
Exec=fexnav --new-window

[Desktop Action new-private-window]
Name=Navegação Privada
Exec=fexnav --private-window
EOF

# Icon placeholder (será substituído pelo real)
cat > /usr/share/icons/hicolor/256x256/apps/fexnav.svg << 'SVG'
<?xml version="1.0" encoding="UTF-8"?>
<svg width="256" height="256" viewBox="0 0 256 256" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#bd93f9"/>
      <stop offset="100%" style="stop-color:#00fff7"/>
    </linearGradient>
  </defs>
  <circle cx="128" cy="128" r="120" fill="#0a0a12" stroke="url(#grad)" stroke-width="6"/>
  <text x="128" y="145" font-family="monospace" font-size="80" font-weight="bold" fill="url(#grad)" text-anchor="middle">F</text>
  <text x="128" y="200" font-family="sans-serif" font-size="24" fill="#f8f8f2" text-anchor="middle">FexNav</text>
</svg>
SVG

echo -e "${GREEN}  ✓ Desktop entry e ícone criados${NC}"

# --- Set as default browser ---
echo -e "${CYAN}[5/5]${NC} Configurando como navegador padrão..."
xdg-settings set default-web-browser fexnav.desktop 2>/dev/null || true
echo -e "${GREEN}  ✓ FexNav definido como navegador padrão${NC}"

echo ""
echo -e "${PURPLE}━━━ FexNav Integration completa! ━━━${NC}"
echo ""
echo -e "  ${CYAN}Para instalar o FexNav:${NC}"
echo -e "  1. Copie o executável para: ${GREEN}/opt/fexnav/bin/${NC}"
echo -e "  2. Execute: ${GREEN}install-fexnav.sh${NC} novamente (opcional)"
echo ""
echo -e "  ${CYAN}Formatos suportados:${NC}"
echo -e "  • Linux binary → /opt/fexnav/bin/fexnav"
echo -e "  • AppImage → /opt/fexnav/bin/FexNav-*.AppImage"
echo -e "  • Windows exe → /opt/fexnav/bin/FexNav.exe (via Wine)"
echo ""
echo -e "  O launcher auto-detecta o formato ao executar."
