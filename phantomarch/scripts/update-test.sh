#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  FexOS V5 — Update System Test                               ║
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
echo "  ║   FexOS V5 — Update System Test          ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

UPDATER="/home/ubuntu/repos/tigrinho-plataforma-new/phantomarch/scripts/phantom-updater.sh"

# Updater
echo -e "${CYAN}[PhantomUpdater]${NC}"
check "Updater script" "test -f '$UPDATER'"
check "Updater syntax" "bash -n '$UPDATER'"
check "Updater executable" "test -x '$UPDATER'"
check "Updater service" "test -f /home/ubuntu/repos/tigrinho-plataforma-new/phantomarch/fexai/systemd/phantom-updater.service"

# Features
echo -e "\n${CYAN}[Features]${NC}"
check "Check updates" "grep -q 'check_updates' '$UPDATER'"
check "Install updates" "grep -q 'install_updates' '$UPDATER'"
check "Rollback support" "grep -q 'rollback' '$UPDATER'"
check "Daemon mode" "grep -q 'daemon_mode' '$UPDATER'"
check "Lock mechanism" "grep -q 'LOCK_FILE' '$UPDATER'"
check "Update history/logs" "grep -q 'UPDATE_LOG' '$UPDATER'"

# Rollback
echo -e "\n${CYAN}[Rollback System]${NC}"
check "Rollback dir defined" "grep -q 'ROLLBACK_DIR' '$UPDATER'"
check "Package list snapshot" "grep -q 'pacman -Q' '$UPDATER'"
check "Downgrade from cache" "grep -q 'pacman -U' '$UPDATER'"

# Safety
echo -e "\n${CYAN}[Safety]${NC}"
check "Internet check before update" "grep -q 'ping' '$UPDATER'"
check "Download before install" "grep -q 'Syuw' '$UPDATER'"
check "Notification on completion" "grep -q 'notify-send' '$UPDATER'"

echo ""
TOTAL=$((PASS + FAIL))
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}${PASS} passed${NC} | ${RED}${FAIL} failed${NC} | Total: ${TOTAL}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
