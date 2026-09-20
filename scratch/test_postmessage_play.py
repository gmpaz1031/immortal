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

hwnd = 132588 # Studio HWND
# Check if Studio has ribbon child
def find_ribbon(parent):
    children = []
    def cb(h, _):
        if win32gui.IsWindowVisible(h):
            children.append(h)
    win32gui.EnumChildWindows(parent, cb, None)
    return children

children = find_ribbon(hwnd)
print("Visible children count:", len(children))

# Target ribbon toolbar
# The ribbon toolbar was HWND 132326 or child with rect around (0, 43, 1920, 138)
ribbon_hwnd = None
for ch in children:
    rect = win32gui.GetWindowRect(ch)
    if rect[1] in (43, 23) and rect[2] >= 1900:
        ribbon_hwnd = ch
        break

print(f"Found ribbon child: {ribbon_hwnd}")
if ribbon_hwnd:
    c_rect = win32gui.GetWindowRect(ribbon_hwnd)
    # Play button relative pos
    play_rel_x = 121 - c_rect[0]
    play_rel_y = 68 - c_rect[1]
    lParam = win32api.MAKELONG(play_rel_x, play_rel_y)
    print(f"Sending PostMessage to {ribbon_hwnd} at rel coords: ({play_rel_x}, {play_rel_y})")
    win32api.PostMessage(ribbon_hwnd, win32con.WM_LBUTTONDOWN, win32con.MK_LBUTTON, lParam)
    time.sleep(0.05)
    win32api.PostMessage(ribbon_hwnd, win32con.WM_LBUTTONUP, 0, lParam)

print("Posted message without stealing focus or moving cursor.")
