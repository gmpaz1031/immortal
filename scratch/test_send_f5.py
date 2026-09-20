"""
scratch/test_send_f5.py
Tests sending F5 to Roblox Studio to enter Playtest mode.
"""
import ctypes
import time
import win32gui
import win32con
import win32api

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
print(f"Studio HWND: {studio_hwnd}")

if not studio_hwnd:
    print("Studio not found!")
    exit(1)

# Check if Studio is already running/playing
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from bridge.exec import exec_code
ok, out = exec_code("return game:GetService('RunService'):IsRunning()")
print(f"Before F5: IsRunning={out}")

# Send F5 via PostMessage
# Note: In Qt / Roblox Studio, the main window accelerator receives WM_KEYDOWN / WM_COMMAND
scan = win32api.MapVirtualKey(win32con.VK_F5, 0)
lp_dn = 1 | (scan << 16)
lp_up = 1 | (scan << 16) | (1 << 30) | (1 << 31)

print("Posting F5 to Studio...")
win32api.PostMessage(studio_hwnd, win32con.WM_KEYDOWN, win32con.VK_F5, lp_dn)
time.sleep(0.05)
win32api.PostMessage(studio_hwnd, win32con.WM_KEYUP, win32con.VK_F5, lp_up)

# Wait 4 seconds for Play mode to initialize
print("Waiting 4s for play mode...")
time.sleep(4.0)

ok, out = exec_code("local rs = game:GetService('RunService'); return 'IsRunning=' .. tostring(rs:IsRunning()) .. ', Player=' .. tostring(game:GetService('Players').LocalPlayer ~= nil)", timeout=8.0)
print(f"After F5: {ok} | {out}")
