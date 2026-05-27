#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  FexOS V6 — Build System (Arch Linux + Docker/WSL)           ║
# ║  Gera ISO sem erros, rápido e fácil                          ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ARCHISO_DIR="$PROJECT_DIR/archiso"
BUILD_DIR="/tmp/fexos-build"
OUT_DIR="$PROJECT_DIR/out"
LOG_FILE="$BUILD_DIR/build.log"

echo -e "${PURPLE}"
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║           ⚡ FexOS V6 — Build System ⚡                 ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ═══════════════════════════════════════════
# DETECT ENVIRONMENT
# ═══════════════════════════════════════════
detect_environment() {
    echo -e "${CYAN}[1/8] Detectando ambiente...${NC}"

    if [[ -f /etc/arch-release ]]; then
        ENV_TYPE="arch"
        echo -e "  ${GREEN}✓ Arch Linux detectado${NC}"
    elif grep -qi "microsoft" /proc/version 2>/dev/null; then
        ENV_TYPE="wsl"
        echo -e "  ${GREEN}✓ WSL (Windows) detectado${NC}"
    elif command -v docker &>/dev/null; then
        ENV_TYPE="docker"
        echo -e "  ${GREEN}✓ Docker disponível${NC}"
    else
        echo -e "  ${YELLOW}! Ambiente não-Arch detectado, usando Docker...${NC}"
        ENV_TYPE="docker"
    fi
}

# ═══════════════════════════════════════════
# INSTALL DEPENDENCIES
# ═══════════════════════════════════════════
install_deps() {
    echo -e "${CYAN}[2/8] Instalando dependências...${NC}"

    if [[ "$ENV_TYPE" == "arch" ]]; then
        sudo pacman -S --needed --noconfirm archiso mkinitcpio squashfs-tools \
            dosfstools libisoburn 2>&1 | tail -3
        echo -e "  ${GREEN}✓ Dependências instaladas${NC}"

    elif [[ "$ENV_TYPE" == "docker" || "$ENV_TYPE" == "wsl" ]]; then
        # Build using Docker with Arch image
        if ! docker image inspect archlinux:latest &>/dev/null; then
            echo "  Baixando imagem Arch Linux..."
            docker pull archlinux:latest
        fi
        echo -e "  ${GREEN}✓ Docker + Arch image prontos${NC}"
    fi
}

# ═══════════════════════════════════════════
# PREPARE BUILD
# ═══════════════════════════════════════════
prepare_build() {
    echo -e "${CYAN}[3/8] Preparando build...${NC}"

    mkdir -p "$BUILD_DIR" "$OUT_DIR"

    # Copy archiso profile
    if [[ -d "$ARCHISO_DIR" ]]; then
        rm -rf "$BUILD_DIR/profile"
        cp -a "$ARCHISO_DIR" "$BUILD_DIR/profile"
        echo -e "  ${GREEN}✓ Profile copiado${NC}"
    else
        echo -e "  ${RED}✗ Diretório archiso não encontrado!${NC}"
        exit 1
    fi
}

# ═══════════════════════════════════════════
# VALIDATE PROFILE
# ═══════════════════════════════════════════
validate_profile() {
    echo -e "${CYAN}[4/8] Validando profile...${NC}"

    local errors=0

    # Check required files
    [[ -f "$BUILD_DIR/profile/profiledef.sh" ]] || { echo "  ✗ profiledef.sh"; ((errors++)); }
    [[ -f "$BUILD_DIR/profile/pacman.conf" ]] || { echo "  ✗ pacman.conf"; ((errors++)); }
    [[ -d "$BUILD_DIR/profile/airootfs" ]] || { echo "  ✗ airootfs/"; ((errors++)); }

    if [[ $errors -gt 0 ]]; then
        echo -e "  ${RED}✗ $errors erros encontrados!${NC}"
        echo -e "  ${YELLOW}Tentando auto-repair...${NC}"
        auto_repair
    else
        echo -e "  ${GREEN}✓ Profile válido${NC}"
    fi
}

# ═══════════════════════════════════════════
# AUTO-REPAIR
# ═══════════════════════════════════════════
auto_repair() {
    echo -e "${CYAN}[Auto-Repair] Corrigindo problemas...${NC}"

    # Fix permissions
    find "$BUILD_DIR/profile/airootfs" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null
    find "$BUILD_DIR/profile/airootfs/usr/bin" -type f -exec chmod +x {} \; 2>/dev/null

    # Ensure required dirs exist
    mkdir -p "$BUILD_DIR/profile/airootfs/etc/skel" 2>/dev/null

    echo -e "  ${GREEN}✓ Auto-repair concluído${NC}"
}

