#!/usr/bin/env python3
"""
FexOS Task Manager — PyQt6 Native System Monitor.
Real-time CPU/RAM/GPU/Process monitoring.
Zero web technologies.
"""

import sys
import os
import subprocess
from pathlib import Path

try:
    from PyQt6.QtWidgets import (
        QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
        QLabel, QPushButton, QTabWidget, QTableWidget, QTableWidgetItem,
        QProgressBar, QFrame, QHeaderView, QMessageBox
    )
    from PyQt6.QtCore import Qt, QTimer, QSize
    from PyQt6.QtGui import QFont, QColor, QPalette, QAction
    HAS_QT = True
except ImportError:
    HAS_QT = False
    print("[TaskManager] PyQt6 não encontrado.")
    sys.exit(1)


def get_cpu_usage():
    try:
        with open("/proc/stat") as f:
            parts = f.readline().split()
        total = sum(int(x) for x in parts[1:])
        idle = int(parts[4])
        return max(0, min(100, int((1 - idle / max(total, 1)) * 100)))
    except Exception:
        return 0


def get_memory_info():
    info = {}
    try:
        with open("/proc/meminfo") as f:
            for line in f:
                parts = line.split()
                if parts[0] in ("MemTotal:", "MemAvailable:", "SwapTotal:", "SwapFree:"):
                    info[parts[0].rstrip(":")] = int(parts[1])
    except Exception:
        pass
    total = info.get("MemTotal", 0) // 1024
    available = info.get("MemAvailable", 0) // 1024
    used = total - available
    swap_total = info.get("SwapTotal", 0) // 1024
    swap_free = info.get("SwapFree", 0) // 1024
    swap_used = swap_total - swap_free
    return {"total": total, "used": used, "available": available,
            "swap_total": swap_total, "swap_used": swap_used}


def get_gpu_info():
    # NVIDIA
    try:
        result = subprocess.run(
            ["nvidia-smi", "--query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu",
             "--format=csv,noheader,nounits"],
            capture_output=True, text=True, timeout=3)
        if result.returncode == 0:
            parts = result.stdout.strip().split(", ")
            return {"type": "NVIDIA", "usage": int(parts[0]),
                    "vram_used": int(parts[1]), "vram_total": int(parts[2]),
                    "temp": int(parts[3])}
    except Exception:
        pass
    # AMD
    try:
        usage_file = Path("/sys/class/drm/card0/device/gpu_busy_percent")
        if usage_file.exists():
            return {"type": "AMD", "usage": int(usage_file.read_text().strip()),
                    "vram_used": 0, "vram_total": 0, "temp": 0}
    except Exception:
        pass
    return {"type": "N/A", "usage": 0, "vram_used": 0, "vram_total": 0, "temp": 0}


def get_processes():
    procs = []
    try:
        result = subprocess.run(
            ["ps", "aux", "--sort=-%mem"],
            capture_output=True, text=True, timeout=5)
        for line in result.stdout.strip().split("\n")[1:31]:
            parts = line.split(None, 10)
            if len(parts) >= 11:
                procs.append({
                    "pid": parts[1],
                    "user": parts[0],
                    "cpu": parts[2],
                    "mem": parts[3],
                    "command": parts[10][:60]
                })
    except Exception:
        pass
    return procs


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


