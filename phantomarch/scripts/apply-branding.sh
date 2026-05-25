#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch V4 — Apply FexOS Branding                       ║
# ║  Aplica identidade visual proprietária ao sistema            ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRANDING_DIR="$(dirname "$SCRIPT_DIR")/branding"

echo -e "${PURPLE}━━━ FexOS Branding V4 ━━━${NC}"

# 1. Replace os-release
echo -e "${CYAN}[1/7]${NC} Aplicando os-release..."
cp "$BRANDING_DIR/os-release" /etc/os-release 2>/dev/null || true
echo -e "${GREEN}  ✓ /etc/os-release -> FexOS${NC}"

# 2. Set hostname
echo -e "${CYAN}[2/7]${NC} Configurando hostname..."
echo "fexos" > /etc/hostname 2>/dev/null || true
echo -e "${GREEN}  ✓ Hostname: fexos${NC}"

# 3. Neofetch config
echo -e "${CYAN}[3/7]${NC} Aplicando neofetch custom..."
for user_home in /home/*/; do
    mkdir -p "${user_home}.config/neofetch"
    cp "$BRANDING_DIR/neofetch-config.conf" "${user_home}.config/neofetch/config.conf" 2>/dev/null || true
done
echo -e "${GREEN}  ✓ Neofetch branded${NC}"

# 4. SDDM branding
echo -e "${CYAN}[4/7]${NC} SDDM branding..."
# Update SDDM theme to show FexOS
if [[ -f /usr/share/sddm/themes/phantom-v3/Main.qml ]]; then
    sed -i 's/PhantomArch/FexOS/g' /usr/share/sddm/themes/phantom-v3/Main.qml 2>/dev/null || true
fi
echo -e "${GREEN}  ✓ SDDM branded${NC}"

# 5. Plymouth
echo -e "${CYAN}[5/7]${NC} Plymouth branding..."
if [[ -f /usr/share/plymouth/themes/phantom-v3/phantom-v3.plymouth ]]; then
    sed -i 's/PhantomArch/FexOS/g' /usr/share/plymouth/themes/phantom-v3/phantom-v3.plymouth 2>/dev/null || true
fi
echo -e "${GREEN}  ✓ Plymouth branded${NC}"

# 6. GRUB
echo -e "${CYAN}[6/7]${NC} GRUB branding..."
if [[ -f /etc/default/grub ]]; then
    sed -i 's/GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="FexOS"/' /etc/default/grub 2>/dev/null || true
fi
echo -e "${GREEN}  ✓ GRUB branded${NC}"

# 7. Create branding directories
echo -e "${CYAN}[7/7]${NC} Criando diretórios de branding..."
mkdir -p /usr/share/fexos/{branding,wallpapers,sounds,icons}

# Generate minimal SVG logo
cat > /usr/share/fexos/branding/logo.svg << 'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
  <defs>
    <linearGradient id="fexGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#bd93f9"/>
      <stop offset="100%" style="stop-color:#00fff7"/>
    </linearGradient>
  </defs>
  <rect width="200" height="200" rx="30" fill="#0a0a12"/>
  <rect x="10" y="10" width="180" height="180" rx="25" fill="none" stroke="url(#fexGrad)" stroke-width="3"/>
  <text x="100" y="85" font-family="Inter, sans-serif" font-size="48" font-weight="900" fill="url(#fexGrad)" text-anchor="middle">Fex</text>
  <text x="100" y="130" font-family="Inter, sans-serif" font-size="28" font-weight="300" fill="#8b8da3" text-anchor="middle">OS</text>
  <circle cx="100" cy="160" r="4" fill="#00fff7"/>
</svg>
SVG

echo -e "${GREEN}  ✓ Branding completo!${NC}"
echo ""
echo -e "${GREEN}FexOS branding aplicado com sucesso.${NC}"
