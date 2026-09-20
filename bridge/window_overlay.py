"""
bridge/window_overlay.py
========================
Python-driven Desktop Visual Overlay for Roblox Studio.

Features:
  - Transparent border around the ENTIRE Roblox Studio window (all 4 edges).
  - Bold 8px pulsing crimson red frame.
  - Notification banner: "AI is currently testing, please wait..."
  - Smart Input Lockout:
    * When Roblox Studio is active/focused by user: absorbs and denies clicks on Studio,
      displaying "[Input Blocked]" warning animation and denial ripple.
    * When user is in another app/tab (doing other work): automatically yields click-through
      so the user can type and click freely in their other applications without interruption.
  - Virtual Cursor animation using assets/icons/ai_cursor.png (gliding & golden ripple clicks).
  - Process-isolated Tkinter architecture: runs in its own subprocess to guarantee zero Tcl threading errors.
"""

import sys
import time
import subprocess
import threading
import ctypes
from pathlib import Path
from typing import Optional
import tkinter as tk
from PIL import Image, ImageTk
import win32gui
import win32con
import win32api

user32 = ctypes.windll.user32
ICON_PATH = Path(__file__).resolve().parent.parent / "assets" / "icons" / "ai_cursor.png"

# Win32 Constants
GWL_EXSTYLE = -20
WS_EX_LAYERED = 0x00080000
WS_EX_TRANSPARENT = 0x00000020
WS_EX_TOPMOST = 0x00000008
SWP_NOACTIVATE = 0x0010
SWP_NOMOVE = 0x0002
SWP_NOSIZE = 0x0001
HWND_TOPMOST = -1
HWND_NOTOPMOST = -2

def attach_desktop():
    """Attaches current thread to interactive desktop WinSta0\\Default."""
    hwinsta = user32.OpenWindowStationW("WinSta0", False, 0x10000000)
    if hwinsta:
        user32.SetProcessWindowStation(hwinsta)
    hdesk = user32.OpenDesktopW("Default", 0, False, 0x10000000)
    if hdesk:
        user32.SetThreadDesktop(hdesk)

def find_studio_window():
    """Locates the Roblox Studio main window HWND and title."""
    attach_desktop()
    found = []
    def enum_cb(hwnd, _):
        if win32gui.IsWindow(hwnd):
            t = win32gui.GetWindowText(hwnd)
            if "Roblox Studio" in t:
                try:
                    rect = win32gui.GetWindowRect(hwnd)
                    w = rect[2] - rect[0]
                    h = rect[3] - rect[1]
                    if w > 400 and h > 400:
                        found.append((hwnd, t, w * h))
                except Exception:
                    pass

    hdesk = user32.OpenDesktopW("Default", 0, False, 0x10000000)
    if hdesk:
        try:
            win32gui.EnumDesktopWindows(hdesk, enum_cb, None)
        except Exception:
            pass
        user32.CloseDesktop(hdesk)

    if not found:
        try:
            win32gui.EnumWindows(enum_cb, None)
        except Exception:
            pass

    if found:
        found.sort(key=lambda x: x[2], reverse=True)
        return found[0][0], found[0][1]
    return None, None

