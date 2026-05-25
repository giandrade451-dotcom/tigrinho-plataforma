#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch V2 — Fex Control Center                         ║
# ║  Painel central de controle do sistema                        ║
# ╚══════════════════════════════════════════════════════════════╝

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
NC='\033[0m'

VERSION="2.0"

show_header() {
    clear
    echo -e "${PURPLE}"
    echo "  ╔══════════════════════════════════════════════════════════╗"
    echo "  ║           ⚡ Fex Control Center v${VERSION}                    ║"
    echo "  ║           PhantomArch System Manager                     ║"
    echo "  ╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

show_status_bar() {
    local cpu_usage=$(awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else printf "%.0f", (u-u1)*100/(t-t1)}' <(grep 'cpu ' /proc/stat) <(sleep 0.3 && grep 'cpu ' /proc/stat) 2>/dev/null || echo "?")
    local ram_used=$(free -m | awk 'NR==2{printf "%.0f%%", $3*100/$2}')
    local gpu=$(lspci | grep -oP '(?<=: ).*(?=\[)' | grep -iE 'nvidia|amd|intel' | head -1 | cut -c1-30)
    local temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{printf "%.0f°C", $1/1000}' || echo "N/A")

    echo -e "  ${CYAN}CPU:${NC} ${cpu_usage}%  ${CYAN}RAM:${NC} ${ram_used}  ${CYAN}Temp:${NC} ${temp}  ${CYAN}GPU:${NC} ${gpu:-N/A}"
    echo -e "  ${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

show_main_menu() {
    show_header
    show_status_bar
    echo ""
    echo -e "  ${WHITE}┌─ SISTEMA ──────────────────────────────────┐${NC}"
    echo -e "  │ ${CYAN}[1]${NC} ⚡ Desempenho       ${CYAN}[2]${NC} 🎨 Aparência  │"
    echo -e "  │ ${CYAN}[3]${NC} 🎮 Jogos            ${CYAN}[4]${NC} 💻 Dev        │"
    echo -e "  │ ${CYAN}[5]${NC} 🔄 Updates          ${CYAN}[6]${NC} 🤖 IA         │"
    echo -e "  │ ${CYAN}[7]${NC} 🖥️  Drivers          ${CYAN}[8]${NC} 📊 FPS/Stats  │"
    echo -e "  │ ${CYAN}[9]${NC} 🛡️  Segurança        ${CYAN}[A]${NC} 📱 Android    │"
    echo -e "  │ ${CYAN}[B]${NC} 🪟 Windows           ${CYAN}[C]${NC} 🌐 FexNav     │"
    echo -e "  │ ${CYAN}[D]${NC} 🔧 Ferramentas      ${CYAN}[0]${NC} 🚪 Sair       │"
    echo -e "  ${WHITE}└────────────────────────────────────────────┘${NC}"
    echo ""
    echo -ne "  ${PURPLE}Fex>>${NC} "
}

menu_performance() {
    show_header
    echo -e "  ${WHITE}⚡ DESEMPENHO${NC}"
    echo -e "  ${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC} Ativar TURBO MODE (max performance)"
    echo -e "  ${CYAN}[2]${NC} Ativar DEV MODE (balanced)"
    echo -e "  ${CYAN}[3]${NC} Ativar GAME MODE"
    echo -e "  ${CYAN}[4]${NC} Ativar BATTERY MODE"
    echo -e "  ${CYAN}[5]${NC} Auto-Optimizer (detecta e otimiza)"
    echo -e "  ${CYAN}[6]${NC} Limpar RAM/Cache"
    echo -e "  ${CYAN}[7]${NC} Benchmark rápido"
    echo -e "  ${CYAN}[8]${NC} Ver processos pesados"
    echo -e "  ${CYAN}[0]${NC} Voltar"
    echo ""
    echo -ne "  ${PURPLE}Perf>>${NC} "
    read -r choice
    case $choice in
        1) turbo_mode ;;
        2) dev_mode ;;
        3) game_mode ;;
        4) battery_mode ;;
        5) auto_optimize ;;
        6) clean_ram ;;
        7) phantom-optimizer 2>/dev/null || echo "Execute: phantom-optimizer" ;;
        8) ps aux --sort=-%mem | head -15 ;;
    esac
}

