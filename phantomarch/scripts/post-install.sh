#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch — Post-Installation Script                      ║
# ║  Configurações automáticas após instalação                   ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${PURPLE}"
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║       PhantomArch Post-Installation                  ║"
echo "  ║       Configurando seu sistema para máxima perf.     ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Verificar se é root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Execute como root: sudo $0${NC}"
    exit 1
fi

TARGET_USER="${SUDO_USER:-$(logname 2>/dev/null || echo '')}"
if [[ -z "$TARGET_USER" ]]; then
    echo -e "${YELLOW}Informe o nome do usuário:${NC}"
    read -r TARGET_USER
fi
TARGET_HOME="/home/$TARGET_USER"

# ═══════════════════════════════════════════════════════════════
# 1. Grupos do Usuário
# ═══════════════════════════════════════════════════════════════
echo -e "${CYAN}[1/12]${NC} Configurando grupos do usuário..."
usermod -aG wheel,video,audio,input,games,docker,libvirt,kvm "$TARGET_USER" 2>/dev/null || true
echo -e "${GREEN}  ✓ Grupos configurados${NC}"

# ═══════════════════════════════════════════════════════════════
# 2. Habilitar Serviços
# ═══════════════════════════════════════════════════════════════
echo -e "${CYAN}[2/12]${NC} Habilitando serviços do sistema..."

SERVICES=(
    "NetworkManager"
    "bluetooth"
    "sddm"
    "docker"
    "libvirtd"
    "fstrim.timer"
    "reflector.timer"
    "systemd-timesyncd"
    "apparmor"
    "firewalld"
    "earlyoom"
    "thermald"
    "power-profiles-daemon"
)

for svc in "${SERVICES[@]}"; do
    systemctl enable "$svc" 2>/dev/null && \
        echo -e "  ${GREEN}✓${NC} $svc" || \
        echo -e "  ${YELLOW}⚠${NC} $svc (não disponível)"
done

# User services
sudo -u "$TARGET_USER" systemctl --user enable pipewire.socket 2>/dev/null || true
sudo -u "$TARGET_USER" systemctl --user enable pipewire-pulse.socket 2>/dev/null || true
sudo -u "$TARGET_USER" systemctl --user enable wireplumber.service 2>/dev/null || true

# ═══════════════════════════════════════════════════════════════
# 3. ZRAM Setup
# ═══════════════════════════════════════════════════════════════
echo -e "${CYAN}[3/12]${NC} Configurando ZRAM..."

cat > /etc/systemd/zram-generator.conf << 'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

echo -e "${GREEN}  ✓ ZRAM configurado (zstd, 50% RAM)${NC}"

# ═══════════════════════════════════════════════════════════════
# 4. Kernel Boot Parameters
# ═══════════════════════════════════════════════════════════════
echo -e "${CYAN}[4/12]${NC} Otimizando parâmetros de boot..."

GRUB_FILE="/etc/default/grub"
if [[ -f "$GRUB_FILE" ]]; then
    # Backup
    cp "$GRUB_FILE" "${GRUB_FILE}.bak"

    # Parâmetros otimizados
    PHANTOM_PARAMS="quiet splash loglevel=3 nowatchdog nmi_watchdog=0"
    PHANTOM_PARAMS+=" threadirqs mitigations=off"
    PHANTOM_PARAMS+=" transparent_hugepage=always"
    PHANTOM_PARAMS+=" split_lock_detect=off"
    PHANTOM_PARAMS+=" preempt=full"

    # Detectar GPU
    if lspci | grep -qi nvidia; then
        PHANTOM_PARAMS+=" nvidia_drm.modeset=1 nvidia_drm.fbdev=1"
    fi

    sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"${PHANTOM_PARAMS}\"|" "$GRUB_FILE"
    grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
fi

echo -e "${GREEN}  ✓ Boot parameters otimizados${NC}"

# ═══════════════════════════════════════════════════════════════
# 5. mkinitcpio
# ═══════════════════════════════════════════════════════════════
echo -e "${CYAN}[5/12]${NC} Configurando mkinitcpio..."

cat > /etc/mkinitcpio.conf << 'EOF'
MODULES=(btrfs amdgpu nvidia nvidia_modeset nvidia_uvm nvidia_drm)
BINARIES=()
FILES=()
HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block filesystems fsck plymouth)
COMPRESSION="zstd"
COMPRESSION_OPTIONS=(-3)
EOF

mkinitcpio -P 2>/dev/null || true
echo -e "${GREEN}  ✓ mkinitcpio configurado${NC}"

# ═══════════════════════════════════════════════════════════════
# 6. Makepkg Optimization
# ═══════════════════════════════════════════════════════════════
echo -e "${CYAN}[6/12]${NC} Otimizando makepkg..."

NPROC=$(nproc)
cat > /etc/makepkg.conf.d/phantomarch.conf << EOF
MAKEFLAGS="-j${NPROC}"
COMPRESSZST=(zstd -c -z -q --threads=0 -)
COMPRESSXZ=(xz -c -z --threads=0 -)
BUILDENV=(!distcc color ccache check !sign)
OPTIONS=(strip docs !libtool !staticlibs emptydirs zipman purge !debug lto)
RUSTFLAGS="-C opt-level=2 -C target-cpu=native"
EOF

