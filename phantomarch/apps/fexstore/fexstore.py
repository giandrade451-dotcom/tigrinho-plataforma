#!/usr/bin/env python3
"""
FexStore — Official App Store for FexOS
Install apps, games, communicate apps (WhatsApp, Telegram).
Supports: Flatpak, native packages, AppImage.
Login: Microsoft, Google accounts.
"""

import sys
import os
import json
import subprocess
import shutil
from pathlib import Path
from datetime import datetime

FEXSTORE_DIR = Path.home() / ".fexstore"
CONFIG_FILE = FEXSTORE_DIR / "config.json"
INSTALLED_FILE = FEXSTORE_DIR / "installed.json"
CACHE_DIR = FEXSTORE_DIR / "cache"

# App catalog (built-in — auto-updated from repo)
APP_CATALOG = {
    "communication": [
        {
            "id": "whatsapp",
            "name": "WhatsApp",
            "icon": "💬",
            "description": "Mensagens e chamadas",
            "install_method": "flatpak",
            "flatpak_id": "io.github.nickvision.whatsapp",
            "category": "communication",
            "free": True,
            "rating": 4.5
        },
        {
            "id": "telegram",
            "name": "Telegram",
            "icon": "✈️",
            "description": "Mensagens rápidas e seguras",
            "install_method": "flatpak",
            "flatpak_id": "org.telegram.desktop",
            "category": "communication",
            "free": True,
            "rating": 4.7
        },
        {
            "id": "discord",
            "name": "Discord",
            "icon": "🎮",
            "description": "Chat para gamers e comunidades",
            "install_method": "flatpak",
            "flatpak_id": "com.discordapp.Discord",
            "category": "communication",
            "free": True,
            "rating": 4.3
        },
        {
            "id": "signal",
            "name": "Signal",
            "icon": "🔒",
            "description": "Mensagens privadas e criptografadas",
            "install_method": "flatpak",
            "flatpak_id": "org.signal.Signal",
            "category": "communication",
            "free": True,
            "rating": 4.6
        },
    ],
    "games": [
        {
            "id": "steam",
            "name": "Steam",
            "icon": "🎮",
            "description": "Plataforma de jogos",
            "install_method": "pacman",
            "package": "steam",
            "category": "games",
            "free": True,
            "rating": 4.8
        },
        {
            "id": "lutris",
            "name": "Lutris",
            "icon": "🎲",
            "description": "Gerenciador de jogos para Linux",
            "install_method": "pacman",
            "package": "lutris",
            "category": "games",
            "free": True,
            "rating": 4.4
        },
        {
            "id": "heroic",
            "name": "Heroic Games Launcher",
            "icon": "⚔️",
            "description": "Epic Games e GOG no Linux",
            "install_method": "flatpak",
            "flatpak_id": "com.heroicgameslauncher.hgl",
            "category": "games",
            "free": True,
            "rating": 4.5
        },
        {
            "id": "minecraft",
            "name": "FexLauncher (Minecraft)",
            "icon": "⛏️",
            "description": "Launcher oficial de Minecraft do FexOS",
            "install_method": "native",
            "command": "fexlauncher --gui",
            "category": "games",
            "free": True,
            "rating": 4.9
        },
        {
            "id": "retroarch",
            "name": "RetroArch",
            "icon": "🕹️",
            "description": "Emulador multi-sistema",
            "install_method": "flatpak",
            "flatpak_id": "org.libretro.RetroArch",
            "category": "games",
            "free": True,
            "rating": 4.6
        },
        {
            "id": "bottles",
            "name": "Bottles",
            "icon": "🍾",
            "description": "Execute jogos e apps Windows",
            "install_method": "flatpak",
            "flatpak_id": "com.usebottles.bottles",
            "category": "games",
            "free": True,
            "rating": 4.5
        },
    ],
    "productivity": [
        {
            "id": "fexcode",
            "name": "FexCode",
            "icon": "💻",
            "description": "IDE oficial do FexOS",
            "install_method": "native",
            "command": "fexcode",
            "category": "productivity",
            "free": True,
            "rating": 4.8
        },
        {
            "id": "libreoffice",
            "name": "LibreOffice",
            "icon": "📄",
            "description": "Suite de escritório completa",
            "install_method": "pacman",
            "package": "libreoffice-fresh",
            "category": "productivity",
            "free": True,
            "rating": 4.4
        },
        {
            "id": "obsidian",
            "name": "Obsidian",
            "icon": "📝",
            "description": "Notas e base de conhecimento",
            "install_method": "flatpak",
            "flatpak_id": "md.obsidian.Obsidian",
            "category": "productivity",
            "free": True,
            "rating": 4.7
        },
    ],
    "multimedia": [
        {
            "id": "spotify",
            "name": "Spotify",
            "icon": "🎵",
            "description": "Música em streaming",
            "install_method": "flatpak",
            "flatpak_id": "com.spotify.Client",
            "category": "multimedia",
            "free": True,
            "rating": 4.6
        },
        {
            "id": "vlc",
            "name": "VLC",
            "icon": "🎬",
            "description": "Player de mídia universal",
            "install_method": "pacman",
            "package": "vlc",
            "category": "multimedia",
            "free": True,
            "rating": 4.8
        },
        {
            "id": "obs",
            "name": "OBS Studio",
            "icon": "📹",
            "description": "Streaming e gravação",
            "install_method": "pacman",
            "package": "obs-studio",
            "category": "multimedia",
            "free": True,
            "rating": 4.9
        },
        {
            "id": "gimp",
            "name": "GIMP",
            "icon": "🖌️",
            "description": "Editor de imagens profissional",
            "install_method": "pacman",
            "package": "gimp",
            "category": "multimedia",
            "free": True,
            "rating": 4.3
        },
        {
            "id": "blender",
            "name": "Blender",
            "icon": "🎨",
            "description": "Modelagem 3D e animação",
            "install_method": "pacman",
            "package": "blender",
            "category": "multimedia",
            "free": True,
            "rating": 4.9
        },
    ],
    "system": [
        {
            "id": "fexnav",
            "name": "FexNav",
            "icon": "🌐",
            "description": "Navegador oficial do FexOS",
            "install_method": "native",
            "command": "fexnav",
            "category": "system",
            "free": True,
            "rating": 4.7
        },
        {
            "id": "timeshift",
            "name": "Timeshift",
            "icon": "⏰",
            "description": "Backup e restore do sistema",
            "install_method": "pacman",
            "package": "timeshift",
            "category": "system",
            "free": True,
            "rating": 4.5
        },
    ]
}


