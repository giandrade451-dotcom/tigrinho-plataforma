#!/usr/bin/env python3
"""
FexLauncher GUI — PyQt6 Native Minecraft Launcher.
Professional desktop application, zero web technologies.
"""

import sys
import os
import json
import hashlib
import subprocess
import urllib.request
from pathlib import Path
from datetime import datetime

try:
    from PyQt6.QtWidgets import (
        QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
        QLabel, QPushButton, QComboBox, QTabWidget, QListWidget,
        QListWidgetItem, QProgressBar, QLineEdit, QFileDialog,
        QMessageBox, QFrame, QSplitter, QGroupBox, QSpinBox,
        QCheckBox, QTextEdit, QStackedWidget, QSizePolicy,
        QScrollArea, QGridLayout
    )
    from PyQt6.QtCore import Qt, QThread, pyqtSignal, QSize, QTimer
    from PyQt6.QtGui import (
        QFont, QColor, QPalette, QIcon, QPainter, QLinearGradient,
        QBrush, QPen, QPixmap
    )
    HAS_QT = True
except ImportError:
    HAS_QT = False
    print("[FexLauncher] PyQt6 não encontrado. Instale: pip install PyQt6")
    sys.exit(1)

# Paths
FEXLAUNCHER_DIR = Path.home() / ".fexlauncher"
VERSIONS_DIR = FEXLAUNCHER_DIR / "versions"
ACCOUNTS_FILE = FEXLAUNCHER_DIR / "accounts.json"
MODS_DIR = FEXLAUNCHER_DIR / "mods"
SKINS_DIR = FEXLAUNCHER_DIR / "skins"
CONFIG_FILE = FEXLAUNCHER_DIR / "config.json"

MOJANG_VERSIONS_URL = "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"


def ensure_dirs():
    for d in [FEXLAUNCHER_DIR, VERSIONS_DIR, MODS_DIR, SKINS_DIR]:
        d.mkdir(parents=True, exist_ok=True)


def load_config():
    if CONFIG_FILE.exists():
        return json.loads(CONFIG_FILE.read_text())
    cfg = {
        "ram_min": "512M", "ram_max": "4G",
        "java_path": "java", "theme": "dark",
        "auto_update": True, "language": "pt_BR"
    }
    CONFIG_FILE.write_text(json.dumps(cfg, indent=2))
    return cfg


def load_accounts():
    if ACCOUNTS_FILE.exists():
        return json.loads(ACCOUNTS_FILE.read_text())
    data = {"accounts": [], "selected": -1}
    ACCOUNTS_FILE.write_text(json.dumps(data, indent=2))
    return data


def save_accounts(data):
    ACCOUNTS_FILE.write_text(json.dumps(data, indent=2))


class VersionFetchThread(QThread):
    finished = pyqtSignal(list)
    error = pyqtSignal(str)

    def run(self):
        try:
            req = urllib.request.Request(MOJANG_VERSIONS_URL)
            req.add_header("User-Agent", "FexLauncher/6.0")
            with urllib.request.urlopen(req, timeout=10) as resp:
                data = json.loads(resp.read())
            versions = []
            for v in data.get("versions", []):
                versions.append({
                    "id": v["id"],
                    "type": v["type"],
                    "url": v["url"],
                    "releaseTime": v.get("releaseTime", "")
                })
            self.finished.emit(versions)
        except Exception as e:
            self.error.emit(str(e))


class LaunchThread(QThread):
    output = pyqtSignal(str)
    finished_signal = pyqtSignal(int)

    def __init__(self, command):
        super().__init__()
        self.command = command

    def run(self):
        try:
            proc = subprocess.Popen(
                self.command, shell=True,
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT
            )
            for line in iter(proc.stdout.readline, b""):
                self.output.emit(line.decode(errors="replace").rstrip())
            proc.wait()
            self.finished_signal.emit(proc.returncode)
        except Exception as e:
            self.output.emit(f"[ERRO] {e}")
            self.finished_signal.emit(1)


