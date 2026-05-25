#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch — ISO Build Script                              ║
# ║  Gera a ISO bootável do PhantomArch                          ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

# --- Variáveis ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${SCRIPT_DIR}/work"
OUT_DIR="${SCRIPT_DIR}/out"
PROFILE_DIR="${SCRIPT_DIR}"

# --- Cores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

banner() {
    echo -e "${PURPLE}"
    echo "  ██████╗ ██╗  ██╗ █████╗ ███╗   ██╗████████╗ ██████╗ ███╗   ███╗"
    echo "  ██╔══██╗██║  ██║██╔══██╗████╗  ██║╚══██╔══╝██╔═══██╗████╗ ████║"
    echo "  ██████╔╝███████║███████║██╔██╗ ██║   ██║   ██║   ██║██╔████╔██║"
    echo "  ██╔═══╝ ██╔══██║██╔══██║██║╚██╗██║   ██║   ██║   ██║██║╚██╔╝██║"
    echo "  ██║     ██║  ██║██║  ██║██║ ╚████║   ██║   ╚██████╔╝██║ ╚═╝ ██║"
    echo "  ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝"
    echo -e "${CYAN}              Ghost in the Machine — Build System${NC}"
    echo ""
}

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${RED}[WARN]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

# --- Verificações ---
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_warn "Este script deve ser executado como root!"
        echo "Use: sudo $0"
        exit 1
    fi
}

check_deps() {
    log_step "Verificando dependências..."
    local deps=(archiso git squashfs-tools)
    for dep in "${deps[@]}"; do
        if ! pacman -Qi "$dep" &>/dev/null; then
            log_info "Instalando $dep..."
            pacman -S --noconfirm "$dep"
        fi
    done
    log_info "Todas dependências OK!"
}

# --- Setup Chaotic-AUR ---
setup_chaotic_aur() {
    log_step "Configurando Chaotic-AUR..."
    if ! pacman-key --list-keys 3056513887B78AEB &>/dev/null 2>&1; then
        pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
        pacman-key --lsign-key 3056513887B78AEB
        pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
        pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    fi
    log_info "Chaotic-AUR configurado!"
}

# --- Merge Package Lists ---
merge_packages() {
    log_step "Gerando lista de pacotes unificada..."
    local pkg_dir="${PROFILE_DIR}/packages"
    local output="${PROFILE_DIR}/packages.x86_64"

    : > "$output"

    for pkg_file in "${pkg_dir}"/packages-*.txt; do
        if [[ -f "$pkg_file" ]]; then
            # Remove comentários e linhas vazias
            grep -v '^\s*#' "$pkg_file" | grep -v '^\s*$' >> "$output"
        fi
    done

    # Remover duplicatas mantendo ordem
    sort -u -o "$output" "$output"
    log_info "$(wc -l < "$output") pacotes na lista final."
}

# --- Build ---
build_iso() {
    log_step "Iniciando build da ISO..."

    # Limpar builds anteriores
    if [[ -d "$WORK_DIR" ]]; then
        log_info "Removendo build anterior..."
        rm -rf "$WORK_DIR"
    fi

    mkdir -p "$OUT_DIR"

    # Executar mkarchiso
    mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$PROFILE_DIR"

    log_info "Build concluído!"
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ISO gerada em: ${OUT_DIR}/${NC}"
    ls -lh "${OUT_DIR}"/*.iso 2>/dev/null
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
}

# --- Cleanup ---
cleanup() {
    log_step "Limpando arquivos temporários..."
    rm -rf "$WORK_DIR"
    log_info "Cleanup concluído!"
}

# --- Main ---
main() {
    banner
    check_root
    check_deps
    setup_chaotic_aur
    merge_packages
    build_iso

    echo ""
    echo -e "${PURPLE}👻 PhantomArch ISO pronta!${NC}"
    echo -e "${CYAN}   Grave em um USB com:${NC}"
    echo -e "   dd bs=4M if=out/phantomarch-*.iso of=/dev/sdX status=progress oflag=sync"
    echo ""
}

# Executar com cleanup em caso de erro
trap cleanup ERR
main "$@"
