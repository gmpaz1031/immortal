"""
scratch/inspect_menubar.py
"""
import uiautomation as auto
import ctypes

user32 = ctypes.windll.user32
hwinsta = user32.OpenWindowStationW("WinSta0", False, 0x10000000)
if hwinsta: user32.SetProcessWindowStation(hwinsta)
hdesk = user32.OpenDesktopW("Default", 0, False, 0x10000000)
if hdesk: user32.SetThreadDesktop(hdesk)

studio = auto.ControlFromHandle(132588)

for ctrl, depth in auto.WalkControl(studio, maxDepth=5):
    if ctrl.ControlTypeName in ("MenuItemControl", "MenuControl", "MenuBarControl"):
        print(f"[{depth}] {ctrl.ControlTypeName}: '{ctrl.Name}' (Rect={ctrl.BoundingRectangle})")