def ensure_dirs():
    for d in [FEXSTORE_DIR, CACHE_DIR]:
        d.mkdir(parents=True, exist_ok=True)


def load_installed():
    if INSTALLED_FILE.exists():
        with open(INSTALLED_FILE) as f:
            return json.load(f)
    return {"apps": []}


def save_installed(data):
    with open(INSTALLED_FILE, "w") as f:
        json.dump(data, f, indent=2)


def install_app(app):
    """Install an app using the appropriate method."""
    method = app.get("install_method")
    name = app.get("name")

    print(f"[FexStore] Instalando {name}...")

    if method == "flatpak":
        flatpak_id = app.get("flatpak_id")
        result = subprocess.run(
            ["flatpak", "install", "-y", "flathub", flatpak_id],
            capture_output=True, text=True
        )
        if result.returncode == 0:
            print(f"[FexStore] {name} instalado com sucesso!")
            mark_installed(app)
            return True
        else:
            print(f"[FexStore] Erro: {result.stderr}")
            return False

    elif method == "pacman":
        package = app.get("package")
        result = subprocess.run(
            ["sudo", "pacman", "-S", "--noconfirm", package],
            capture_output=True, text=True
        )
        if result.returncode == 0:
            print(f"[FexStore] {name} instalado com sucesso!")
            mark_installed(app)
            return True
        else:
            print(f"[FexStore] Erro: {result.stderr}")
            return False

    elif method == "native":
        print(f"[FexStore] {name} já está integrado ao sistema")
        mark_installed(app)
        return True

    return False


def uninstall_app(app):
    """Uninstall an app."""
    method = app.get("install_method")
    name = app.get("name")

    if method == "flatpak":
        flatpak_id = app.get("flatpak_id")
        subprocess.run(["flatpak", "uninstall", "-y", flatpak_id])
    elif method == "pacman":
        package = app.get("package")
        subprocess.run(["sudo", "pacman", "-R", "--noconfirm", package])

    # Remove from installed
    installed = load_installed()
    installed["apps"] = [a for a in installed["apps"] if a["id"] != app["id"]]
    save_installed(installed)
    print(f"[FexStore] {name} removido")


