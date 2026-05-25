# PhantomArch — Descrição do Tema Visual Phantom

## Identidade Visual

### Paleta de Cores

| Nome | Hex | RGB | Uso |
|------|-----|-----|-----|
| **Phantom Black** | `#0a0a12` | 10, 10, 18 | Background principal |
| **Deep Purple** | `#1a1a2e` | 26, 26, 46 | Background secundário |
| **Neon Purple** | `#bd93f9` | 189, 147, 249 | Cor de destaque primária, bordas ativas |
| **Neon Cyan** | `#00fff7` | 0, 255, 247 | Cor de destaque secundária, cursor, links |
| **Neon Magenta** | `#ff79c6` | 255, 121, 198 | Terceira cor de acento |
| **Neon Green** | `#50fa7b` | 80, 250, 123 | Sucesso, confirmação |
| **Neon Orange** | `#ffb86c` | 255, 184, 108 | Avisos |
| **Neon Red** | `#ff5555` | 255, 85, 85 | Erros, urgência |
| **Ghost White** | `#f8f8f2` | 248, 248, 242 | Texto principal |
| **Muted Gray** | `#8b8da3` | 139, 141, 163 | Texto secundário |
| **Surface** | `#3d3d5c` | 61, 61, 92 | Elementos de superfície |

### Tipografia

| Contexto | Fonte | Fallback |
|----------|-------|----------|
| Terminal | JetBrainsMono Nerd Font | CaskaydiaCove Nerd Font |
| UI Headings | Inter Bold | sans-serif |
| UI Body | Inter Regular | sans-serif |
| Code | Fira Code | monospace |
| Icons | Nerd Fonts Symbols | - |

### Iconografia

- **Icon Theme**: Tela Circle (Purple variant)
- **Fallback**: Papirus Dark
- **Cursor**: Catppuccin Mocha Dark
- **Cursor Size**: 24px

---

## Componentes Visuais

### Hyprland Window Decorations
- **Border**: 2px, gradiente 45° de neon-purple para neon-cyan
- **Border (inativo)**: 2px, `#1a1a2e`
- **Rounding**: 8px
- **Gaps**: 4px (inner), 8px (outer)
- **Shadow**: 20px range, cor `#bd93f966`
- **Blur**: 6 size, 3 passes, com noise 0.02

### Waybar
- **Background**: `rgba(10, 10, 18, 0.92)`
- **Border bottom**: 2px solid `rgba(189, 147, 249, 0.4)`
- **Border radius**: 12px
- **Margin**: 4px top, 8px left/right
- **Height**: 36px
- **Active workspace**: Neon cyan com glow
- **Hover effects**: Purple com fade

### Wofi Launcher
- **Background**: `rgba(10, 10, 18, 0.95)`
- **Border**: 2px solid `rgba(189, 147, 249, 0.6)`
- **Border radius**: 16px
- **Input field**: Borda cyan, glow on focus
- **Selected item**: Background purple transparente, borda esquerda purple
- **Size**: 600x400px

### Dunst Notifications
- **Background**: `#0a0a12ee`
- **Border**: 2px frame
- **Normal**: Frame purple
- **Critical**: Frame red, pulsando
- **Corner radius**: 12px
- **Position**: Top-right, 12px offset

### Kitty Terminal
- **Opacity**: 0.88
- **Colorscheme**: Phantom Neon (baseado em Dracula, ajustado)
- **Tab bar**: Powerline slanted, purple ativo
- **Cursor**: Beam, neon cyan, blink 0.5s

### SDDM Login
- **Theme**: Sugar Candy customizado
- **Background**: Wallpaper phantom-lock com blur
- **Input field**: Borda purple, glow cyan
- **Clock**: Neon cyan, bold, 72px
- **Logo**: Ghost emoji + "PhantomArch"

### Plymouth Boot
- **Background**: Gradiente preto profundo (top: #0a0a12, bottom: #050508)
- **Logo**: PhantomArch ghost animado com pulse de opacidade
- **Progress bar**: Gradiente purple → cyan
- **Text**: Neon cyan, Sans 11pt

---

## Wallpapers

### Estilo dos Wallpapers
Todos os wallpapers seguem o tema cyberpunk com:
- Predominância de preto/roxo profundo
- Elementos neon (linhas, grids, texto)
- Aesthetic futurista/tecnológica
- Resolução mínima: 3840x2160 (4K)

### Wallpapers Inclusos
1. **phantom-cyberpunk-default.png** — Cidade cyberpunk com neon roxo/ciano
2. **phantom-neon-grid.png** — Grid retrô neon com perspectiva
3. **phantom-ghost-machine.png** — Abstract ghost/circuito com glow
4. **phantom-lock.png** — Versão escura para lockscreen (sem elementos brilhantes demais)
5. **phantom-dark-minimal.png** — Minimalista, logo ghost em fundo escuro

### Geração dos Wallpapers
Os wallpapers devem ser gerados com:
- **Resolução**: 3840x2160 (4K)
- **Formato**: PNG (sem compressão)
- **Ferramentas sugeridas**: Stable Diffusion, MidJourney, ou design manual em Figma/GIMP
- **Prompt base**: "dark cyberpunk cityscape, neon purple and cyan lights, 4k wallpaper, no text, dark background, futuristic, abstract digital art"

---

## Sons do Sistema

### Tema Sonoro
- **Estilo**: Cyberpunk/Sci-fi minimalista
- **Formato**: OGG Vorbis
- **Sons inclusos**:
  - `login.ogg` — Som suave de "power on" eletrônico
  - `logout.ogg` — Fade out digital
  - `notification.ogg` — Ping cristalino curto
  - `error.ogg` — Buzz eletrônico baixo
  - `volume-change.ogg` — Click digital sutil

---

## GTK Theme

### phantom-gtk (GTK 3/4)
Baseado no **Catppuccin Mocha** com overrides:
- Window background: `#0a0a12`
- Headerbar: `#0a0a12` com border-bottom purple
- Buttons: `#1a1a2e`, hover purple
- Selected/Focused: `#bd93f9`
- Links: `#00fff7`
- Scrollbar: Purple translúcido

### Qt Theme
- **Engine**: Kvantum
- **Theme**: Catppuccin-Mocha-Lavender customizado
- **qt5ct/qt6ct**: Configurados para seguir o tema GTK

---

## Consistência Visual

### Regras
1. **Nunca** usar branco puro (`#ffffff`) como background
2. **Nunca** usar bordas maiores que 2px
3. **Sempre** usar border-radius entre 8-16px
4. **Sempre** manter opacidade de terminais entre 0.85-0.92
5. **Glow effects** apenas em elementos interativos hover/focus
6. **Animações** devem ser suaves e rápidas (< 300ms)
7. **Gradientes** sempre de purple para cyan (45°)

### Inspirações
- Dracula Theme
- Catppuccin Mocha
- Tokyo Night
- Cyberpunk 2077 UI
- Ghost in the Shell aesthetics
- Blade Runner 2049 color grading
