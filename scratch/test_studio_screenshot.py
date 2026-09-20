"""
scratch/test_studio_screenshot.py
Tests capturing the entire Roblox Studio window from Python.
"""
import ctypes
import time
from pathlib import Path
from PIL import Image, ImageGrab
import win32gui

user32 = ctypes.windll.user32
hwinsta = user32.OpenWindowStationW("WinSta0", False, 0x10000000)
if hwinsta: user32.SetProcessWindowStation(hwinsta)
hdesk = user32.OpenDesktopW("Default", 0, False, 0x10000000)
if hdesk: user32.SetThreadDesktop(hdesk)

studio_hwnd = None
def enum_cb(hwnd, _):
    global studio_hwnd
    if win32gui.IsWindowVisible(hwnd):
        t = win32gui.GetWindowText(hwnd)
        if "Roblox Studio" in t:
            studio_hwnd = hwnd

win32gui.EnumWindows(enum_cb, None)
if not studio_hwnd:
    print("Studio not found!")
    exit(1)

rect = win32gui.GetWindowRect(studio_hwnd)
print(f"Studio Rect: {rect}")
x, y, r, b = rect
# Clamp to monitor
x1 = max(0, x)
y1 = max(0, y)
x2 = max(x1 + 100, r)
y2 = max(y1 + 100, b)

try:
    img = ImageGrab.grab(bbox=(x1, y1, x2, y2), all_screens=True)
    out = Path("assets/screenshots/studio_window_capture.png")
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    print(f"[SUCCESS] Saved Studio window screenshot: {out} ({img.size})")
except Exception as e:
    print(f"[FAIL] ImageGrab failed: {e}")
