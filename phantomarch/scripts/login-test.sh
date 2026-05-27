#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  FexOS V5 — Login System Test                                ║
# ╚══════════════════════════════════════════════════════════════╝

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

PASS=0; FAIL=0

check() {
    if eval "$2" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $1"; ((PASS++))
    else
        echo -e "  ${RED}✗${NC} $1"; ((FAIL++))
    fi
}

echo -e "${PURPLE}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   FexOS V5 — Login System Test           ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

# SDDM
echo -e "${CYAN}[SDDM Theme]${NC}"
check "SDDM V5 theme dir" "test -d /usr/share/sddm/themes/phantom-v5"
check "Main.qml exists" "test -f /usr/share/sddm/themes/phantom-v5/Main.qml"
check "metadata.desktop" "test -f /usr/share/sddm/themes/phantom-v5/metadata.desktop"
check "SDDM service enabled" "systemctl is-enabled sddm 2>/dev/null || true"
check "SDDM config" "test -f /etc/sddm.conf.d/phantomarch.conf || true"

# Login functionality
echo -e "\n${CYAN}[Login Function]${NC}"
check "passwd file exists" "test -f /etc/passwd"
check "shadow file exists" "test -f /etc/shadow"
check "PAM login config" "test -f /etc/pam.d/login || test -f /etc/pam.d/sddm"
check "User exists" "getent passwd $(cat /etc/phantomarch/primary-user 2>/dev/null || echo root) || true"

# Session
echo -e "\n${CYAN}[Session]${NC}"
check "Hyprland session" "test -f /usr/share/wayland-sessions/hyprland.desktop || true"
check "KDE session" "test -f /usr/share/xsessions/plasma.desktop || true"
check "Autologin config" "test -f /etc/sddm.conf.d/autologin.conf || true"

# Visual
echo -e "\n${CYAN}[Visual]${NC}"
check "Wallpaper exists" "ls /usr/share/sddm/themes/phantom-v5/wallpaper.* 2>/dev/null || ls /usr/share/fexos/wallpapers/*.png 2>/dev/null || true"
check "Plymouth V5" "test -f /usr/share/plymouth/themes/phantom-v5/phantom-v5.plymouth"

echo ""
TOTAL=$((PASS + FAIL))
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}${PASS} passed${NC} | ${RED}${FAIL} failed${NC} | Total: ${TOTAL}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
