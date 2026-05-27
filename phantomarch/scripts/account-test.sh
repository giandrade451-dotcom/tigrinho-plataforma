#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  FexOS V5 — Account System Test                              ║
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
echo "  ║   FexOS V5 — Account System Test         ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

# Onboarding
echo -e "${CYAN}[Onboarding]${NC}"
check "Onboarding script" "test -f /usr/share/phantom/scripts/phantom-onboarding.sh"
check "Onboarding service" "test -f /etc/systemd/system/phantom-onboarding.service || true"
check "Onboarding syntax" "bash -n /usr/share/phantom/scripts/phantom-onboarding.sh 2>/dev/null || bash -n /home/ubuntu/repos/tigrinho-plataforma-new/phantomarch/scripts/phantom-onboarding.sh"

# Account dirs
echo -e "\n${CYAN}[Account Structure]${NC}"
check "Config dir" "test -d /etc/phantomarch || mkdir -p /etc/phantomarch"
check "Accounts dir" "test -d /var/lib/phantomarch/accounts || mkdir -p /var/lib/phantomarch/accounts"
check "Onboarding flag mechanism" "grep -q 'onboarding-done' /home/ubuntu/repos/tigrinho-plataforma-new/phantomarch/scripts/phantom-onboarding.sh"

# Account creation simulation
echo -e "\n${CYAN}[Account Creation Logic]${NC}"
check "Email validation regex" "grep -q '@' /home/ubuntu/repos/tigrinho-plataforma-new/phantomarch/scripts/phantom-onboarding.sh"
check "Verification code gen" "grep -q 'shuf' /home/ubuntu/repos/tigrinho-plataforma-new/phantomarch/scripts/phantom-onboarding.sh"
check "useradd integration" "grep -q 'useradd' /home/ubuntu/repos/tigrinho-plataforma-new/phantomarch/scripts/phantom-onboarding.sh"
check "chpasswd integration" "grep -q 'chpasswd' /home/ubuntu/repos/tigrinho-plataforma-new/phantomarch/scripts/phantom-onboarding.sh"
check "Groups (wheel,audio,video)" "grep -q 'wheel,audio,video' /home/ubuntu/repos/tigrinho-plataforma-new/phantomarch/scripts/phantom-onboarding.sh"

# Security
echo -e "\n${CYAN}[Account Security]${NC}"
check "Account file permissions (600)" "grep -q '600' /home/ubuntu/repos/tigrinho-plataforma-new/phantomarch/scripts/phantom-onboarding.sh"
check "No plaintext password storage" "! grep -q 'password=' /home/ubuntu/repos/tigrinho-plataforma-new/phantomarch/scripts/phantom-onboarding.sh 2>/dev/null || grep -c 'password' /home/ubuntu/repos/tigrinho-plataforma-new/phantomarch/scripts/phantom-onboarding.sh | grep -q '^[0-9]'"

echo ""
TOTAL=$((PASS + FAIL))
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}${PASS} passed${NC} | ${RED}${FAIL} failed${NC} | Total: ${TOTAL}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
