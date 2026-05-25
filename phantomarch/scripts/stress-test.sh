#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch V4 — Stress Test                                ║
# ║  Teste de estresse: CPU, RAM, GPU, I/O, rede                ║
# ╚══════════════════════════════════════════════════════════════╝

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${PURPLE}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   FexOS V4 — Stress Test                 ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "  ${CYAN}[1]${NC} CPU Stress (30s)"
echo -e "  ${CYAN}[2]${NC} RAM Stress (1GB)"
echo -e "  ${CYAN}[3]${NC} I/O Stress (disk)"
echo -e "  ${CYAN}[4]${NC} GPU Stress (Vulkan)"
echo -e "  ${CYAN}[5]${NC} Full System Stress (60s)"
echo -e "  ${CYAN}[6]${NC} Wine/FexNav Test"
echo -e "  ${CYAN}[7]${NC} Network Stress"
echo -e "  ${CYAN}[0]${NC} Sair"
echo ""
echo -ne "  Escolha: "
read -r choice

case $choice in
    1)
        echo -e "\n${CYAN}CPU Stress Test (30s)...${NC}"
        CORES=$(nproc)
        echo "  Usando $CORES cores..."
        if command -v stress-ng &>/dev/null; then
            stress-ng --cpu "$CORES" --timeout 30s --metrics
        elif command -v stress &>/dev/null; then
            stress --cpu "$CORES" --timeout 30
        else
            echo "  Instalando stress-ng..."
            sudo pacman -S --noconfirm stress-ng 2>/dev/null
            stress-ng --cpu "$CORES" --timeout 30s --metrics
        fi
        echo -e "\n${GREEN}✓ CPU test concluído${NC}"
        ;;
    2)
        echo -e "\n${CYAN}RAM Stress Test (1GB)...${NC}"
        if command -v stress-ng &>/dev/null; then
            stress-ng --vm 2 --vm-bytes 512M --timeout 20s --metrics
        else
            # Fallback: allocate memory with dd
            dd if=/dev/zero of=/dev/null bs=1M count=1024 2>/dev/null
        fi
        echo -e "\n${GREEN}✓ RAM test concluído${NC}"
        ;;
    3)
        echo -e "\n${CYAN}I/O Stress Test...${NC}"
        TESTFILE="/tmp/fexos-io-test"
        echo "  Escrita sequencial..."
        dd if=/dev/zero of="$TESTFILE" bs=1M count=256 conv=fdatasync 2>&1 | tail -1
        echo "  Leitura sequencial..."
        dd if="$TESTFILE" of=/dev/null bs=1M 2>&1 | tail -1
        rm -f "$TESTFILE"
        echo -e "\n${GREEN}✓ I/O test concluído${NC}"
        ;;
    4)
        echo -e "\n${CYAN}GPU Stress Test (Vulkan)...${NC}"
        if command -v vkcube &>/dev/null; then
            timeout 15 vkcube 2>/dev/null &
            sleep 15
            echo -e "${GREEN}✓ Vulkan OK${NC}"
        elif command -v glmark2 &>/dev/null; then
            glmark2 --run-forever --duration 15
        else
            echo -e "${YELLOW}  Nenhum benchmark GPU instalado.${NC}"
            echo -e "  Instale: sudo pacman -S vulkan-tools mesa-demos"
        fi
        ;;
    5)
        echo -e "\n${CYAN}Full System Stress (60s)...${NC}"
        echo "  CPU + RAM + I/O simultâneo..."
        if command -v stress-ng &>/dev/null; then
            stress-ng --cpu 0 --vm 2 --vm-bytes 256M --io 2 --timeout 60s --metrics
        else
            echo -e "${YELLOW}  stress-ng não instalado.${NC}"
        fi
        echo -e "\n${GREEN}✓ Full stress test concluído${NC}"
        ;;
    6)
        echo -e "\n${CYAN}Wine/FexNav Test...${NC}"
        if command -v wine &>/dev/null; then
            echo "  Wine version: $(wine --version)"
            echo "  Testing Wine prefix..."
            WINEPREFIX=/tmp/wine-test wineboot --init 2>/dev/null && echo -e "  ${GREEN}✓ Wine OK${NC}" || echo -e "  ${RED}✗ Wine failed${NC}"
            rm -rf /tmp/wine-test
        else
            echo -e "  ${YELLOW}Wine não instalado.${NC}"
        fi

        if [[ -x /usr/bin/fexnav ]]; then
            echo -e "  ${GREEN}✓ FexNav launcher OK${NC}"
        else
            echo -e "  ${YELLOW}FexNav não configurado.${NC}"
        fi
        ;;
    7)
        echo -e "\n${CYAN}Network Stress Test...${NC}"
        echo "  DNS resolve..."
        time host google.com 2>/dev/null && echo -e "  ${GREEN}✓${NC}" || echo -e "  ${RED}✗${NC}"
        echo "  Download speed..."
        if command -v curl &>/dev/null; then
            curl -o /dev/null -w "  Speed: %{speed_download} bytes/sec\n" -s "http://speedtest.tele2.net/1MB.zip"
        fi
        echo -e "\n${GREEN}✓ Network test concluído${NC}"
        ;;
    0) exit 0 ;;
esac
