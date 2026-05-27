#!/usr/bin/env python3
"""
FexLauncher — Official Minecraft Launcher for FexOS
Supports: Pirate + Original accounts, versions 1.8.8 to latest,
auto-update, skins/capes/mods/textures.

Built with PyQt6 (native, no Electron).
"""

import sys
import os
import json
import hashlib
import subprocess
import shutil
import urllib.request
import urllib.error
from pathlib import Path
from datetime import datetime

# Paths
FEXLAUNCHER_DIR = Path.home() / ".fexlauncher"
VERSIONS_DIR = FEXLAUNCHER_DIR / "versions"
INSTANCES_DIR = FEXLAUNCHER_DIR / "instances"
SKINS_DIR = FEXLAUNCHER_DIR / "skins"
MODS_DIR = FEXLAUNCHER_DIR / "mods"
TEXTURES_DIR = FEXLAUNCHER_DIR / "textures"
CONFIG_FILE = FEXLAUNCHER_DIR / "config.json"
ACCOUNTS_FILE = FEXLAUNCHER_DIR / "accounts.json"

# Mojang/Microsoft URLs
VERSION_MANIFEST = "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"
AUTHLIB_INJECTOR = "https://github.com/yushijinhun/authlib-injector/releases/latest"

# Default config
DEFAULT_CONFIG = {
    "ram_min": "512M",
    "ram_max": "4G",
    "java_path": "java",
    "theme": "dark",
    "language": "pt_BR",
    "auto_update": True,
    "close_on_launch": False,
    "fullscreen": False,
    "resolution": {"width": 1280, "height": 720},
    "game_directory": str(FEXLAUNCHER_DIR / "game"),
    "jvm_args": ["-XX:+UseG1GC", "-XX:+ParallelRefProcEnabled",
                 "-XX:MaxGCPauseMillis=200", "-XX:+UnlockExperimentalVMOptions",
                 "-XX:+DisableExplicitGC", "-XX:G1NewSizePercent=30",
                 "-XX:G1MaxNewSizePercent=40", "-XX:G1HeapRegionSize=8M",
                 "-XX:G1ReservePercent=20", "-XX:G1HeapWastePercent=5",
                 "-XX:G1MixedGCCountTarget=4", "-XX:InitiatingHeapOccupancyPercent=15",
                 "-XX:G1MixedGCLiveThresholdPercent=90",
                 "-XX:G1RSetUpdatingPauseTimePercent=5",
                 "-XX:SurvivorRatio=32", "-XX:+PerfDisableSharedMem",
                 "-XX:MaxTenuringThreshold=1"]
}


def ensure_dirs():
    """Create all necessary directories."""
    for d in [FEXLAUNCHER_DIR, VERSIONS_DIR, INSTANCES_DIR,
              SKINS_DIR, MODS_DIR, TEXTURES_DIR]:
        d.mkdir(parents=True, exist_ok=True)


def load_config():
    """Load or create config file."""
    if CONFIG_FILE.exists():
        with open(CONFIG_FILE) as f:
            return json.load(f)
    save_config(DEFAULT_CONFIG)
    return DEFAULT_CONFIG.copy()


def save_config(config):
    """Save config to file."""
    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f, indent=2)


def load_accounts():
    """Load accounts from file."""
    if ACCOUNTS_FILE.exists():
        with open(ACCOUNTS_FILE) as f:
            return json.load(f)
    return {"accounts": [], "selected": None}


def save_accounts(data):
    """Save accounts to file."""
    with open(ACCOUNTS_FILE, "w") as f:
        json.dump(data, f, indent=2)


def fetch_versions():
    """Fetch available Minecraft versions from Mojang."""
    try:
        req = urllib.request.Request(VERSION_MANIFEST,
                                    headers={"User-Agent": "FexLauncher/1.0"})
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read())
            return data
    except (urllib.error.URLError, TimeoutError):
        # Return cached if available
        cache = FEXLAUNCHER_DIR / "version_manifest.json"
        if cache.exists():
            with open(cache) as f:
                return json.load(f)
        return {"latest": {"release": "1.21.4", "snapshot": "25w01a"}, "versions": []}


