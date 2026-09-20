import sys
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
print(f"Studio HWND={hwnd}")

# Screen coordinates of the play button
# Since studio window is at (-8, -8) or (0, 0), client coords:
play_x = 121
play_y = 68

# Find child at (play_x, play_y)
pt = (play_x, play_y)
child = win32gui.ChildWindowFromPoint(hwnd, pt)
print(f"ChildWindowFromPoint at {pt}: {child}, Class: {win32gui.GetClassName(child) if child else None}")

# If child has its own children:
if child and child != hwnd:
    # Convert point to child's client coords
    c_rect = win32gui.GetWindowRect(child)
    rel_x = play_x - c_rect[0]
    rel_y = play_y - c_rect[1]
    print(f"Child rect: {c_rect}, relative pos: ({rel_x}, {rel_y})")
    subchild = win32gui.ChildWindowFromPoint(child, (rel_x, rel_y))
    print(f"Subchild: {subchild}, Class: {win32gui.GetClassName(subchild) if subchild else None}")
