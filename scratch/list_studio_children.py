"""
scratch/list_studio_children.py
Lists all child windows and classes of Roblox Studio HWND.
"""
import win32gui

studio_hwnd = 132588
children = []

def enum_child(hwnd, _):
    cls = win32gui.GetClassName(hwnd)
    txt = win32gui.GetWindowText(hwnd)
    children.append((hwnd, cls, txt))

win32gui.EnumChildWindows(studio_hwnd, enum_child, None)
print(f"Studio has {len(children)} child windows:")
for h, c, t in children[:20]:
    print(f"  HWND={h}, Class='{c}', Text='{t}'")