def download_version(version_id, version_url):
    """Download a specific Minecraft version."""
    version_dir = VERSIONS_DIR / version_id
    version_dir.mkdir(parents=True, exist_ok=True)
    jar_path = version_dir / f"{version_id}.jar"

    if jar_path.exists():
        return str(jar_path)

    try:
        # Get version JSON
        req = urllib.request.Request(version_url,
                                    headers={"User-Agent": "FexLauncher/1.0"})
        with urllib.request.urlopen(req, timeout=30) as resp:
            version_data = json.loads(resp.read())

        # Save version JSON
        with open(version_dir / f"{version_id}.json", "w") as f:
            json.dump(version_data, f, indent=2)

        # Download client JAR
        client_url = version_data["downloads"]["client"]["url"]
        urllib.request.urlretrieve(client_url, str(jar_path))
        return str(jar_path)
    except Exception as e:
        print(f"[FexLauncher] Download error: {e}")
        return None


def launch_minecraft(version_id, account, config):
    """Launch Minecraft with specified version and account."""
    version_dir = VERSIONS_DIR / version_id
    jar_path = version_dir / f"{version_id}.jar"
    json_path = version_dir / f"{version_id}.json"

    if not jar_path.exists():
        print(f"[FexLauncher] Version {version_id} not downloaded")
        return False

    java_path = config.get("java_path", "java")
    ram_min = config.get("ram_min", "512M")
    ram_max = config.get("ram_max", "4G")
    jvm_args = config.get("jvm_args", [])

    # Build command
    cmd = [java_path]
    cmd.extend(jvm_args)
    cmd.extend([f"-Xms{ram_min}", f"-Xmx{ram_max}"])

    # Auth (pirate or original)
    username = account.get("username", "Player")
    uuid = account.get("uuid", hashlib.md5(username.encode()).hexdigest())
    access_token = account.get("access_token", "0")
    account_type = account.get("type", "offline")

    if account_type == "offline":
        # Offline/pirate mode
        cmd.extend([
            f"-Duser.name={username}",
            "-jar", str(jar_path),
            "--username", username,
            "--uuid", uuid,
            "--accessToken", "0",
            "--userType", "legacy"
        ])
    else:
        # Microsoft/Mojang account
        cmd.extend([
            "-jar", str(jar_path),
            "--username", username,
            "--uuid", uuid,
            "--accessToken", access_token,
            "--userType", "msa"
        ])

    # Resolution
    res = config.get("resolution", {})
    if res:
        cmd.extend(["--width", str(res.get("width", 1280)),
                    "--height", str(res.get("height", 720))])

    # Game directory
    game_dir = config.get("game_directory", str(FEXLAUNCHER_DIR / "game"))
    cmd.extend(["--gameDir", game_dir])

    print(f"[FexLauncher] Launching Minecraft {version_id} as {username}")
    try:
        process = subprocess.Popen(cmd, cwd=str(version_dir))
        return process
    except Exception as e:
        print(f"[FexLauncher] Launch error: {e}")
        return None


def add_offline_account(username):
    """Add an offline (pirate) account."""
    accounts = load_accounts()
    uuid = hashlib.md5(username.encode()).hexdigest()
    uuid = f"{uuid[:8]}-{uuid[8:12]}-{uuid[12:16]}-{uuid[16:20]}-{uuid[20:]}"

    account = {
        "username": username,
        "uuid": uuid,
        "type": "offline",
        "access_token": "0",
        "skin": None,
        "cape": None,
        "created": datetime.now().isoformat()
    }

    accounts["accounts"].append(account)
    accounts["selected"] = len(accounts["accounts"]) - 1
    save_accounts(accounts)
    return account


def set_skin(account_index, skin_path):
    """Set custom skin for account (works for pirate too)."""
    accounts = load_accounts()
    if account_index < len(accounts["accounts"]):
        skin_dest = SKINS_DIR / f"skin_{account_index}.png"
        shutil.copy2(skin_path, str(skin_dest))
        accounts["accounts"][account_index]["skin"] = str(skin_dest)
        save_accounts(accounts)
        return True
    return False


