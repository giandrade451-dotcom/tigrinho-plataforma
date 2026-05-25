#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch V2 — Build System Enhanced                      ║
# ║  Build ISO com auto-fix, recovery, logs e verificação        ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

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
LOG_FILE="${LOG_DIR}/build-$(date +%Y%m%d_%H%M%S).log"

mkdir -p "$LOG_DIR" "$OUT_DIR"

# Logging
log() {
    local msg="[$(date '+%H:%M:%S')] $1"
    echo -e "$msg" | tee -a "$LOG_FILE"
}

error() {
    log "${RED}ERRO: $1${NC}"
}

success() {
    log "${GREEN}✓ $1${NC}"
}

warn() {
    log "${YELLOW}! $1${NC}"
}

# Header
echo -e "${PURPLE}" | tee -a "$LOG_FILE"
echo "  ╔══════════════════════════════════════════════════════════╗" | tee -a "$LOG_FILE"
echo "  ║       PhantomArch V2 — Build System Enhanced             ║" | tee -a "$LOG_FILE"
echo "  ║       $(date '+%Y-%m-%d %H:%M:%S')                              ║" | tee -a "$LOG_FILE"
echo "  ╚══════════════════════════════════════════════════════════╝" | tee -a "$LOG_FILE"
echo -e "${NC}" | tee -a "$LOG_FILE"

# --- Step 1: Verificações ---
log "${CYAN}[1/10]${NC} Verificações de sistema..."

if [[ $EUID -ne 0 ]]; then
    error "Execute como root: sudo $0"
    exit 1
fi
success "Root: OK"

if ! command -v mkarchiso &>/dev/null; then
    warn "archiso não encontrado, instalando..."
    pacman -S --noconfirm archiso || { error "Falha ao instalar archiso"; exit 1; }
fi
success "archiso: OK"

# Disk space check (need 25GB+)
AVAILABLE_GB=$(df -BG "$ARCHISO_DIR" | awk 'NR==2 {gsub("G",""); print $4}')
if [[ "$AVAILABLE_GB" -lt 25 ]]; then
    error "Espaço insuficiente: ${AVAILABLE_GB}GB disponível (precisa 25GB+)"
    exit 1
fi
success "Espaço em disco: ${AVAILABLE_GB}GB disponível"

# RAM check
RAM_GB=$(free -g | awk 'NR==2 {print $2}')
if [[ "$RAM_GB" -lt 4 ]]; then
    warn "RAM baixa: ${RAM_GB}GB (recomendado 8GB+)"
fi
success "RAM: ${RAM_GB}GB"

# --- Step 2: Chaotic-AUR ---
log "${CYAN}[2/10]${NC} Configurando Chaotic-AUR..."
if ! grep -q "chaotic-aur" /etc/pacman.conf 2>/dev/null; then
    pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com 2>/dev/null || true
    pacman-key --lsign-key 3056513887B78AEB 2>/dev/null || true
    pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 2>/dev/null || true
    pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' 2>/dev/null || true

    if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
        echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf
    fi
    pacman -Sy
fi
success "Chaotic-AUR: configurado"

# --- Step 3: Gerar lista de pacotes ---
log "${CYAN}[3/10]${NC} Gerando lista unificada de pacotes..."
cd "$ARCHISO_DIR"

cat packages/packages-*.txt 2>/dev/null | \
    grep -v '^\s*#' | grep -v '^\s*$' | \
    sed 's/#.*//' | sed 's/[[:space:]]*$//' | \
    sort -u > packages.x86_64

PKG_COUNT=$(wc -l < packages.x86_64)
success "Pacotes: ${PKG_COUNT} pacotes na lista"

# --- Step 4: Validar pacotes ---
log "${CYAN}[4/10]${NC} Validando disponibilidade de pacotes..."
MISSING=0
MISSING_FILE="${LOG_DIR}/missing-packages.txt"
> "$MISSING_FILE"

while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    if ! pacman -Ss "^${pkg}$" &>/dev/null; then
        echo "$pkg" >> "$MISSING_FILE"
        ((MISSING++)) || true
    fi
done < packages.x86_64