def mark_installed(app):
    installed = load_installed()
    if not any(a["id"] == app["id"] for a in installed["apps"]):
        installed["apps"].append({
            "id": app["id"],
            "name": app["name"],
            "installed_at": datetime.now().isoformat(),
            "method": app["install_method"]
        })
        save_installed(installed)


def search_apps(query):
    """Search apps in catalog."""
    results = []
    query = query.lower()
    for category, apps in APP_CATALOG.items():
        for app in apps:
            if (query in app["name"].lower() or
                query in app.get("description", "").lower() or
                query in app["id"]):
                results.append(app)
    return results


def list_category(category):
    """List apps in a category."""
    return APP_CATALOG.get(category, [])


def main():
    ensure_dirs()

    if len(sys.argv) < 2:
        print("FexStore — Loja de Apps FexOS")
        print("")
        print("Uso: fexstore [comando]")
        print("")
        print("Comandos:")
        print("  list [category]    Lista apps (communication/games/productivity/multimedia/system)")
        print("  search <query>     Buscar apps")
        print("  install <app_id>   Instalar app")
        print("  uninstall <app_id> Remover app")
        print("  installed          Listar apps instalados")
        print("  update             Atualizar todos os apps")
        print("  --gui              Interface gráfica")
        print("")
        print("Categorias: communication, games, productivity, multimedia, system")
        return

    cmd = sys.argv[1]

    if cmd == "list":
        category = sys.argv[2] if len(sys.argv) > 2 else None
        if category:
            apps = list_category(category)
            print(f"\n  ⚡ {category.upper()}\n")
            for app in apps:
                status = "✓" if is_installed(app["id"]) else " "
                price = "Grátis" if app["free"] else "Pago"
                print(f"  [{status}] {app['icon']} {app['name']:<25} {price:<8} ⭐{app['rating']}")
                print(f"       {app['description']}")
                print()
        else:
            for cat in APP_CATALOG:
                print(f"\n  ⚡ {cat.upper()}")
                for app in APP_CATALOG[cat]:
                    print(f"    {app['icon']} {app['name']}")

    elif cmd == "search":
        query = " ".join(sys.argv[2:])
        results = search_apps(query)
        if results:
            print(f"\n  Resultados para '{query}':\n")
            for app in results:
                print(f"  {app['icon']} {app['name']} — {app['description']}")
        else:
            print(f"  Nenhum resultado para '{query}'")

    elif cmd == "install":
        app_id = sys.argv[2] if len(sys.argv) > 2 else None
        if not app_id:
            print("Uso: fexstore install <app_id>")
            return
        app = find_app(app_id)
        if app:
            install_app(app)
        else:
            print(f"App '{app_id}' não encontrado")

    elif cmd == "uninstall":
        app_id = sys.argv[2] if len(sys.argv) > 2 else None
        if app_id:
            app = find_app(app_id)
            if app:
                uninstall_app(app)

    elif cmd == "installed":
        installed = load_installed()
        if installed["apps"]:
            print("\n  Apps instalados:\n")
            for app in installed["apps"]:
                print(f"  ✓ {app['name']} (desde {app['installed_at'][:10]})")
        else:
            print("  Nenhum app instalado via FexStore")

    elif cmd == "update":
        print("[FexStore] Atualizando apps...")
        subprocess.run(["flatpak", "update", "-y"])
        subprocess.run(["sudo", "pacman", "-Syu", "--noconfirm"])
        print("[FexStore] Atualização concluída!")

    elif cmd == "--gui":
        print("[FexStore] Iniciando interface gráfica...")
        launch_gui()


def find_app(app_id):
    for category, apps in APP_CATALOG.items():
        for app in apps:
            if app["id"] == app_id:
                return app
    return None


def is_installed(app_id):
    installed = load_installed()
    return any(a["id"] == app_id for a in installed["apps"])


def launch_gui():
    try:
        from fexstore_gui import FexStoreApp
        app = FexStoreApp(sys.argv)
        sys.exit(app.exec())
    except ImportError:
        print("[FexStore] PyQt6 necessário. Instale: pip install PyQt6")
        print("[FexStore] Use modo CLI: fexstore --help")


if __name__ == "__main__":
    main()
