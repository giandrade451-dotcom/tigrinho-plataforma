#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch V3 — Build System (Stable & Auto-Repair)        ║
# ║  Build com validação, auto-repair e testes automáticos       ║
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
LOG_FILE="${LOG_DIR}/build-v3-$(date +%Y%m%d_%H%M%S).log"
MAX_RETRIES=3

mkdir -p "$LOG_DIR" "$OUT_DIR"

log() { echo -e "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"; }
err() { log "${RED}ERRO: $1${NC}"; }
ok() { log "${GREEN}✓ $1${NC}"; }
warn() { log "${YELLOW}! $1${NC}"; }

echo -e "${PURPLE}" | tee -a "$LOG_FILE"
echo "  ╔══════════════════════════════════════════════════════════╗" | tee -a "$LOG_FILE"
echo "  ║   PhantomArch V3 — Stable Build System                   ║" | tee -a "$LOG_FILE"
echo "  ║   $(date '+%Y-%m-%d %H:%M:%S')                                  ║" | tee -a "$LOG_FILE"
echo "  ╚══════════════════════════════════════════════════════════╝" | tee -a "$LOG_FILE"
echo -e "${NC}" | tee -a "$LOG_FILE"

# --- Pre-checks ---
log "${CYAN}[PRE]${NC} Verificações..."

[[ $EUID -ne 0 ]] && { err "Execute como root: sudo $0"; exit 1; }

for cmd in mkarchiso pacman; do
    command -v "$cmd" &>/dev/null || { err "$cmd não encontrado"; exit 1; }
done

AVAILABLE_GB=$(df -BG "$ARCHISO_DIR" | awk 'NR==2 {gsub("G",""); print $4}')
[[ "$AVAILABLE_GB" -lt 20 ]] && { err "Espaço insuficiente: ${AVAILABLE_GB}GB (precisa 20GB+)"; exit 1; }

ok "Root OK | archiso OK | ${AVAILABLE_GB}GB livres"

# --- Verify structure ---
log "${CYAN}[1/8]${NC} Verificando estrutura..."
for f in profiledef.sh pacman.conf; do
    [[ -f "$ARCHISO_DIR/$f" ]] || { err "$f não encontrado!"; exit 1; }
done
ok "Estrutura válida"

# --- Generate package list ---
log "${CYAN}[2/8]${NC} Gerando lista de pacotes..."
cd "$ARCHISO_DIR"

cat packages/packages-*.txt 2>/dev/null | \
    grep -v '^\s*#' | grep -v '^\s*$' | \
    sed 's/#.*//' | sed 's/[[:space:]]*$//' | \
    sort -u > packages.x86_64

PKG_COUNT=$(wc -l < packages.x86_64)
ok "${PKG_COUNT} pacotes"

# --- Validate packages (with auto-remove) ---
log "${CYAN}[3/8]${NC} Validando pacotes (removendo inválidos)..."
pacman -Sy &>/dev/null  # refresh DB

VALID_PKGS=$(mktemp)
REMOVED=0

while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    if pacman -Ss "^${pkg}$" &>/dev/null || pacman -Sp "$pkg" &>/dev/null 2>&1; then
        echo "$pkg" >> "$VALID_PKGS"
    else
        warn "Removido: $pkg"
        ((REMOVED++)) || true
    fi
done < packages.x86_64

mv "$VALID_PKGS" packages.x86_64
PKG_COUNT=$(wc -l < packages.x86_64)
ok "${PKG_COUNT} pacotes válidos (${REMOVED} removidos)"

# --- Fix permissions ---
log "${CYAN}[4/8]${NC} Corrigindo permissões..."
find "$ARCHISO_DIR/airootfs" -name "*.sh" -exec chmod +x {} \; 2>/dev/null
find "$ARCHISO_DIR/airootfs/usr/bin" -type f -exec chmod +x {} \; 2>/dev/null
ok "Permissões OK"

# --- Clean previous ---
log "${CYAN}[5/8]${NC} Limpando build anterior..."
rm -rf "$BUILD_DIR" 2>/dev/null
ok "Limpo"

