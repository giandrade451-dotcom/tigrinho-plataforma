#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch V3 — Recovery Mode                              ║
# ║  Modo de recuperação para emergências                        ║
# ╚══════════════════════════════════════════════════════════════╝

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   PhantomArch V3 — RECOVERY MODE         ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "  ${YELLOW}Sistema em modo de recuperação.${NC}"
echo ""
echo -e "  ${CYAN}[1]${NC} Auto-Fix (corrigir problemas automaticamente)"
echo -e "  ${CYAN}[2]${NC} Reconstruir GRUB"
echo -e "  ${CYAN}[3]${NC} Reinstalar pacotes base"
echo -e "  ${CYAN}[4]${NC} Resetar configurações desktop"
echo -e "  ${CYAN}[5]${NC} Reparar Wine/FexNav"
echo -e "  ${CYAN}[6]${NC} Reparar PipeWire (áudio)"
echo -e "  ${CYAN}[7]${NC} Reparar rede"
echo -e "  ${CYAN}[8]${NC} Reparar permissões"
echo -e "  ${CYAN}[9]${NC} Resetar GPU drivers"
echo -e "  ${CYAN}[A]${NC} Limpar cache/temp"
echo -e "  ${CYAN}[B]${NC} Diagnóstico completo"
echo -e "  ${CYAN}[C]${NC} Shell de emergência"
echo -e "  ${CYAN}[0]${NC} Sair"
echo ""
echo -ne "  ${RED}Recovery>>${NC} "
read -r choice

case $choice in
    1)
        echo -e "\n${CYAN}Executando Auto-Fix...${NC}"
        bash /usr/share/phantom/scripts/auto-fix.sh 2>/dev/null || bash "$(dirname "$0")/auto-fix.sh"
        ;;
    2)
        echo -e "\n${CYAN}Reconstruindo GRUB...${NC}"
        grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=PhantomArch 2>/dev/null || \
        grub-install --target=i386-pc /dev/sda 2>/dev/null
        grub-mkconfig -o /boot/grub/grub.cfg
        echo -e "${GREEN}GRUB reconstruído.${NC}"
        ;;
    3)
        echo -e "\n${CYAN}Reinstalando pacotes base...${NC}"
        pacman -S --noconfirm base base-devel linux-zen linux-zen-headers linux-firmware
        echo -e "${GREEN}Pacotes base reinstalados.${NC}"
        ;;
    4)
        echo -e "\n${CYAN}Resetando configurações desktop...${NC}"
        echo -ne "  Usuário: "
        read -r target_user
        if [[ -d "/home/$target_user" ]]; then
            # Backup current
            cp -r "/home/$target_user/.config" "/home/$target_user/.config.backup.$(date +%s)" 2>/dev/null
            # Reset Hyprland
            if [[ -f /etc/skel/.config/hypr/hyprland.conf ]]; then
                cp -r /etc/skel/.config/hypr "/home/$target_user/.config/"
            fi
            # Reset Waybar
            if [[ -f /etc/skel/.config/waybar/config.jsonc ]]; then
                cp -r /etc/skel/.config/waybar "/home/$target_user/.config/"
            fi
            chown -R "$target_user:$target_user" "/home/$target_user/.config"
            echo -e "${GREEN}Configs resetadas (backup salvo em .config.backup.*).${NC}"
        else
            echo -e "${RED}Usuário não encontrado.${NC}"
        fi
        ;;
    5)
        echo -e "\n${CYAN}Reparando Wine/FexNav...${NC}"
        # Kill stuck Wine processes
        pkill -9 wine 2>/dev/null
        pkill -9 wineserver 2>/dev/null
        # Reinstall Wine
        pacman -S --noconfirm wine-staging winetricks 2>/dev/null
        # Fix FexNav permissions
        chmod -R 755 /opt/fexnav 2>/dev/null
        echo -e "${GREEN}Wine e FexNav reparados.${NC}"
        ;;
    6)
        echo -e "\n${CYAN}Reparando PipeWire...${NC}"
        systemctl --user restart pipewire pipewire-pulse wireplumber 2>/dev/null
        # Fallback: reinstall
        pacman -S --noconfirm pipewire pipewire-pulse wireplumber 2>/dev/null
        echo -e "${GREEN}PipeWire reparado. Faça logout/login se necessário.${NC}"
        ;;
    7)
        echo -e "\n${CYAN}Reparando rede...${NC}"
        systemctl restart NetworkManager 2>/dev/null
        # Fix DNS
        echo -e "nameserver 1.1.1.1\nnameserver 8.8.8.8" > /etc/resolv.conf
        # Reset NetworkManager connections
        nmcli networking off && nmcli networking on
        echo -e "${GREEN}Rede reparada.${NC}"
        ;;
    8)
        echo -e "\n${CYAN}Reparando permissões...${NC}"
        chmod 1777 /tmp /var/tmp
        for home_dir in /home/*/; do
            user=$(basename "$home_dir")
            chown -R "$user:$user" "$home_dir"
        done
        chmod -R 755 /opt/fexnav 2>/dev/null
        chmod -R 755 /opt/fexai 2>/dev/null
        echo -e "${GREEN}Permissões reparadas.${NC}"
        ;;
    9)
        echo -e "\n${CYAN}Resetando GPU drivers...${NC}"
        if lspci | grep -qi nvidia; then
            modprobe -r nvidia_drm nvidia_modeset nvidia_uvm nvidia 2>/dev/null
            modprobe nvidia nvidia_drm nvidia_modeset 2>/dev/null
            echo -e "${GREEN}NVIDIA drivers recarregados.${NC}"
        elif lspci | grep -qi amd; then
            echo -e "${YELLOW}AMD: driver amdgpu é parte do kernel, reinicie para reset completo.${NC}"
        fi
        ;;
    [aA])
        echo -e "\n${CYAN}Limpando cache...${NC}"
        # Package cache
        pacman -Sc --noconfirm 2>/dev/null
        # Temp files
        rm -rf /tmp/* 2>/dev/null
        rm -rf /var/tmp/* 2>/dev/null
        # Journal
        journalctl --vacuum-size=100M 2>/dev/null
        # Thumbnail cache
        for home_dir in /home/*/; do
            rm -rf "${home_dir}.cache/thumbnails" 2>/dev/null
        done
        echo -e "${GREEN}Cache limpo.${NC}"
        ;;
    [bB])
        echo -e "\n${CYAN}Diagnóstico completo...${NC}"
        bash /usr/share/phantom/scripts/debug-v3.sh 2>/dev/null || bash "$(dirname "$0")/debug-v3.sh"
        ;;
    [cC])
        echo -e "\n${YELLOW}Entrando em shell de emergência (Ctrl+D para sair)...${NC}"
        /bin/bash --norc --noprofile
        ;;
    0)
        echo -e "\n${GREEN}Saindo do modo recovery.${NC}"
        exit 0
        ;;
esac

echo ""
echo -ne "  ${CYAN}[Enter] para voltar ao menu...${NC}"
read -r
exec "$0"
