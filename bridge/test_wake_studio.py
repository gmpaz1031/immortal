import sys, os
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import win32gui, win32con, win32api, time, urllib.request, json
from window_overlay import find_studio_window, attach_desktop

attach_desktop()
hwnd, _ = find_studio_window()
print(f"Studio HWND: {hwnd}")

def get_status():
    try:
        return json.loads(urllib.request.urlopen('http://127.0.0.1:34875/status', timeout=1.0).read().decode())
    except Exception as e:
        return {"error": str(e)}

print("Initial Status:", get_status())

# Test 1: Send WM_MOUSEMOVE to Studio main window at (100, 100)
print("\n--- Test 1: WM_MOUSEMOVE to Studio window ---")
lParam = win32api.MAKELONG(100, 100)
win32api.PostMessage(hwnd, win32con.WM_MOUSEMOVE, 0, lParam)
time.sleep(1.0)
print("Status after WM_MOUSEMOVE:", get_status())

# Test 2: Find intermediate D3D window and send WM_MOUSEMOVE
d3d_windows = []
def enum(h, _):
    cls = win32gui.GetClassName(h)
    if "D3D" in cls or "Qt" in cls:
        d3d_windows.append(h)
win32gui.EnumChildWindows(hwnd, enum, None)

print(f"\n--- Test 2: WM_MOUSEMOVE to {len(d3d_windows)} child windows ---")
for ch in d3d_windows:
    win32api.PostMessage(ch, win32con.WM_MOUSEMOVE, 0, lParam)
time.sleep(1.0)
print("Status after child WM_MOUSEMOVE:", get_status())
