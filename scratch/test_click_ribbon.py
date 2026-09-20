import sys
import time
from pathlib import Path
import win32gui
import win32con
import win32api
import ctypes

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "bridge"))
from window_overlay import find_studio_window, attach_desktop
from exec import exec_code

attach_desktop()
hwnd, title = find_studio_window()

# Target is the ribbon subchild 132326
# Let's get the exact subchild dynamically
play_screen_x = 121
play_screen_y = 68

subchild = 132326 # or dynamically find
c_rect = win32gui.GetWindowRect(subchild)
rel_x = play_screen_x - c_rect[0]
rel_y = play_screen_y - c_rect[1]

print(f"Ribbon HWND={subchild}, rect={c_rect}, relative click at ({rel_x}, {rel_y})")

lParam = win32api.MAKELONG(rel_x, rel_y)

# Send WM_LBUTTONDOWN and WM_LBUTTONUP
win32gui.SendMessage(subchild, win32con.WM_LBUTTONDOWN, win32con.MK_LBUTTON, lParam)
time.sleep(0.05)
win32gui.SendMessage(subchild, win32con.WM_LBUTTONUP, 0, lParam)

print("Sent click messages. Waiting 3s to check RunService...")
time.sleep(3.0)

ok, out = exec_code("return 'IsRunning=' .. tostring(game:GetService('RunService'):IsRunning())")
print("Result:", out)
