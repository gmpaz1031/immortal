import sys
import time
from pathlib import Path
import win32gui
import win32con
import win32api
import ctypes

user32 = ctypes.windll.user32
hwinsta = user32.OpenWindowStationW("WinSta0", False, 0x10000000)
if hwinsta: user32.SetProcessWindowStation(hwinsta)
hdesk = user32.OpenDesktopW("Default", 0, False, 0x10000000)
if hdesk: user32.SetThreadDesktop(hdesk)

hwnd = 132588
ribbon_hwnd = 459852

c_rect = win32gui.GetWindowRect(ribbon_hwnd)
stop_rel_x = 196 - c_rect[0]
stop_rel_y = 68 - c_rect[1]
lParam = win32api.MAKELONG(stop_rel_x, stop_rel_y)

print(f"Posting stop click to {ribbon_hwnd} at ({stop_rel_x}, {stop_rel_y})")
win32api.PostMessage(ribbon_hwnd, win32con.WM_LBUTTONDOWN, win32con.MK_LBUTTON, lParam)
time.sleep(0.05)
win32api.PostMessage(ribbon_hwnd, win32con.WM_LBUTTONUP, 0, lParam)

print("Posted stop message. Waiting 3s to check status...")
time.sleep(3.0)

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "bridge"))
from exec import exec_code
ok, out = exec_code("local r = game:GetService('RunService'); return 'IsRunning=' .. tostring(r:IsRunning()) .. ' IsEdit=' .. tostring(r:IsEdit())")
print("Status:", out)
