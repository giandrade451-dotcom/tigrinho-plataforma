#!/usr/bin/env python3
"""
FexStore GUI — PyQt6 App Store Interface.
Beautiful, modern, Windows Store-inspired.
"""

import sys
from pathlib import Path

try:
    from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout,
                                  QHBoxLayout, QLabel, QPushButton, QTabWidget,
                                  QListWidget, QListWidgetItem, QLineEdit,
                                  QScrollArea, QGridLayout, QFrame, QSizePolicy)
    from PyQt6.QtCore import Qt, QSize
    from PyQt6.QtGui import QFont, QColor, QPalette
    HAS_QT = True
except ImportError:
    HAS_QT = False

from fexstore import (APP_CATALOG, ensure_dirs, install_app, uninstall_app,
                       is_installed, search_apps, load_installed)

STYLESHEET = """
QMainWindow { background-color: #0a0a12; }
QWidget { color: #e0e0e0; font-family: "Inter", "Segoe UI", sans-serif; }
QTabWidget::pane { border: none; background: #0f0f1a; }
QTabBar::tab {
    background: #1a1a2e; color: #8b8da3; padding: 12px 20px;
    border: none; border-bottom: 2px solid transparent;
}
QTabBar::tab:selected { color: #bd93f9; border-bottom: 2px solid #bd93f9; }
QTabBar::tab:hover { color: #fff; background: #16162a; }
QPushButton {
    background: qlineargradient(x1:0,y1:0,x2:1,y2:0, stop:0 #bd93f9, stop:1 #00fff7);
    color: #0a0a12; border: none; border-radius: 8px;
    padding: 8px 16px; font-weight: 700; font-size: 12px;
}
QPushButton:hover { background: #cda4ff; }
QPushButton#installed {
    background: rgba(80,250,123,0.15); color: #50fa7b;
    border: 1px solid rgba(80,250,123,0.3);
}
QPushButton#uninstall {
    background: rgba(255,85,85,0.15); color: #ff5555;
    border: 1px solid rgba(255,85,85,0.3);
}
QLineEdit {
    background: #1a1a2e; border: 1px solid #2a2a3e; border-radius: 10px;
    padding: 10px 16px; color: #e0e0e0; font-size: 14px;
}
QLineEdit:focus { border-color: #bd93f9; }
QFrame#appCard {
    background: #12121f; border: 1px solid #1e1e35;
    border-radius: 12px; padding: 16px;
}
QFrame#appCard:hover { border-color: rgba(189,147,249,0.3); }
QLabel#title { font-size: 22px; font-weight: 800; color: #fff; }
QLabel#appName { font-size: 14px; font-weight: 600; color: #fff; }
QLabel#appDesc { font-size: 12px; color: #6b6d80; }
QLabel#appIcon { font-size: 32px; }
QLabel#categoryTitle { font-size: 16px; font-weight: 700; color: #bd93f9; }
QScrollArea { border: none; }
"""


class FexStoreApp(QApplication):
    def __init__(self, argv):
        super().__init__(argv)
        self.setApplicationName("FexStore")
        self.setStyle("Fusion")
        self.setStyleSheet(STYLESHEET)
        self.window = FexStoreWindow()
        self.window.show()


class FexStoreWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("FexStore — Apps & Jogos")
        self.setMinimumSize(1000, 650)
        self.resize(1100, 700)
        ensure_dirs()
        self.setup_ui()

    def setup_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        layout = QVBoxLayout(central)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)

        # Header
        header = QFrame()
        header.setFixedHeight(70)
        header.setStyleSheet("background: #0a0a12; border-bottom: 1px solid #1a1a2e;")
        h_layout = QHBoxLayout(header)
        h_layout.setContentsMargins(24, 0, 24, 0)

        logo = QLabel("⚡ FexStore")
        logo.setStyleSheet("font-size: 20px; font-weight: 800; color: #bd93f9;")
        h_layout.addWidget(logo)

        self.search_bar = QLineEdit()
        self.search_bar.setPlaceholderText("Buscar apps e jogos...")
        self.search_bar.setFixedWidth(300)
        self.search_bar.returnPressed.connect(self.do_search)
        h_layout.addStretch()
        h_layout.addWidget(self.search_bar)

        layout.addWidget(header)

        # Tabs
        tabs = QTabWidget()
        tabs.addTab(self.create_discover_tab(), "🏠 Descobrir")
        tabs.addTab(self.create_category_tab("games", "🎮 Jogos"), "🎮 Jogos")
        tabs.addTab(self.create_category_tab("communication", "💬 Comunicação"), "💬 Social")
        tabs.addTab(self.create_category_tab("multimedia", "🎬 Mídia"), "🎬 Mídia")
        tabs.addTab(self.create_category_tab("productivity", "💼 Produtividade"), "💼 Produtividade")
        tabs.addTab(self.create_installed_tab(), "✓ Instalados")
        layout.addWidget(tabs)

    def create_discover_tab(self):
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        content = QWidget()
        layout = QVBoxLayout(content)
        layout.setContentsMargins(24, 24, 24, 24)
        layout.setSpacing(24)

        title = QLabel("Descubra apps e jogos")
        title.setObjectName("title")
        layout.addWidget(title)

        # Featured section
        for category, apps in APP_CATALOG.items():
            cat_label = QLabel(f"{'🎮' if category=='games' else '💬' if category=='communication' else '🎬' if category=='multimedia' else '💼'} {category.capitalize()}")
            cat_label.setObjectName("categoryTitle")
            layout.addWidget(cat_label)

            grid = QGridLayout()
            grid.setSpacing(12)
            for i, app in enumerate(apps[:4]):
                card = self.create_app_card(app)
                grid.addWidget(card, 0, i)
            layout.addLayout(grid)

        layout.addStretch()
        scroll.setWidget(content)
        return scroll

    def create_category_tab(self, category, title_text):
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        content = QWidget()
        layout = QVBoxLayout(content)
        layout.setContentsMargins(24, 24, 24, 24)
        layout.setSpacing(12)

        title = QLabel(title_text)
        title.setObjectName("title")
        layout.addWidget(title)

        apps = APP_CATALOG.get(category, [])
        grid = QGridLayout()
        grid.setSpacing(12)
        for i, app in enumerate(apps):
            card = self.create_app_card(app)
            grid.addWidget(card, i // 3, i % 3)
        layout.addLayout(grid)

        layout.addStretch()
        scroll.setWidget(content)
        return scroll

    def create_installed_tab(self):
        widget = QWidget()
        layout = QVBoxLayout(widget)
        layout.setContentsMargins(24, 24, 24, 24)

        title = QLabel("Apps Instalados")
        title.setObjectName("title")
        layout.addWidget(title)

        installed = load_installed()
        if installed["apps"]:
            for app_info in installed["apps"]:
                label = QLabel(f"✓ {app_info['name']} — instalado em {app_info['installed_at'][:10]}")
                layout.addWidget(label)
        else:
            layout.addWidget(QLabel("Nenhum app instalado via FexStore"))

        layout.addStretch()
        return widget

    def create_app_card(self, app):
        card = QFrame()
        card.setObjectName("appCard")
        card.setFixedHeight(140)
        card.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)

        layout = QVBoxLayout(card)
        layout.setSpacing(6)

        # Icon + name
        top = QHBoxLayout()
        icon = QLabel(app.get("icon", "📦"))
        icon.setObjectName("appIcon")
        top.addWidget(icon)

        info = QVBoxLayout()
        name = QLabel(app["name"])
        name.setObjectName("appName")
        info.addWidget(name)

        desc = QLabel(app.get("description", ""))
        desc.setObjectName("appDesc")
        info.addWidget(desc)
        top.addLayout(info)
        top.addStretch()

        layout.addLayout(top)

        # Rating + Install button
        bottom = QHBoxLayout()
        rating = QLabel(f"⭐ {app.get('rating', 'N/A')}")
        rating.setStyleSheet("color: #f1fa8c; font-size: 11px;")
        bottom.addWidget(rating)

        price = QLabel("Grátis" if app.get("free") else "Pago")
        price.setStyleSheet("color: #50fa7b; font-size: 11px;")
        bottom.addWidget(price)
        bottom.addStretch()

        if is_installed(app["id"]):
            btn = QPushButton("✓ Instalado")
            btn.setObjectName("installed")
        else:
            btn = QPushButton("Instalar")
            btn.clicked.connect(lambda checked, a=app: self.install_clicked(a))
        bottom.addWidget(btn)

        layout.addLayout(bottom)
        return card

    def install_clicked(self, app):
        install_app(app)

    def do_search(self):
        query = self.search_bar.text()
        results = search_apps(query)
        # Could update UI with results


if not HAS_QT:
    class FexStoreApp:
        def __init__(self, argv):
            print("[FexStore] PyQt6 required")
            sys.exit(1)
