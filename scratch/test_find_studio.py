import ctypes
import win32gui

user32 = ctypes.windll.user32

def get_studio_hwnd():
    hwinsta = user32.OpenWindowStationW("WinSta0", False, 0x10000000)
    if hwinsta:
        user32.SetProcessWindowStation(hwinsta)
    hdesk = user32.OpenDesktopW("Default", 0, False, 0x10000000)
    if hdesk:
        user32.SetThreadDesktop(hdesk)

    res = []
    def cb(h, _):
        if win32gui.IsWindowVisible(h):
            t = win32gui.GetWindowText(h)
            if "Roblox Studio" in t:
                res.append((h, t))
    for _ in range(5):
        try:
            win32gui.EnumWindows(cb, None)
            if res:
                break
        except Exception as e:
            import time
            time.sleep(0.1)
    return res[0] if res else (None, None)

print(get_studio_hwnd())