if [[ $MISSING -gt 0 ]]; then
    warn "${MISSING} pacotes não encontrados (removidos da lista)"
    warn "Ver: ${MISSING_FILE}"
    # Auto-fix: remove missing packages
    while IFS= read -r pkg; do
        sed -i "/^${pkg}$/d" packages.x86_64
    done < "$MISSING_FILE"
    PKG_COUNT=$(wc -l < packages.x86_64)
    success "Lista corrigida: ${PKG_COUNT} pacotes válidos"
else
    success "Todos os pacotes validados!"
fi

# --- Step 5: Preparar airootfs ---
log "${CYAN}[5/10]${NC} Preparando airootfs..."

# Ensure scripts are executable
find "$ARCHISO_DIR/airootfs" -name "*.sh" -exec chmod +x {} \;
find "$ARCHISO_DIR/airootfs/usr/bin" -type f -exec chmod +x {} \; 2>/dev/null || true

success "Permissões corrigidas"

# --- Step 6: Limpar build anterior ---
log "${CYAN}[6/10]${NC} Limpando build anterior..."
if [[ -d "$BUILD_DIR" ]]; then
    rm -rf "$BUILD_DIR"
    success "Build anterior removido"
else
    success "Nenhum build anterior"
fi

# --- Step 7: Build ISO ---
log "${CYAN}[7/10]${NC} Construindo ISO (pode demorar 15-60 min)..."
log "  Log completo: $LOG_FILE"

BUILD_START=$(date +%s)

mkarchiso -v -w "$BUILD_DIR" -o "$OUT_DIR" "$ARCHISO_DIR" 2>&1 | tee -a "$LOG_FILE"
BUILD_STATUS=${PIPESTATUS[0]}

BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))
BUILD_MIN=$((BUILD_TIME / 60))
BUILD_SEC=$((BUILD_TIME % 60))

if [[ $BUILD_STATUS -ne 0 ]]; then
    error "Build falhou! (${BUILD_MIN}m ${BUILD_SEC}s)"
    error "Verifique: $LOG_FILE"
    echo ""
    echo -e "${YELLOW}Tentando auto-fix...${NC}"

    # Auto-fix: Try removing problematic packages
    LAST_ERROR=$(tail -50 "$LOG_FILE" | grep -oP "error:.*target not found: \K.*" | head -1)
    if [[ -n "$LAST_ERROR" ]]; then
        warn "Removendo pacote problemático: $LAST_ERROR"
        sed -i "/^${LAST_ERROR}$/d" packages.x86_64
        warn "Execute o build novamente: sudo $0"
    fi
    exit 1
fi

success "Build concluída em ${BUILD_MIN}m ${BUILD_SEC}s!"

# --- Step 8: Verificação da ISO ---
log "${CYAN}[8/10]${NC} Verificando ISO..."
ISO_FILE=$(ls -t "$OUT_DIR"/*.iso 2>/dev/null | head -1)

if [[ -z "$ISO_FILE" ]]; then
    error "ISO não encontrada em $OUT_DIR/"
    exit 1
fi

ISO_SIZE=$(du -h "$ISO_FILE" | awk '{print $1}')
success "ISO gerada: $(basename "$ISO_FILE") (${ISO_SIZE})"

# --- Step 9: Checksums ---
log "${CYAN}[9/10]${NC} Gerando checksums..."
cd "$OUT_DIR"
sha256sum "$(basename "$ISO_FILE")" > "$(basename "$ISO_FILE").sha256"
md5sum "$(basename "$ISO_FILE")" > "$(basename "$ISO_FILE").md5"
success "SHA256 e MD5 gerados"

# --- Step 10: Relatório final ---
log "${CYAN}[10/10]${NC} Relatório final"
echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}BUILD COMPLETA!${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${CYAN}ISO:${NC}      $ISO_FILE"
echo -e "  ${CYAN}Tamanho:${NC}  $ISO_SIZE"
echo -e "  ${CYAN}Tempo:${NC}    ${BUILD_MIN}m ${BUILD_SEC}s"
echo -e "  ${CYAN}Pacotes:${NC}  $PKG_COUNT"
echo -e "  ${CYAN}Log:${NC}      $LOG_FILE"
echo ""
echo -e "  ${YELLOW}Próximo passo:${NC}"
echo -e "  sudo dd bs=4M if=$ISO_FILE of=/dev/sdX status=progress"
echo -e "  ou QEMU: qemu-system-x86_64 -m 4G -enable-kvm -cdrom $ISO_FILE"
echo ""
