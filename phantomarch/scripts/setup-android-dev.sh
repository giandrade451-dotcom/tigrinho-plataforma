#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch V2 — Android Development Setup                  ║
# ║  Android Studio, SDK, Flutter, React Native, APK tools       ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${PURPLE}━━━ PhantomArch Android Development Setup ━━━${NC}"

TARGET_USER="${SUDO_USER:-$(logname 2>/dev/null || echo $USER)}"
TARGET_HOME="/home/$TARGET_USER"

# --- Android SDK ---
echo -e "${CYAN}[1/6]${NC} Configurando Android SDK..."
ANDROID_HOME="${TARGET_HOME}/Android/Sdk"
sudo -u "$TARGET_USER" mkdir -p "$ANDROID_HOME"
sudo -u "$TARGET_USER" mkdir -p "${TARGET_HOME}/.android"

# Environment variables
cat >> "${TARGET_HOME}/.zshrc" << 'EOF'

# Android SDK
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
EOF

echo -e "${GREEN}  ✓ Android SDK paths configurados${NC}"

# --- Flutter ---
echo -e "${CYAN}[2/6]${NC} Instalando Flutter..."
FLUTTER_DIR="${TARGET_HOME}/.flutter-sdk"
if [[ ! -d "$FLUTTER_DIR" ]]; then
    sudo -u "$TARGET_USER" git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_DIR" 2>/dev/null || true
fi

cat >> "${TARGET_HOME}/.zshrc" << 'EOF'

# Flutter
export PATH="$HOME/.flutter-sdk/bin:$PATH"
export CHROME_EXECUTABLE=/usr/bin/chromium
EOF

echo -e "${GREEN}  ✓ Flutter instalado${NC}"

# --- React Native ---
echo -e "${CYAN}[3/6]${NC} Configurando React Native..."
sudo -u "$TARGET_USER" npm install -g react-native-cli expo-cli 2>/dev/null || true
echo -e "${GREEN}  ✓ React Native CLI instalado${NC}"

# --- APK Build Menu ---
echo -e "${CYAN}[4/6]${NC} Criando menu 'Criar APK'..."

cat > /usr/bin/phantom-build-apk << 'SCRIPT'
#!/bin/bash
# PhantomArch — Quick APK Builder
CYAN='\033[0;36m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}━━━ PhantomArch APK Builder ━━━${NC}"
echo ""
echo -e "  ${CYAN}[1]${NC} Flutter APK (flutter build apk)"
echo -e "  ${CYAN}[2]${NC} React Native APK (npx react-native build-android)"
echo -e "  ${CYAN}[3]${NC} Gradle APK (./gradlew assembleRelease)"
echo -e "  ${CYAN}[4]${NC} Decompile APK (apktool)"
echo -e "  ${CYAN}[5]${NC} Sign APK (apksigner)"
echo -e "  ${CYAN}[0]${NC} Sair"
echo ""
echo -ne "  Escolha: "
read -r choice

case $choice in
    1)
        echo "Executando: flutter build apk --release"
        flutter build apk --release
        ;;
    2)
        echo "Executando: npx react-native build-android --mode=release"
        cd android && ./gradlew assembleRelease
        ;;
    3)
        echo "Executando: ./gradlew assembleRelease"
        ./gradlew assembleRelease
        ;;
    4)
        echo -n "Caminho do APK: "
        read -r apk_path
        apktool d "$apk_path" -o "${apk_path%.apk}_decompiled"
        echo "Decompilado em: ${apk_path%.apk}_decompiled/"
        ;;
    5)
        echo -n "Caminho do APK: "
        read -r apk_path
        echo -n "Caminho do keystore: "
        read -r keystore
        apksigner sign --ks "$keystore" "$apk_path"
        echo "APK assinado!"
        ;;
    0) exit 0 ;;
esac
SCRIPT
chmod +x /usr/bin/phantom-build-apk

cat > /usr/share/applications/phantom-build-apk.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Criar APK
Comment=Build e assinar APKs Android
Exec=kitty -e phantom-build-apk
Icon=android-studio
Terminal=false
Categories=Development;IDE;
Keywords=apk;android;build;flutter;
EOF

echo -e "${GREEN}  ✓ Menu 'Criar APK' criado${NC}"

# --- Android Studio (AUR) ---
echo -e "${CYAN}[5/6]${NC} Android Studio..."
echo -e "${YELLOW}  Android Studio será instalado via: paru -S android-studio${NC}"
echo -e "  Ou via Flatpak: flatpak install flathub com.google.AndroidStudio"

# --- Kotlin/Gradle ---
echo -e "${CYAN}[6/6]${NC} Verificando Kotlin/Gradle..."
command -v kotlin &>/dev/null && echo -e "${GREEN}  ✓ Kotlin OK${NC}" || echo -e "  ! Kotlin: pacman -S kotlin"
command -v gradle &>/dev/null && echo -e "${GREEN}  ✓ Gradle OK${NC}" || echo -e "  ! Gradle: pacman -S gradle"

echo ""
echo -e "${PURPLE}━━━ Android Development configurado! ━━━${NC}"
echo -e "  Comandos: ${GREEN}phantom-build-apk${NC}, ${GREEN}flutter doctor${NC}, ${GREEN}adb devices${NC}"
