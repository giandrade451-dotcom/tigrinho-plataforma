#!/usr/bin/env python3
"""
FexNav Window — GTK4 + WebKitGTK browser.
100% native, zero Electron, zero web-tech UI.
The browser chrome and start page are all native GTK widgets.
"""

import sys
import json
from pathlib import Path

try:
    import gi
    gi.require_version("Gtk", "4.0")
    gi.require_version("Adw", "1")
    gi.require_version("WebKit", "6.0")
    from gi.repository import Gtk, Adw, WebKit, GLib, Gio, Gdk, Pango
    HAS_GTK = True
except (ImportError, ValueError):
    HAS_GTK = False
    print("[FexNav] GTK4 + WebKitGTK necessário. Instale: gtk4 libadwaita webkit2gtk-5.0")
    sys.exit(1)

FEXNAV_DIR = Path.home() / ".fexnav"
CONFIG_FILE = FEXNAV_DIR / "config.json"
BOOKMARKS_FILE = FEXNAV_DIR / "bookmarks.json"
HISTORY_FILE = FEXNAV_DIR / "history.json"

DEFAULT_BOOKMARKS = [
    {"name": "Google", "url": "https://www.google.com"},
    {"name": "YouTube", "url": "https://www.youtube.com"},
    {"name": "GitHub", "url": "https://github.com"},
    {"name": "Spotify", "url": "https://open.spotify.com"},
    {"name": "WhatsApp", "url": "https://web.whatsapp.com"},
    {"name": "Discord", "url": "https://discord.com/app"},
    {"name": "Steam", "url": "https://store.steampowered.com"},
    {"name": "Twitch", "url": "https://www.twitch.tv"},
]


def ensure_dirs():
    FEXNAV_DIR.mkdir(parents=True, exist_ok=True)


def load_config():
    if CONFIG_FILE.exists():
        return json.loads(CONFIG_FILE.read_text())
    cfg = {
        "homepage": "fexnav://home",
        "search_engine": "https://www.google.com/search?q=",
        "hardware_acceleration": True,
        "smooth_scrolling": True,
    }
    ensure_dirs()
    CONFIG_FILE.write_text(json.dumps(cfg, indent=2))
    return cfg


def load_bookmarks():
    if BOOKMARKS_FILE.exists():
        return json.loads(BOOKMARKS_FILE.read_text())
    ensure_dirs()
    BOOKMARKS_FILE.write_text(json.dumps(DEFAULT_BOOKMARKS, indent=2))
    return DEFAULT_BOOKMARKS


def add_history(url, title):
    ensure_dirs()
    history = []
    if HISTORY_FILE.exists():
        try:
            history = json.loads(HISTORY_FILE.read_text())
        except Exception:
            history = []
    from datetime import datetime
    history.insert(0, {"url": url, "title": title, "time": datetime.now().isoformat()})
    history = history[:500]
    HISTORY_FILE.write_text(json.dumps(history, indent=2))


class FexNavStartPage(Gtk.Box):
    """Native GTK4 start page — no HTML, no web technologies."""

    def __init__(self, navigate_callback):
        super().__init__(orientation=Gtk.Orientation.VERTICAL)
        self.navigate = navigate_callback
        self.set_halign(Gtk.Align.CENTER)
        self.set_valign(Gtk.Align.CENTER)
        self.set_spacing(24)
        self.set_margin_top(80)
        self.set_margin_bottom(80)

        # Logo
        logo = Gtk.Label(label="FexNav")
        logo.add_css_class("title-1")
        logo.set_markup("<span size='xx-large' weight='bold' foreground='#a78bfa'>FexNav</span>")
        self.append(logo)

        # Subtitle
        sub = Gtk.Label(label="Navegador oficial do FexOS")
        sub.add_css_class("dim-label")
        self.append(sub)

        # Search entry
        self.search_entry = Gtk.Entry()
        self.search_entry.set_placeholder_text("Pesquisar na web...")
        self.search_entry.set_size_request(420, 44)
        self.search_entry.add_css_class("search-entry")
        self.search_entry.connect("activate", self.on_search)
        self.append(self.search_entry)

        # Bookmarks grid
        bookmarks = load_bookmarks()
        grid = Gtk.FlowBox()
        grid.set_max_children_per_line(4)
        grid.set_min_children_per_line(4)
        grid.set_column_spacing(12)
        grid.set_row_spacing(12)
        grid.set_selection_mode(Gtk.SelectionMode.NONE)
        grid.set_homogeneous(True)

        for bm in bookmarks[:8]:
            btn = Gtk.Button()
            btn.set_size_request(100, 80)
            btn.add_css_class("flat")
            btn.add_css_class("bookmark-btn")

            box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
            box.set_halign(Gtk.Align.CENTER)
            box.set_valign(Gtk.Align.CENTER)

            # Icon (first letter in circle)
            icon_label = Gtk.Label(label=bm["name"][0].upper())
            icon_label.add_css_class("title-3")
            box.append(icon_label)

            name_label = Gtk.Label(label=bm["name"])
            name_label.add_css_class("caption")
            name_label.set_ellipsize(Pango.EllipsizeMode.END)
            box.append(name_label)

            btn.set_child(box)
            btn.connect("clicked", lambda b, url=bm["url"]: self.navigate(url))
            grid.append(btn)

        self.append(grid)

    def on_search(self, entry):
        text = entry.get_text()
        if text:
            config = load_config()
            if "." in text and " " not in text:
                self.navigate(f"https://{text}")
            else:
                self.navigate(f"{config['search_engine']}{text}")