echo -e "${GREEN}  ✓ makepkg otimizado (${NPROC} threads)${NC}"

# ═══════════════════════════════════════════════════════════════
# 7. Gaming Performance
# ═══════════════════════════════════════════════════════════════
echo -e "${CYAN}[7/12]${NC} Configurando performance para gaming..."

# Steam Proton paths
sudo -u "$TARGET_USER" mkdir -p "${TARGET_HOME}/.local/share/Steam/compatibilitytools.d"

# Game mode script
cat > /usr/bin/phantom-gamemode-toggle << 'SCRIPT'
#!/bin/bash
if gamemoded -s 2>/dev/null | grep -q "active"; then
    gamemoded -r
    notify-send "PhantomArch" "🎮 GameMode DESATIVADO" -u normal
else
    gamemoded -d
    notify-send "PhantomArch" "🎮 GameMode ATIVADO — Performance Máxima!" -u normal
fi
SCRIPT
chmod +x /usr/bin/phantom-gamemode-toggle

# GameMode config
mkdir -p /etc/gamemode.ini.d
cat > /etc/gamemode.ini << 'EOF'
[general]
renice=10
ioprio=0
inhibit_screensaver=1

[gpu]
apply_gpu_optimisations=accept-responsibility
gpu_device=0
amd_performance_level=high
nv_powermizer_mode=1
nv_core_clock_mhz_offset=100
nv_mem_clock_mhz_offset=200

[cpu]
pin_cores=yes

[custom]
start=notify-send "GameMode" "Performance mode activated"
end=notify-send "GameMode" "Performance mode deactivated"
EOF

echo -e "${GREEN}  ✓ Gaming performance configurado${NC}"

# ═══════════════════════════════════════════════════════════════
# 8. Instalar Rust & Dev Tools
# ═══════════════════════════════════════════════════════════════
echo -e "${CYAN}[8/12]${NC} Configurando ferramentas de desenvolvimento..."

# Rustup para o usuário
sudo -u "$TARGET_USER" bash -c 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable' 2>/dev/null || true

# Pyenv
sudo -u "$TARGET_USER" bash -c 'curl https://pyenv.run | bash' 2>/dev/null || true

# Node.js (garantir versão LTS via nvm)
sudo -u "$TARGET_USER" bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash' 2>/dev/null || true

echo -e "${GREEN}  ✓ Dev tools configurados${NC}"

# ═══════════════════════════════════════════════════════════════
# 9. Flatpak Setup
# ═══════════════════════════════════════════════════════════════
echo -e "${CYAN}[9/12]${NC} Configurando Flatpak..."

if command -v flatpak &>/dev/null; then
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    echo -e "${GREEN}  ✓ Flathub adicionado${NC}"
else
    pacman -S --noconfirm flatpak 2>/dev/null || true
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    echo -e "${GREEN}  ✓ Flatpak instalado e Flathub configurado${NC}"
fi

# ═══════════════════════════════════════════════════════════════
# 10. Shell Setup (Zsh + Starship)
# ═══════════════════════════════════════════════════════════════
echo -e "${CYAN}[10/12]${NC} Configurando shell..."

chsh -s /bin/zsh "$TARGET_USER" 2>/dev/null || true

sudo -u "$TARGET_USER" mkdir -p "${TARGET_HOME}/.config"

# .zshrc básico
sudo -u "$TARGET_USER" cat > "${TARGET_HOME}/.zshrc" << 'EOF'
# PhantomArch Zsh Configuration
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

# Aliases
alias ls='eza --icons --color=always --group-directories-first'
alias ll='eza -la --icons --color=always --group-directories-first'
alias cat='bat --style=auto'
alias grep='rg'
alias find='fd'
alias top='btop'
alias vim='nvim'
alias update='sudo pacman -Syu && paru -Sua'
alias cleanup='sudo pacman -Rns $(pacman -Qdtq) 2>/dev/null; sudo paru -Sccd'

# Gaming aliases
alias gamemode-on='gamemoded -d && echo "🎮 GameMode ON"'
alias gamemode-off='gamemoded -r && echo "GameMode OFF"'
alias mangohud-run='MANGOHUD=1'
alias proton-run='STEAM_COMPAT_CLIENT_INSTALL_PATH=~/.local/share/Steam'

# Dev aliases
alias dc='docker compose'
alias k='kubectl'
alias g='git'
alias gs='git status'
alias gc='git commit'
alias gp='git push'

# Environment
export EDITOR=nvim
export VISUAL=nvim
export TERMINAL=kitty
export BROWSER=firefox

# PATH
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
[[ -d "$HOME/.pyenv" ]] && export PATH="$HOME/.pyenv/bin:$PATH" && eval "$(pyenv init -)"

# History
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# Completions
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Plugins
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Welcome
if [[ -z "$PHANTOM_WELCOMED" ]]; then
    export PHANTOM_WELCOMED=1
    fastfetch 2>/dev/null || neofetch 2>/dev/null
fi
EOF

