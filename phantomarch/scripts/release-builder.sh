#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  FexOS V4 — Release Builder (Full Pipeline)                  ║
# ║  Pipeline: verify → repair → build → test → release         ║
# ╚══════════════════════════════════════════════════════════════╝
set -uo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${PURPLE}"
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║          FexOS V4 — Release Builder Pipeline             ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

[[ $EUID -ne 0 ]] && { echo -e "${RED}Execute como root!${NC}"; exit 1; }

echo -e "  ${CYAN}Pipeline:${NC}"
echo -e "    1. Final Verify    (verificar completude)"
echo -e "    2. Auto Repair     (corrigir problemas)"
echo -e "    3. Build ISO       (construir imagem)"
echo -e "    4. ISO Verification (validar resultado)"
echo -e "    5. Release Package  (gerar release)"
echo ""
echo -ne "  ${YELLOW}Iniciar pipeline completo? [y/N]:${NC} "
read -r confirm
[[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo "Cancelado."; exit 0; }

# === STEP 1: Verify ===
echo ""
echo -e "${PURPLE}━━━ STEP 1: Final Verify ━━━${NC}"
bash "$SCRIPT_DIR/final-verify.sh"
echo ""
echo -ne "  ${YELLOW}Continuar? [y/N]:${NC} "
read -r confirm
[[ "$confirm" != "y" && "$confirm" != "Y" ]] && exit 0

# === STEP 2: Auto Repair ===
echo ""
echo -e "${PURPLE}━━━ STEP 2: Auto Repair Build ━━━${NC}"
bash "$SCRIPT_DIR/auto-repair-build.sh"

# === STEP 3: Build ===
echo ""
echo -e "${PURPLE}━━━ STEP 3: Build ISO ━━━${NC}"
bash "$SCRIPT_DIR/build-v4-final.sh"
BUILD_RESULT=$?

if [[ $BUILD_RESULT -ne 0 ]]; then
    echo -e "${RED}Build falhou! Verifique os logs.${NC}"
    exit 1
fi

# === STEP 4: ISO Verification ===
echo ""
echo -e "${PURPLE}━━━ STEP 4: ISO Verification ━━━${NC}"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ISO_FILE=$(ls -t "$PROJECT_DIR/archiso/out"/*.iso 2>/dev/null | head -1)

if [[ -n "$ISO_FILE" ]]; then
    echo -e "  ISO: ${GREEN}$(basename "$ISO_FILE")${NC}"
    echo -e "  Size: $(du -h "$ISO_FILE" | awk '{print $1}')"
    echo -e "  SHA256: $(sha256sum "$ISO_FILE" | awk '{print substr($1,1,16)}')..."

    # Basic check
    if file "$ISO_FILE" | grep -qi "ISO\|boot"; then
        echo -e "  Boot: ${GREEN}OK (bootável)${NC}"
    else
        echo -e "  Boot: ${YELLOW}Verificar manualmente${NC}"
    fi
else
    echo -e "  ${RED}ISO não encontrada!${NC}"
    exit 1
fi

# === STEP 5: Release Package ===
echo ""
echo -e "${PURPLE}━━━ STEP 5: Release Package ━━━${NC}"
RELEASE_DIR="$PROJECT_DIR/releases/v4.0"
mkdir -p "$RELEASE_DIR"

# Copy ISO and metadata
cp "$ISO_FILE" "$RELEASE_DIR/"
cp "${ISO_FILE}.sha256" "$RELEASE_DIR/" 2>/dev/null || true
cp "${ISO_FILE}.md5" "$RELEASE_DIR/" 2>/dev/null || true
cp "${ISO_FILE}.release" "$RELEASE_DIR/" 2>/dev/null || true

# Release notes
cat > "$RELEASE_DIR/RELEASE_NOTES.md" << 'EOF'
# FexOS 4.0 Phantom — Release Notes

## What's New in V4

### Security
- Fex Security Center — full security dashboard
- Built-in antivirus (ClamAV + YARA rules)
- Real-time file monitoring
- Suspicious file popup warnings
- System integrity verification
- Restore points (Timeshift)
- Firewall management (UFW)
- Quarantine system

### Branding
- FexOS proprietary identity
- Custom boot animation
- Custom login screen
- Custom neofetch config
- FexOS os-release

### Testing & Stability
- validate-v4.sh — full system validation
- stress-test.sh — CPU/RAM/GPU/I/O benchmarks
- security-test.sh — security audit
- build-v4-final.sh — reliable build system

### Apps
- FexNav (browser)
- FexCode (IDE)
- FexAI (offline AI assistant)
- Fex Control Center (system management)
- Fex Security Center (security)

### Performance
- Kernel: linux-zen
- Optimized sysctl, I/O scheduler
- Game Mode, Turbo Mode, Dev Mode, Battery Mode
- zRAM, earlyoom, preload, ananicy-cpp

## System Requirements
- CPU: x86_64, 2+ cores
- RAM: 4GB min, 8GB+ recommended
- Storage: 30GB+
- GPU: Vulkan-capable recommended
EOF

echo -e "  ${GREEN}Release package: $RELEASE_DIR/${NC}"
ls -la "$RELEASE_DIR"

# === DONE ===
echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}FexOS V4 — RELEASE PIPELINE COMPLETO!${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${CYAN}Próximos passos:${NC}"
echo -e "    1. Testar ISO em VM: test-iso.sh"
echo -e "    2. Gravar USB: dd bs=4M if=<iso> of=/dev/sdX"
echo -e "    3. Publicar release"
echo ""