class StudioWindowOverlayServer:
    """Runs the Tkinter UI on its own main thread inside an isolated subprocess."""
    def __init__(self, studio_hwnd: int):
        self.studio_hwnd = studio_hwnd
        self.root = None
        self.canvas = None
        self.cursor_item = None
        self.cursor_tk = None
        self.is_running = False
        self.banner_items = []
        self.border_item = None
        self.overlay_hwnd = None
        self._fade_job = None
        self.screen_bounds = (0, 0, 1920, 1080)
        self.is_click_through = False
        self.current_cursor = (500, 500)

    def run(self):
        attach_desktop()
        rect = win32gui.GetWindowRect(self.studio_hwnd)
        x, y, r, b = rect
        w = r - x
        h = b - y

        screen_w = user32.GetSystemMetrics(0)
        screen_h = user32.GetSystemMetrics(1)

        x_adj = max(0, x)
        y_adj = max(0, y)
        w_adj = min(w - (x_adj - x), screen_w - x_adj)
        h_adj = min(h - (y_adj - y), screen_h - y_adj)
        self.screen_bounds = (x_adj, y_adj, w_adj, h_adj)
        self.current_cursor = (w_adj // 2, h_adj // 2)

        self.root = tk.Tk()
        self.root.title("RobloxStudio_AI_Overlay")
        self.root.overrideredirect(True)
        self.root.wm_attributes("-topmost", True)
        self.root.wm_attributes("-transparentcolor", "#010101")
        self.root.geometry(f"{w_adj}x{h_adj}+{x_adj}+{y_adj}")
        self.root.configure(bg="#010101")

        self.canvas = tk.Canvas(self.root, width=w_adj, height=h_adj, bg="#010101", highlightthickness=0)
        self.canvas.pack(fill="both", expand=True)

        BORDER_THICKNESS = 8
        half = BORDER_THICKNESS // 2
        self.border_item = self.canvas.create_rectangle(
            half, half, w_adj - half, h_adj - half,
            outline="#ff2222",
            width=BORDER_THICKNESS
        )

        BANNER_W, BANNER_H = 340, 42
        bx1 = (w_adj - BANNER_W) // 2
        by1 = 55
        bx2 = bx1 + BANNER_W
        by2 = by1 + BANNER_H

        b_bg = self.canvas.create_rectangle(
            bx1, by1, bx2, by2,
            fill="#12161c",
            outline="#ff3333",
            width=2
        )
        b_txt = self.canvas.create_text(
            (bx1 + bx2) // 2,
            (by1 + by2) // 2,
            text="AI is currently testing, please wait...",
            fill="#ffffff",
            font=("Segoe UI", 12, "bold")
        )
        self.banner_items = [b_bg, b_txt, (bx1, by1, bx2, by2)]

        if ICON_PATH.exists():
            pil_img = Image.open(ICON_PATH).resize((36, 36), Image.Resampling.LANCZOS)
            self.cursor_tk = ImageTk.PhotoImage(pil_img)
            self.cursor_item = self.canvas.create_image(
                self.current_cursor[0], self.current_cursor[1],
                image=self.cursor_tk,
                anchor="nw"
            )

        self.canvas.bind("<Button-1>", self._on_user_click)
        self.canvas.bind("<Button-2>", self._on_user_click)
        self.canvas.bind("<Button-3>", self._on_user_click)

        self.root.update()
        self.overlay_hwnd = int(self.root.frame(), 16) if hasattr(self.root, "frame") else None
        if not self.overlay_hwnd:
            self.overlay_hwnd = win32gui.FindWindow(None, "RobloxStudio_AI_Overlay")

        self.is_running = True

        # Launch stdin listener thread
        threading.Thread(target=self._listen_stdin, daemon=True).start()

        # Start pulsing & focus tracking loop
        self._pulse_and_track_focus(0)
        self.root.mainloop()

    def set_click_through(self, click_through: bool):
        if not self.overlay_hwnd:
            self.overlay_hwnd = win32gui.FindWindow(None, "RobloxStudio_AI_Overlay")
        if self.overlay_hwnd and self.is_click_through != click_through:
            ex = user32.GetWindowLongW(self.overlay_hwnd, GWL_EXSTYLE)
            if click_through:
                user32.SetWindowLongW(self.overlay_hwnd, GWL_EXSTYLE, ex | WS_EX_TRANSPARENT)
            else:
                user32.SetWindowLongW(self.overlay_hwnd, GWL_EXSTYLE, ex & ~WS_EX_TRANSPARENT)
            self.is_click_through = click_through

    def _pulse_and_track_focus(self, step):
        if not self.is_running or not self.root or not self.canvas:
            return

        fg = user32.GetForegroundWindow()
        user_on_studio = (fg == self.studio_hwnd or fg == self.overlay_hwnd)

        if user_on_studio:
            self.set_click_through(False)
            try:
                user32.SetWindowPos(self.overlay_hwnd, HWND_TOPMOST, 0, 0, 0, 0,
                                   SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE)
            except Exception:
                pass
        else:
            self.set_click_through(True)

        colors = ["#ff1111", "#ff2e2e", "#ff4747", "#ff6363", "#ff4747", "#ff2e2e"]
        col = colors[step % len(colors)]
        if self.border_item:
            self.canvas.itemconfig(self.border_item, outline=col)

        self.root.after(150, lambda: self._pulse_and_track_focus(step + 1))

    def _on_user_click(self, event):
        if not self.canvas or len(self.banner_items) < 2:
            return

        self.canvas.itemconfig(self.banner_items[0], fill="#3a0d0d", outline="#ffdd33", width=3)
        self.canvas.itemconfig(self.banner_items[1], text="AI is currently testing, please wait... [Input Blocked]", fill="#ffff55")

        cx, cy = event.x, event.y
        ripple = self.canvas.create_oval(cx - 5, cy - 5, cx + 5, cy + 5, outline="#ff2222", width=3)
        self._animate_denial_ripple(ripple, cx, cy, 5)

        if self._fade_job:
            self.root.after_cancel(self._fade_job)
        self._fade_job = self.root.after(1400, self._reset_banner)

    def _animate_denial_ripple(self, item, cx, cy, radius):
        if not self.is_running or not self.canvas:
            return
        if radius < 36:
            self.canvas.coords(item, cx - radius, cy - radius, cx + radius, cy + radius)
            self.root.after(20, lambda: self._animate_denial_ripple(item, cx, cy, radius + 4))
        else:
            self.canvas.delete(item)

    def _reset_banner(self):
        if self.canvas and len(self.banner_items) >= 2:
            self.canvas.itemconfig(self.banner_items[0], fill="#12161c", outline="#ff3333", width=2)
            self.canvas.itemconfig(self.banner_items[1], text="AI is currently testing, please wait...", fill="#ffffff")

    def _listen_stdin(self):
        while self.is_running:
            line = sys.stdin.readline()
            if not line:
                break
            line = line.strip()
            if not line:
                continue
            parts = line.split(" ", 2)
            cmd = parts[0].upper()
            if cmd == "STOP":
                self.is_running = False
                if self.root:
                    self.root.after_idle(self.root.destroy)
                break
            elif cmd == "BANNER" and len(parts) > 1:
                text = line[7:]
                if self.root:
                    self.root.after_idle(lambda t=text: self._update_banner(t))
            elif cmd == "GLIDE" and len(parts) >= 3:
                try:
                    tx, ty = int(parts[1]), int(parts[2])
                    dur = float(parts[3]) if len(parts) > 3 else 0.4
                    self._glide_cursor(tx, ty, dur)
                except Exception:
                    pass
            elif cmd == "CLICK" and len(parts) >= 3:
                try:
                    cx, cy = int(parts[1]), int(parts[2])
                    if self.root:
                        self.root.after_idle(lambda x=cx, y=cy: self._click_anim(x, y))
                except Exception:
                    pass

    def _update_banner(self, text: str):
        if self.canvas and len(self.banner_items) >= 2:
            self.canvas.itemconfig(self.banner_items[1], text=text)

    def _glide_cursor(self, target_x: int, target_y: int, duration: float):
        sx, sy = self.current_cursor
        steps = int(max(10, duration * 35))
        for i in range(1, steps + 1):
            t = i / steps
            ease = 1 - (1 - t) ** 3
            cx = sx + (target_x - sx) * ease
            cy = sy + (target_y - sy) * ease
            if self.root and self.canvas and self.cursor_item:
                self.root.after_idle(lambda x=cx, y=cy: self.canvas.coords(self.cursor_item, x, y) if self.canvas and self.cursor_item else None)
            time.sleep(duration / steps)
        self.current_cursor = (target_x, target_y)

    def _click_anim(self, cx: int, cy: int):
        if not self.canvas:
            return
        if self.cursor_item:
            self.canvas.move(self.cursor_item, 2, 2)
            self.root.after(60, lambda: self.canvas.move(self.cursor_item, -2, -2) if self.canvas and self.cursor_item else None)

        ripple = self.canvas.create_oval(cx - 3, cy - 3, cx + 3, cy + 3, outline="#ffd700", width=3)
        self._animate_click_ripple(ripple, cx, cy, 4)

    def _animate_click_ripple(self, item, cx, cy, radius):
        if not self.is_running or not self.canvas or not self.root:
            return
        if radius < 32:
            self.canvas.coords(item, cx - radius, cy - radius, cx + radius, cy + radius)
            self.root.after(18, lambda: self._animate_click_ripple(item, cx, cy, radius + 4))
        else:
            self.canvas.delete(item)


class StudioWindowOverlay:
    """Client class used by ai_playtest_runner. Controls overlay via subprocess."""
    def __init__(self, studio_hwnd: int):
        self.studio_hwnd = studio_hwnd
        self.proc: Optional[subprocess.Popen] = None

    def start(self):
        script_path = str(Path(__file__).resolve())
        self.proc = subprocess.Popen(
            [sys.executable, script_path, str(self.studio_hwnd)],
            stdin=subprocess.PIPE,
            text=True,
            bufsize=1
        )
        time.sleep(0.4)

    def update_banner_text(self, text: str):
        if self.proc and self.proc.stdin:
            try:
                self.proc.stdin.write(f"BANNER {text}\n")
                self.proc.stdin.flush()
            except Exception:
                pass

    def glide_cursor(self, target_x: int, target_y: int, duration: float = 0.5):
        if self.proc and self.proc.stdin:
            try:
                self.proc.stdin.write(f"GLIDE {target_x} {target_y} {duration}\n")
                self.proc.stdin.flush()
                time.sleep(duration)
            except Exception:
                pass

    def play_click_animation(self, cx: int, cy: int):
        if self.proc and self.proc.stdin:
            try:
                self.proc.stdin.write(f"CLICK {cx} {cy}\n")
                self.proc.stdin.flush()
                time.sleep(0.12)
            except Exception:
                pass

    def stop(self):
        if self.proc:
            try:
                if self.proc.stdin:
                    self.proc.stdin.write("STOP\n")
                    self.proc.stdin.flush()
                self.proc.terminate()
                self.proc.wait(timeout=2.0)
            except Exception:
                pass
            self.proc = None

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1].isdigit():
        hwnd = int(sys.argv[1])
    else:
        hwnd, _ = find_studio_window()

    if hwnd:
        server = StudioWindowOverlayServer(hwnd)
        server.run()
