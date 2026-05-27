#!/usr/bin/env python3
"""
FexLauncher GUI — PyQt6 Interface
Modern, beautiful Minecraft launcher interface.
"""

import sys
import os
from pathlib import Path

try:
    from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout,
                                  QHBoxLayout, QLabel, QPushButton, QComboBox,
                                  QLineEdit, QTabWidget, QListWidget, QListWidgetItem,
                                  QProgressBar, QStackedWidget, QFrame, QScrollArea,
                                  QGridLayout, QFileDialog, QSpinBox, QCheckBox,
                                  QGraphicsDropShadowEffect, QSizePolicy)
    from PyQt6.QtCore import Qt, QThread, pyqtSignal, QSize, QTimer
    from PyQt6.QtGui import QFont, QColor, QPalette, QIcon, QPixmap, QLinearGradient
    HAS_QT = True
except ImportError:
    HAS_QT = False

from fexlauncher import (ensure_dirs, load_config, save_config, load_accounts,
                          save_accounts, fetch_versions, download_version,
                          launch_minecraft, add_offline_account, set_skin,
                          install_mod, install_texture_pack, check_java,
                          FEXLAUNCHER_DIR, VERSIONS_DIR)

STYLESHEET = """
QMainWindow {
    background-color: #0a0a12;
}
QWidget {
    color: #e0e0e0;
    font-family: "Inter", "Segoe UI", sans-serif;
}
QTabWidget::pane {
    border: none;
    background-color: #0f0f1a;
}
QTabBar::tab {
    background: #1a1a2e;
    color: #8b8da3;
    padding: 12px 24px;
    border: none;
    border-bottom: 2px solid transparent;
    font-size: 13px;
    font-weight: 500;
}
QTabBar::tab:selected {
    color: #bd93f9;
    border-bottom: 2px solid #bd93f9;
    background: #12121f;
}
QTabBar::tab:hover {
    color: #ffffff;
    background: #16162a;
}
QPushButton {
    background: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                                stop:0 #bd93f9, stop:1 #00fff7);
    color: #0a0a12;
    border: none;
    border-radius: 8px;
    padding: 10px 24px;
    font-weight: 700;
    font-size: 13px;
}
QPushButton:hover {
    background: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                                stop:0 #cda4ff, stop:1 #33fffa);
}
QPushButton:pressed {
    background: #9d73d9;
}
QPushButton#secondary {
    background: rgba(189, 147, 249, 0.15);
    color: #bd93f9;
    border: 1px solid rgba(189, 147, 249, 0.3);
}
QPushButton#secondary:hover {
    background: rgba(189, 147, 249, 0.25);
}
QComboBox {
    background: #1a1a2e;
    border: 1px solid #2a2a3e;
    border-radius: 8px;
    padding: 8px 16px;
    color: #e0e0e0;
    font-size: 13px;
}
QComboBox:hover {
    border-color: #bd93f9;
}
QComboBox::drop-down {
    border: none;
    width: 30px;
}
QLineEdit {
    background: #1a1a2e;
    border: 1px solid #2a2a3e;
    border-radius: 8px;
    padding: 10px 16px;
    color: #e0e0e0;
    font-size: 13px;
}
QLineEdit:focus {
    border-color: #bd93f9;
}
QListWidget {
    background: #0f0f1a;
    border: 1px solid #1a1a2e;
    border-radius: 8px;
    padding: 4px;
}
QListWidget::item {
    background: #1a1a2e;
    border-radius: 6px;
    padding: 12px;
    margin: 2px 0;
}
QListWidget::item:selected {
    background: rgba(189, 147, 249, 0.2);
    border: 1px solid rgba(189, 147, 249, 0.4);
}
QListWidget::item:hover {
    background: #22223a;
}
QProgressBar {
    background: #1a1a2e;
    border: none;
    border-radius: 4px;
    height: 6px;
}
QProgressBar::chunk {
    background: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                                stop:0 #bd93f9, stop:1 #00fff7);
    border-radius: 4px;
}
QScrollBar:vertical {
    background: #0a0a12;
    width: 8px;
    border-radius: 4px;
}
QScrollBar::handle:vertical {
    background: #3a3a5e;
    border-radius: 4px;
    min-height: 30px;
}
QScrollBar::handle:vertical:hover {
    background: #bd93f9;
}
QLabel#title {
    font-size: 24px;
    font-weight: 800;
    color: #ffffff;
}
QLabel#subtitle {
    font-size: 13px;
    color: #6b6d80;
}
QLabel#version-badge {
    background: rgba(189, 147, 249, 0.15);
    color: #bd93f9;
    border-radius: 10px;
    padding: 4px 12px;
    font-size: 11px;
    font-weight: 600;
}
QFrame#card {
    background: #12121f;
    border: 1px solid #1e1e35;
    border-radius: 12px;
    padding: 16px;
}
QFrame#card:hover {
    border-color: rgba(189, 147, 249, 0.3);
}
QSpinBox {
    background: #1a1a2e;
    border: 1px solid #2a2a3e;
    border-radius: 8px;
    padding: 8px;
    color: #e0e0e0;
}
QCheckBox {
    color: #e0e0e0;
    spacing: 8px;
}
QCheckBox::indicator {
    width: 18px;
    height: 18px;
    border-radius: 4px;
    border: 2px solid #3a3a5e;
    background: #1a1a2e;
}
QCheckBox::indicator:checked {
    background: #bd93f9;
    border-color: #bd93f9;
}
"""