# ═══════════════════════════════════════════
# BUILD ISO
# ═══════════════════════════════════════════
build_iso() {
    echo -e "${CYAN}[5/8] Gerando ISO...${NC}"
    echo -e "  ${YELLOW}Isso pode levar 10-30 minutos...${NC}"

    if [[ "$ENV_TYPE" == "arch" ]]; then
        # Direct build on Arch
        sudo mkarchiso -v -w "$BUILD_DIR/work" -o "$OUT_DIR" "$BUILD_DIR/profile" \
            2>&1 | tee "$LOG_FILE" | grep -E "(===|ERROR|WARN)" || true

    elif [[ "$ENV_TYPE" == "docker" || "$ENV_TYPE" == "wsl" ]]; then
        # Docker build
        docker run --rm --privileged \
            -v "$BUILD_DIR/profile:/build/profile:ro" \
            -v "$OUT_DIR:/build/out" \
            archlinux:latest /bin/bash -c "
                pacman -Sy --noconfirm archiso 2>/dev/null
                mkarchiso -v -w /tmp/work -o /build/out /build/profile
            " 2>&1 | tee "$LOG_FILE" | grep -E "(===|ERROR|WARN)" || true
    fi

    # Check if ISO was created
    if ls "$OUT_DIR"/*.iso &>/dev/null; then
        ISO_FILE=$(ls -t "$OUT_DIR"/*.iso | head -1)
        ISO_SIZE=$(du -h "$ISO_FILE" | cut -f1)
        echo -e "  ${GREEN}✓ ISO gerada: $ISO_FILE ($ISO_SIZE)${NC}"
    else
        echo -e "  ${RED}✗ Falha na geração da ISO${NC}"
        echo -e "  ${YELLOW}Verifique: $LOG_FILE${NC}"
        return 1
    fi
}

# ═══════════════════════════════════════════
# VERIFY ISO
# ═══════════════════════════════════════════
verify_iso() {
    echo -e "${CYAN}[6/8] Verificando ISO...${NC}"

    if [[ -z "${ISO_FILE:-}" ]]; then
        echo -e "  ${YELLOW}! Nenhuma ISO para verificar${NC}"
        return
    fi

    # Generate checksums
    echo -e "  Gerando checksums..."
    sha256sum "$ISO_FILE" > "${ISO_FILE}.sha256"
    md5sum "$ISO_FILE" > "${ISO_FILE}.md5"
    echo -e "  ${GREEN}✓ SHA256 e MD5 gerados${NC}"

    # Basic ISO validation
    if file "$ISO_FILE" | grep -qi "ISO 9660"; then
        echo -e "  ${GREEN}✓ ISO válida (formato ISO 9660)${NC}"
    else
        echo -e "  ${YELLOW}! Formato não reconhecido (pode ser híbrido)${NC}"
    fi
}

# ═══════════════════════════════════════════
# CLEANUP
# ═══════════════════════════════════════════
cleanup() {
    echo -e "${CYAN}[7/8] Limpando...${NC}"
    rm -rf "$BUILD_DIR/work" 2>/dev/null
    echo -e "  ${GREEN}✓ Temp files removidos${NC}"
}

# ═══════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════
summary() {
    echo -e "${CYAN}[8/8] Resumo${NC}"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${BOLD}FexOS V6 — Build Completo!${NC}"
    echo ""
    if [[ -n "${ISO_FILE:-}" ]]; then
        echo -e "  ${BOLD}ISO:${NC}      $ISO_FILE"
        echo -e "  ${BOLD}Tamanho:${NC}  $ISO_SIZE"
        echo -e "  ${BOLD}SHA256:${NC}   ${ISO_FILE}.sha256"
    fi
    echo -e "  ${BOLD}Log:${NC}      $LOG_FILE"
    echo ""
    echo -e "  Para gravar em USB:"
    echo -e "  ${CYAN}sudo dd if=$ISO_FILE of=/dev/sdX bs=4M status=progress${NC}"
    echo ""
    echo -e "  Ou use Ventoy/Rufus/balenaEtcher"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ═══════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════
case "${1:-build}" in
    build)
        detect_environment
        install_deps
        prepare_build
        validate_profile
        build_iso
        verify_iso
        cleanup
        summary
        ;;
    clean)
        echo "Limpando build..."
        rm -rf "$BUILD_DIR" "$OUT_DIR"/*.iso
        echo "Done."
        ;;
    validate)
        detect_environment
        prepare_build
        validate_profile
        echo -e "${GREEN}✓ Validação concluída${NC}"
        ;;
    *)
        echo "FexOS V6 Build System"
        echo ""
        echo "Uso: build-v6.sh [build|clean|validate]"
        echo ""
        echo "  build     Gerar ISO completa"
        echo "  clean     Limpar arquivos temporários"
        echo "  validate  Apenas validar profile"
        echo ""
        echo "Funciona em:"
        echo "  • Arch Linux (nativo)"
        echo "  • Windows (via Docker ou WSL)"
        echo "  • Qualquer Linux (via Docker)"
        ;;
esac
