#!/usr/bin/env python3
"""
FexStore GUI — PyQt6 Native App Store.
Professional desktop application, zero web technologies.
"""

import sys
import json
import subprocess
from pathlib import Path

try:
    from PyQt6.QtWidgets import (
        QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
        QLabel, QPushButton, QTabWidget, QListWidget, QListWidgetItem,
        QLineEdit, QScrollArea, QGridLayout, QFrame, QSizePolicy,
        QMessageBox, QProgressBar
    )
    from PyQt6.QtCore import Qt, QSize, QThread, pyqtSignal
    from PyQt6.QtGui import QFont, QColor, QPalette, QIcon
    HAS_QT = True
except ImportError:
    HAS_QT = False
    print("[FexStore] PyQt6 não encontrado. Instale: pip install PyQt6")
    sys.exit(1)

# App catalog
APP_CATALOG = {
    "communication": [
        {"id": "whatsapp", "name": "WhatsApp", "desc": "Mensagens e chamadas",
         "method": "flatpak", "flatpak_id": "io.github.nickvision.whatsapp",
         "free": True, "rating": 4.5},
        {"id": "telegram", "name": "Telegram", "desc": "Mensagens rápidas e seguras",
         "method": "flatpak", "flatpak_id": "org.telegram.desktop",
         "free": True, "rating": 4.7},
        {"id": "discord", "name": "Discord", "desc": "Chat para gamers",
         "method": "flatpak", "flatpak_id": "com.discordapp.Discord",
         "free": True, "rating": 4.3},
        {"id": "signal", "name": "Signal", "desc": "Mensagens criptografadas",
         "method": "flatpak", "flatpak_id": "org.signal.Signal",
         "free": True, "rating": 4.6},
    ],
    "games": [
        {"id": "steam", "name": "Steam", "desc": "Plataforma de jogos",
         "method": "pacman", "package": "steam",
         "free": True, "rating": 4.8},
        {"id": "lutris", "name": "Lutris", "desc": "Gerenciador de jogos Linux",
         "method": "pacman", "package": "lutris",
         "free": True, "rating": 4.4},
        {"id": "heroic", "name": "Heroic Launcher", "desc": "Epic Games e GOG",
         "method": "flatpak", "flatpak_id": "com.heroicgameslauncher.hgl",
         "free": True, "rating": 4.2},
        {"id": "retroarch", "name": "RetroArch", "desc": "Emulador multissistema",
         "method": "pacman", "package": "retroarch",
         "free": True, "rating": 4.5},
        {"id": "bottles", "name": "Bottles", "desc": "Execute apps Windows",
         "method": "flatpak", "flatpak_id": "com.usebottles.bottles",
         "free": True, "rating": 4.3},
        {"id": "fexlauncher", "name": "FexLauncher", "desc": "Minecraft Launcher",
         "method": "native", "command": "fexlauncher --gui",
         "free": True, "rating": 4.9},
    ],
    "productivity": [
        {"id": "libreoffice", "name": "LibreOffice", "desc": "Suite de escritório",
         "method": "pacman", "package": "libreoffice-fresh",
         "free": True, "rating": 4.3},
        {"id": "obsidian", "name": "Obsidian", "desc": "Notas e conhecimento",
         "method": "flatpak", "flatpak_id": "md.obsidian.Obsidian",
         "free": True, "rating": 4.7},
        {"id": "fexcode", "name": "FexCode", "desc": "IDE do FexOS",
         "method": "native", "command": "fexcode",
         "free": True, "rating": 4.8},
        {"id": "thunderbird", "name": "Thunderbird", "desc": "Cliente de email",
         "method": "pacman", "package": "thunderbird",
         "free": True, "rating": 4.2},
    ],
    "multimedia": [
        {"id": "spotify", "name": "Spotify", "desc": "Streaming de música",
         "method": "flatpak", "flatpak_id": "com.spotify.Client",
         "free": True, "rating": 4.6},
        {"id": "vlc", "name": "VLC", "desc": "Reprodutor de mídia",
         "method": "pacman", "package": "vlc",
         "free": True, "rating": 4.8},
        {"id": "obs", "name": "OBS Studio", "desc": "Gravação e streaming",
         "method": "pacman", "package": "obs-studio",
         "free": True, "rating": 4.7},
        {"id": "gimp", "name": "GIMP", "desc": "Edição de imagens",
         "method": "pacman", "package": "gimp",
         "free": True, "rating": 4.3},
        {"id": "blender", "name": "Blender", "desc": "Modelagem 3D e animação",
         "method": "pacman", "package": "blender",
         "free": True, "rating": 4.9},
    ],
    "system": [
        {"id": "fexnav", "name": "FexNav", "desc": "Navegador do FexOS",
         "method": "native", "command": "fexnav",
         "free": True, "rating": 4.8},
        {"id": "timeshift", "name": "Timeshift", "desc": "Backup do sistema",
         "method": "pacman", "package": "timeshift",
         "free": True, "rating": 4.5},
        {"id": "kitty", "name": "Kitty", "desc": "Terminal GPU-accelerated",
         "method": "pacman", "package": "kitty",
         "free": True, "rating": 4.6},
    ],
}

