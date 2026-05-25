#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch V4 — Fex Antivirus File Check Popup             ║
# ║  Exibe popup antes de executar arquivo suspeito              ║
# ╚══════════════════════════════════════════════════════════════╝
# Usage: fex-antivirus-popup.sh <file_path>

FILE="$1"
QUARANTINE="/var/lib/phantomarch/quarantine"

if [[ -z "$FILE" ]]; then
    echo "Uso: fex-antivirus-popup.sh <arquivo>"
    exit 1
fi

if [[ ! -f "$FILE" ]]; then
    echo "Arquivo não encontrado: $FILE"
    exit 1
fi

mkdir -p "$QUARANTINE"

# Check file reputation
is_suspicious() {
    local file="$1"

    # Check with ClamAV
    if command -v clamscan &>/dev/null; then
        if clamscan --no-summary "$file" 2>/dev/null | grep -q "FOUND"; then
            return 0  # suspicious
        fi
    fi

    # Check with YARA
    if command -v yara &>/dev/null && [[ -d /opt/fexai/security/yara-rules ]]; then
        if yara -r /opt/fexai/security/yara-rules "$file" 2>/dev/null | grep -q ":"; then
            return 0  # suspicious
        fi
    fi

    # Heuristic: downloaded .exe, .sh with suspicious content
    case "${file,,}" in
        *.exe|*.msi|*.bat|*.cmd|*.ps1|*.vbs)
            return 0  # Always warn for Windows executables
            ;;
        *.sh)
            # Check for dangerous commands
            if grep -qE "(rm -rf /|:()\{|/dev/tcp/|chmod 777 /)" "$file" 2>/dev/null; then
                return 0
            fi
            ;;
    esac

    return 1  # safe
}

# Show popup using zenity/kdialog/terminal
show_popup() {
    local file="$1"
    local filename=$(basename "$file")
    local filesize=$(du -h "$file" | awk '{print $1}')

    # Try zenity (GTK)
    if command -v zenity &>/dev/null && [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
        RESPONSE=$(zenity --question \
            --title="⚠ Fex Security" \
            --text="<b>Este arquivo pode ser perigoso.</b>\n\nArquivo: $filename\nTamanho: $filesize\n\nDeseja executar mesmo assim?" \
            --ok-label="Executar mesmo assim" \
            --cancel-label="Cancelar" \
            --extra-button="Quarentena" \
            --width=400 2>&1)

        case $? in
            0) return 0 ;;  # Execute
            1) return 1 ;;  # Cancel
            *) return 2 ;;  # Extra (Quarantine)
        esac

    # Try kdialog (KDE)
    elif command -v kdialog &>/dev/null && [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
        kdialog --warningyesnocancel \
            "Este arquivo pode ser perigoso.\n\nArquivo: $filename\nTamanho: $filesize\n\nDeseja executar?" \
            --title "Fex Security" \
            --yes-label "Executar" \
            --no-label "Quarentena" \
            --cancel-label "Cancelar"

        case $? in
            0) return 0 ;;  # Yes = Execute
            1) return 2 ;;  # No = Quarantine
            2) return 1 ;;  # Cancel
        esac

    # Fallback: terminal
    else
        echo ""
        echo "  ⚠ FEX SECURITY WARNING"
        echo "  ━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  Este arquivo pode ser perigoso."
        echo ""
        echo "  Arquivo: $filename"
        echo "  Tamanho: $filesize"
        echo ""
        echo "  [1] Executar mesmo assim"
        echo "  [2] Cancelar"
        echo "  [3] Colocar em quarentena"
        echo ""
        echo -n "  Escolha: "
        read -r choice
        case $choice in
            1) return 0 ;;
            2) return 1 ;;
            3) return 2 ;;
            *) return 1 ;;
        esac
    fi
}

# === MAIN ===
if is_suspicious "$FILE"; then
    show_popup "$FILE"
    RESULT=$?

    case $RESULT in
        0)
            # User chose to execute
            echo "WARN: User executed suspicious file: $FILE" >> /var/log/phantomarch/security/monitor.log
            chmod +x "$FILE" 2>/dev/null
            exec "$FILE"
            ;;
        1)
            # Cancelled
            echo "Execução cancelada."
            exit 0
            ;;
        2)
            # Quarantine
            mv "$FILE" "$QUARANTINE/"
            notify-send "Fex Security" "Arquivo movido para quarentena: $(basename "$FILE")" 2>/dev/null
            echo "Arquivo movido para quarentena."
            exit 0
            ;;
    esac
else
    # File appears safe, execute normally
    chmod +x "$FILE" 2>/dev/null
    exec "$FILE"
fi
