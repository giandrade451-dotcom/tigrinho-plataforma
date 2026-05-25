#!/bin/bash
# ============================================================
# PhantomArch — KDE Plasma 6 Theme Installer
# Aplica o tema Phantom cyberpunk neon no KDE
# ============================================================

echo "🎨 Aplicando tema PhantomArch no KDE Plasma 6..."

# Global Theme
plasma-apply-lookandfeel -a org.kde.breezedark.desktop 2>/dev/null

# Color Scheme — Phantom Dark
mkdir -p ~/.local/share/color-schemes
cat > ~/.local/share/color-schemes/PhantomDark.colors << 'EOF'
[General]
ColorScheme=PhantomDark
Name=Phantom Dark

[Colors:Window]
BackgroundNormal=10,10,18
ForegroundNormal=248,248,242

[Colors:View]
BackgroundNormal=26,26,46
ForegroundNormal=248,248,242
DecorationHover=189,147,249
DecorationFocus=0,255,247

[Colors:Button]
BackgroundNormal=30,30,50
ForegroundNormal=248,248,242
DecorationHover=189,147,249
DecorationFocus=0,255,247

[Colors:Selection]
BackgroundNormal=189,147,249
ForegroundNormal=10,10,18

[Colors:Tooltip]
BackgroundNormal=26,26,46
ForegroundNormal=248,248,242

[Colors:Complementary]
BackgroundNormal=10,10,18
ForegroundNormal=248,248,242

[Colors:Header]
BackgroundNormal=10,10,18
ForegroundNormal=248,248,242

[WM]
activeBackground=10,10,18
activeForeground=248,248,242
inactiveBackground=10,10,18
inactiveForeground=139,141,163
activeBlend=189,147,249
EOF

plasma-apply-colorscheme PhantomDark 2>/dev/null

# Icon Theme
/usr/bin/plasma-apply-desktoptheme breeze-dark 2>/dev/null

# Cursor Theme
mkdir -p ~/.icons/default
cat > ~/.icons/default/index.theme << 'EOF'
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=Catppuccin-Mocha-Dark-Cursors
EOF

# Wallpaper
plasma-apply-wallpaperimage /usr/share/phantom/wallpapers/phantom-cyberpunk-default.png 2>/dev/null

# Konsole Profile
mkdir -p ~/.local/share/konsole
cat > ~/.local/share/konsole/PhantomArch.profile << 'EOF'
[Appearance]
ColorScheme=PhantomNeon
Font=JetBrainsMono Nerd Font,12,-1,5,50,0,0,0,0,0
UseFontLineChararacters=true

[General]
Command=/bin/zsh
Name=PhantomArch
Parent=FALLBACK/
TerminalColumns=120
TerminalRows=36

[Scrolling]
HistoryMode=2
ScrollBarPosition=2
EOF

# Konsole Color Scheme
cat > ~/.local/share/konsole/PhantomNeon.colorscheme << 'EOF'
[General]
Description=Phantom Neon
Opacity=0.88
Wallpaper=

[Background]
Color=10,10,18

[Foreground]
Color=248,248,242

[Color0]
Color=26,26,46

[Color1]
Color=255,85,85

[Color2]
Color=80,250,123

[Color3]
Color=241,250,140

[Color4]
Color=98,114,164

[Color5]
Color=255,121,198

[Color6]
Color=0,255,247

[Color7]
Color=248,248,242

[Color8]
Color=61,61,92

[Color9]
Color=255,110,110

[Color10]
Color=105,255,148

[Color11]
Color=255,255,165

[Color12]
Color=139,233,253

[Color13]
Color=255,146,223

[Color14]
Color=51,255,249

[Color15]
Color=255,255,255
EOF

echo "✅ Tema PhantomArch aplicado com sucesso no KDE!"