INSTALLED_FILE = Path.home() / ".fexstore" / "installed.json"


def load_installed():
    if INSTALLED_FILE.exists():
        return json.loads(INSTALLED_FILE.read_text())
    return {"apps": []}


def save_installed(data):
    INSTALLED_FILE.parent.mkdir(parents=True, exist_ok=True)
    INSTALLED_FILE.write_text(json.dumps(data, indent=2))


def is_installed(app_id):
    data = load_installed()
    return any(a["id"] == app_id for a in data["apps"])


class InstallThread(QThread):
    progress = pyqtSignal(str)
    done = pyqtSignal(bool, str)

    def __init__(self, app):
        super().__init__()
        self.app = app

    def run(self):
        app = self.app
        method = app.get("method", "")
        try:
            if method == "flatpak":
                self.progress.emit(f"Instalando {app['name']} via Flatpak...")
                result = subprocess.run(
                    ["flatpak", "install", "-y", "flathub", app["flatpak_id"]],
                    capture_output=True, text=True, timeout=300)
                if result.returncode == 0:
                    self.done.emit(True, app["name"])
                else:
                    self.done.emit(False, result.stderr[:200])
            elif method == "pacman":
                self.progress.emit(f"Instalando {app['name']} via pacman...")
                result = subprocess.run(
                    ["sudo", "pacman", "-S", "--noconfirm", app["package"]],
                    capture_output=True, text=True, timeout=300)
                if result.returncode == 0:
                    self.done.emit(True, app["name"])
                else:
                    self.done.emit(False, result.stderr[:200])
            elif method == "native":
                self.done.emit(True, f"{app['name']} já está instalado")
            else:
                self.done.emit(False, "Método desconhecido")
        except Exception as e:
            self.done.emit(False, str(e))


def create_dark_palette():
    palette = QPalette()
    palette.setColor(QPalette.ColorRole.Window, QColor(14, 14, 22))
    palette.setColor(QPalette.ColorRole.WindowText, QColor(224, 224, 240))
    palette.setColor(QPalette.ColorRole.Base, QColor(10, 10, 18))
    palette.setColor(QPalette.ColorRole.AlternateBase, QColor(18, 18, 28))
    palette.setColor(QPalette.ColorRole.Text, QColor(224, 224, 240))
    palette.setColor(QPalette.ColorRole.Button, QColor(24, 24, 38))
    palette.setColor(QPalette.ColorRole.ButtonText, QColor(224, 224, 240))
    palette.setColor(QPalette.ColorRole.Highlight, QColor(108, 77, 179))
    palette.setColor(QPalette.ColorRole.HighlightedText, QColor(255, 255, 255))
    return palette


