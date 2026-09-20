"""
scratch/find_all_buttons.py
"""
import uiautomation as auto
import ctypes

user32 = ctypes.windll.user32
hwinsta = user32.OpenWindowStationW("WinSta0", False, 0x10000000)
if hwinsta: user32.SetProcessWindowStation(hwinsta)
hdesk = user32.OpenDesktopW("Default", 0, False, 0x10000000)
if hdesk: user32.SetThreadDesktop(hdesk)

studio = auto.ControlFromHandle(132588)

for ctrl, depth in auto.WalkControl(studio, maxDepth=12):
    t = ctrl.ControlTypeName
    name = ctrl.Name
    aid = ctrl.AutomationId
    if "button" in t.lower() or "play" in name.lower() or "play" in aid.lower():
        if name or aid:
            print(f"  [{depth}] {t}: Name='{name}', AutoId='{aid}'")
