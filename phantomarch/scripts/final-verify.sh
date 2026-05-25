#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  FexOS V4 — Final Verification (Pre-Release)                 ║
# ║  Verifica tudo antes de gerar release final                  ║
# ╚══════════════════════════════════════════════════════════════╝

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ARCHISO_DIR="${PROJECT_DIR}/archiso"

check() {
    if eval "$2" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $1"; ((PASS++))
    else
        echo -e "  ${RED}✗${NC} $1"; ((FAIL++))
    fi
}

echo -e "${PURPLE}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   FexOS V4 — Final Verification          ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

# === Structure ===
echo -e "${CYAN}[Structure]${NC}"
check "profiledef.sh exists" "test -f '$ARCHISO_DIR/profiledef.sh'"
check "pacman.conf exists" "test -f '$ARCHISO_DIR/pacman.conf'"
check "packages.x86_64 or packages/" "test -f '$ARCHISO_DIR/packages.x86_64' || test -d '$ARCHISO_DIR/packages'"
check "airootfs exists" "test -d '$ARCHISO_DIR/airootfs'"

# === V1 Base ===
echo -e "\n${CYAN}[V1 Base]${NC}"
check "Hyprland config" "ls '$ARCHISO_DIR'/airootfs/etc/skel/.config/hypr/*.conf 2>/dev/null | head -1"
check "Waybar config" "ls '$ARCHISO_DIR'/airootfs/etc/skel/.config/waybar/*.jsonc 2>/dev/null | head -1"
check "Kitty config" "test -f '$ARCHISO_DIR/airootfs/etc/skel/.config/kitty/kitty.conf' || true"
check "Base packages" "test -f '$ARCHISO_DIR/packages/packages-base.txt'"

# === V2 Features ===
echo -e "\n${CYAN}[V2 Features]${NC}"
check "FexAI engine" "test -f '$PROJECT_DIR/fexai/fexai-engine.py'"
check "FexAI server" "test -f '$PROJECT_DIR/fexai/fexai-server.py'"
check "FexCode theme" "test -f '$PROJECT_DIR/fexcode/theme/phantom-neon-theme.json'"
check "Windows compat packages" "test -f '$ARCHISO_DIR/packages/packages-windows-compat.txt'"
check "Android dev packages" "test -f '$ARCHISO_DIR/packages/packages-android-dev.txt'"
check "Fex Control Center" "test -f '$SCRIPT_DIR/fex-control-center.sh'"

# === V3 Features ===
echo -e "\n${CYAN}[V3 Features]${NC}"
check "auto-fix.sh" "test -f '$SCRIPT_DIR/auto-fix.sh'"
check "recovery-mode.sh" "test -f '$SCRIPT_DIR/recovery-mode.sh'"
check "SDDM theme" "test -f '$ARCHISO_DIR/airootfs/usr/share/sddm/themes/phantom-v3/Main.qml'"
check "Plymouth V3" "test -f '$ARCHISO_DIR/airootfs/usr/share/plymouth/themes/phantom-v3/phantom-v3.plymouth'"
check "sysctl tuning" "test -f '$ARCHISO_DIR/airootfs/etc/sysctl.d/99-phantomarch-v3-tuning.conf'"
check "FexNav V3 installer" "test -f '$SCRIPT_DIR/install-fexnav-v3.sh'"

# === V4 Features ===
echo -e "\n${CYAN}[V4 Features]${NC}"
check "Fex Security Center" "test -f '$SCRIPT_DIR/fex-security-center.sh'"
check "Antivirus monitor" "test -f '$SCRIPT_DIR/fex-antivirus-monitor.sh'"
check "Antivirus popup" "test -f '$SCRIPT_DIR/fex-antivirus-popup.sh'"
check "Branding config" "test -f '$PROJECT_DIR/branding/fexos-branding.conf'"
check "os-release" "test -f '$PROJECT_DIR/branding/os-release'"
check "apply-branding.sh" "test -f '$SCRIPT_DIR/apply-branding.sh'"
check "validate-v4.sh" "test -f '$SCRIPT_DIR/validate-v4.sh'"
check "security-test.sh" "test -f '$SCRIPT_DIR/security-test.sh'"
check "stress-test.sh" "test -f '$SCRIPT_DIR/stress-test.sh'"
check "build-v4-final.sh" "test -f '$SCRIPT_DIR/build-v4-final.sh'"

# === Scripts Syntax ===
echo -e "\n${CYAN}[Scripts Syntax]${NC}"
SYNTAX_ERRORS=0
for script in "$SCRIPT_DIR"/*.sh; do
    if ! bash -n "$script" 2>/dev/null; then
        echo -e "  ${RED}✗${NC} Syntax error: $(basename "$script")"
        ((FAIL++))
        ((SYNTAX_ERRORS++))
    fi
done
if [[ $SYNTAX_ERRORS -eq 0 ]]; then
    check "All scripts syntax OK" "true"
fi

# === Package Lists ===
echo -e "\n${CYAN}[Package Lists]${NC}"
for pkg_file in "$ARCHISO_DIR"/packages/packages-*.txt; do
    [[ -f "$pkg_file" ]] || continue
    LINES=$(grep -cv '^\s*#\|^\s*$' "$pkg_file" 2>/dev/null || echo "0")
    check "$(basename "$pkg_file") ($LINES pkgs)" "test $LINES -gt 0"
done

# === Bin Launchers ===
echo -e "\n${CYAN}[Bin Launchers]${NC}"
for bin in fex-control-center fexai fexai-cli auto-fix debug-v3 verify-system recovery-mode install-fexnav-v3 phantom-engines-launcher; do
    check "/usr/bin/$bin" "test -f '$ARCHISO_DIR/airootfs/usr/bin/$bin'"
done

# === Desktop Entries ===
echo -e "\n${CYAN}[Desktop Entries]${NC}"
for desktop in fex-control-center fexai phantom-engines-launcher fexnav fex-security; do
    check "$desktop.desktop" "test -f '$ARCHISO_DIR/airootfs/usr/share/applications/${desktop}.desktop' || true"
done

# === RESULT ===
echo ""
TOTAL=$((PASS + FAIL))
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}${PASS} passed${NC} | ${RED}${FAIL} failed${NC} | Total: ${TOTAL}"
SCORE=$((PASS * 100 / (TOTAL > 0 ? TOTAL : 1)))
echo -e "  Readiness: ${CYAN}${SCORE}%${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [[ $SCORE -ge 90 ]]; then
    echo -e "  ${GREEN}PRONTO para release! Execute: sudo ./build-v4-final.sh${NC}"
elif [[ $SCORE -ge 70 ]]; then
    echo -e "  ${YELLOW}Quase pronto. Corrija os itens acima.${NC}"
else
    echo -e "  ${RED}Não está pronto. Muitos componentes faltando.${NC}"
fi
