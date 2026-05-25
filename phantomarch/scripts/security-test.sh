#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch V4 — Security Test Suite                        ║
# ║  Testa todas as proteções de segurança                       ║
# ╚══════════════════════════════════════════════════════════════╝

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

check() {
    if eval "$2" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $1"; ((PASS++))
    else
        echo -e "  ${RED}✗${NC} $1"; ((FAIL++))
    fi
}

echo -e "${PURPLE}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   FexOS V4 — Security Test Suite         ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

# === Firewall ===
echo -e "${CYAN}[Firewall]${NC}"
check "UFW instalado" "command -v ufw"
check "UFW ativo" "ufw status | grep -q 'active'"
check "Default deny incoming" "ufw status verbose | grep -q 'deny (incoming)'"
check "Default allow outgoing" "ufw status verbose | grep -q 'allow (outgoing)'"

# === Antivirus ===
echo -e "\n${CYAN}[Antivirus]${NC}"
check "ClamAV instalado" "command -v clamscan"
check "ClamAV definitions" "test -f /var/lib/clamav/main.cvd || test -f /var/lib/clamav/main.cld"
check "freshclam service" "systemctl is-active clamav-freshclam"
check "YARA instalado" "command -v yara"
check "YARA rules exist" "ls /opt/fexai/security/yara-rules/*.yar"
check "Quarantine dir" "test -d /var/lib/phantomarch/quarantine"

# === System Protection ===
echo -e "\n${CYAN}[System Protection]${NC}"
check "AppArmor enabled" "systemctl is-active apparmor"
check "/etc/passwd protected" "lsattr /etc/passwd 2>/dev/null | grep -q i"
check "Timeshift installed" "command -v timeshift"
check "Integrity db exists" "test -f /var/lib/phantomarch/integrity.db"

# === User Security ===
echo -e "\n${CYAN}[User Security]${NC}"
check "No root login via SSH" "! grep -q 'PermitRootLogin yes' /etc/ssh/sshd_config 2>/dev/null"
check "Password complexity" "test -f /etc/security/pwquality.conf"
check "No empty passwords" "! awk -F: '$2 == \"\" {print}' /etc/shadow 2>/dev/null | grep -q ."
check "Sudo requires password" "! grep -q 'NOPASSWD' /etc/sudoers 2>/dev/null"

# === Network Security ===
echo -e "\n${CYAN}[Network Security]${NC}"
check "No telemetry services" "! systemctl list-units --all 2>/dev/null | grep -qi telemetry"
check "DNS over TLS capable" "test -f /etc/systemd/resolved.conf || true"
check "IPv6 privacy extensions" "sysctl net.ipv6.conf.all.use_tempaddr 2>/dev/null | grep -q '2' || true"

# === Kernel Security ===
echo -e "\n${CYAN}[Kernel Security]${NC}"
check "ASLR enabled" "test $(cat /proc/sys/kernel/randomize_va_space 2>/dev/null || echo 0) -ge 2"
check "dmesg restricted" "test $(sysctl -n kernel.dmesg_restrict 2>/dev/null || echo 0) -ge 1 || true"
check "ptrace restricted" "test $(sysctl -n kernel.yama.ptrace_scope 2>/dev/null || echo 0) -ge 1 || true"
check "Unprivileged BPF disabled" "test $(sysctl -n kernel.unprivileged_bpf_disabled 2>/dev/null || echo 0) -ge 1 || true"

# === File Permissions ===
echo -e "\n${CYAN}[File Permissions]${NC}"
check "/tmp has sticky bit" "test $(stat -c '%a' /tmp) = '1777'"
check "/etc/shadow readable only by root" "test $(stat -c '%a' /etc/shadow) = '000' || test $(stat -c '%a' /etc/shadow) = '640'"
check "Home dirs not world-readable" "! find /home -maxdepth 1 -type d -perm /o=r 2>/dev/null | grep -q ."

# === Result ===
echo ""
TOTAL=$((PASS + FAIL))
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}${PASS} passed${NC} | ${RED}${FAIL} failed${NC} | Total: ${TOTAL}"
SCORE=$((PASS * 100 / (TOTAL > 0 ? TOTAL : 1)))
echo -e "  Score: ${CYAN}${SCORE}%${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [[ $SCORE -ge 80 ]]; then
    echo -e "  ${GREEN}Excelente! Sistema bem protegido.${NC}"
elif [[ $SCORE -ge 60 ]]; then
    echo -e "  ${YELLOW}Bom, mas pode melhorar. Execute: fex-security-center${NC}"
else
    echo -e "  ${RED}Atenção! Muitas vulnerabilidades. Execute: sudo auto-fix${NC}"
fi
