#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch V2 — Auto Clean                                 ║
# ║  Limpa builds anteriores, cache e logs antigos               ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ARCHISO_DIR="${PROJECT_DIR}/archiso"

echo -e "${PURPLE}━━━ PhantomArch Auto Clean ━━━${NC}"
echo ""

FREED=0

# Build dir
if [[ -d "$ARCHISO_DIR/work" ]]; then
    SIZE=$(du -sh "$ARCHISO_DIR/work" | awk '{print $1}')
    echo -e "  ${CYAN}Removendo:${NC} work/ (${SIZE})"
    rm -rf "$ARCHISO_DIR/work"
    FREED=1
fi

# Old ISOs (keep only latest)
ISO_COUNT=$(ls "$ARCHISO_DIR/out"/*.iso 2>/dev/null | wc -l)
if [[ $ISO_COUNT -gt 1 ]]; then
    echo -e "  ${CYAN}Removendo:${NC} ISOs antigas (mantendo mais recente)"
    ls -t "$ARCHISO_DIR/out"/*.iso | tail -n +2 | xargs rm -f
    ls -t "$ARCHISO_DIR/out"/*.sha256 2>/dev/null | tail -n +2 | xargs rm -f 2>/dev/null || true
    ls -t "$ARCHISO_DIR/out"/*.md5 2>/dev/null | tail -n +2 | xargs rm -f 2>/dev/null || true
    FREED=1
fi

# Old logs (keep last 5)
LOG_COUNT=$(ls "$PROJECT_DIR/logs"/build-*.log 2>/dev/null | wc -l)
if [[ $LOG_COUNT -gt 5 ]]; then
    echo -e "  ${CYAN}Removendo:${NC} logs antigos (mantendo últimos 5)"
    ls -t "$PROJECT_DIR/logs"/build-*.log | tail -n +6 | xargs rm -f
    FREED=1
fi

# Generated packages.x86_64
if [[ -f "$ARCHISO_DIR/packages.x86_64" ]]; then
    echo -e "  ${CYAN}Removendo:${NC} packages.x86_64 (será regenerado)"
    rm -f "$ARCHISO_DIR/packages.x86_64"
    FREED=1
fi

if [[ $FREED -eq 0 ]]; then
    echo -e "  ${GREEN}Nada para limpar — tudo já está limpo!${NC}"
else
    echo ""
    echo -e "  ${GREEN}✓ Limpeza concluída!${NC}"
    AVAIL=$(df -h "$PROJECT_DIR" | awk 'NR==2 {print $4}')
    echo -e "  ${CYAN}Espaço disponível:${NC} $AVAIL"
fi
