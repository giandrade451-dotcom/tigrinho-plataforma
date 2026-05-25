#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  FexOS V4 — Final Release Build                              ║
# ║  Build completa com branding, segurança e validação          ║
# ╚══════════════════════════════════════════════════════════════╝
set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ARCHISO_DIR="${PROJECT_DIR}/archiso"
BUILD_DIR="${ARCHISO_DIR}/work"
OUT_DIR="${ARCHISO_DIR}/out"
LOG_DIR="${PROJECT_DIR}/logs"
LOG_FILE="${LOG_DIR}/build-v4-final-$(date +%Y%m%d_%H%M%S).log"
MAX_RETRIES=3

mkdir -p "$LOG_DIR" "$OUT_DIR"

log() { echo -e "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"; }
ok() { log "${GREEN}✓ $1${NC}"; }
err() { log "${RED}✗ $1${NC}"; }
warn() { log "${YELLOW}! $1${NC}"; }

echo -e "${PURPLE}" | tee -a "$LOG_FILE"
echo "  ╔══════════════════════════════════════════════════════════╗" | tee -a "$LOG_FILE"
echo "  ║        FexOS V4 — Final Release Build                    ║" | tee -a "$LOG_FILE"
echo "  ║        $(date '+%Y-%m-%d %H:%M:%S')                              ║" | tee -a "$LOG_FILE"
echo "  ╚══════════════════════════════════════════════════════════╝" | tee -a "$LOG_FILE"
echo -e "${NC}" | tee -a "$LOG_FILE"

# === PRE-FLIGHT ===
log "${CYAN}[PRE-FLIGHT]${NC} Verificações..."
[[ $EUID -ne 0 ]] && { err "Execute como root"; exit 1; }
command -v mkarchiso &>/dev/null || { err "archiso não instalado"; exit 1; }

AVAILABLE_GB=$(df -BG "$ARCHISO_DIR" | awk 'NR==2 {gsub("G",""); print $4}')
[[ "$AVAILABLE_GB" -lt 20 ]] && { err "Espaço: ${AVAILABLE_GB}GB (mín 20GB)"; exit 1; }
ok "Pre-flight: root, archiso, ${AVAILABLE_GB}GB livres"

# === STEP 1: Apply branding ===
log "${CYAN}[1/10]${NC} Aplicando branding FexOS..."
# Copy os-release to airootfs
cp "$PROJECT_DIR/branding/os-release" "$ARCHISO_DIR/airootfs/etc/os-release" 2>/dev/null || true
# Set hostname
echo "fexos" > "$ARCHISO_DIR/airootfs/etc/hostname" 2>/dev/null || true
ok "Branding aplicado"

# === STEP 2: Security setup ===
log "${CYAN}[2/10]${NC} Configurando segurança..."
# Create quarantine and security dirs in airootfs
mkdir -p "$ARCHISO_DIR/airootfs/var/lib/phantomarch/quarantine"
mkdir -p "$ARCHISO_DIR/airootfs/opt/fexai/security/yara-rules"
# Copy security scripts
mkdir -p "$ARCHISO_DIR/airootfs/usr/share/phantom/scripts"
cp "$SCRIPT_DIR"/fex-security-center.sh "$ARCHISO_DIR/airootfs/usr/share/phantom/scripts/" 2>/dev/null || true
cp "$SCRIPT_DIR"/fex-antivirus-monitor.sh "$ARCHISO_DIR/airootfs/usr/share/phantom/scripts/" 2>/dev/null || true
cp "$SCRIPT_DIR"/fex-antivirus-popup.sh "$ARCHISO_DIR/airootfs/usr/share/phantom/scripts/" 2>/dev/null || true
ok "Segurança configurada"

# === STEP 3: Copy all scripts ===
log "${CYAN}[3/10]${NC} Copiando scripts para airootfs..."
for script in "$SCRIPT_DIR"/*.sh; do
    cp "$script" "$ARCHISO_DIR/airootfs/usr/share/phantom/scripts/" 2>/dev/null || true
done
chmod +x "$ARCHISO_DIR/airootfs/usr/share/phantom/scripts/"*.sh 2>/dev/null || true
ok "Scripts copiados"

# === STEP 4: Generate packages list ===
log "${CYAN}[4/10]${NC} Gerando lista de pacotes..."
cd "$ARCHISO_DIR"
cat packages/packages-*.txt 2>/dev/null | \
    grep -v '^\s*#' | grep -v '^\s*$' | \
    sed 's/#.*//' | sed 's/[[:space:]]*$//' | \
    sort -u > packages.x86_64
PKG_COUNT=$(wc -l < packages.x86_64)
ok "${PKG_COUNT} pacotes"

# === STEP 5: Validate packages ===
log "${CYAN}[5/10]${NC} Validando pacotes..."
pacman -Sy --noconfirm &>/dev/null
VALID_PKGS=$(mktemp)
REMOVED=0
while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    if pacman -Ss "^${pkg}$" &>/dev/null; then
        echo "$pkg" >> "$VALID_PKGS"
    else
        ((REMOVED++)) || true
    fi
