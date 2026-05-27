#!/usr/bin/env python3
"""
FexNav — Official Browser for FexOS
Native browser (GTK4 + WebKitGTK), NO Electron.
Features: AI assistant, fast tabs, Opera-style sidebar, configurable RAM/performance.
"""

import sys
import os
import json
import subprocess
from pathlib import Path
from datetime import datetime

# FexNav paths
FEXNAV_DIR = Path.home() / ".fexnav"
CONFIG_FILE = FEXNAV_DIR / "config.json"
BOOKMARKS_FILE = FEXNAV_DIR / "bookmarks.json"
HISTORY_FILE = FEXNAV_DIR / "history.json"
EXTENSIONS_DIR = FEXNAV_DIR / "extensions"

DEFAULT_CONFIG = {
    "homepage": "fexnav://home",
    "search_engine": "https://www.google.com/search?q=",
    "theme": "dark",
    "language": "pt_BR",
    "ram_limit_mb": 2048,
    "hardware_acceleration": True,
    "smooth_scrolling": True,
    "preload_pages": True,
    "ad_blocker": True,
    "tracker_blocker": True,
    "ai_enabled": True,
    "ai_model": "local",
    "sidebar_enabled": True,
    "sidebar_apps": ["spotify", "whatsapp", "telegram", "discord"],
    "new_tab_page": "speed_dial",
    "download_dir": str(Path.home() / "Downloads"),
    "proxy": None,
    "user_agent": "FexNav/6.0 (Linux; FexOS) WebKit",
    "max_tabs": 50,
    "tab_sleep_timeout": 300,
    "dns_over_https": True,
    "performance_mode": "balanced"
}

DEFAULT_BOOKMARKS = {
    "bookmarks": [
        {"title": "Google", "url": "https://www.google.com", "icon": "🔍"},
        {"title": "YouTube", "url": "https://www.youtube.com", "icon": "📺"},
        {"title": "GitHub", "url": "https://github.com", "icon": "💻"},
        {"title": "Spotify", "url": "https://open.spotify.com", "icon": "🎵"},
        {"title": "WhatsApp", "url": "https://web.whatsapp.com", "icon": "💬"},
        {"title": "Discord", "url": "https://discord.com/app", "icon": "🎮"},
    ],
    "folders": [
        {"name": "Desenvolvimento", "bookmarks": [
            {"title": "Stack Overflow", "url": "https://stackoverflow.com"},
            {"title": "MDN", "url": "https://developer.mozilla.org"},
        ]},
        {"name": "Gaming", "bookmarks": [
            {"title": "Steam", "url": "https://store.steampowered.com"},
            {"title": "Epic Games", "url": "https://store.epicgames.com"},
        ]}
    ]
}


def ensure_dirs():
    for d in [FEXNAV_DIR, EXTENSIONS_DIR]:
        d.mkdir(parents=True, exist_ok=True)


def load_config():
    if CONFIG_FILE.exists():
        with open(CONFIG_FILE) as f:
            return json.load(f)
    save_config(DEFAULT_CONFIG)
    return DEFAULT_CONFIG.copy()


def save_config(config):
    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f, indent=2)


def load_bookmarks():
    if BOOKMARKS_FILE.exists():
        with open(BOOKMARKS_FILE) as f:
            return json.load(f)
    with open(BOOKMARKS_FILE, "w") as f:
        json.dump(DEFAULT_BOOKMARKS, f, indent=2)
    return DEFAULT_BOOKMARKS.copy()


def add_history(url, title=""):
    history = []
    if HISTORY_FILE.exists():
        with open(HISTORY_FILE) as f:
            history = json.load(f)
    history.insert(0, {
        "url": url,
        "title": title,
        "timestamp": datetime.now().isoformat()
    })
    # Keep last 10000
    history = history[:10000]
    with open(HISTORY_FILE, "w") as f:
        json.dump(history, f)


def launch_browser(url=None):
    """Launch FexNav using GTK4 + WebKitGTK."""
    ensure_dirs()
    config = load_config()

    try:
        import gi
        gi.require_version("Gtk", "4.0")
        gi.require_version("WebKit", "6.0")
        from gi.repository import Gtk, WebKit, GLib, Gdk
        from fexnav_window import FexNavApplication
        app = FexNavApplication(config=config, start_url=url)
        app.run(sys.argv)
    except (ImportError, ValueError) as e:
        print(f"[FexNav] GTK4/WebKitGTK não disponível: {e}")
        print("[FexNav] Instale: sudo pacman -S webkit2gtk-5.0 gtk4")
        print("[FexNav] Abrindo URL no navegador padrão...")
        if url:
            subprocess.run(["xdg-open", url])


def main():
    ensure_dirs()

    if len(sys.argv) < 2:
        launch_browser()
        return

    cmd = sys.argv[1]

    if cmd == "--help":
        print("FexNav — Navegador FexOS")
        print("Uso: fexnav [url]")
        print("")
        print("Opções:")
        print("  --config       Mostrar configuração")
        print("  --reset        Resetar configurações")
        print("  --private      Modo privado")
        print("  --performance  Modo performance")
        print("  --ai           Abrir assistente IA")
        return

    if cmd == "--config":
        config = load_config()
        print(json.dumps(config, indent=2))

    elif cmd == "--reset":
        save_config(DEFAULT_CONFIG)
        print("[FexNav] Configurações resetadas")

    elif cmd == "--private":
        os.environ["FEXNAV_PRIVATE"] = "1"
        launch_browser()

    elif cmd == "--performance":
        config = load_config()
        config["performance_mode"] = "high"
        config["hardware_acceleration"] = True
        config["preload_pages"] = False
        config["tab_sleep_timeout"] = 60
        save_config(config)
        launch_browser()

    elif cmd.startswith("http") or cmd.startswith("fexnav://"):
        launch_browser(cmd)

    else:
        launch_browser(f"https://www.google.com/search?q={cmd}")


if __name__ == "__main__":
    main()