# Starship config
sudo -u "$TARGET_USER" cat > "${TARGET_HOME}/.config/starship.toml" << 'EOF'
# PhantomArch Starship Prompt — Cyberpunk Neon
format = """
[┌──](bold purple)$os$username$hostname$directory$git_branch$git_status$rust$python$nodejs$golang$docker_context$cmd_duration
[└─](bold purple)$character"""

[os]
format = "[$symbol](bold purple) "
disabled = false
[os.symbols]
Arch = "👻"

[username]
format = "[$user](bold cyan)"
show_always = false

[hostname]
format = "[@$hostname](bold purple) "
ssh_only = true

[directory]
format = "[$path](bold cyan)[$read_only](red) "
truncation_length = 4
truncate_to_repo = true
read_only = " 🔒"

[git_branch]
format = "[$symbol$branch](bold magenta) "
symbol = " "

[git_status]
format = '([$all_status$ahead_behind](bold red) )'

[rust]
format = "[$symbol($version)](bold orange) "
symbol = " "

[python]
format = "[$symbol($version)](bold yellow) "
symbol = " "

[nodejs]
format = "[$symbol($version)](bold green) "
symbol = " "

[golang]
format = "[$symbol($version)](bold cyan) "
symbol = " "

[docker_context]
format = "[$symbol$context](bold blue) "
symbol = " "

[cmd_duration]
format = "[$duration](bold yellow) "
min_time = 2000

[character]
success_symbol = "[❯](bold cyan)"
error_symbol = "[❯](bold red)"
EOF

echo -e "${GREEN}  ✓ Shell configurado (Zsh + Starship)${NC}"

# ═══════════════════════════════════════════════════════════════
# 11. Neovim Configuration
# ═══════════════════════════════════════════════════════════════
echo -e "${CYAN}[11/12]${NC} Configurando Neovim..."

sudo -u "$TARGET_USER" mkdir -p "${TARGET_HOME}/.config/nvim"
sudo -u "$TARGET_USER" cat > "${TARGET_HOME}/.config/nvim/init.lua" << 'EOF'
-- PhantomArch Neovim Configuration
-- Minimal but powerful setup

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.showmode = false
vim.opt.clipboard = "unnamedplus"
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.inccommand = "split"
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.termguicolors = true

-- Keymaps
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist)
vim.keymap.set("n", "<C-h>", "<C-w><C-h>")
vim.keymap.set("n", "<C-l>", "<C-w><C-l>")
vim.keymap.set("n", "<C-j>", "<C-w><C-j>")
vim.keymap.set("n", "<C-k>", "<C-w><C-k>")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- Plugins
require("lazy").setup({
    { "catppuccin/nvim", name = "catppuccin", priority = 1000,
      config = function()
        require("catppuccin").setup({ flavour = "mocha",
          color_overrides = { mocha = {
            base = "#0a0a12", mantle = "#0a0a12", crust = "#0a0a12",
          }}
        })
        vim.cmd.colorscheme("catppuccin")
      end },
    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
    { "neovim/nvim-lspconfig" },
    { "hrsh7th/nvim-cmp" },
    { "hrsh7th/cmp-nvim-lsp" },
    { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
    { "lewis6991/gitsigns.nvim", config = true },
    { "nvim-lualine/lualine.nvim", config = true },
    { "windwp/nvim-autopairs", config = true },
    { "numToStr/Comment.nvim", config = true },
})
EOF

echo -e "${GREEN}  ✓ Neovim configurado${NC}"

# ═══════════════════════════════════════════════════════════════
# 12. Phantom Welcome & Final
# ═══════════════════════════════════════════════════════════════
echo -e "${CYAN}[12/12]${NC} Finalizando configuração..."

# Criar diretórios do usuário
sudo -u "$TARGET_USER" xdg-user-dirs-update 2>/dev/null || true
sudo -u "$TARGET_USER" mkdir -p "${TARGET_HOME}/Games" "${TARGET_HOME}/Projects" "${TARGET_HOME}/Pictures/Screenshots"

# Ownership fix
chown -R "${TARGET_USER}:${TARGET_USER}" "$TARGET_HOME"

echo -e "${GREEN}  ✓ Configuração finalizada${NC}"

# ═══════════════════════════════════════════════════════════════
# Resultado
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}  👻 PhantomArch — Pós-instalação concluída!${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${CYAN}Próximos passos:${NC}"
echo -e "  1. Reinicie o sistema"
echo -e "  2. Execute ${GREEN}phantom-welcome${NC} para checklist de performance"
echo -e "  3. Execute ${GREEN}phantom-optimizer${NC} para tuning avançado"
echo ""
echo -e "  ${CYAN}Comandos úteis:${NC}"
echo -e "  • ${GREEN}gamemode-on${NC}  — Ativar modo gaming"
echo -e "  • ${GREEN}update${NC}       — Atualizar sistema"
echo -e "  • ${GREEN}mangohud-run GAME${NC} — Rodar jogo com overlay"
echo ""
echo -e "${PURPLE}  Ghost in the Machine — Máxima Performance. Liberdade Total.${NC}"
echo ""
