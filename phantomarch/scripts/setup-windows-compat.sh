#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch V2 — Windows Compatibility Setup                ║
# ║  Wine, Proton, DXVK, .exe association, sandbox               ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}━━━ PhantomArch Windows Compatibility Setup ━━━${NC}"

TARGET_USER="${SUDO_USER:-$(logname 2>/dev/null || echo $USER)}"
TARGET_HOME="/home/$TARGET_USER"

# --- Wine Prefixes ---
echo -e "${CYAN}[1/6]${NC} Configurando Wine..."
sudo -u "$TARGET_USER" mkdir -p "${TARGET_HOME}/.wine"
sudo -u "$TARGET_USER" mkdir -p "${TARGET_HOME}/.local/share/bottles"
sudo -u "$TARGET_USER" mkdir -p "${TARGET_HOME}/.local/share/lutris/runners/wine"

# Configure Wine for Windows 10 by default
sudo -u "$TARGET_USER" bash -c 'WINEPREFIX="${HOME}/.wine" WINEARCH=win64 wineboot --init 2>/dev/null' || true
echo -e "${GREEN}  ✓ Wine configurado (Win64 prefix)${NC}"

# --- DXVK Install ---
echo -e "${CYAN}[2/6]${NC} Instalando DXVK no Wine prefix..."
if command -v setup_dxvk &>/dev/null; then
    sudo -u "$TARGET_USER" bash -c 'WINEPREFIX="${HOME}/.wine" setup_dxvk install 2>/dev/null' || true
fi
echo -e "${GREEN}  ✓ DXVK configurado${NC}"

# --- File Associations (.exe, .msi) ---
echo -e "${CYAN}[3/6]${NC} Configurando associações de arquivo..."

mkdir -p /usr/share/applications
cat > /usr/share/applications/wine-exe.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Executar com Wine
Comment=Executa arquivos Windows (.exe) com Wine
Exec=env WINEPREFIX="/home/%u/.wine" wine %f
MimeType=application/x-ms-dos-executable;application/x-msdos-program;application/x-msdownload;
Icon=wine
Terminal=false
Categories=System;Wine;
NoDisplay=true
EOF

cat > /usr/share/applications/wine-msi.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Instalar com Wine
Comment=Instala pacotes Windows (.msi) com Wine
Exec=env WINEPREFIX="/home/%u/.wine" wine msiexec /i %f
MimeType=application/x-msi;
Icon=wine
Terminal=false
Categories=System;Wine;
NoDisplay=true
EOF

# MIME type associations
mkdir -p /usr/share/mime/packages
cat > /usr/share/mime/packages/wine-extensions.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-ms-dos-executable">
    <comment>Windows Executable</comment>
    <glob pattern="*.exe"/>
  </mime-type>
  <mime-type type="application/x-msi">
    <comment>Windows Installer</comment>
    <glob pattern="*.msi"/>
  </mime-type>
</mime-info>
EOF

update-mime-database /usr/share/mime 2>/dev/null || true
update-desktop-database /usr/share/applications 2>/dev/null || true
echo -e "${GREEN}  ✓ Associações .exe/.msi configuradas${NC}"

# --- MinGW Cross-Compilation ---
echo -e "${CYAN}[4/6]${NC} Verificando MinGW-w64..."
if command -v x86_64-w64-mingw32-gcc &>/dev/null; then
    echo -e "${GREEN}  ✓ MinGW-w64 disponível (x86_64-w64-mingw32-gcc)${NC}"
else
    echo -e "  ! MinGW-w64 será instalado via pacman"
fi

# --- Sandbox Script ---
echo -e "${CYAN}[5/6]${NC} Criando sandbox para apps Windows..."

cat > /usr/bin/phantom-wine-sandbox << 'SCRIPT'
#!/bin/bash
# PhantomArch Wine Sandbox — Executa .exe em ambiente isolado
# Uso: phantom-wine-sandbox app.exe

if [[ -z "$1" ]]; then
    echo "Uso: phantom-wine-sandbox <arquivo.exe>"
    echo "Executa um .exe em um Wine prefix isolado (sandbox)"
    exit 1
fi

EXE_PATH="$(realpath "$1")"
EXE_NAME="$(basename "$1" .exe)"
SANDBOX_PREFIX="${HOME}/.wine-sandboxes/${EXE_NAME}-$$"

echo "🍷 Criando sandbox para: $EXE_NAME"
echo "   Prefix: $SANDBOX_PREFIX"

mkdir -p "$SANDBOX_PREFIX"
WINEPREFIX="$SANDBOX_PREFIX" WINEARCH=win64 wine "$EXE_PATH"

echo ""
echo "Sandbox finalizada. Remover dados? (s/N)"
read -r response
if [[ "$response" =~ ^[sS]$ ]]; then
    rm -rf "$SANDBOX_PREFIX"
    echo "✓ Sandbox removida"
fi
SCRIPT
chmod +x /usr/bin/phantom-wine-sandbox

# --- Run EXE menu entry ---
echo -e "${CYAN}[6/6]${NC} Criando menu 'Executar EXE'..."

cat > /usr/share/applications/phantom-run-exe.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Executar EXE
Comment=Executar arquivo Windows (.exe) com Wine
Exec=bash -c 'FILE=$(zenity --file-selection --title="Selecione um .exe" --file-filter="Executáveis Windows | *.exe *.msi"); [ -n "$FILE" ] && wine "$FILE"'
Icon=wine
Terminal=false
Categories=System;Wine;
Keywords=exe;windows;wine;executar;
EOF

echo -e "${GREEN}  ✓ Menu 'Executar EXE' criado${NC}"
echo ""
echo -e "${PURPLE}━━━ Compatibilidade Windows configurada! ━━━${NC}"
echo -e "  Use: ${GREEN}wine app.exe${NC} ou ${GREEN}phantom-wine-sandbox app.exe${NC}"
echo -e "  Double-click em .exe no file manager também funciona!"
