#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch V3 — Auto Repair Build                          ║
# ║  Detecta e corrige problemas que impedem a build             ║
# ╚══════════════════════════════════════════════════════════════╝
set -uo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ARCHISO_DIR="${PROJECT_DIR}/archiso"

echo -e "${PURPLE}━━━ PhantomArch V3 — Auto Repair Build ━━━${NC}"
echo ""

FIXED=0

# 1. Check archiso installed
echo -e "${CYAN}[1]${NC} Verificando archiso..."
if ! command -v mkarchiso &>/dev/null; then
    pacman -S --noconfirm archiso
    ((FIXED++))
    echo -e "  ${GREEN}archiso instalado${NC}"
else
    echo -e "  ${GREEN}OK${NC}"
fi

# 2. Check pacman keyring
echo -e "${CYAN}[2]${NC} Verificando keyring..."
if ! pacman-key --list-keys &>/dev/null; then
    pacman-key --init
    pacman-key --populate archlinux
    ((FIXED++))
    echo -e "  ${GREEN}Keyring inicializado${NC}"
else
    echo -e "  ${GREEN}OK${NC}"
fi

# 3. Remove pacman lock
echo -e "${CYAN}[3]${NC} Verificando lock..."
if [[ -f /var/lib/pacman/db.lck ]]; then
    rm -f /var/lib/pacman/db.lck
    ((FIXED++))
    echo -e "  ${GREEN}Lock removido${NC}"
else
    echo -e "  ${GREEN}OK${NC}"
fi

# 4. Sync repos
echo -e "${CYAN}[4]${NC} Sincronizando repositórios..."
pacman -Sy --noconfirm &>/dev/null
echo -e "  ${GREEN}OK${NC}"

# 5. Fix package lists
echo -e "${CYAN}[5]${NC} Validando listas de pacotes..."
cd "$ARCHISO_DIR"
REMOVED=0

if [[ -d packages ]]; then
    for f in packages/packages-*.txt; do
        [[ -f "$f" ]] || continue
        # Remove empty lines, fix trailing whitespace
        sed -i '/^\s*$/d' "$f"
        sed -i 's/[[:space:]]*$//' "$f"
    done

    # Generate and validate
    cat packages/packages-*.txt 2>/dev/null | \
        grep -v '^\s*#' | grep -v '^\s*$' | \
        sed 's/#.*//' | sed 's/[[:space:]]*$//' | \
        sort -u > packages.x86_64.tmp

    while IFS= read -r pkg; do
        if ! pacman -Ss "^${pkg}$" &>/dev/null; then
            ((REMOVED++))
        else
            echo "$pkg"
        fi
    done < packages.x86_64.tmp > packages.x86_64

    rm -f packages.x86_64.tmp
    echo -e "  ${GREEN}${REMOVED} pacotes inválidos removidos${NC}"
    ((FIXED += REMOVED))
fi

# 6. Fix profiledef.sh
echo -e "${CYAN}[6]${NC} Verificando profiledef.sh..."
if [[ -f "$ARCHISO_DIR/profiledef.sh" ]]; then
    if ! bash -n "$ARCHISO_DIR/profiledef.sh" 2>/dev/null; then
        echo -e "  ${RED}Erro de sintaxe em profiledef.sh!${NC}"
    else
        echo -e "  ${GREEN}OK${NC}"
    fi
else
    echo -e "  ${RED}Não encontrado!${NC}"
fi

# 7. Fix permissions
echo -e "${CYAN}[7]${NC} Corrigindo permissões..."
find "$ARCHISO_DIR/airootfs" -name "*.sh" -exec chmod +x {} \; 2>/dev/null
find "$ARCHISO_DIR/airootfs/usr/bin" -type f -exec chmod +x {} \; 2>/dev/null
echo -e "  ${GREEN}OK${NC}"

# 8. Clean work dir
echo -e "${CYAN}[8]${NC} Limpando work dir..."
if [[ -d "$ARCHISO_DIR/work" ]]; then
    rm -rf "$ARCHISO_DIR/work"
    ((FIXED++))
    echo -e "  ${GREEN}Removido${NC}"
else
    echo -e "  ${GREEN}OK (não existe)${NC}"
fi

# 9. Check scripts syntax
echo -e "${CYAN}[9]${NC} Verificando scripts..."
SCRIPT_ERRORS=0
for script in "$SCRIPT_DIR"/*.sh; do
    if ! bash -n "$script" 2>/dev/null; then
        echo -e "  ${RED}Erro: $(basename "$script")${NC}"
        ((SCRIPT_ERRORS++))
    fi
done
if [[ $SCRIPT_ERRORS -eq 0 ]]; then
    echo -e "  ${GREEN}Todos os scripts OK${NC}"
fi

# --- Result ---
echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}Reparos: ${FIXED}${NC} | Erros de script: ${SCRIPT_ERRORS}"
if [[ $FIXED -gt 0 || $SCRIPT_ERRORS -eq 0 ]]; then
    echo -e "  ${GREEN}Build pronta! Execute: sudo ./build-v3.sh${NC}"
else
    echo -e "  ${YELLOW}Corrija os erros de script antes de buildar.${NC}"
fi
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
