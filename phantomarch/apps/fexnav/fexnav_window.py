#!/usr/bin/env python3
"""
FexNav Window — GTK4 + WebKitGTK browser window.
Native performance, no Electron overhead.
"""

import sys
import json
from pathlib import Path

try:
    import gi
    gi.require_version("Gtk", "4.0")
    gi.require_version("Adw", "1")
    gi.require_version("WebKit", "6.0")
    from gi.repository import Gtk, Adw, WebKit, GLib, Gio, Gdk
    HAS_GTK = True
except (ImportError, ValueError):
    HAS_GTK = False

if HAS_GTK:
    from fexnav import load_config, save_config, load_bookmarks, add_history, FEXNAV_DIR

    class FexNavApplication(Adw.Application):
        def __init__(self, config=None, start_url=None):
            super().__init__(application_id="io.fexos.fexnav",
                           flags=Gio.ApplicationFlags.HANDLES_OPEN)
            self.config = config or load_config()
            self.start_url = start_url
            self.tabs = []

        def do_activate(self):
            win = FexNavWindow(application=self, config=self.config)
            win.present()
            url = self.start_url or self.config.get("homepage", "fexnav://home")
            if url == "fexnav://home":
                win.load_home()
            else:
                win.navigate(url)

    class FexNavWindow(Adw.ApplicationWindow):
        def __init__(self, config=None, **kwargs):
            super().__init__(**kwargs)
            self.config = config or load_config()
            self.set_title("FexNav")
            self.set_default_size(1280, 800)

            # Main layout
            box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
            self.set_content(box)

            # Header/toolbar
            header = Adw.HeaderBar()
            header.set_show_end_title_buttons(True)

            # Navigation buttons
            nav_box = Gtk.Box(spacing=4)
            self.back_btn = Gtk.Button(icon_name="go-previous-symbolic")
            self.back_btn.connect("clicked", self.go_back)
            nav_box.append(self.back_btn)

            self.forward_btn = Gtk.Button(icon_name="go-next-symbolic")
            self.forward_btn.connect("clicked", self.go_forward)
            nav_box.append(self.forward_btn)

            self.refresh_btn = Gtk.Button(icon_name="view-refresh-symbolic")
            self.refresh_btn.connect("clicked", self.refresh)
            nav_box.append(self.refresh_btn)

            header.pack_start(nav_box)

            # URL bar
            self.url_entry = Gtk.Entry()
            self.url_entry.set_hexpand(True)
            self.url_entry.set_placeholder_text("Pesquisar ou digitar URL...")
            self.url_entry.connect("activate", self.on_url_activate)
            header.set_title_widget(self.url_entry)

            # Menu button
            menu_btn = Gtk.MenuButton(icon_name="open-menu-symbolic")
            header.pack_end(menu_btn)

            box.append(header)

            # WebView
            web_settings = WebKit.Settings()
            web_settings.set_enable_javascript(True)
            web_settings.set_enable_smooth_scrolling(
                self.config.get("smooth_scrolling", True))
            web_settings.set_hardware_acceleration_policy(
                WebKit.HardwareAccelerationPolicy.ALWAYS if
                self.config.get("hardware_acceleration", True) else
                WebKit.HardwareAccelerationPolicy.NEVER)
            web_settings.set_user_agent_with_application_details(
                "FexNav", "6.0")

            self.webview = WebKit.WebView()
            self.webview.set_settings(web_settings)
            self.webview.set_vexpand(True)
            self.webview.set_hexpand(True)
            self.webview.connect("notify::title", self.on_title_changed)
            self.webview.connect("notify::uri", self.on_uri_changed)
            self.webview.connect("load-changed", self.on_load_changed)

            box.append(self.webview)

            # Status bar
            self.status = Gtk.Label(label="Pronto")
            self.status.set_halign(Gtk.Align.START)
            self.status.add_css_class("dim-label")
            box.append(self.status)

        def navigate(self, url):
            if not url.startswith(("http://", "https://", "file://", "fexnav://")):
                if "." in url and " " not in url:
                    url = "https://" + url
                else:
                    search = self.config.get("search_engine",
                                            "https://www.google.com/search?q=")
                    url = search + url
            self.webview.load_uri(url)

        def load_home(self):
            home_html = """
            <html>
            <head>
                <style>
                    body {
                        background: #0a0a12;
                        color: #e0e0e0;
                        font-family: 'Inter', 'Segoe UI', sans-serif;
                        display: flex;
                        flex-direction: column;
                        align-items: center;
                        justify-content: center;
                        height: 100vh;
                        margin: 0;
                    }
                    h1 {
                        font-size: 48px;
                        font-weight: 800;
                        background: linear-gradient(135deg, #bd93f9, #00fff7);
                        -webkit-background-clip: text;
                        -webkit-text-fill-color: transparent;
                        margin-bottom: 8px;
                    }
                    .subtitle { color: #6b6d80; margin-bottom: 40px; }
                    .search {
                        width: 500px;
                        padding: 16px 24px;
                        border-radius: 12px;
                        border: 1px solid #2a2a3e;
                        background: #12121f;
                        color: #e0e0e0;
                        font-size: 16px;
                        outline: none;
                    }
                    .search:focus { border-color: #bd93f9; }
                    .shortcuts {
                        display: grid;
                        grid-template-columns: repeat(4, 1fr);
                        gap: 16px;
                        margin-top: 40px;
                    }
                    .shortcut {
                        padding: 20px;
                        background: #12121f;
                        border: 1px solid #1e1e35;
                        border-radius: 12px;
                        text-align: center;
                        cursor: pointer;
                        text-decoration: none;
                        color: #e0e0e0;
                    }
                    .shortcut:hover {
                        border-color: rgba(189, 147, 249, 0.4);
                        background: #16162a;
                    }
                    .shortcut .icon { font-size: 28px; margin-bottom: 8px; }
                    .shortcut .name { font-size: 12px; color: #8b8da3; }
                </style>
            </head>
            <body>
                <h1>⚡ FexNav</h1>
                <p class="subtitle">Navegador oficial do FexOS</p>
                <input class="search" placeholder="Pesquisar na web..." autofocus
                    onkeypress="if(event.key==='Enter')window.location='https://www.google.com/search?q='+this.value">
                <div class="shortcuts">
                    <a class="shortcut" href="https://www.google.com">
                        <div class="icon">🔍</div><div class="name">Google</div>
                    </a>
                    <a class="shortcut" href="https://www.youtube.com">
                        <div class="icon">📺</div><div class="name">YouTube</div>
                    </a>
                    <a class="shortcut" href="https://github.com">
                        <div class="icon">💻</div><div class="name">GitHub</div>
                    </a>
                    <a class="shortcut" href="https://open.spotify.com">
                        <div class="icon">🎵</div><div class="name">Spotify</div>
                    </a>
                    <a class="shortcut" href="https://web.whatsapp.com">
                        <div class="icon">💬</div><div class="name">WhatsApp</div>
                    </a>
                    <a class="shortcut" href="https://discord.com/app">
                        <div class="icon">🎮</div><div class="name">Discord</div>
                    </a>
                    <a class="shortcut" href="https://store.steampowered.com">
                        <div class="icon">🕹️</div><div class="name">Steam</div>
                    </a>
                    <a class="shortcut" href="https://www.twitch.tv">
                        <div class="icon">📡</div><div class="name">Twitch</div>
                    </a>
                </div>
            </body>
            </html>
            """
            self.webview.load_html(home_html, "fexnav://home")

        def go_back(self, btn):
            if self.webview.can_go_back():
                self.webview.go_back()

        def go_forward(self, btn):
            if self.webview.can_go_forward():
                self.webview.go_forward()

        def refresh(self, btn):
            self.webview.reload()

        def on_url_activate(self, entry):
            self.navigate(entry.get_text())

        def on_title_changed(self, webview, param):
            title = webview.get_title()
            if title:
                self.set_title(f"{title} — FexNav")

        def on_uri_changed(self, webview, param):
            uri = webview.get_uri()
            if uri and not uri.startswith("fexnav://"):
                self.url_entry.set_text(uri)
                add_history(uri, webview.get_title() or "")

        def on_load_changed(self, webview, event):
            if event == WebKit.LoadEvent.STARTED:
                self.status.set_label("Carregando...")
            elif event == WebKit.LoadEvent.FINISHED:
                self.status.set_label("Pronto")

else:
    class FexNavApplication:
        def __init__(self, **kwargs):
            print("[FexNav] GTK4/WebKitGTK not available")
            sys.exit(1)
