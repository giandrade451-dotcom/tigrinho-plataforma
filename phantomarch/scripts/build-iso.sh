#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch — Full ISO Build Pipeline                       ║
# ║  Script completo para build em qualquer máquina Arch         ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ARCHISO_DIR="${PROJECT_ROOT}/archiso"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${PURPLE}"
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║       PhantomArch Full Build Pipeline                ║"
echo "  ║       v1.0 Phantom — Ghost in the Machine            ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# --- Passo 1: Verificar sistema ---
echo -e "${CYAN}[1/8]${NC} Verificando sistema host..."

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}ERRO: Execute como root (sudo)${NC}"
    exit 1
fi

if ! command -v pacman &>/dev/null; then
    echo -e "${RED}ERRO: Este script requer Arch Linux (pacman não encontrado)${NC}"
    exit 1
fi

# Verificar espaço em disco (20GB mínimo)
AVAILABLE=$(df -BG "${PROJECT_ROOT}" | awk 'NR==2 {print $4}' | tr -d 'G')
if [[ "$AVAILABLE" -lt 20 ]]; then
    echo -e "${YELLOW}AVISO: Espaço disponível (${AVAILABLE}GB) pode ser insuficiente. Recomendado: 20GB+${NC}"
fi

echo -e "${GREEN}  ✓ Sistema verificado${NC}"

# --- Passo 2: Instalar dependências ---
echo -e "${CYAN}[2/8]${NC} Instalando dependências do build..."

pacman -Sy --needed --noconfirm \
    archiso \
    git \
    squashfs-tools \
    xorriso \
    mtools \
    dosfstools \
    erofs-utils

echo -e "${GREEN}  ✓ Dependências instaladas${NC}"

# --- Passo 3: Configurar Chaotic-AUR ---
echo -e "${CYAN}[3/8]${NC} Configurando repositório Chaotic-AUR..."

if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
    pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    pacman-key --lsign-key 3056513887B78AEB
    pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

    cat >> /etc/pacman.conf << 'EOF'

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF
    pacman -Sy
fi

echo -e "${GREEN}  ✓ Chaotic-AUR configurado${NC}"

# --- Passo 4: Gerar lista de pacotes ---
echo -e "${CYAN}[4/8]${NC} Gerando lista unificada de pacotes..."

PKG_OUTPUT="${ARCHISO_DIR}/packages.x86_64"
: > "$PKG_OUTPUT"

for f in "${ARCHISO_DIR}/packages"/packages-*.txt; do
    [[ -f "$f" ]] || continue
    grep -v '^\s*#' "$f" | grep -v '^\s*$' >> "$PKG_OUTPUT"
done

sort -u -o "$PKG_OUTPUT" "$PKG_OUTPUT"
TOTAL_PKGS=$(wc -l < "$PKG_OUTPUT")
echo -e "${GREEN}  ✓ $TOTAL_PKGS pacotes na lista final${NC}"

# --- Passo 5: Copiar configurações ---
echo -e "${CYAN}[5/8]${NC} Verificando configurações..."

# Garantir permissões corretas
chmod +x "${ARCHISO_DIR}/airootfs/usr/bin/"* 2>/dev/null || true
chmod 755 "${ARCHISO_DIR}/profiledef.sh"

echo -e "${GREEN}  ✓ Configurações verificadas${NC}"

# --- Passo 6: Copiar Chaotic mirrorlist para airootfs ---
echo -e "${CYAN}[6/8]${NC} Preparando mirrors para o ambiente live..."

mkdir -p "${ARCHISO_DIR}/airootfs/etc/pacman.d"
if [[ -f /etc/pacman.d/chaotic-mirrorlist ]]; then
    cp /etc/pacman.d/chaotic-mirrorlist "${ARCHISO_DIR}/airootfs/etc/pacman.d/"
fi

echo -e "${GREEN}  ✓ Mirrors preparados${NC}"

# --- Passo 7: Build ISO ---
echo -e "${CYAN}[7/8]${NC} Buildando ISO (isso pode demorar 30-60min)..."
echo -e "${YELLOW}       Depende da velocidade de internet e disco.${NC}"

WORK_DIR="${ARCHISO_DIR}/work"
OUT_DIR="${ARCHISO_DIR}/out"

rm -rf "$WORK_DIR"
mkdir -p "$OUT_DIR"

mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$ARCHISO_DIR"

echo -e "${GREEN}  ✓ ISO gerada com sucesso!${NC}"

# --- Passo 8: Verificação final ---
echo -e "${CYAN}[8/8]${NC} Verificação final..."

ISO_FILE=$(ls "${OUT_DIR}"/*.iso 2>/dev/null | head -1)
if [[ -f "$ISO_FILE" ]]; then
    ISO_SIZE=$(du -h "$ISO_FILE" | cut -f1)
    ISO_SHA=$(sha256sum "$ISO_FILE" | cut -d' ' -f1)

    echo ""
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  👻 PhantomArch 1.0 Phantom — Build Completo!${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${CYAN}ISO:${NC}    $ISO_FILE"
    echo -e "  ${CYAN}Tamanho:${NC} $ISO_SIZE"
    echo -e "  ${CYAN}SHA256:${NC}  $ISO_SHA"
    echo ""
    echo -e "  ${GREEN}Gravar em USB:${NC}"
    echo -e "  sudo dd bs=4M if=$ISO_FILE of=/dev/sdX status=progress oflag=sync"
    echo ""
    echo -e "  ${GREEN}Testar com QEMU:${NC}"
    echo -e "  qemu-system-x86_64 -m 4G -enable-kvm -cdrom $ISO_FILE"
    echo ""
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
else
    echo -e "${RED}ERRO: ISO não encontrada em ${OUT_DIR}${NC}"
    exit 1
fi

# Cleanup work directory
echo -e "${CYAN}Limpando diretório de trabalho...${NC}"
rm -rf "$WORK_DIR"
echo -e "${GREEN}Done!${NC}"
