import ctypes
import win32gui

user32 = ctypes.windll.user32
hdesk = user32.OpenDesktopW("Default", 0, False, 0x10000000)
hwinsta = user32.OpenWindowStationW("WinSta0", False, 0x10000000)
if hwinsta: user32.SetProcessWindowStation(hwinsta)
if hdesk: user32.SetThreadDesktop(hdesk)

print("Testing EnumWindows...")
res = []
try:
    def cb(h, _):
        t = win32gui.GetWindowText(h)
        if "Roblox Studio" in t:
            res.append((h, t))
    win32gui.EnumWindows(cb, None)
    print("EnumWindows result:", res)
except Exception as e:
    print("EnumWindows exception:", e)

print("Testing EnumDesktopWindows...")
res2 = []
try:
    def cb2(h, _):
        t = win32gui.GetWindowText(h)
        if "Roblox Studio" in t:
            res2.append((h, t))
    win32gui.EnumDesktopWindows(hdesk, cb2, None)
    print("EnumDesktopWindows result:", res2)
except Exception as e:
    print("EnumDesktopWindows exception:", e)