class FexNavWindow(Adw.ApplicationWindow):
    """Main browser window — native GTK4 chrome."""

    def __init__(self, config=None, **kwargs):
        super().__init__(**kwargs)
        self.config = config or load_config()
        self.set_title("FexNav")
        self.set_default_size(1280, 800)
        self.showing_startpage = True

        # Apply custom CSS
        css = Gtk.CssProvider()
        css.load_from_string("""
            .search-entry { border-radius: 12px; padding: 8px; }
            .bookmark-btn { border-radius: 12px; padding: 12px; min-width: 90px; }
        """)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), css,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

        # Main box
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.set_content(box)

        # Header bar
        header = Adw.HeaderBar()
        header.set_show_end_title_buttons(True)
        header.set_show_start_title_buttons(True)

        # Navigation buttons
        nav_box = Gtk.Box(spacing=2)
        self.back_btn = Gtk.Button(icon_name="go-previous-symbolic")
        self.back_btn.set_tooltip_text("Voltar")
        self.back_btn.connect("clicked", self.go_back)
        self.back_btn.set_sensitive(False)
        nav_box.append(self.back_btn)

        self.fwd_btn = Gtk.Button(icon_name="go-next-symbolic")
        self.fwd_btn.set_tooltip_text("Avançar")
        self.fwd_btn.connect("clicked", self.go_forward)
        self.fwd_btn.set_sensitive(False)
        nav_box.append(self.fwd_btn)

        self.refresh_btn = Gtk.Button(icon_name="view-refresh-symbolic")
        self.refresh_btn.set_tooltip_text("Recarregar")
        self.refresh_btn.connect("clicked", self.refresh)
        nav_box.append(self.refresh_btn)

        home_btn = Gtk.Button(icon_name="go-home-symbolic")
        home_btn.set_tooltip_text("Página inicial")
        home_btn.connect("clicked", lambda b: self.show_start_page())
        nav_box.append(home_btn)

        header.pack_start(nav_box)

        # URL entry
        self.url_entry = Gtk.Entry()
        self.url_entry.set_hexpand(True)
        self.url_entry.set_placeholder_text("Pesquisar ou digitar URL...")
        self.url_entry.connect("activate", self.on_url_activate)
        header.set_title_widget(self.url_entry)

        # Menu
        menu_btn = Gtk.MenuButton(icon_name="open-menu-symbolic")
        header.pack_end(menu_btn)

        box.append(header)

        # Stack for start page vs webview
        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE)

        # Start page (native GTK)
        self.start_page = FexNavStartPage(self.navigate)
        start_scroll = Gtk.ScrolledWindow()
        start_scroll.set_child(self.start_page)
        self.stack.add_named(start_scroll, "start")

        # WebView
        settings = WebKit.Settings()
        settings.set_enable_javascript(True)
        settings.set_enable_smooth_scrolling(self.config.get("smooth_scrolling", True))
        settings.set_hardware_acceleration_policy(
            WebKit.HardwareAccelerationPolicy.ALWAYS
            if self.config.get("hardware_acceleration", True)
            else WebKit.HardwareAccelerationPolicy.NEVER)
        settings.set_user_agent_with_application_details("FexNav", "6.0")

        self.webview = WebKit.WebView()
        self.webview.set_settings(settings)
        self.webview.set_vexpand(True)
        self.webview.set_hexpand(True)
        self.webview.connect("notify::title", self.on_title_changed)
        self.webview.connect("notify::uri", self.on_uri_changed)
        self.webview.connect("load-changed", self.on_load_changed)
        self.stack.add_named(self.webview, "web")

        box.append(self.stack)

        # Show start page
        self.show_start_page()

    def show_start_page(self):
        self.stack.set_visible_child_name("start")
        self.showing_startpage = True
        self.url_entry.set_text("")
        self.set_title("FexNav")

    def navigate(self, url):
        if not url:
            return
        if url == "fexnav://home":
            self.show_start_page()
            return
        if not url.startswith(("http://", "https://", "file://")):
            if "." in url and " " not in url:
                url = "https://" + url
            else:
                url = f"{self.config.get('search_engine', 'https://www.google.com/search?q=')}{url}"
        self.stack.set_visible_child_name("web")
        self.showing_startpage = False
        self.webview.load_uri(url)

    def go_back(self, btn):
        if self.webview.can_go_back():
            self.webview.go_back()

    def go_forward(self, btn):
        if self.webview.can_go_forward():
            self.webview.go_forward()

    def refresh(self, btn):
        if self.showing_startpage:
            return
        self.webview.reload()

    def on_url_activate(self, entry):
        self.navigate(entry.get_text())

    def on_title_changed(self, webview, param):
        title = webview.get_title()
        if title:
            self.set_title(f"{title} — FexNav")

    def on_uri_changed(self, webview, param):
        uri = webview.get_uri()
        if uri:
            self.url_entry.set_text(uri)
            self.back_btn.set_sensitive(webview.can_go_back())
            self.fwd_btn.set_sensitive(webview.can_go_forward())
            add_history(uri, webview.get_title() or "")

    def on_load_changed(self, webview, event):
        pass


class FexNavApplication(Adw.Application):
    def __init__(self, start_url=None):
        super().__init__(application_id="io.fexos.fexnav",
                        flags=Gio.ApplicationFlags.HANDLES_OPEN)
        self.start_url = start_url
        self.config = load_config()

    def do_activate(self):
        win = FexNavWindow(application=self, config=self.config)
        win.present()
        if self.start_url and self.start_url != "fexnav://home":
            win.navigate(self.start_url)


def main(url=None):
    ensure_dirs()
    app = FexNavApplication(start_url=url)
    app.run(sys.argv[1:] if not url else [])


if __name__ == "__main__":
    url = sys.argv[1] if len(sys.argv) > 1 else None
    main(url)