class AppCard(QFrame):
    def __init__(self, app, parent=None):
        super().__init__(parent)
        self.app = app
        self.setFixedHeight(100)
        self.setStyleSheet("""
            AppCard {
                background: #16161e; border: 1px solid #1e1e30;
                border-radius: 10px;
            }
            AppCard:hover { border-color: #3d3d6e; background: #1a1a24; }
        """)

        layout = QHBoxLayout(self)
        layout.setContentsMargins(16, 12, 16, 12)
        layout.setSpacing(14)

        # App icon (first letter in colored circle)
        icon_frame = QFrame()
        icon_frame.setFixedSize(56, 56)
        icon_frame.setStyleSheet(f"""
            QFrame {{
                background: {self._get_color()};
                border-radius: 12px; border: none;
            }}
        """)
        icon_label = QLabel(app["name"][0].upper())
        icon_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        icon_label.setFont(QFont("Inter", 20, QFont.Weight.Bold))
        icon_label.setStyleSheet("color: #fff; border: none; background: transparent;")
        icon_layout = QVBoxLayout(icon_frame)
        icon_layout.setContentsMargins(0, 0, 0, 0)
        icon_layout.addWidget(icon_label)
        layout.addWidget(icon_frame)

        # Info
        info_layout = QVBoxLayout()
        info_layout.setSpacing(3)

        name_label = QLabel(app["name"])
        name_label.setFont(QFont("Inter", 14, QFont.Weight.DemiBold))
        name_label.setStyleSheet("color: #f0f0f5; border: none;")
        info_layout.addWidget(name_label)

        desc_label = QLabel(app.get("desc", ""))
        desc_label.setStyleSheet("color: #6b6b80; font-size: 12px; border: none;")
        info_layout.addWidget(desc_label)

        rating_label = QLabel(f"{'★' * int(app.get('rating', 0))} {app.get('rating', '')}")
        rating_label.setStyleSheet("color: #c9a227; font-size: 11px; border: none;")
        info_layout.addWidget(rating_label)

        layout.addLayout(info_layout)
        layout.addStretch()

        # Install button
        if is_installed(app["id"]):
            btn = QPushButton("Instalado")
            btn.setEnabled(False)
            btn.setStyleSheet("""
                QPushButton {
                    background: rgba(80,200,120,0.12); color: #50c878;
                    border: 1px solid rgba(80,200,120,0.25);
                    border-radius: 8px; padding: 8px 16px; font-size: 12px;
                }
            """)
        else:
            btn = QPushButton("Instalar")
            btn.setStyleSheet("""
                QPushButton {
                    background: #6d4db3; color: #fff; border: none;
                    border-radius: 8px; padding: 8px 16px;
                    font-weight: bold; font-size: 12px;
                }
                QPushButton:hover { background: #7c5cbf; }
                QPushButton:pressed { background: #5b3d9e; }
            """)
            btn.clicked.connect(lambda: self.install_app())
        layout.addWidget(btn)

    def _get_color(self):
        colors = ["#6d4db3", "#4d8fb3", "#4db36d", "#b34d4d", "#b38f4d", "#4d4db3"]
        return colors[hash(self.app["id"]) % len(colors)]

    def install_app(self):
        self.thread = InstallThread(self.app)
        self.thread.done.connect(self.on_install_done)
        self.thread.start()

    def on_install_done(self, success, msg):
        if success:
            installed = load_installed()
            installed["apps"].append({
                "id": self.app["id"], "name": self.app["name"],
                "method": self.app.get("method", "")
            })
            save_installed(installed)


class CategoryPage(QWidget):
    def __init__(self, category, title, parent=None):
        super().__init__(parent)
        layout = QVBoxLayout(self)
        layout.setContentsMargins(24, 24, 24, 24)
        layout.setSpacing(16)

        header = QLabel(title)
        header.setFont(QFont("Inter", 20, QFont.Weight.Bold))
        header.setStyleSheet("color: #f0f0f5;")
        layout.addWidget(header)

        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setStyleSheet("QScrollArea { border: none; }")

        content = QWidget()
        grid = QVBoxLayout(content)
        grid.setSpacing(8)

        apps = APP_CATALOG.get(category, [])
        for app in apps:
            card = AppCard(app)
            grid.addWidget(card)
        grid.addStretch()

        scroll.setWidget(content)
        layout.addWidget(scroll)