class FexLauncherApp(QApplication):
    def __init__(self, argv):
        super().__init__(argv)
        self.setApplicationName("FexLauncher")
        self.setStyle("Fusion")

        # Dark palette
        palette = QPalette()
        palette.setColor(QPalette.ColorRole.Window, QColor(10, 10, 18))
        palette.setColor(QPalette.ColorRole.WindowText, QColor(224, 224, 224))
        palette.setColor(QPalette.ColorRole.Base, QColor(15, 15, 26))
        palette.setColor(QPalette.ColorRole.Text, QColor(224, 224, 224))
        self.setPalette(palette)

        self.setStyleSheet(STYLESHEET)

        self.window = FexLauncherWindow()
        self.window.show()


class FexLauncherWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("FexLauncher — Minecraft")
        self.setMinimumSize(1100, 700)
        self.resize(1200, 750)

        ensure_dirs()
        self.config = load_config()
        self.accounts = load_accounts()
        self.versions_data = None

        self.setup_ui()
        self.load_versions()

    def setup_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        main_layout = QVBoxLayout(central)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.setSpacing(0)

        # Header
        header = QFrame()
        header.setFixedHeight(70)
        header.setStyleSheet("background: #0a0a12; border-bottom: 1px solid #1a1a2e;")
        header_layout = QHBoxLayout(header)
        header_layout.setContentsMargins(24, 0, 24, 0)

        logo = QLabel("⚡ FexLauncher")
        logo.setStyleSheet("font-size: 20px; font-weight: 800; color: #bd93f9;")
        header_layout.addWidget(logo)
        header_layout.addStretch()

        # Account selector in header
        self.account_label = QLabel("Sem conta")
        self.account_label.setStyleSheet("color: #8b8da3; font-size: 12px;")
        if self.accounts["accounts"]:
            sel = self.accounts.get("selected", 0) or 0
            self.account_label.setText(self.accounts["accounts"][sel]["username"])
        header_layout.addWidget(self.account_label)

        main_layout.addWidget(header)

        # Tabs
        self.tabs = QTabWidget()
        self.tabs.addTab(self.create_play_tab(), "⚡ Jogar")
        self.tabs.addTab(self.create_versions_tab(), "📦 Versões")
        self.tabs.addTab(self.create_accounts_tab(), "👤 Contas")
        self.tabs.addTab(self.create_mods_tab(), "🔧 Mods")
        self.tabs.addTab(self.create_skins_tab(), "🎨 Skins")
        self.tabs.addTab(self.create_settings_tab(), "⚙ Config")
        main_layout.addWidget(self.tabs)

    def create_play_tab(self):
        widget = QWidget()
        layout = QVBoxLayout(widget)
        layout.setContentsMargins(32, 32, 32, 32)
        layout.setSpacing(20)

        # Welcome
        title = QLabel("Pronto para jogar")
        title.setObjectName("title")
        layout.addWidget(title)

        subtitle = QLabel("Selecione uma versão e clique em Jogar")
        subtitle.setObjectName("subtitle")
        layout.addWidget(subtitle)

        layout.addSpacing(20)

        # Version selector
        ver_layout = QHBoxLayout()
        ver_label = QLabel("Versão:")
        ver_label.setStyleSheet("font-weight: 600;")
        ver_layout.addWidget(ver_label)

        self.version_combo = QComboBox()
        self.version_combo.setMinimumWidth(200)
        ver_layout.addWidget(self.version_combo)
        ver_layout.addStretch()
        layout.addLayout(ver_layout)

        # Play button
        self.play_btn = QPushButton("⚡  JOGAR")
        self.play_btn.setFixedHeight(56)
        self.play_btn.setStyleSheet("""
            QPushButton {
                font-size: 18px;
                font-weight: 800;
                border-radius: 12px;
                background: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                    stop:0 #bd93f9, stop:1 #00fff7);
            }
        """)
        self.play_btn.clicked.connect(self.play_game)
        layout.addWidget(self.play_btn)

        # Progress
        self.progress = QProgressBar()
        self.progress.setVisible(False)
        layout.addWidget(self.progress)

        self.status_label = QLabel("")
        self.status_label.setObjectName("subtitle")
        layout.addWidget(self.status_label)

        layout.addStretch()
        return widget

    def create_versions_tab(self):
        widget = QWidget()
        layout = QVBoxLayout(widget)
        layout.setContentsMargins(32, 32, 32, 32)

        title = QLabel("Versões Disponíveis")
        title.setObjectName("title")
        layout.addWidget(title)

        self.versions_list = QListWidget()
        layout.addWidget(self.versions_list)

        btn_layout = QHBoxLayout()
        dl_btn = QPushButton("Baixar Selecionada")
        dl_btn.clicked.connect(self.download_selected)
        btn_layout.addWidget(dl_btn)
        btn_layout.addStretch()
        layout.addLayout(btn_layout)

        return widget

    def create_accounts_tab(self):
        widget = QWidget()
        layout = QVBoxLayout(widget)
        layout.setContentsMargins(32, 32, 32, 32)

        title = QLabel("Contas")
        title.setObjectName("title")
        layout.addWidget(title)

        subtitle = QLabel("Adicione contas pirata (offline) ou originais (Microsoft)")
        subtitle.setObjectName("subtitle")
        layout.addWidget(subtitle)

        layout.addSpacing(16)

        # Add account
        add_layout = QHBoxLayout()
        self.username_input = QLineEdit()
        self.username_input.setPlaceholderText("Nome de usuário...")
        add_layout.addWidget(self.username_input)

        add_btn = QPushButton("Adicionar Offline")
        add_btn.clicked.connect(self.add_account)
        add_layout.addWidget(add_btn)

        ms_btn = QPushButton("Login Microsoft")
        ms_btn.setObjectName("secondary")
        add_layout.addWidget(ms_btn)
        layout.addLayout(add_layout)

        # Accounts list
        self.accounts_list = QListWidget()
        self.refresh_accounts_list()
        layout.addWidget(self.accounts_list)

        return widget

    def create_mods_tab(self):
        widget = QWidget()
        layout = QVBoxLayout(widget)
        layout.setContentsMargins(32, 32, 32, 32)

        title = QLabel("Mods & Textures")
        title.setObjectName("title")
        layout.addWidget(title)

        btn_layout = QHBoxLayout()
        mod_btn = QPushButton("Instalar Mod (.jar)")
        mod_btn.clicked.connect(self.install_mod_dialog)
        btn_layout.addWidget(mod_btn)

        tex_btn = QPushButton("Instalar Texture Pack (.zip)")
        tex_btn.setObjectName("secondary")
        tex_btn.clicked.connect(self.install_texture_dialog)
        btn_layout.addWidget(tex_btn)
        btn_layout.addStretch()
        layout.addLayout(btn_layout)

        self.mods_list = QListWidget()
        layout.addWidget(self.mods_list)

        return widget

    def create_skins_tab(self):
        widget = QWidget()
        layout = QVBoxLayout(widget)
        layout.setContentsMargins(32, 32, 32, 32)

        title = QLabel("Skins & Capas")
        title.setObjectName("title")
        layout.addWidget(title)

        subtitle = QLabel("Funciona para contas pirata e original")
        subtitle.setObjectName("subtitle")
        layout.addWidget(subtitle)

        btn_layout = QHBoxLayout()
        skin_btn = QPushButton("Alterar Skin (.png)")
        skin_btn.clicked.connect(self.change_skin_dialog)
        btn_layout.addWidget(skin_btn)
        btn_layout.addStretch()
        layout.addLayout(btn_layout)

        layout.addStretch()
        return widget

    def create_settings_tab(self):
        widget = QWidget()
        layout = QVBoxLayout(widget)
        layout.setContentsMargins(32, 32, 32, 32)

        title = QLabel("Configurações")
        title.setObjectName("title")
        layout.addWidget(title)

        layout.addSpacing(16)

        # RAM
        ram_layout = QHBoxLayout()
        ram_layout.addWidget(QLabel("RAM Máxima (GB):"))
        self.ram_spin = QSpinBox()
        self.ram_spin.setRange(1, 32)
        self.ram_spin.setValue(int(self.config.get("ram_max", "4G").replace("G", "")))
        ram_layout.addWidget(self.ram_spin)
        ram_layout.addStretch()
        layout.addLayout(ram_layout)

        # Auto-update
        self.auto_update_check = QCheckBox("Atualização automática")
        self.auto_update_check.setChecked(self.config.get("auto_update", True))
        layout.addWidget(self.auto_update_check)

        # Close on launch
        self.close_check = QCheckBox("Fechar launcher ao iniciar jogo")
        self.close_check.setChecked(self.config.get("close_on_launch", False))
        layout.addWidget(self.close_check)

        # Fullscreen
        self.fs_check = QCheckBox("Tela cheia")
        self.fs_check.setChecked(self.config.get("fullscreen", False))
        layout.addWidget(self.fs_check)

        layout.addSpacing(16)
        save_btn = QPushButton("Salvar Configurações")
        save_btn.clicked.connect(self.save_settings)
        layout.addWidget(save_btn)

        layout.addStretch()
        return widget

    def load_versions(self):
        self.versions_data = fetch_versions()
        if self.versions_data and "versions" in self.versions_data:
            for v in self.versions_data["versions"][:50]:
                if v["type"] == "release":
                    self.version_combo.addItem(v["id"])
                    self.versions_list.addItem(f"[{v['type']}] {v['id']}")

    def play_game(self):
        version = self.version_combo.currentText()
        if not version:
            self.status_label.setText("Selecione uma versão")
            return
        if not self.accounts["accounts"]:
            self.status_label.setText("Adicione uma conta primeiro")
            return
        sel = self.accounts.get("selected", 0) or 0
        account = self.accounts["accounts"][sel]
        self.status_label.setText(f"Iniciando Minecraft {version}...")
        launch_minecraft(version, account, self.config)

    def download_selected(self):
        item = self.versions_list.currentItem()
        if item:
            version_id = item.text().split("] ")[1]
            self.status_label.setText(f"Baixando {version_id}...")

    def add_account(self):
        name = self.username_input.text().strip()
        if name:
            add_offline_account(name)
            self.accounts = load_accounts()
            self.refresh_accounts_list()
            self.username_input.clear()
            self.account_label.setText(name)

    def refresh_accounts_list(self):
        self.accounts_list.clear()
        for i, acc in enumerate(self.accounts["accounts"]):
            sel = "→ " if i == self.accounts.get("selected") else "  "
            self.accounts_list.addItem(f"{sel}[{acc['type']}] {acc['username']}")

    def install_mod_dialog(self):
        path, _ = QFileDialog.getOpenFileName(self, "Selecionar Mod", "",
                                               "Mods (*.jar)")
        if path:
            install_mod(path)
            self.mods_list.addItem(Path(path).name)

    def install_texture_dialog(self):
        path, _ = QFileDialog.getOpenFileName(self, "Selecionar Texture Pack", "",
                                               "Textures (*.zip)")
        if path:
            install_texture_pack(path)

    def change_skin_dialog(self):
        path, _ = QFileDialog.getOpenFileName(self, "Selecionar Skin", "",
                                               "Skins (*.png)")
        if path:
            sel = self.accounts.get("selected", 0) or 0
            set_skin(sel, path)

    def save_settings(self):
        self.config["ram_max"] = f"{self.ram_spin.value()}G"
        self.config["auto_update"] = self.auto_update_check.isChecked()
        self.config["close_on_launch"] = self.close_check.isChecked()
        self.config["fullscreen"] = self.fs_check.isChecked()
        save_config(self.config)
        self.status_label.setText("Configurações salvas!")


if not HAS_QT:
    class FexLauncherApp:
        def __init__(self, argv):
            print("[FexLauncher] PyQt6 required for GUI mode")
            print("Install: pip install PyQt6")
            sys.exit(1)