def install_mod(mod_path, instance="default"):
    """Install a mod to an instance."""
    instance_mods = INSTANCES_DIR / instance / "mods"
    instance_mods.mkdir(parents=True, exist_ok=True)
    shutil.copy2(mod_path, str(instance_mods / Path(mod_path).name))
    return True


def install_texture_pack(texture_path, instance="default"):
    """Install a texture/resource pack."""
    instance_textures = INSTANCES_DIR / instance / "resourcepacks"
    instance_textures.mkdir(parents=True, exist_ok=True)
    shutil.copy2(texture_path, str(instance_textures / Path(texture_path).name))
    return True


def check_java():
    """Check if Java is installed and return version."""
    try:
        result = subprocess.run(["java", "-version"],
                                capture_output=True, text=True, timeout=5)
        output = result.stderr or result.stdout
        return output.split("\n")[0] if output else None
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return None


def auto_install_java():
    """Auto-install Java if not found."""
    if check_java():
        return True
    print("[FexLauncher] Java not found, installing...")
    try:
        subprocess.run(["sudo", "pacman", "-S", "--noconfirm", "jre-openjdk"],
                       timeout=120)
        return check_java() is not None
    except Exception:
        return False


# CLI mode
def main():
    ensure_dirs()
    config = load_config()

    if len(sys.argv) < 2:
        print("FexLauncher — Minecraft Launcher para FexOS")
        print("Uso: fexlauncher [comando]")
        print("")
        print("Comandos:")
        print("  versions     Lista versões disponíveis")
        print("  download     Baixar versão")
        print("  launch       Iniciar jogo")
        print("  accounts     Gerenciar contas")
        print("  config       Configurações")
        print("  mods         Gerenciar mods")
        print("  skins        Gerenciar skins")
        print("")
        print("Interface gráfica: fexlauncher --gui")
        return

    cmd = sys.argv[1]

    if cmd == "versions":
        data = fetch_versions()
        print(f"Última release: {data['latest']['release']}")
        print(f"Último snapshot: {data['latest']['snapshot']}")
        print("\nVersões recentes:")
        for v in data.get("versions", [])[:20]:
            print(f"  [{v['type']}] {v['id']}")

    elif cmd == "download":
        version = sys.argv[2] if len(sys.argv) > 2 else None
        if not version:
            print("Uso: fexlauncher download <version>")
            return
        data = fetch_versions()
        for v in data.get("versions", []):
            if v["id"] == version:
                print(f"Baixando {version}...")
                result = download_version(version, v["url"])
                if result:
                    print(f"Download completo: {result}")
                else:
                    print("Erro no download")
                return
        print(f"Versão {version} não encontrada")

    elif cmd == "launch":
        version = sys.argv[2] if len(sys.argv) > 2 else None
        accounts = load_accounts()
        if not accounts["accounts"]:
            print("Nenhuma conta. Use: fexlauncher accounts add <nome>")
            return
        account = accounts["accounts"][accounts["selected"] or 0]
        if version:
            launch_minecraft(version, account, config)
        else:
            print("Uso: fexlauncher launch <version>")

    elif cmd == "accounts":
        sub = sys.argv[2] if len(sys.argv) > 2 else "list"
        if sub == "add":
            name = sys.argv[3] if len(sys.argv) > 3 else "Player"
            acc = add_offline_account(name)
            print(f"Conta criada: {acc['username']} (offline)")
        elif sub == "list":
            accounts = load_accounts()
            for i, acc in enumerate(accounts["accounts"]):
                sel = "→" if i == accounts.get("selected") else " "
                print(f"  {sel} [{acc['type']}] {acc['username']}")

    elif cmd == "--gui":
        print("[FexLauncher] Iniciando interface gráfica...")
        launch_gui()

    else:
        print(f"Comando desconhecido: {cmd}")


def launch_gui():
    """Launch PyQt6 GUI (imported only when needed)."""
    try:
        from fexlauncher_gui import FexLauncherApp
        app = FexLauncherApp(sys.argv)
        sys.exit(app.exec())
    except ImportError:
        print("[FexLauncher] PyQt6 não instalado. Instale: pip install PyQt6")
        print("[FexLauncher] Ou use modo CLI: fexlauncher --help")


if __name__ == "__main__":
    main()