class DiscoverPage(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        layout = QVBoxLayout(self)
        layout.setContentsMargins(24, 24, 24, 24)
        layout.setSpacing(20)

        header = QLabel("Descubra Apps e Jogos")
        header.setFont(QFont("Inter", 22, QFont.Weight.Bold))
        header.setStyleSheet("color: #f0f0f5;")
        layout.addWidget(header)

        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setStyleSheet("QScrollArea { border: none; }")

        content = QWidget()
        content_layout = QVBoxLayout(content)
        content_layout.setSpacing(20)

        categories = [
            ("games", "Jogos"),
            ("communication", "Comunicação"),
            ("multimedia", "Multimídia"),
            ("productivity", "Produtividade"),
            ("system", "Sistema"),
        ]

        for cat_id, cat_name in categories:
            sec_label = QLabel(cat_name)
            sec_label.setFont(QFont("Inter", 15, QFont.Weight.DemiBold))
            sec_label.setStyleSheet("color: #a78bfa;")
            content_layout.addWidget(sec_label)

            apps = APP_CATALOG.get(cat_id, [])[:3]
            for app in apps:
                card = AppCard(app)
                content_layout.addWidget(card)

        content_layout.addStretch()
        scroll.setWidget(content)
        layout.addWidget(scroll)


class FexStoreWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("FexStore")
        self.setMinimumSize(900, 600)
        self.resize(1000, 700)
        self.setup_ui()

    def setup_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        layout = QVBoxLayout(central)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)

        # Search bar
        search_frame = QFrame()
        search_frame.setFixedHeight(56)
        search_frame.setStyleSheet("QFrame { background: #0e0e16; border-bottom: 1px solid #1e1e30; }")
        search_layout = QHBoxLayout(search_frame)
        search_layout.setContentsMargins(24, 0, 24, 0)

        logo = QLabel("FexStore")
        logo.setFont(QFont("Inter", 16, QFont.Weight.Bold))
        logo.setStyleSheet("color: #a78bfa; border: none;")
        search_layout.addWidget(logo)

        search_layout.addStretch()

        self.search_input = QLineEdit()
        self.search_input.setPlaceholderText("Buscar apps e jogos...")
        self.search_input.setFixedWidth(280)
        self.search_input.setStyleSheet("""
            QLineEdit {
                background: #14141f; border: 1px solid #2a2a3e;
                border-radius: 8px; padding: 8px 14px;
                color: #e0e0f0; font-size: 13px;
            }
            QLineEdit:focus { border-color: #6d4db3; }
        """)
        search_layout.addWidget(self.search_input)
        layout.addWidget(search_frame)

        # Tabs
        self.tabs = QTabWidget()
        self.tabs.setStyleSheet("""
            QTabWidget::pane { border: none; background: #0e0e16; }
            QTabBar::tab {
                background: #0a0a12; color: #6b6b80;
                padding: 12px 20px; border: none;
                border-bottom: 2px solid transparent;
                font-size: 13px;
            }
            QTabBar::tab:selected {
                color: #a78bfa; border-bottom: 2px solid #6d4db3;
                background: #0e0e16;
            }
            QTabBar::tab:hover { color: #c0c0d8; }
        """)

        self.tabs.addTab(DiscoverPage(), "Descobrir")
        self.tabs.addTab(CategoryPage("games", "Jogos"), "Jogos")
        self.tabs.addTab(CategoryPage("communication", "Comunicação"), "Social")
        self.tabs.addTab(CategoryPage("multimedia", "Multimídia"), "Mídia")
        self.tabs.addTab(CategoryPage("productivity", "Produtividade"), "Produtividade")
        self.tabs.addTab(CategoryPage("system", "Sistema"), "Sistema")

        layout.addWidget(self.tabs)


def main():
    app = QApplication(sys.argv)
    app.setApplicationName("FexStore")
    app.setStyle("Fusion")
    app.setPalette(create_dark_palette())
    window = FexStoreWindow()
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
