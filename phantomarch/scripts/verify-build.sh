#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch V2 — Verify Build                               ║
# ║  Verifica integridade da ISO e estrutura                      ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ARCHISO_DIR="${PROJECT_DIR}/archiso"
OUT_DIR="${ARCHISO_DIR}/out"

PASS=0
FAIL=0
WARN=0

check() {
    if eval "$2" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $1"
        ((PASS++))
    else
        echo -e "  ${RED}✗${NC} $1"
        ((FAIL++))
    fi
}

warn_check() {
    if eval "$2" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $1"
        ((PASS++))
    else
        echo -e "  ${YELLOW}!${NC} $1 (warning)"
        ((WARN++))
    fi
}

echo -e "${PURPLE}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║  PhantomArch Build Verification          ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

# --- Estrutura ---
echo -e "${CYAN}[Estrutura do Projeto]${NC}"
check "profiledef.sh existe" "test -f $ARCHISO_DIR/profiledef.sh"
check "pacman.conf existe" "test -f $ARCHISO_DIR/pacman.conf"
check "packages.x86_64 existe ou packages/ dir" "test -f $ARCHISO_DIR/packages.x86_64 || test -d $ARCHISO_DIR/packages"
check "grub.cfg existe" "test -f $ARCHISO_DIR/grub/grub.cfg"
check "syslinux.cfg existe" "test -f $ARCHISO_DIR/syslinux/syslinux.cfg"
check "efiboot existe" "test -d $ARCHISO_DIR/efiboot"

# --- Airootfs ---
echo ""
echo -e "${CYAN}[Airootfs]${NC}"
check "sysctl config" "test -f $ARCHISO_DIR/airootfs/etc/sysctl.d/99-phantomarch-performance.conf"
check "limits.conf" "test -f $ARCHISO_DIR/airootfs/etc/security/limits.conf"
check "modprobe.conf" "test -f $ARCHISO_DIR/airootfs/etc/modprobe.d/phantomarch.conf"
check "udev rules" "test -f $ARCHISO_DIR/airootfs/etc/udev/rules.d/99-phantomarch-gaming.rules"
check "Hyprland config" "test -f $ARCHISO_DIR/airootfs/etc/skel/.config/hypr/hyprland.conf"
check "Waybar config" "test -f $ARCHISO_DIR/airootfs/etc/skel/.config/waybar/config.jsonc"
check "Kitty config" "test -f $ARCHISO_DIR/airootfs/etc/skel/.config/kitty/kitty.conf"
check "Plymouth theme" "test -f $ARCHISO_DIR/airootfs/usr/share/plymouth/themes/phantom/phantom.plymouth"
check "Calamares branding" "test -f $ARCHISO_DIR/airootfs/etc/calamares/branding/phantomarch/branding.desc"

# --- Scripts ---
echo ""
echo -e "${CYAN}[Scripts]${NC}"
check "build-v2.sh executável" "test -x $SCRIPT_DIR/build-v2.sh"
check "post-install.sh executável" "test -x $SCRIPT_DIR/post-install.sh"
check "phantom-welcome.sh executável" "test -x $SCRIPT_DIR/phantom-welcome.sh"
check "phantom-optimizer.sh executável" "test -x $SCRIPT_DIR/phantom-optimizer.sh"
check "fex-control-center.sh executável" "test -x $SCRIPT_DIR/fex-control-center.sh"
check "install-fexnav.sh executável" "test -x $SCRIPT_DIR/install-fexnav.sh"
check "install-fexcode.sh executável" "test -x $SCRIPT_DIR/install-fexcode.sh"
check "setup-windows-compat.sh executável" "test -x $SCRIPT_DIR/setup-windows-compat.sh"
check "setup-android-dev.sh executável" "test -x $SCRIPT_DIR/setup-android-dev.sh"

# --- V2 Features ---
echo ""
echo -e "${CYAN}[V2 Features]${NC}"
check "FexAI engine" "test -f $PROJECT_DIR/fexai/fexai-engine.py"
check "FexAI server" "test -f $PROJECT_DIR/fexai/fexai-server.py"
check "FexCode settings" "test -f $PROJECT_DIR/fexcode/settings/settings.json"
check "FexCode theme" "test -f $PROJECT_DIR/fexcode/theme/phantom-neon-theme.json"
check "Waybar V2 config" "test -f $ARCHISO_DIR/airootfs/etc/skel/.config/waybar/config-v2.jsonc"
check "wlogout config" "test -f $ARCHISO_DIR/airootfs/etc/skel/.config/wlogout/layout"
check "Windows compat packages" "test -f $ARCHISO_DIR/packages/packages-windows-compat.txt"
check "Android dev packages" "test -f $ARCHISO_DIR/packages/packages-android-dev.txt"
check "AI packages" "test -f $ARCHISO_DIR/packages/packages-ai-dev.txt"

# --- ISO (se existir) ---
echo ""
echo -e "${CYAN}[ISO Output]${NC}"
ISO_FILE=$(ls -t "$OUT_DIR"/*.iso 2>/dev/null | head -1)
if [[ -n "$ISO_FILE" ]]; then
    check "ISO existe" "test -f '$ISO_FILE'"
    check "ISO > 1GB" "test $(stat -c%s '$ISO_FILE') -gt 1073741824"
    check "SHA256 existe" "test -f '${ISO_FILE}.sha256'"
    warn_check "ISO < 15GB (tamanho razoável)" "test $(stat -c%s '$ISO_FILE') -lt 16106127360"
else
    echo -e "  ${YELLOW}!${NC} Nenhuma ISO encontrada (execute build-v2.sh primeiro)"
    ((WARN++))
fi

# --- Resultado ---
echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Resultado: ${GREEN}${PASS} passed${NC} | ${RED}${FAIL} failed${NC} | ${YELLOW}${WARN} warnings${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [[ $FAIL -gt 0 ]]; then
    echo -e "  ${RED}Build NÃO está pronta. Corrija os erros acima.${NC}"
    exit 1
else
    echo -e "  ${GREEN}Build PRONTA para gerar ISO!${NC}"
fi
