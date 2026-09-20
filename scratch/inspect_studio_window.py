import sys
from pathlib import Path
import win32gui
import win32con
import win32process
import ctypes

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "bridge"))
from window_overlay import find_studio_window, attach_desktop

attach_desktop()
hwnd, title = find_studio_window()
print(f"Studio HWND: {hwnd}, Title: {title}")

# Enumerate child windows
children = []
def enum_child(child_hwnd, _):
    c_title = win32gui.GetWindowText(child_hwnd)
    c_class = win32gui.GetClassName(child_hwnd)
    c_rect = win32gui.GetWindowRect(child_hwnd)
    if win32gui.IsWindowVisible(child_hwnd):
        children.append((child_hwnd, c_class, c_title, c_rect))
win32gui.EnumChildWindows(hwnd, enum_child, None)

print(f"Total visible child windows: {len(children)}")
for ch, cls, t, rect in children[:25]:
    print(f"  Child: {ch} | Class: {cls} | Text: '{t}' | Rect: {rect}")