class OverviewWidget(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        layout = QVBoxLayout(self)
        layout.setSpacing(16)
        layout.setContentsMargins(24, 24, 24, 24)

        # CPU
        cpu_frame = QFrame()
        cpu_frame.setStyleSheet("QFrame { background: #14141f; border: 1px solid #1e1e35; border-radius: 10px; padding: 16px; }")
        cpu_layout = QVBoxLayout(cpu_frame)
        cpu_header = QHBoxLayout()
        cpu_title = QLabel("CPU")
        cpu_title.setFont(QFont("Inter", 14, QFont.Weight.DemiBold))
        cpu_title.setStyleSheet("color: #50c878; border: none;")
        cpu_header.addWidget(cpu_title)
        self.cpu_percent = QLabel("0%")
        self.cpu_percent.setFont(QFont("Inter", 20, QFont.Weight.Bold))
        self.cpu_percent.setStyleSheet("color: #50c878; border: none;")
        self.cpu_percent.setAlignment(Qt.AlignmentFlag.AlignRight)
        cpu_header.addWidget(self.cpu_percent)
        cpu_layout.addLayout(cpu_header)
        self.cpu_bar = QProgressBar()
        self.cpu_bar.setFixedHeight(8)
        self.cpu_bar.setTextVisible(False)
        self.cpu_bar.setStyleSheet("""
            QProgressBar { background: #1e1e35; border: none; border-radius: 4px; }
            QProgressBar::chunk { background: #50c878; border-radius: 4px; }
        """)
        cpu_layout.addWidget(self.cpu_bar)
        layout.addWidget(cpu_frame)

        # RAM
        ram_frame = QFrame()
        ram_frame.setStyleSheet("QFrame { background: #14141f; border: 1px solid #1e1e35; border-radius: 10px; padding: 16px; }")
        ram_layout = QVBoxLayout(ram_frame)
        ram_header = QHBoxLayout()
        ram_title = QLabel("RAM")
        ram_title.setFont(QFont("Inter", 14, QFont.Weight.DemiBold))
        ram_title.setStyleSheet("color: #e078c0; border: none;")
        ram_header.addWidget(ram_title)
        self.ram_label = QLabel("0 / 0 MB")
        self.ram_label.setStyleSheet("color: #a0a0b8; font-size: 12px; border: none;")
        ram_header.addWidget(self.ram_label)
        self.ram_percent = QLabel("0%")
        self.ram_percent.setFont(QFont("Inter", 20, QFont.Weight.Bold))
        self.ram_percent.setStyleSheet("color: #e078c0; border: none;")
        self.ram_percent.setAlignment(Qt.AlignmentFlag.AlignRight)
        ram_header.addWidget(self.ram_percent)
        ram_layout.addLayout(ram_header)
        self.ram_bar = QProgressBar()
        self.ram_bar.setFixedHeight(8)
        self.ram_bar.setTextVisible(False)
        self.ram_bar.setStyleSheet("""
            QProgressBar { background: #1e1e35; border: none; border-radius: 4px; }
            QProgressBar::chunk { background: #e078c0; border-radius: 4px; }
        """)
        ram_layout.addWidget(self.ram_bar)
        layout.addWidget(ram_frame)

        # GPU
        gpu_frame = QFrame()
        gpu_frame.setStyleSheet("QFrame { background: #14141f; border: 1px solid #1e1e35; border-radius: 10px; padding: 16px; }")
        gpu_layout = QVBoxLayout(gpu_frame)
        gpu_header = QHBoxLayout()
        gpu_title = QLabel("GPU")
        gpu_title.setFont(QFont("Inter", 14, QFont.Weight.DemiBold))
        gpu_title.setStyleSheet("color: #c8a050; border: none;")
        gpu_header.addWidget(gpu_title)
        self.gpu_type = QLabel("")
        self.gpu_type.setStyleSheet("color: #6b6b80; font-size: 12px; border: none;")
        gpu_header.addWidget(self.gpu_type)
        self.gpu_percent = QLabel("0%")
        self.gpu_percent.setFont(QFont("Inter", 20, QFont.Weight.Bold))
        self.gpu_percent.setStyleSheet("color: #c8a050; border: none;")
        self.gpu_percent.setAlignment(Qt.AlignmentFlag.AlignRight)
        gpu_header.addWidget(self.gpu_percent)
        gpu_layout.addLayout(gpu_header)
        self.gpu_bar = QProgressBar()
        self.gpu_bar.setFixedHeight(8)
        self.gpu_bar.setTextVisible(False)
        self.gpu_bar.setStyleSheet("""
            QProgressBar { background: #1e1e35; border: none; border-radius: 4px; }
            QProgressBar::chunk { background: #c8a050; border-radius: 4px; }
        """)
        gpu_layout.addWidget(self.gpu_bar)
        layout.addWidget(gpu_frame)

        layout.addStretch()

    def update_data(self):
        cpu = get_cpu_usage()
        self.cpu_percent.setText(f"{cpu}%")
        self.cpu_bar.setValue(cpu)

        mem = get_memory_info()
        if mem["total"] > 0:
            pct = int(mem["used"] / mem["total"] * 100)
            self.ram_percent.setText(f"{pct}%")
            self.ram_bar.setValue(pct)
            self.ram_label.setText(f"{mem['used']} / {mem['total']} MB")

        gpu = get_gpu_info()
        self.gpu_type.setText(gpu["type"])
        self.gpu_percent.setText(f"{gpu['usage']}%")
        self.gpu_bar.setValue(gpu["usage"])


class ProcessesWidget(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        layout = QVBoxLayout(self)
        layout.setContentsMargins(16, 16, 16, 16)
        layout.setSpacing(8)

        # Header
        header = QHBoxLayout()
        title = QLabel("Processos")
        title.setFont(QFont("Inter", 16, QFont.Weight.Bold))
        title.setStyleSheet("color: #f0f0f5;")
        header.addWidget(title)
        header.addStretch()

        kill_btn = QPushButton("Encerrar processo")
        kill_btn.setStyleSheet("""
            QPushButton {
                background: #3e1a1a; color: #e05555; border: none;
                border-radius: 8px; padding: 8px 14px; font-size: 12px;
            }
            QPushButton:hover { background: #4e2222; }
        """)
        kill_btn.clicked.connect(self.kill_selected)
        header.addWidget(kill_btn)
        layout.addLayout(header)

        # Table
        self.table = QTableWidget()
        self.table.setColumnCount(5)
        self.table.setHorizontalHeaderLabels(["PID", "Usuário", "CPU%", "RAM%", "Comando"])
        self.table.horizontalHeader().setStretchLastSection(True)
        self.table.verticalHeader().setVisible(False)
        self.table.setSelectionBehavior(QTableWidget.SelectionBehavior.SelectRows)
        self.table.setStyleSheet("""
            QTableWidget {
                background: #0e0e16; border: 1px solid #1e1e35;
                border-radius: 8px; gridline-color: #1e1e35;
            }
            QTableWidget::item { padding: 6px; color: #c0c0d8; }
            QTableWidget::item:selected { background: #2a2a4e; }
            QHeaderView::section {
                background: #14141f; color: #8080a0;
                border: none; padding: 8px; font-size: 11px;
            }
        """)
        layout.addWidget(self.table)

    def update_data(self):
        procs = get_processes()
        self.table.setRowCount(len(procs))
        for i, p in enumerate(procs):
            self.table.setItem(i, 0, QTableWidgetItem(p["pid"]))
            self.table.setItem(i, 1, QTableWidgetItem(p["user"]))
            self.table.setItem(i, 2, QTableWidgetItem(p["cpu"]))
            self.table.setItem(i, 3, QTableWidgetItem(p["mem"]))
            self.table.setItem(i, 4, QTableWidgetItem(p["command"]))

    def kill_selected(self):
        row = self.table.currentRow()
        if row < 0:
            return
        pid = self.table.item(row, 0).text()
        reply = QMessageBox.question(
            self, "Encerrar processo",
            f"Encerrar processo PID {pid}?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No)
        if reply == QMessageBox.StandardButton.Yes:
            os.system(f"kill {pid}")
            self.update_data()


class TaskManagerWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Gerenciador de Tarefas — FexOS")
        self.setMinimumSize(800, 550)
        self.resize(900, 620)
        self.setup_ui()
        self.start_updates()

    def setup_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        layout = QVBoxLayout(central)
        layout.setContentsMargins(0, 0, 0, 0)

        self.tabs = QTabWidget()
        self.tabs.setStyleSheet("""
            QTabWidget::pane { border: none; background: #0e0e16; }
            QTabBar::tab {
                background: #0a0a12; color: #6b6b80;
                padding: 12px 20px; border: none;
                border-bottom: 2px solid transparent; font-size: 13px;
            }
            QTabBar::tab:selected { color: #a78bfa; border-bottom: 2px solid #6d4db3; background: #0e0e16; }
            QTabBar::tab:hover { color: #c0c0d8; }
        """)

        self.overview = OverviewWidget()
        self.processes = ProcessesWidget()
        self.tabs.addTab(self.overview, "Visão Geral")
        self.tabs.addTab(self.processes, "Processos")

        layout.addWidget(self.tabs)

    def start_updates(self):
        self.timer = QTimer()
        self.timer.timeout.connect(self.refresh)
        self.timer.start(2000)
        self.refresh()

    def refresh(self):
        self.overview.update_data()
        if self.tabs.currentIndex() == 1:
            self.processes.update_data()


def main():
    app = QApplication(sys.argv)
    app.setApplicationName("FexOS Task Manager")
    app.setStyle("Fusion")
    app.setPalette(create_dark_palette())
    window = TaskManagerWindow()
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
