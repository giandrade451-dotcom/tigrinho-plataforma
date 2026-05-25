# PhantomArch 1.0 Phantom

```
 ██████╗ ██╗  ██╗ █████╗ ███╗   ██╗████████╗ ██████╗ ███╗   ███╗
 ██╔══██╗██║  ██║██╔══██╗████╗  ██║╚══██╔══╝██╔═══██╗████╗ ████║
 ██████╔╝███████║███████║██╔██╗ ██║   ██║   ██║   ██║██╔████╔██║
 ██╔═══╝ ██╔══██║██╔══██║██║╚██╗██║   ██║   ██║   ██║██║╚██╔╝██║
 ██║     ██║  ██║██║  ██║██║ ╚████║   ██║   ╚██████╔╝██║ ╚═╝ ██║
 ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝
                █████╗ ██████╗  ██████╗██╗  ██╗
               ██╔══██╗██╔══██╗██╔════╝██║  ██║
               ███████║██████╔╝██║     ███████║
               ██╔══██║██╔══██╗██║     ██╔══██║
               ██║  ██║██║  ██║╚██████╗██║  ██║
               ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
```

> **"Ghost in the Machine — Máxima Performance. Liberdade Total."**

## O que é PhantomArch?

PhantomArch é uma distribuição Linux baseada em **Arch Linux** (rolling release), otimizada para **gaming extremo** e **desenvolvimento de jogos/software**. Estilo visual **cyberpunk neon escuro** (preto, roxo profundo, ciano e magenta).

### Filosofia

- Performance extrema em jogos AAA via Proton/Wine
- Ambiente perfeito para programadores e game developers
- Zero telemetria, zero contas obrigatórias, zero paywall
- Funcional 100% offline após instalação
- Liberdade total do usuário

## Características Principais

### 🎮 Gaming
- Steam + Proton-GE + Wine-GE + Wine-Staging
- GameMode, Gamescope, MangoHud, vkBasalt
- Heroic Games Launcher, Lutris, Bottles
- VKD3D-Proton, DXVK, D8VK, FSR 3.1
- OBS Studio com hardware encoding

### 💻 Desenvolvimento
- VS Code, Neovim (config Phantom), Zed
- Godot 4.3+, Unity Hub, Unreal Engine deps
- Rust, Python, C/C++, Go, Node.js 22, Zig, Lua, Java
- Docker, Podman, Distrobox, Kubernetes

### 🖥️ Desktop
- **Hyprland** (Wayland) — principal, ultra-otimizado
- **KDE Plasma 6** — alternativa opcional
- Tema completo Phantom (cyberpunk neon)
- Plymouth boot animado

### 🔒 Segurança
- AppArmor habilitado
- Firewalld + UFW
- hardened_malloc opcional
- Zero telemetria

## Estrutura do Projeto

```
phantomarch/
├── archiso/                    # Archiso profile completo
│   ├── airootfs/              # Sistema de arquivos raiz
│   │   ├── etc/               # Configurações do sistema
│   │   ├── usr/               # Binários e recursos
│   │   └── root/              # Home do root (live)
│   ├── efiboot/               # Boot EFI
│   ├── syslinux/              # Boot legacy
│   ├── grub/                  # GRUB config
│   ├── packages/              # Listas de pacotes
│   ├── pacman.conf            # Pacman config customizado
│   ├── profiledef.sh          # Definição do perfil Archiso
│   └── build.sh               # Script de build principal
├── scripts/                    # Scripts auxiliares
│   ├── build-iso.sh           # Builder completo da ISO
│   ├── post-install.sh        # Pós-instalação
│   ├── phantom-welcome.sh     # App de boas-vindas
│   └── phantom-optimizer.sh   # Ferramenta de otimização
├── branding/                   # Assets visuais
├── docs/                       # Documentação
│   ├── BUILD.md               # Instruções de build
│   ├── TESTING.md             # Checklist de testes
│   └── HANDBOOK.md            # Manual do usuário
└── README.md                  # Este arquivo
```

## Quick Build

```bash
# Em uma máquina Arch Linux:
cd phantomarch/archiso
sudo ./build.sh

# A ISO será gerada em out/
```

Veja [docs/BUILD.md](docs/BUILD.md) para instruções detalhadas.

## Requisitos de Build

- Arch Linux (ou derivado) com `archiso` instalado
- 20GB+ de espaço em disco
- Conexão com internet (para download de pacotes)
- 8GB+ RAM recomendado

## Kernels Inclusos

| Kernel | Descrição |
|--------|-----------|
| linux-zen | Padrão — melhor equilíbrio performance/latência |
| linux-xanmod | Alta performance para gaming |
| linux-xanmod-edge | Bleeding edge com últimas otimizações |

## Licença

PhantomArch é software livre. Todos os scripts e configurações neste repositório estão sob a licença **GPL-3.0**.

---

*Desenvolvido com 👻 por PhantomArch Team*