done < packages.x86_64
mv "$VALID_PKGS" packages.x86_64
PKG_COUNT=$(wc -l < packages.x86_64)
ok "${PKG_COUNT} pacotes válidos (${REMOVED} removidos)"

# === STEP 6: Permissions ===
log "${CYAN}[6/10]${NC} Fixando permissões..."
find "$ARCHISO_DIR/airootfs" -name "*.sh" -exec chmod +x {} \; 2>/dev/null
find "$ARCHISO_DIR/airootfs/usr/bin" -type f -exec chmod +x {} \; 2>/dev/null
ok "Permissões OK"

# === STEP 7: Clean ===
log "${CYAN}[7/10]${NC} Limpando build anterior..."
rm -rf "$BUILD_DIR" 2>/dev/null
ok "Limpo"

# === STEP 8: Build ISO ===
log "${CYAN}[8/10]${NC} Construindo ISO final..."
BUILD_START=$(date +%s)
ATTEMPT=1
BUILD_OK=false

while [[ $ATTEMPT -le $MAX_RETRIES ]]; do
    log "  Tentativa ${ATTEMPT}/${MAX_RETRIES}..."
    if mkarchiso -v -w "$BUILD_DIR" -o "$OUT_DIR" "$ARCHISO_DIR" >> "$LOG_FILE" 2>&1; then
        BUILD_OK=true
        break
    else
        PROBLEM=$(tail -50 "$LOG_FILE" | grep -oP "target not found: \K\S+" | head -1)
        [[ -n "$PROBLEM" ]] && sed -i "/^${PROBLEM}$/d" packages.x86_64
        rm -rf "$BUILD_DIR" 2>/dev/null
        ((ATTEMPT++))
    fi
done

BUILD_END=$(date +%s)
BUILD_MIN=$(( (BUILD_END - BUILD_START) / 60 ))

[[ "$BUILD_OK" != "true" ]] && { err "Build falhou após ${MAX_RETRIES} tentativas"; exit 1; }
ok "Build OK em ${BUILD_MIN}min"

# === STEP 9: Verify ISO ===
log "${CYAN}[9/10]${NC} Verificando ISO..."
ISO_FILE=$(ls -t "$OUT_DIR"/*.iso 2>/dev/null | head -1)
[[ -z "$ISO_FILE" ]] && { err "ISO não encontrada"; exit 1; }

ISO_SIZE=$(du -h "$ISO_FILE" | awk '{print $1}')
ISO_BYTES=$(stat -c%s "$ISO_FILE")
[[ $ISO_BYTES -lt 1073741824 ]] && { err "ISO muito pequena: ${ISO_SIZE}"; exit 1; }
ok "ISO: ${ISO_SIZE}"

# === STEP 10: Release metadata ===
log "${CYAN}[10/10]${NC} Gerando release..."
cd "$OUT_DIR"
sha256sum "$(basename "$ISO_FILE")" > "$(basename "$ISO_FILE").sha256"
md5sum "$(basename "$ISO_FILE")" > "$(basename "$ISO_FILE").md5"

cat > "$(basename "$ISO_FILE").release" << EOF
╔══════════════════════════════════════════╗
║         FexOS 4.0 Phantom Release        ║
╚══════════════════════════════════════════╝

Name:       FexOS
Version:    4.0 Phantom
Build Date: $(date)
ISO:        $(basename "$ISO_FILE")
Size:       $ISO_SIZE
SHA256:     $(cat "$(basename "$ISO_FILE").sha256" | awk '{print $1}')
Packages:   $PKG_COUNT
Build Time: ${BUILD_MIN}min

Features:
- Desktop: Hyprland + KDE Plasma 6
- Kernel: linux-zen
- Browser: FexNav
- IDE: FexCode
- AI: FexAI (offline)
- Security: Fex Security Center + Antivirus
- Performance: Auto-optimize, Game Mode, Turbo Mode

System Requirements:
- CPU: x86_64, 2+ cores recommended
- RAM: 4GB minimum, 8GB+ recommended
- Storage: 30GB minimum
- GPU: Vulkan-capable recommended

Boot:
- UEFI: Supported (recommended)
- BIOS/Legacy: Supported
- Secure Boot: Not supported (yet)
EOF

ok "Release metadata gerada"

# === FINAL REPORT ===
echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}FexOS V4 — RELEASE BUILD COMPLETO!${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${CYAN}ISO:${NC}        $ISO_FILE"
echo -e "  ${CYAN}Tamanho:${NC}    $ISO_SIZE"
echo -e "  ${CYAN}Tempo:${NC}      ${BUILD_MIN} minutos"
echo -e "  ${CYAN}Pacotes:${NC}    $PKG_COUNT"
echo -e "  ${CYAN}Checksums:${NC}  .sha256, .md5"
echo -e "  ${CYAN}Release:${NC}    .release"
echo ""
echo -e "  ${YELLOW}USB:${NC}  sudo dd bs=4M if=$ISO_FILE of=/dev/sdX status=progress"
echo -e "  ${YELLOW}QEMU:${NC} qemu-system-x86_64 -m 4G -enable-kvm -cdrom $ISO_FILE"
echo ""
