#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  PhantomArch V4 — Fex Antivirus Real-Time Monitor            ║
# ║  Monitora downloads, /tmp e comportamento suspeito           ║
# ╚══════════════════════════════════════════════════════════════╝

LOG_DIR="/var/log/phantomarch/security"
QUARANTINE="/var/lib/phantomarch/quarantine"
YARA_RULES="/opt/fexai/security/yara-rules"
WATCH_DIRS="/tmp /home/*/Downloads"

mkdir -p "$LOG_DIR" "$QUARANTINE" "$YARA_RULES"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_DIR/monitor.log"
}

notify_threat() {
    local file="$1"
    local threat="$2"
    # Desktop notification
    if command -v notify-send &>/dev/null; then
        notify-send -u critical "⚠ Fex Security" \
            "Ameaça detectada:\n$threat\nArquivo: $(basename "$file")\n\nMovido para quarentena." \
            --icon=dialog-warning
    fi
    log "THREAT: $threat — $file"
}

# === YARA Rules (built-in) ===
setup_yara_rules() {
    # Basic malware detection rules
    cat > "$YARA_RULES/crypto_miners.yar" << 'YARA'
rule CryptoMiner {
    meta:
        description = "Detects cryptocurrency miners"
    strings:
        $s1 = "stratum+tcp://" ascii
        $s2 = "xmrig" ascii nocase
        $s3 = "cryptonight" ascii nocase
        $s4 = "monero" ascii nocase
        $s5 = "coinhive" ascii nocase
        $s6 = "minergate" ascii nocase
    condition:
        2 of them
}
YARA

    cat > "$YARA_RULES/ransomware.yar" << 'YARA'
rule Ransomware {
    meta:
        description = "Detects ransomware indicators"
    strings:
        $s1 = "Your files have been encrypted" ascii nocase
        $s2 = "bitcoin" ascii nocase
        $s3 = ".onion" ascii
        $s4 = "decrypt" ascii nocase
        $s5 = "ransom" ascii nocase
        $s6 = "pay" ascii nocase
    condition:
        3 of them
}
YARA

    cat > "$YARA_RULES/malicious_scripts.yar" << 'YARA'
rule MaliciousScript {
    meta:
        description = "Detects potentially malicious scripts"
    strings:
        $rm_rf = "rm -rf /" ascii
        $rm_rf2 = "rm -rf /*" ascii
        $fork_bomb = ":(){ :|:& };:" ascii
        $reverse_shell = "/dev/tcp/" ascii
        $nc_shell = "nc -e /bin/" ascii
        $base64_exec = "base64 -d" ascii
        $curl_bash = "curl" ascii
        $wget_sh = "wget" ascii
        $chmod_777 = "chmod 777 /" ascii
        $dd_dev = "dd if=/dev/zero of=/dev/sd" ascii
    condition:
        ($rm_rf or $rm_rf2 or $fork_bomb or $dd_dev) or
        ($reverse_shell and $nc_shell) or
        ($chmod_777)
}
YARA
}

# === Process Monitor ===
check_suspicious_processes() {
    # High CPU usage (possible miner)
    while read -r pid cpu cmd; do
        if (( $(echo "$cpu > 90" | bc -l 2>/dev/null || echo 0) )); then
            # Check if it's a known process
            if echo "$cmd" | grep -qiE "(xmrig|minerd|cpuminer)"; then
                log "SUSPICIOUS PROCESS: PID=$pid CPU=$cpu% CMD=$cmd"
                notify_threat "$cmd" "Processo suspeito com alto uso de CPU (possível minerador)"
                kill "$pid" 2>/dev/null
            fi
        fi
    done < <(ps aux --no-headers | awk '{print $2, $3, $11}' | sort -k2 -nr | head -5)
}

# === File Monitor (inotifywait) ===
monitor_files() {
    if ! command -v inotifywait &>/dev/null; then
        log "WARN: inotifywait não disponível. Usando polling."
        monitor_polling
        return
    fi

    log "Starting real-time file monitor..."

    # Monitor Downloads and /tmp
    for dir in /home/*/Downloads /tmp; do
        [[ -d "$dir" ]] || continue
        inotifywait -m -r -e create,modify,moved_to "$dir" 2>/dev/null | while read -r path event file; do
            full_path="${path}${file}"

            # Skip tiny files
            [[ -f "$full_path" ]] || continue
            SIZE=$(stat -c%s "$full_path" 2>/dev/null || echo 0)
            [[ $SIZE -lt 100 ]] && continue

            # Quick scan with ClamAV
            if command -v clamscan &>/dev/null; then
                if clamscan --no-summary "$full_path" 2>/dev/null | grep -q "FOUND"; then
                    mv "$full_path" "$QUARANTINE/" 2>/dev/null
                    notify_threat "$full_path" "ClamAV: Malware detectado"
                fi
            fi

            # YARA scan
            if command -v yara &>/dev/null && [[ -d "$YARA_RULES" ]]; then
                if yara -r "$YARA_RULES" "$full_path" 2>/dev/null | grep -q ":"; then
                    RULE=$(yara -r "$YARA_RULES" "$full_path" 2>/dev/null | head -1 | awk '{print $1}')
                    mv "$full_path" "$QUARANTINE/" 2>/dev/null
                    notify_threat "$full_path" "YARA: $RULE"
                fi
            fi
        done &
    done

    # Process monitor loop
    while true; do
        check_suspicious_processes
        sleep 30
    done
}

# === Polling fallback ===
monitor_polling() {
    log "Starting polling monitor..."
    while true; do
        check_suspicious_processes

        # Scan new files in Downloads
        for dir in /home/*/Downloads; do
            [[ -d "$dir" ]] || continue
            find "$dir" -newer "$LOG_DIR/monitor.log" -type f 2>/dev/null | while read -r file; do
                if command -v clamscan &>/dev/null; then
                    if clamscan --no-summary "$file" 2>/dev/null | grep -q "FOUND"; then
                        mv "$file" "$QUARANTINE/"
                        notify_threat "$file" "ClamAV: Malware detectado"
                    fi
                fi
            done
        done

        sleep 60
    done
}

# === MAIN ===
setup_yara_rules
log "Fex Antivirus Monitor started (PID: $$)"
monitor_files