# Dark theme palette
def create_dark_palette():
    palette = QPalette()
    palette.setColor(QPalette.ColorRole.Window, QColor(18, 18, 28))
    palette.setColor(QPalette.ColorRole.WindowText, QColor(224, 224, 240))
    palette.setColor(QPalette.ColorRole.Base, QColor(14, 14, 22))
    palette.setColor(QPalette.ColorRole.AlternateBase, QColor(22, 22, 34))
    palette.setColor(QPalette.ColorRole.Text, QColor(224, 224, 240))
    palette.setColor(QPalette.ColorRole.Button, QColor(28, 28, 44))
    palette.setColor(QPalette.ColorRole.ButtonText, QColor(224, 224, 240))
    palette.setColor(QPalette.ColorRole.Highlight, QColor(108, 77, 179))
    palette.setColor(QPalette.ColorRole.HighlightedText, QColor(255, 255, 255))
    palette.setColor(QPalette.ColorRole.ToolTipBase, QColor(28, 28, 44))
    palette.setColor(QPalette.ColorRole.ToolTipText, QColor(224, 224, 240))
    return palette


class PlayTab(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.main_window = parent
        self.versions = []
        self.setup_ui()

    def setup_ui(self):
        layout = QVBoxLayout(self)
        layout.setSpacing(16)
        layout.setContentsMargins(24, 24, 24, 24)

        # Header
        header = QLabel("Pronto para jogar")
        header.setFont(QFont("Inter", 22, QFont.Weight.Bold))
        header.setStyleSheet("color: #f0f0f5;")
        layout.addWidget(header)

        subtitle = QLabel("Selecione uma versão e clique em Jogar")
        subtitle.setStyleSheet("color: #6b6b80; font-size: 13px;")
        layout.addWidget(subtitle)

        layout.addSpacing(12)

        # Account display
        acc_frame = QFrame()
        acc_frame.setStyleSheet("""
            QFrame { background: #14141f; border: 1px solid #1e1e35;
                     border-radius: 8px; padding: 12px; }
        """)
        acc_layout = QHBoxLayout(acc_frame)
        self.account_label = QLabel("Nenhuma conta")
        self.account_label.setStyleSheet("color: #a0a0b8; font-size: 13px; border: none;")
        acc_layout.addWidget(self.account_label)
        acc_layout.addStretch()
        layout.addWidget(acc_frame)

        # Version selector
        ver_layout = QHBoxLayout()
        ver_label = QLabel("Versão:")
        ver_label.setStyleSheet("color: #c0c0d0; font-size: 13px;")
        ver_layout.addWidget(ver_label)

        self.version_combo = QComboBox()
        self.version_combo.setMinimumWidth(250)
        self.version_combo.setStyleSheet("""
            QComboBox {
                background: #14141f; border: 1px solid #2a2a3e;
                border-radius: 8px; padding: 8px 12px;
                color: #e0e0f0; font-size: 13px;
            }
            QComboBox:hover { border-color: #6d4db3; }
            QComboBox::drop-down { border: none; width: 24px; }
            QComboBox QAbstractItemView {
                background: #14141f; color: #e0e0f0;
                selection-background-color: #6d4db3;
                border: 1px solid #2a2a3e;
            }
        """)
        ver_layout.addWidget(self.version_combo)

        self.filter_combo = QComboBox()
        self.filter_combo.addItems(["Releases", "Snapshots", "Todas"])
        self.filter_combo.setStyleSheet("""
            QComboBox {
                background: #14141f; border: 1px solid #2a2a3e;
                border-radius: 8px; padding: 8px 12px;
                color: #8080a0; font-size: 12px;
            }
            QComboBox::drop-down { border: none; width: 24px; }
        """)
        self.filter_combo.currentIndexChanged.connect(self.filter_versions)
        ver_layout.addWidget(self.filter_combo)
        ver_layout.addStretch()
        layout.addLayout(ver_layout)

        layout.addStretch()

        # Play button
        self.play_btn = QPushButton("  JOGAR")
        self.play_btn.setFixedHeight(56)
        self.play_btn.setFont(QFont("Inter", 16, QFont.Weight.Bold))
        self.play_btn.setStyleSheet("""
            QPushButton {
                background: qlineargradient(x1:0,y1:0,x2:1,y2:0,
                    stop:0 #6d4db3, stop:1 #4d8fb3);
                color: #ffffff; border: none; border-radius: 12px;
            }
            QPushButton:hover {
                background: qlineargradient(x1:0,y1:0,x2:1,y2:0,
                    stop:0 #7c5cbf, stop:1 #5ca0c4);
            }
            QPushButton:pressed {
                background: qlineargradient(x1:0,y1:0,x2:1,y2:0,
                    stop:0 #5b3d9e, stop:1 #3d7a9e);
            }
            QPushButton:disabled { background: #2a2a3e; color: #4a4a60; }
        """)
        self.play_btn.clicked.connect(self.launch_game)
        layout.addWidget(self.play_btn)

        # Progress
        self.progress = QProgressBar()
        self.progress.setFixedHeight(4)
        self.progress.setTextVisible(False)
        self.progress.setStyleSheet("""
            QProgressBar { background: #1a1a2e; border: none; border-radius: 2px; }
            QProgressBar::chunk { background: #6d4db3; border-radius: 2px; }
        """)
        self.progress.hide()
        layout.addWidget(self.progress)

        # Status
        self.status_label = QLabel("")
        self.status_label.setStyleSheet("color: #6b6b80; font-size: 12px;")
        layout.addWidget(self.status_label)

        # Load versions
        self.fetch_versions()

    def fetch_versions(self):
        self.status_label.setText("Carregando versões...")
        self.thread = VersionFetchThread()
        self.thread.finished.connect(self.on_versions_loaded)
        self.thread.error.connect(self.on_versions_error)
        self.thread.start()

    def on_versions_loaded(self, versions):
        self.versions = versions
        self.filter_versions()
        self.status_label.setText(f"{len(versions)} versões disponíveis")

    def on_versions_error(self, err):
        self.status_label.setText(f"Offline — use versões já instaladas")
        # Load locally installed versions
        if VERSIONS_DIR.exists():
            for d in sorted(VERSIONS_DIR.iterdir()):
                if d.is_dir():
                    self.version_combo.addItem(f"[local] {d.name}")

    def filter_versions(self):
        self.version_combo.clear()
        filt = self.filter_combo.currentText()
        for v in self.versions:
            if filt == "Releases" and v["type"] != "release":
                continue
            if filt == "Snapshots" and v["type"] != "snapshot":
                continue
            self.version_combo.addItem(f"[{v['type']}] {v['id']}")

    def launch_game(self):
        if self.version_combo.count() == 0:
            return
        version = self.version_combo.currentText().split("] ")[1] if "] " in self.version_combo.currentText() else self.version_combo.currentText()
        accounts = load_accounts()
        if not accounts["accounts"]:
            QMessageBox.warning(self, "FexLauncher",
                "Crie uma conta na aba 'Contas' antes de jogar.")
            return

        acc = accounts["accounts"][accounts["selected"]]
        self.status_label.setText(f"Iniciando Minecraft {version}...")
        self.play_btn.setEnabled(False)
        self.progress.show()
        self.progress.setRange(0, 0)

        config = load_config()
        java = config.get("java_path", "java")
        ram_max = config.get("ram_max", "4G")
        ram_min = config.get("ram_min", "512M")

        ver_dir = VERSIONS_DIR / version
        jar_file = ver_dir / f"{version}.jar"

        if jar_file.exists():
            cmd = (f'{java} -Xms{ram_min} -Xmx{ram_max} '
                   f'-XX:+UseG1GC -XX:+ParallelRefProcEnabled '
                   f'-Djava.library.path={ver_dir}/natives '
                   f'-cp "{jar_file}" net.minecraft.client.main.Main '
                   f'--username {acc["username"]} --uuid {acc["uuid"]} '
                   f'--accessToken {acc.get("access_token", "0")} '
                   f'--version {version}')
            self.launch_thread = LaunchThread(cmd)
            self.launch_thread.output.connect(self.on_game_output)
            self.launch_thread.finished_signal.connect(self.on_game_exit)
            self.launch_thread.start()
        else:
            self.status_label.setText(f"Baixando versão {version}...")
            self.download_version(version)

    def download_version(self, version):
        for v in self.versions:
            if v["id"] == version:
                self.status_label.setText(f"Buscando metadados de {version}...")
                try:
                    req = urllib.request.Request(v["url"])
                    req.add_header("User-Agent", "FexLauncher/6.0")
                    with urllib.request.urlopen(req, timeout=15) as resp:
                        meta = json.loads(resp.read())

                    ver_dir = VERSIONS_DIR / version
                    ver_dir.mkdir(parents=True, exist_ok=True)

                    client_url = meta["downloads"]["client"]["url"]
                    jar_file = ver_dir / f"{version}.jar"

                    self.status_label.setText(f"Baixando {version}.jar...")
                    urllib.request.urlretrieve(client_url, str(jar_file))
                    (ver_dir / f"{version}.json").write_text(json.dumps(meta, indent=2))
                    self.status_label.setText(f"Versão {version} baixada!")
                    self.launch_game()
                except Exception as e:
                    self.status_label.setText(f"Erro: {e}")
                    self.play_btn.setEnabled(True)
                    self.progress.hide()
                return
        self.status_label.setText("Versão não encontrada")
        self.play_btn.setEnabled(True)
        self.progress.hide()

    def on_game_output(self, line):
        self.status_label.setText(line[-80:] if len(line) > 80 else line)

    def on_game_exit(self, code):
        self.play_btn.setEnabled(True)
        self.progress.hide()
        self.status_label.setText(
            "Jogo encerrado" if code == 0 else f"Jogo encerrado (código {code})")


class AccountsTab(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setup_ui()

    def setup_ui(self):
        layout = QVBoxLayout(self)
        layout.setSpacing(16)
        layout.setContentsMargins(24, 24, 24, 24)

        header = QLabel("Gerenciar Contas")
        header.setFont(QFont("Inter", 18, QFont.Weight.Bold))
        header.setStyleSheet("color: #f0f0f5;")
        layout.addWidget(header)

        # Account list
        self.acc_list = QListWidget()
        self.acc_list.setStyleSheet("""
            QListWidget {
                background: #14141f; border: 1px solid #1e1e35;
                border-radius: 8px; padding: 4px;
            }
            QListWidget::item {
                padding: 10px; border-radius: 6px; color: #e0e0f0;
            }
            QListWidget::item:selected { background: #2a2a4e; }
            QListWidget::item:hover { background: #1e1e32; }
        """)
        layout.addWidget(self.acc_list)

        # Add offline account
        add_frame = QFrame()
        add_frame.setStyleSheet("QFrame { background: #14141f; border: 1px solid #1e1e35; border-radius: 8px; padding: 12px; }")
        add_layout = QVBoxLayout(add_frame)

        add_label = QLabel("Adicionar conta offline (pirata)")
        add_label.setStyleSheet("color: #a0a0b8; font-size: 13px; border: none;")
        add_layout.addWidget(add_label)

        input_row = QHBoxLayout()
        self.username_input = QLineEdit()
        self.username_input.setPlaceholderText("Nome de usuário")
        self.username_input.setStyleSheet("""
            QLineEdit {
                background: #0e0e16; border: 1px solid #2a2a3e;
                border-radius: 8px; padding: 10px; color: #e0e0f0;
            }
            QLineEdit:focus { border-color: #6d4db3; }
        """)
        input_row.addWidget(self.username_input)

        add_btn = QPushButton("Adicionar")
        add_btn.setStyleSheet("""
            QPushButton {
                background: #6d4db3; color: #fff; border: none;
                border-radius: 8px; padding: 10px 20px; font-weight: bold;
            }
            QPushButton:hover { background: #7c5cbf; }
        """)
        add_btn.clicked.connect(self.add_account)
        input_row.addWidget(add_btn)
        add_layout.addLayout(input_row)

        layout.addWidget(add_frame)

        # Select / Remove buttons
        btn_row = QHBoxLayout()
        select_btn = QPushButton("Usar selecionada")
        select_btn.setStyleSheet("""
            QPushButton {
                background: #1e3a5c; color: #7cb8e0; border: none;
                border-radius: 8px; padding: 10px 16px;
            }
            QPushButton:hover { background: #254a6e; }
        """)
        select_btn.clicked.connect(self.select_account)
        btn_row.addWidget(select_btn)

        remove_btn = QPushButton("Remover")
        remove_btn.setStyleSheet("""
            QPushButton {
                background: #3e1a1a; color: #e05555; border: none;
                border-radius: 8px; padding: 10px 16px;
            }
            QPushButton:hover { background: #4e2222; }
        """)
        remove_btn.clicked.connect(self.remove_account)
        btn_row.addWidget(remove_btn)
        btn_row.addStretch()
        layout.addLayout(btn_row)

        self.refresh_list()

    def refresh_list(self):
        self.acc_list.clear()
        accounts = load_accounts()
        for i, acc in enumerate(accounts["accounts"]):
            marker = " (ativa)" if i == accounts["selected"] else ""
            item = QListWidgetItem(
                f"  {acc['username']}{marker} — {acc['type']}")
            self.acc_list.addItem(item)

    def add_account(self):
        username = self.username_input.text().strip()
        if not username:
            return
        accounts = load_accounts()
        uuid = hashlib.md5(username.encode()).hexdigest()
        uuid = f"{uuid[:8]}-{uuid[8:12]}-{uuid[12:16]}-{uuid[16:20]}-{uuid[20:]}"
        accounts["accounts"].append({
            "username": username, "uuid": uuid,
            "type": "offline", "access_token": "0",
            "created": datetime.now().isoformat()
        })
        if accounts["selected"] < 0:
            accounts["selected"] = 0
        save_accounts(accounts)
        self.username_input.clear()
        self.refresh_list()

    def select_account(self):
        row = self.acc_list.currentRow()
        if row < 0:
            return
        accounts = load_accounts()
        accounts["selected"] = row
        save_accounts(accounts)
        self.refresh_list()

    def remove_account(self):
        row = self.acc_list.currentRow()
        if row < 0:
            return
        accounts = load_accounts()
        accounts["accounts"].pop(row)
        if accounts["selected"] >= len(accounts["accounts"]):
            accounts["selected"] = len(accounts["accounts"]) - 1
        save_accounts(accounts)
        self.refresh_list()


class ModsTab(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setup_ui()

    def setup_ui(self):
        layout = QVBoxLayout(self)
        layout.setSpacing(16)
        layout.setContentsMargins(24, 24, 24, 24)

        header = QLabel("Mods e Texturas")
        header.setFont(QFont("Inter", 18, QFont.Weight.Bold))
        header.setStyleSheet("color: #f0f0f5;")
        layout.addWidget(header)

        desc = QLabel("Arraste arquivos .jar para mods ou .zip para texturas")
        desc.setStyleSheet("color: #6b6b80; font-size: 13px;")
        layout.addWidget(desc)

        # Mods list
        mods_group = QGroupBox("Mods instalados")
        mods_group.setStyleSheet("""
            QGroupBox {
                color: #a0a0b8; border: 1px solid #1e1e35;
                border-radius: 8px; padding-top: 20px;
            }
            QGroupBox::title { padding: 0 8px; }
        """)
        mods_layout = QVBoxLayout(mods_group)
        self.mods_list = QListWidget()
        self.mods_list.setStyleSheet("""
            QListWidget { background: #0e0e16; border: none; border-radius: 6px; }
            QListWidget::item { padding: 8px; color: #c0c0d8; }
        """)
        mods_layout.addWidget(self.mods_list)

        add_mod_btn = QPushButton("Adicionar Mod (.jar)")
        add_mod_btn.setStyleSheet("""
            QPushButton {
                background: #1e3a1e; color: #50c878; border: none;
                border-radius: 8px; padding: 10px;
            }
            QPushButton:hover { background: #264a26; }
        """)
        add_mod_btn.clicked.connect(self.add_mod)
        mods_layout.addWidget(add_mod_btn)
        layout.addWidget(mods_group)

        # Textures
        tex_group = QGroupBox("Texturas instaladas")
        tex_group.setStyleSheet("""
            QGroupBox {
                color: #a0a0b8; border: 1px solid #1e1e35;
                border-radius: 8px; padding-top: 20px;
            }
            QGroupBox::title { padding: 0 8px; }
        """)
        tex_layout = QVBoxLayout(tex_group)
        self.tex_list = QListWidget()
        self.tex_list.setStyleSheet("""
            QListWidget { background: #0e0e16; border: none; border-radius: 6px; }
            QListWidget::item { padding: 8px; color: #c0c0d8; }
        """)
        tex_layout.addWidget(self.tex_list)

        add_tex_btn = QPushButton("Adicionar Textura (.zip)")
        add_tex_btn.setStyleSheet("""
            QPushButton {
                background: #1e1e3a; color: #7878e0; border: none;
                border-radius: 8px; padding: 10px;
            }
            QPushButton:hover { background: #26264a; }
        """)
        add_tex_btn.clicked.connect(self.add_texture)
        tex_layout.addWidget(add_tex_btn)
        layout.addWidget(tex_group)

        self.refresh_lists()

    def refresh_lists(self):
        self.mods_list.clear()
        if MODS_DIR.exists():
            for f in sorted(MODS_DIR.iterdir()):
                if f.suffix == ".jar":
                    self.mods_list.addItem(f"  {f.name}")

        self.tex_list.clear()
        tex_dir = FEXLAUNCHER_DIR / "textures"
        if tex_dir.exists():
            for f in sorted(tex_dir.iterdir()):
                if f.suffix == ".zip":
                    self.tex_list.addItem(f"  {f.name}")

    def add_mod(self):
        files, _ = QFileDialog.getOpenFileNames(
            self, "Selecionar Mods", "", "Mods (*.jar)")
        for f in files:
            src = Path(f)
            dest = MODS_DIR / src.name
            import shutil
            shutil.copy2(src, dest)
        self.refresh_lists()

    def add_texture(self):
        files, _ = QFileDialog.getOpenFileNames(
            self, "Selecionar Texturas", "", "Texturas (*.zip)")
        tex_dir = FEXLAUNCHER_DIR / "textures"
        tex_dir.mkdir(exist_ok=True)
        for f in files:
            src = Path(f)
            dest = tex_dir / src.name
            import shutil
            shutil.copy2(src, dest)
        self.refresh_lists()


class SkinsTab(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setup_ui()

    def setup_ui(self):
        layout = QVBoxLayout(self)
        layout.setSpacing(16)
        layout.setContentsMargins(24, 24, 24, 24)

        header = QLabel("Skins e Capas")
        header.setFont(QFont("Inter", 18, QFont.Weight.Bold))
        header.setStyleSheet("color: #f0f0f5;")
        layout.addWidget(header)

        desc = QLabel("Adicione skins (.png 64x64) e capas para sua conta")
        desc.setStyleSheet("color: #6b6b80; font-size: 13px;")
        layout.addWidget(desc)

        # Current skin preview area
        preview_frame = QFrame()
        preview_frame.setFixedHeight(200)
        preview_frame.setStyleSheet("""
            QFrame { background: #14141f; border: 1px solid #1e1e35;
                     border-radius: 12px; }
        """)
        preview_layout = QVBoxLayout(preview_frame)
        self.preview_label = QLabel("Nenhuma skin selecionada")
        self.preview_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.preview_label.setStyleSheet("color: #4a4a60; font-size: 14px; border: none;")
        preview_layout.addWidget(self.preview_label)
        layout.addWidget(preview_frame)

        # Buttons
        btn_row = QHBoxLayout()
        skin_btn = QPushButton("Selecionar Skin (.png)")
        skin_btn.setStyleSheet("""
            QPushButton {
                background: #6d4db3; color: #fff; border: none;
                border-radius: 8px; padding: 12px 20px; font-weight: bold;
            }
            QPushButton:hover { background: #7c5cbf; }
        """)
        skin_btn.clicked.connect(self.select_skin)
        btn_row.addWidget(skin_btn)

        cape_btn = QPushButton("Selecionar Capa (.png)")
        cape_btn.setStyleSheet("""
            QPushButton {
                background: #1e3a5c; color: #7cb8e0; border: none;
                border-radius: 8px; padding: 12px 20px; font-weight: bold;
            }
            QPushButton:hover { background: #254a6e; }
        """)
        cape_btn.clicked.connect(self.select_cape)
        btn_row.addWidget(cape_btn)
        btn_row.addStretch()
        layout.addLayout(btn_row)

        # Saved skins list
        self.skins_list = QListWidget()
        self.skins_list.setStyleSheet("""
            QListWidget { background: #0e0e16; border: 1px solid #1e1e35; border-radius: 8px; }
            QListWidget::item { padding: 8px; color: #c0c0d8; }
            QListWidget::item:selected { background: #2a2a4e; }
        """)
        layout.addWidget(self.skins_list)
        self.refresh_skins()

        layout.addStretch()

    def select_skin(self):
        file, _ = QFileDialog.getOpenFileName(
            self, "Selecionar Skin", "", "Imagem (*.png)")
        if file:
            import shutil
            dest = SKINS_DIR / Path(file).name
            shutil.copy2(file, dest)
            accounts = load_accounts()
            if accounts["selected"] >= 0:
                accounts["accounts"][accounts["selected"]]["skin"] = str(dest)
                save_accounts(accounts)
            self.preview_label.setText(f"Skin: {Path(file).name}")
            self.refresh_skins()

    def select_cape(self):
        file, _ = QFileDialog.getOpenFileName(
            self, "Selecionar Capa", "", "Imagem (*.png)")
        if file:
            import shutil
            dest = SKINS_DIR / f"cape_{Path(file).name}"
            shutil.copy2(file, dest)
            accounts = load_accounts()
            if accounts["selected"] >= 0:
                accounts["accounts"][accounts["selected"]]["cape"] = str(dest)
                save_accounts(accounts)
            self.refresh_skins()

    def refresh_skins(self):
        self.skins_list.clear()
        if SKINS_DIR.exists():
            for f in sorted(SKINS_DIR.iterdir()):
                if f.suffix == ".png":
                    prefix = "Capa" if f.name.startswith("cape_") else "Skin"
                    self.skins_list.addItem(f"  [{prefix}] {f.name}")


class SettingsTab(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.config = load_config()
        self.setup_ui()

    def setup_ui(self):
        layout = QVBoxLayout(self)
        layout.setSpacing(16)
        layout.setContentsMargins(24, 24, 24, 24)

        header = QLabel("Configurações")
        header.setFont(QFont("Inter", 18, QFont.Weight.Bold))
        header.setStyleSheet("color: #f0f0f5;")
        layout.addWidget(header)

        # RAM settings
        ram_group = QGroupBox("Memória (RAM)")
        ram_group.setStyleSheet("""
            QGroupBox { color: #a0a0b8; border: 1px solid #1e1e35;
                        border-radius: 8px; padding-top: 20px; }
        """)
        ram_layout = QGridLayout(ram_group)

        ram_layout.addWidget(QLabel("Mínima:"), 0, 0)
        self.ram_min = QComboBox()
        self.ram_min.addItems(["256M", "512M", "1G", "2G"])
        self.ram_min.setCurrentText(self.config.get("ram_min", "512M"))
        ram_layout.addWidget(self.ram_min, 0, 1)

        ram_layout.addWidget(QLabel("Máxima:"), 1, 0)
        self.ram_max = QComboBox()
        self.ram_max.addItems(["2G", "4G", "6G", "8G", "12G", "16G"])
        self.ram_max.setCurrentText(self.config.get("ram_max", "4G"))
        ram_layout.addWidget(self.ram_max, 1, 1)
        layout.addWidget(ram_group)

        # Java path
        java_group = QGroupBox("Java")
        java_group.setStyleSheet("""
            QGroupBox { color: #a0a0b8; border: 1px solid #1e1e35;
                        border-radius: 8px; padding-top: 20px; }
        """)
        java_layout = QHBoxLayout(java_group)
        self.java_input = QLineEdit(self.config.get("java_path", "java"))
        self.java_input.setStyleSheet("""
            QLineEdit { background: #0e0e16; border: 1px solid #2a2a3e;
                        border-radius: 8px; padding: 8px; color: #e0e0f0; }
        """)
        java_layout.addWidget(self.java_input)
        layout.addWidget(java_group)

        # Save button
        save_btn = QPushButton("Salvar configurações")
        save_btn.setStyleSheet("""
            QPushButton {
                background: #6d4db3; color: #fff; border: none;
                border-radius: 8px; padding: 12px; font-weight: bold;
            }
            QPushButton:hover { background: #7c5cbf; }
        """)
        save_btn.clicked.connect(self.save_settings)
        layout.addWidget(save_btn)

        layout.addStretch()

    def save_settings(self):
        self.config["ram_min"] = self.ram_min.currentText()
        self.config["ram_max"] = self.ram_max.currentText()
        self.config["java_path"] = self.java_input.text()
        CONFIG_FILE.write_text(json.dumps(self.config, indent=2))


class FexLauncherWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("FexLauncher")
        self.setMinimumSize(900, 600)
        self.resize(1000, 680)
        ensure_dirs()
        self.setup_ui()

    def setup_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        layout = QVBoxLayout(central)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)

        # Tabs
        self.tabs = QTabWidget()
        self.tabs.setStyleSheet("""
            QTabWidget::pane { border: none; background: #12121c; }
            QTabBar::tab {
                background: #0e0e16; color: #6b6b80;
                padding: 14px 24px; border: none;
                border-bottom: 2px solid transparent;
                font-size: 13px; font-weight: 500;
            }
            QTabBar::tab:selected {
                color: #a78bfa; border-bottom: 2px solid #6d4db3;
                background: #12121c;
            }
            QTabBar::tab:hover { color: #c0c0d8; background: #16161e; }
        """)

        self.play_tab = PlayTab(self)
        self.tabs.addTab(self.play_tab, "Jogar")
        self.tabs.addTab(AccountsTab(self), "Contas")
        self.tabs.addTab(ModsTab(self), "Mods")
        self.tabs.addTab(SkinsTab(self), "Skins")
        self.tabs.addTab(SettingsTab(self), "Config")

        layout.addWidget(self.tabs)

        # Update account display
        self.update_account_display()

    def update_account_display(self):
        accounts = load_accounts()
        if accounts["accounts"] and accounts["selected"] >= 0:
            acc = accounts["accounts"][accounts["selected"]]
            self.play_tab.account_label.setText(
                f"Conta: {acc['username']} ({acc['type']})")
        else:
            self.play_tab.account_label.setText("Nenhuma conta — crie na aba Contas")


def main():
    app = QApplication(sys.argv)
    app.setApplicationName("FexLauncher")
    app.setStyle("Fusion")
    app.setPalette(create_dark_palette())
    window = FexLauncherWindow()
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
