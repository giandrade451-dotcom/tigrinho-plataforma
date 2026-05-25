# PhantomArch 1.0 Phantom — Handbook Offline

> **Ghost in the Machine — Máxima Performance. Liberdade Total.**

---

## Índice

1. [Introdução](#introdução)
2. [Instalação](#instalação)
3. [Primeiro Boot](#primeiro-boot)
4. [Desktop (Hyprland)](#desktop-hyprland)
5. [Gaming](#gaming)
6. [Desenvolvimento](#desenvolvimento)
7. [Multimídia](#multimídia)
8. [Segurança](#segurança)
9. [Manutenção](#manutenção)
10. [Troubleshooting](#troubleshooting)
11. [Keybindings](#keybindings)

---

## Introdução

PhantomArch é uma distribuição Linux baseada em Arch Linux, projetada para gamers e desenvolvedores que exigem máxima performance sem comprometer a privacidade.

### Kernels Disponíveis
- **linux-zen**: Padrão, melhor equilíbrio entre performance e compatibilidade
- **linux-xanmod**: Otimizado para desktops e gaming
- **linux-xanmod-edge**: Bleeding edge com últimas otimizações

Para trocar o kernel:
```bash
# Instalar
sudo pacman -S linux-xanmod linux-xanmod-headers

# Atualizar GRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Reiniciar e selecionar no GRUB
```

---

## Instalação

### Requisitos Mínimos
- CPU: x86_64, 4+ cores recomendado
- RAM: 4GB mínimo, 16GB+ recomendado
- Disco: 50GB mínimo, SSD/NVMe recomendado
- GPU: AMD ou NVIDIA com suporte Vulkan

### Processo
1. Grave a ISO em USB (dd ou Ventoy)
2. Boot pelo USB
3. O Calamares Installer abrirá automaticamente
4. Siga os passos: idioma → teclado → partições → usuário → instalar
5. Reinicie sem o USB

### Particionamento Recomendado (Btrfs)
| Partição | Tamanho | Filesystem | Mount |
|----------|---------|------------|-------|
| EFI | 512MB | FAT32 | /boot/efi |
| Root | 100GB+ | Btrfs | / |
| Home | Restante | Btrfs | /home |

Subvolumes Btrfs recomendados: `@`, `@home`, `@cache`, `@log`, `@snapshots`

---

## Primeiro Boot

Após instalar, execute:
```bash
phantom-welcome     # Checklist de performance
phantom-optimizer   # Tuning interativo
```

O script de pós-instalação (`post-install.sh`) é executado automaticamente e configura:
- Grupos do usuário
- Serviços do sistema
- ZRAM
- Boot parameters
- Gaming performance
- Shell (Zsh + Starship)

---

## Desktop (Hyprland)

### Conceitos
- **Tiling**: Janelas são organizadas automaticamente
- **Workspaces**: 10 áreas de trabalho virtuais
- **Floating**: Janelas podem ser flutuantes (SUPER+V)
- **Fullscreen**: SUPER+F

### Keybindings Essenciais
| Tecla | Ação |
|-------|------|
| SUPER+RETURN | Terminal (Kitty) |
| SUPER+SPACE | Launcher (Wofi) |
| SUPER+Q | Fechar janela |
| SUPER+V | Toggle floating |
| SUPER+F | Fullscreen |
| SUPER+B | Firefox |
| SUPER+C | VS Code |
| SUPER+E | File Manager |
| SUPER+G | Toggle GameMode |
| SUPER+SHIFT+S | Screenshot (seleção) |
| SUPER+SHIFT+X | Lock screen |
| SUPER+SHIFT+E | Power menu |
| SUPER+1-0 | Workspace 1-10 |
| SUPER+SHIFT+1-0 | Mover para workspace |

### Configuração
Os arquivos de configuração estão em `~/.config/hypr/`:
- `hyprland.conf` — Configuração principal
- `hyprpaper.conf` — Wallpapers
- `hyprlock.conf` — Lockscreen
- `hypridle.conf` — Idle management

---

## Gaming

### Steam + Proton
```bash
# Steam já vem instalado
# Para jogos Windows, habilite Proton nas configurações do Steam:
# Steam → Settings → Compatibility → Enable Steam Play for all titles

# Para instalar Proton-GE:
# Baixe de https://github.com/GloriousEggroll/proton-ge-custom/releases
# Extraia em ~/.local/share/Steam/compatibilitytools.d/
```

### GameMode
```bash
# Ativar via keybinding: SUPER+G
# Ou manualmente:
gamemoded -d     # Ativar
gamemoded -r     # Desativar
gamemoded -s     # Status

# Para rodar um jogo com GameMode:
gamemoderun ./game
```

### MangoHud
```bash
# Overlay de performance in-game
# Rodar jogo com overlay:
mangohud ./game

# Ou via variável de ambiente:
MANGOHUD=1 steam

# Configuração: ~/.config/MangoHud/MangoHud.conf
```

### Gamescope
```bash
# Compositor gaming — melhor latência e upscaling
gamescope -W 1920 -H 1080 -f -- ./game

# Com FSR upscaling:
gamescope -W 1280 -H 720 -w 1920 -h 1080 -F fsr -f -- ./game
```

### Launchers Alternativos
- **Heroic Games Launcher**: Epic Games, GOG, Amazon
- **Lutris**: Qualquer jogo, múltiplos runners
- **Bottles**: Ambientes Wine isolados

### Performance Tips
1. Use kernel linux-zen ou linux-xanmod
2. Ative GameMode antes de jogar
3. Desative blur/animações para jogos pesados (`phantom-optimizer` → Gaming)
4. Use Gamescope para jogos que não suportam Wayland bem
5. Configure MangoHud para monitorar FPS/temps

---

## Desenvolvimento

### Editores
- **VS Code**: `code` ou `codium` (sem telemetria)
- **Neovim**: Configuração Phantom com LSP, Treesitter, Telescope
- **Zed**: Editor moderno em Rust

### Linguagens

```bash
# Rust
rustup default stable
cargo install cargo-watch cargo-edit

# Python (via pyenv)
pyenv install 3.12.0
pyenv global 3.12.0

# Node.js (via nvm)
nvm install --lts
nvm use --lts

# Go
go version

# Zig
zig version
```

### Docker
```bash
# Já configurado e habilitado
docker run hello-world

# Docker Compose
docker compose up -d

# Podman (alternativa rootless)
podman run hello-world
```

### Game Development
```bash
# Godot
godot  # Abre o editor

# Blender
blender

# Para Unity Hub (via flatpak se necessário):
flatpak install flathub com.unity.UnityHub
```

### GPU Passthrough (Looking Glass)
Para usar GPU dedicada em VM:
1. Configure IOMMU no BIOS
2. Adicione `intel_iommu=on` ou `amd_iommu=on` nos boot params
3. Configure vfio-pci para a GPU secundária
4. Use virt-manager + Looking Glass

---

## Multimídia

### PipeWire
PhantomArch usa PipeWire como servidor de áudio:
```bash
# Status
systemctl --user status pipewire wireplumber

# Controle de volume
wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+   # Aumentar
wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-   # Diminuir
wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle  # Mute

# EasyEffects para equalizer/efeitos
easyeffects
```

### Codecs
Todos os codecs estão instalados: H.264, H.265/HEVC, AV1, VP9, AAC, FLAC, etc.

```bash
# Player de vídeo
mpv video.mkv

# Player de imagem
imv image.png
```

---

## Segurança

### Firewall
```bash
# Status
sudo ufw status

# Permitir porta
sudo ufw allow 8080/tcp

# Bloquear
sudo ufw deny 22
```

### AppArmor
```bash
# Status
sudo aa-status

# Perfis
ls /etc/apparmor.d/
```

### Privacidade
- Zero telemetria em todos os pacotes
- DNS pode ser configurado para DoH:
  ```
  # /etc/systemd/resolved.conf
  [Resolve]
  DNS=9.9.9.9#dns.quad9.net
  DNSOverTLS=yes
  ```

---

## Manutenção

### Atualizar Sistema
```bash
# Método rápido
update  # alias configurado

# Manual
sudo pacman -Syu       # Pacotes oficiais
paru -Sua              # AUR

# Atualizar mirrors
sudo reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
```

### Limpar Sistema
```bash
# Pacotes órfãos
sudo pacman -Rns $(pacman -Qdtq)

# Cache do pacman (manter últimas 3 versões)
sudo paccache -r

# Logs do journal
sudo journalctl --vacuum-time=7d
```

### Snapshots (Btrfs)
```bash
# Se usar Btrfs + snapper:
sudo snapper create -d "antes da atualização"
sudo snapper list
sudo snapper rollback N  # Restaurar snapshot N
```

---

## Troubleshooting

### Sistema não boota
1. No GRUB, selecione "Modo Seguro"
2. Ou adicione `nomodeset` nos parâmetros do kernel
3. Verifique logs: `journalctl -b -1` (boot anterior)

### Tela preta (NVIDIA)
```bash
# No GRUB, edite a entrada (e) e adicione:
nvidia_drm.modeset=1 nvidia_drm.fbdev=1

# Após boot, tornar permanente:
sudo nano /etc/default/grub
# Adicionar os parâmetros
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### Áudio não funciona
```bash
# Verificar PipeWire
systemctl --user restart pipewire wireplumber

# Verificar dispositivos
wpctl status

# Definir output padrão
wpctl set-default <ID>
```

### Wi-Fi não conecta
```bash
# Verificar NetworkManager
nmcli device status
nmcli device wifi list
nmcli device wifi connect "SSID" password "senha"
```

### Jogo não roda
```bash
# Verificar Vulkan
vulkaninfo --summary

# Forçar Proton versão:
# Steam → Jogo → Properties → Compatibility → Force version

# Verificar logs do Proton:
PROTON_LOG=1 %command%
cat /tmp/proton_*.log
```

---

## Keybindings Completo

### Hyprland
| Tecla | Ação |
|-------|------|
| SUPER+RETURN | Terminal |
| SUPER+Q | Fechar janela |
| SUPER+SHIFT+Q | Sair do Hyprland |
| SUPER+SPACE | App launcher |
| SUPER+V | Float/tile toggle |
| SUPER+F | Fullscreen |
| SUPER+SHIFT+F | Fullscreen (fake) |
| SUPER+P | Pseudo tile |
| SUPER+J | Toggle split |
| SUPER+B | Browser |
| SUPER+C | Code editor |
| SUPER+E | File manager |
| SUPER+G | GameMode toggle |
| SUPER+S | Scratchpad |
| SUPER+SHIFT+V | Clipboard history |
| SUPER+SHIFT+S | Screenshot (área) |
| SUPER+PRINT | Screenshot (tela) |
| SUPER+SHIFT+X | Lock screen |
| SUPER+SHIFT+E | Power menu |
| SUPER+Arrow/HJKL | Mover foco |
| SUPER+SHIFT+Arrow | Mover janela |
| SUPER+CTRL+Arrow | Resize |
| SUPER+1-0 | Ir para workspace |
| SUPER+SHIFT+1-0 | Mover para workspace |
| SUPER+Scroll | Trocar workspace |

### Mídia
| Tecla | Ação |
|-------|------|
| XF86AudioRaiseVolume | Volume + |
| XF86AudioLowerVolume | Volume - |
| XF86AudioMute | Mute toggle |
| XF86AudioPlay | Play/Pause |
| XF86AudioNext | Próxima |
| XF86AudioPrev | Anterior |
| XF86MonBrightnessUp | Brilho + |
| XF86MonBrightnessDown | Brilho - |

---

*PhantomArch 1.0 Phantom — Ghost in the Machine*
*Documentação offline. Acessível sem internet.*