turbo_mode() {
    echo -e "\n${CYAN}⚡ TURBO MODE ativado!${NC}"
    sudo cpupower frequency-set -g performance 2>/dev/null
    echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null
    echo 0 | sudo tee /proc/sys/vm/swappiness 2>/dev/null
    for disk in /sys/block/*/queue/scheduler; do
        echo "none" | sudo tee "$disk" 2>/dev/null
    done
    gamemoded -d 2>/dev/null
    echo -e "${GREEN}  ✓ CPU: performance | Swap: 0 | I/O: none | GameMode: ON${NC}"
}

dev_mode() {
    echo -e "\n${CYAN}💻 DEV MODE ativado!${NC}"
    sudo cpupower frequency-set -g schedutil 2>/dev/null
    echo 10 | sudo tee /proc/sys/vm/swappiness 2>/dev/null
    echo -e "${GREEN}  ✓ CPU: schedutil | Swap: 10 | Optimizado para compilação${NC}"
}

game_mode() {
    echo -e "\n${CYAN}🎮 GAME MODE ativado!${NC}"
    sudo cpupower frequency-set -g performance 2>/dev/null
    gamemoded -d 2>/dev/null
    if command -v hyprctl &>/dev/null; then
        hyprctl keyword decoration:blur:enabled false 2>/dev/null
        hyprctl keyword animations:enabled false 2>/dev/null
    fi
    echo -e "${GREEN}  ✓ Performance max | GameMode ON | Blur OFF | Animations OFF${NC}"
}

battery_mode() {
    echo -e "\n${CYAN}🔋 BATTERY MODE ativado!${NC}"
    sudo cpupower frequency-set -g powersave 2>/dev/null
    echo 60 | sudo tee /proc/sys/vm/swappiness 2>/dev/null
    gamemoded -r 2>/dev/null
    brightnessctl set 30% 2>/dev/null
    echo -e "${GREEN}  ✓ CPU: powersave | Brilho: 30% | Economia máxima${NC}"
}

auto_optimize() {
    echo -e "\n${CYAN}🔄 Auto-Optimizer...${NC}"
    # Detect if on battery
    if [[ -f /sys/class/power_supply/BAT0/status ]]; then
        local status=$(cat /sys/class/power_supply/BAT0/status)
        if [[ "$status" == "Discharging" ]]; then
            echo "  Bateria detectada → Battery Mode"
            battery_mode
            return
        fi
    fi
    # Check if gaming
    if pgrep -x "steam\|lutris\|gamescope" &>/dev/null; then
        echo "  Jogo detectado → Game Mode"
        game_mode
        return
    fi
    # Default to dev
    echo "  Uso geral → Dev Mode"
    dev_mode
}

clean_ram() {
    echo -e "\n${CYAN}🧹 Limpando RAM/Cache...${NC}"
    sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null
    echo -e "${GREEN}  ✓ Cache liberado${NC}"
    free -h | awk 'NR==2{printf "  RAM: %s usada de %s (%.0f%% livre)\n", $3, $2, ($4/$2)*100}'
}

menu_appearance() {
    show_header
    echo -e "  ${WHITE}🎨 APARÊNCIA${NC}"
    echo -e "  ${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC} Modo Neon (padrão cyberpunk)"
    echo -e "  ${CYAN}[2]${NC} Modo Escuro Puro (OLED)"
    echo -e "  ${CYAN}[3]${NC} Modo RGB (animado)"
    echo -e "  ${CYAN}[4]${NC} Trocar wallpaper"
    echo -e "  ${CYAN}[5]${NC} Trocar cores do painel"
    echo -e "  ${CYAN}[6]${NC} Trocar ícones"
    echo -e "  ${CYAN}[7]${NC} Blur ON/OFF"
    echo -e "  ${CYAN}[8]${NC} Animações ON/OFF"
    echo -e "  ${CYAN}[0]${NC} Voltar"
    echo ""
    echo -ne "  ${PURPLE}Theme>>${NC} "
    read -r choice
    case $choice in
        1) apply_neon_theme ;;
        2) apply_dark_theme ;;
        3) apply_rgb_theme ;;
        4) change_wallpaper ;;
        7) toggle_blur ;;
        8) toggle_animations ;;
    esac
}

apply_neon_theme() {
    echo -e "\n${CYAN}Aplicando tema Neon...${NC}"
    if command -v hyprctl &>/dev/null; then
        hyprctl keyword general:col.active_border "rgba(bd93f9ee) rgba(00fff7ee) 45deg" 2>/dev/null
        hyprctl keyword decoration:blur:enabled true 2>/dev/null
        hyprctl keyword animations:enabled true 2>/dev/null
    fi
    echo -e "${GREEN}  ✓ Tema Neon aplicado!${NC}"
}

apply_dark_theme() {
    echo -e "\n${CYAN}Aplicando tema Escuro Puro...${NC}"
    if command -v hyprctl &>/dev/null; then
        hyprctl keyword general:col.active_border "rgba(ffffff33)" 2>/dev/null
        hyprctl keyword general:col.inactive_border "rgba(00000000)" 2>/dev/null
        hyprctl keyword decoration:blur:enabled false 2>/dev/null
    fi
    echo -e "${GREEN}  ✓ Tema Escuro Puro aplicado!${NC}"
}

apply_rgb_theme() {
    echo -e "\n${CYAN}Aplicando tema RGB animado...${NC}"
    if command -v hyprctl &>/dev/null; then
        hyprctl keyword general:col.active_border "rgba(ff0000ee) rgba(00ff00ee) rgba(0000ffee) rgba(ff00ffee) 45deg" 2>/dev/null
    fi
    echo -e "${GREEN}  ✓ Tema RGB aplicado!${NC}"
}

change_wallpaper() {
    local wp_dir="/usr/share/phantom/wallpapers"
    if [[ -d "$wp_dir" ]]; then
        echo "  Wallpapers disponíveis:"
        ls "$wp_dir" 2>/dev/null | nl
    fi
    echo -ne "  Caminho do wallpaper (ou Enter para random): "
    read -r wp
    if [[ -n "$wp" && -f "$wp" ]]; then
        hyprctl hyprpaper wallpaper ",$wp" 2>/dev/null
        echo -e "${GREEN}  ✓ Wallpaper atualizado!${NC}"
    fi
}

toggle_blur() {
    local current=$(hyprctl getoption decoration:blur:enabled 2>/dev/null | grep "int:" | awk '{print $2}')
    if [[ "$current" == "1" ]]; then
        hyprctl keyword decoration:blur:enabled false 2>/dev/null
        echo -e "${GREEN}  ✓ Blur DESATIVADO${NC}"
    else
        hyprctl keyword decoration:blur:enabled true 2>/dev/null
        echo -e "${GREEN}  ✓ Blur ATIVADO${NC}"
    fi
}

toggle_animations() {
    local current=$(hyprctl getoption animations:enabled 2>/dev/null | grep "int:" | awk '{print $2}')
    if [[ "$current" == "1" ]]; then
        hyprctl keyword animations:enabled false 2>/dev/null
        echo -e "${GREEN}  ✓ Animações DESATIVADAS${NC}"
    else
        hyprctl keyword animations:enabled true 2>/dev/null
        echo -e "${GREEN}  ✓ Animações ATIVADAS${NC}"
    fi
}

menu_gaming() {
    show_header
    echo -e "  ${WHITE}🎮 JOGOS${NC}"
    echo -e "  ${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC} Ativar GameMode"
    echo -e "  ${CYAN}[2]${NC} Desativar GameMode"
    echo -e "  ${CYAN}[3]${NC} Abrir Steam"
    echo -e "  ${CYAN}[4]${NC} Abrir Lutris"
    echo -e "  ${CYAN}[5]${NC} Abrir Bottles"
    echo -e "  ${CYAN}[6]${NC} MangoHud Config"
    echo -e "  ${CYAN}[7]${NC} Gamescope Run"
    echo -e "  ${CYAN}[8]${NC} Executar .exe (Wine)"
    echo -e "  ${CYAN}[9]${NC} FPS Counter ON/OFF"
    echo -e "  ${CYAN}[0]${NC} Voltar"
    echo ""
    echo -ne "  ${PURPLE}Game>>${NC} "
    read -r choice
    case $choice in
        1) gamemoded -d && echo -e "${GREEN}  ✓ GameMode ON${NC}" ;;
        2) gamemoded -r && echo -e "${GREEN}  ✓ GameMode OFF${NC}" ;;
        3) steam &>/dev/null & echo "Steam aberto" ;;
        4) lutris &>/dev/null & echo "Lutris aberto" ;;
        5) flatpak run com.usebottles.bottles &>/dev/null & echo "Bottles aberto" ;;
        8) phantom-wine-sandbox ;;
    esac
}

menu_dev() {
    show_header
    echo -e "  ${WHITE}💻 DESENVOLVIMENTO${NC}"
    echo -e "  ${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC} Abrir FexCode IDE"
    echo -e "  ${CYAN}[2]${NC} Abrir VS Code"
    echo -e "  ${CYAN}[3]${NC} Abrir Godot"
    echo -e "  ${CYAN}[4]${NC} Abrir Blender"
    echo -e "  ${CYAN}[5]${NC} Docker status"
    echo -e "  ${CYAN}[6]${NC} Criar APK (Android)"
    echo -e "  ${CYAN}[7]${NC} Criar EXE (Windows)"
    echo -e "  ${CYAN}[8]${NC} Engines Launcher"
    echo -e "  ${CYAN}[9]${NC} Dev Terminal"
    echo -e "  ${CYAN}[0]${NC} Voltar"
    echo ""
    echo -ne "  ${PURPLE}Dev>>${NC} "
    read -r choice
    case $choice in
        1) fexcode &>/dev/null & echo "FexCode aberto" ;;
        2) code &>/dev/null & echo "VS Code aberto" ;;
        3) godot &>/dev/null & echo "Godot aberto" ;;
        4) blender &>/dev/null & echo "Blender aberto" ;;
        5) docker ps 2>/dev/null || echo "Docker não está rodando. Use: sudo systemctl start docker" ;;
        6) phantom-build-apk ;;
        7) echo "Use: x86_64-w64-mingw32-gcc -o app.exe main.c" ;;
        8) phantom-engines-launcher ;;
        9) kitty --class dev-terminal &>/dev/null & ;;
    esac
}

menu_ai() {
    show_header
    echo -e "  ${WHITE}🤖 INTELIGÊNCIA ARTIFICIAL${NC}"
    echo -e "  ${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC} Abrir FexAI (assistente)"
    echo -e "  ${CYAN}[2]${NC} FexAI no terminal"
    echo -e "  ${CYAN}[3]${NC} Ollama models"
    echo -e "  ${CYAN}[4]${NC} Baixar modelo IA"
    echo -e "  ${CYAN}[5]${NC} Status IA"
    echo -e "  ${CYAN}[0]${NC} Voltar"
    echo ""
    echo -ne "  ${PURPLE}AI>>${NC} "
    read -r choice
    case $choice in
        1) fexai &>/dev/null & echo "FexAI aberto" ;;
        2) fexai-cli ;;
        3) ollama list 2>/dev/null || echo "Ollama não instalado" ;;
        4)
            echo -ne "  Modelo (ex: llama3, mistral, phi3): "
            read -r model
            ollama pull "$model" 2>/dev/null
            ;;
        5)
            echo "  Ollama: $(systemctl is-active ollama 2>/dev/null || echo 'inativo')"
            echo "  FexAI: $(systemctl --user is-active fexai 2>/dev/null || echo 'não rodando')"
            ;;
    esac
}

# --- Main Loop ---
while true; do
    show_main_menu
    read -r choice
    case $choice in
        1) menu_performance ;;
        2) menu_appearance ;;
        3) menu_gaming ;;
        4) menu_dev ;;
        5) echo "Atualizando..."; sudo pacman -Syu --noconfirm 2>/dev/null ;;
        6) menu_ai ;;
        7) echo "Drivers:"; lspci -k | grep -A2 -E "(VGA|3D)" ;;
        8) echo "FPS/Stats:"; mangohud --version 2>/dev/null; gamemoded -s 2>/dev/null ;;
        9) echo "Firewall:"; sudo ufw status 2>/dev/null ;;
        [aA]) phantom-build-apk 2>/dev/null || echo "Execute: phantom-build-apk" ;;
        [bB]) phantom-wine-sandbox 2>/dev/null || echo "Use: wine app.exe" ;;
        [cC]) fexnav &>/dev/null & echo "FexNav aberto" ;;
        [dD]) echo "Ferramentas: phantom-optimizer, phantom-welcome, phantom-build-apk" ;;
        0) echo -e "\n${PURPLE}⚡ Até mais!${NC}\n"; exit 0 ;;
        *) echo -e "${RED}  Opção inválida!${NC}" ;;
    esac
    echo ""
    echo -ne "  ${CYAN}[Enter] continuar...${NC}"
    read -r
done
