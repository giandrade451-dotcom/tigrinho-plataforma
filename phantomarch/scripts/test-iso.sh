#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch V3 — ISO Test Suite                             ║
# ║  Testa ISO em QEMU/KVM automaticamente                      ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUT_DIR="${PROJECT_DIR}/archiso/out"

echo -e "${PURPLE}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   PhantomArch V3 — ISO Test Suite        ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

# Find ISO
ISO_FILE=$(ls -t "$OUT_DIR"/*.iso 2>/dev/null | head -1)
if [[ -z "$ISO_FILE" ]]; then
    echo -e "${RED}  Nenhuma ISO encontrada!${NC}"
    echo "  Execute build-v3.sh primeiro."
    exit 1
fi

echo -e "  ISO: ${CYAN}$(basename "$ISO_FILE")${NC}"
echo ""

# Check QEMU
if ! command -v qemu-system-x86_64 &>/dev/null; then
    echo -e "${YELLOW}  QEMU não instalado. Instalando...${NC}"
    sudo pacman -S --noconfirm qemu-full 2>/dev/null || {
        echo -e "${RED}  Não foi possível instalar QEMU.${NC}"
        echo "  Instale manualmente: sudo pacman -S qemu-full"
        exit 1
    }
fi

# Test options
echo -e "  ${CYAN}[1]${NC} Boot rápido (BIOS, 4GB RAM)"
echo -e "  ${CYAN}[2]${NC} Boot UEFI (4GB RAM)"
echo -e "  ${CYAN}[3]${NC} Boot com GPU virtual (8GB RAM)"
echo -e "  ${CYAN}[4]${NC} Verificar ISO apenas (sem boot)"
echo ""
echo -ne "  Escolha: "
read -r choice

case $choice in
    1)
        echo -e "\n${CYAN}Iniciando QEMU (BIOS)...${NC}"
        qemu-system-x86_64 \
            -m 4G \
            -cpu host \
            -enable-kvm \
            -smp 4 \
            -cdrom "$ISO_FILE" \
            -boot d \
            -display gtk \
            -device virtio-vga-gl \
            -device virtio-net-pci,netdev=net0 \
            -netdev user,id=net0 \
            -audio driver=pipewire,model=hda
        ;;
    2)
        echo -e "\n${CYAN}Iniciando QEMU (UEFI)...${NC}"
        OVMF="/usr/share/edk2/x64/OVMF.4m.fd"
        if [[ ! -f "$OVMF" ]]; then
            OVMF="/usr/share/edk2-ovmf/x64/OVMF.fd"
        fi
        if [[ ! -f "$OVMF" ]]; then
            echo -e "${YELLOW}  OVMF não encontrado. Instalando...${NC}"
            sudo pacman -S --noconfirm edk2-ovmf 2>/dev/null
            OVMF="/usr/share/edk2/x64/OVMF.4m.fd"
        fi
        qemu-system-x86_64 \
            -m 4G \
            -cpu host \
            -enable-kvm \
            -smp 4 \
            -bios "$OVMF" \
            -cdrom "$ISO_FILE" \
            -boot d \
            -display gtk \
            -device virtio-vga-gl \
            -device virtio-net-pci,netdev=net0 \
            -netdev user,id=net0
        ;;
    3)
        echo -e "\n${CYAN}Iniciando QEMU (GPU virtual, 8GB)...${NC}"
        qemu-system-x86_64 \
            -m 8G \
            -cpu host \
            -enable-kvm \
            -smp 8 \
            -cdrom "$ISO_FILE" \
            -boot d \
            -display gtk,gl=on \
            -device virtio-vga-gl \
            -device virtio-net-pci,netdev=net0 \
            -netdev user,id=net0 \
            -device ich9-intel-hda \
            -device hda-duplex
        ;;
    4)
        echo -e "\n${CYAN}Verificando ISO...${NC}"
        echo -e "  Tamanho: $(du -h "$ISO_FILE" | awk '{print $1}')"
        echo -e "  SHA256: $(sha256sum "$ISO_FILE" | awk '{print $1}')"

        # Check if bootable
        if file "$ISO_FILE" | grep -q "boot"; then
            echo -e "  Boot: ${GREEN}Bootável${NC}"
        else
            echo -e "  Boot: ${YELLOW}Verificar${NC}"
        fi

        # Check hybrid ISO
        if file "$ISO_FILE" | grep -q "hybrid"; then
            echo -e "  Tipo: ${GREEN}Hybrid (BIOS + UEFI)${NC}"
        fi

        echo -e "\n  ${GREEN}Verificação concluída.${NC}"
        ;;
esac