# --- Build with auto-retry ---
log "${CYAN}[6/8]${NC} Construindo ISO..."
BUILD_START=$(date +%s)
ATTEMPT=1
BUILD_OK=false

while [[ $ATTEMPT -le $MAX_RETRIES ]]; do
    log "  Tentativa ${ATTEMPT}/${MAX_RETRIES}..."

    if mkarchiso -v -w "$BUILD_DIR" -o "$OUT_DIR" "$ARCHISO_DIR" >> "$LOG_FILE" 2>&1; then
        BUILD_OK=true
        break
    else
        warn "Tentativa $ATTEMPT falhou"

        # Auto-repair: find and remove problematic package
        PROBLEM_PKG=$(tail -100 "$LOG_FILE" | grep -oP "error:.*target not found: \K\S+" | head -1)
        if [[ -n "$PROBLEM_PKG" ]]; then
            warn "Removendo pacote problemático: $PROBLEM_PKG"
            sed -i "/^${PROBLEM_PKG}$/d" packages.x86_64
        fi

        # Clean for retry
        rm -rf "$BUILD_DIR" 2>/dev/null
        ((ATTEMPT++))
    fi
done

BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))
BUILD_MIN=$((BUILD_TIME / 60))

if [[ "$BUILD_OK" != "true" ]]; then
    err "Build falhou após ${MAX_RETRIES} tentativas!"
    err "Log: $LOG_FILE"
    exit 1
fi

ok "Build concluída em ${BUILD_MIN}min (tentativa ${ATTEMPT})"

# --- Verify ISO ---
log "${CYAN}[7/8]${NC} Verificando ISO..."
ISO_FILE=$(ls -t "$OUT_DIR"/*.iso 2>/dev/null | head -1)
[[ -z "$ISO_FILE" ]] && { err "ISO não encontrada!"; exit 1; }

ISO_SIZE=$(du -h "$ISO_FILE" | awk '{print $1}')
ISO_BYTES=$(stat -c%s "$ISO_FILE")

# Size sanity check (should be > 1GB)
[[ $ISO_BYTES -lt 1073741824 ]] && { err "ISO muito pequena (${ISO_SIZE}). Possível erro."; exit 1; }

ok "ISO: $(basename "$ISO_FILE") (${ISO_SIZE})"

# --- Checksums & metadata ---
log "${CYAN}[8/8]${NC} Gerando checksums e metadados..."
cd "$OUT_DIR"
sha256sum "$(basename "$ISO_FILE")" > "$(basename "$ISO_FILE").sha256"
md5sum "$(basename "$ISO_FILE")" > "$(basename "$ISO_FILE").md5"

# Build info
cat > "$(basename "$ISO_FILE").info" << EOF
PhantomArch V3 Build Info
=========================
Date: $(date)
ISO: $(basename "$ISO_FILE")
Size: $ISO_SIZE
SHA256: $(cat "$(basename "$ISO_FILE").sha256" | awk '{print $1}')
Packages: $PKG_COUNT
Build Time: ${BUILD_MIN}min
Attempts: $ATTEMPT
Kernel: linux-zen
Desktop: Hyprland + KDE Plasma 6
EOF

ok "Checksums e info gerados"

# --- Final Report ---
echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}PhantomArch V3 — BUILD SUCESSO!${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${CYAN}ISO:${NC}      $ISO_FILE"
echo -e "  ${CYAN}Tamanho:${NC}  $ISO_SIZE"
echo -e "  ${CYAN}Tempo:${NC}    ${BUILD_MIN} minutos"
echo -e "  ${CYAN}Pacotes:${NC}  $PKG_COUNT"
echo -e "  ${CYAN}Retries:${NC}  $ATTEMPT"
echo ""
echo -e "  ${YELLOW}Gravar USB:${NC} sudo dd bs=4M if=$ISO_FILE of=/dev/sdX status=progress"
echo -e "  ${YELLOW}QEMU:${NC}      qemu-system-x86_64 -m 4G -enable-kvm -cdrom $ISO_FILE"
echo ""
