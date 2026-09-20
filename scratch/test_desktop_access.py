"""
scratch/test_desktop_access.py
Attaches to WinSta0\\Default to find interactive windows.
"""
import ctypes
import win32gui

user32 = ctypes.windll.user32

hwinsta = user32.OpenWindowStationW("WinSta0", False, 0x10000000) # MAXIMUM_ALLOWED
print(f"hwinsta: {hwinsta}")
if hwinsta:
    user32.SetProcessWindowStation(hwinsta)

hdesk = user32.OpenDesktopW("Default", 0, False, 0x10000000)
print(f"hdesk: {hdesk}")
if hdesk:
    user32.SetThreadDesktop(hdesk)

windows = []
def enum_cb(hwnd, _):
    if win32gui.IsWindowVisible(hwnd):
        t = win32gui.GetWindowText(hwnd)
        if t:
            windows.append((hwnd, t))

win32gui.EnumWindows(enum_cb, None)
print(f"Total visible windows: {len(windows)}")
for h, t in windows:
    if "Roblox" in t or "immortal" in t.lower():
        print(f"  MATCH: HWND={h}, Title='{t}'")
