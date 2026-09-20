"""
scratch/list_test_menu_items.py
"""
import uiautomation as auto
import ctypes
import time

user32 = ctypes.windll.user32
hwinsta = user32.OpenWindowStationW("WinSta0", False, 0x10000000)
if hwinsta: user32.SetProcessWindowStation(hwinsta)
hdesk = user32.OpenDesktopW("Default", 0, False, 0x10000000)
if hdesk: user32.SetThreadDesktop(hdesk)

studio = auto.ControlFromHandle(132588)
test_menu = studio.MenuItemControl(Name="Test")
expand = test_menu.GetExpandCollapsePattern()
if expand:
    expand.Expand()
    time.sleep(0.3)

# Search for Menu / MenuItems under studio and root
items = []
for c in test_menu.GetChildren():
    print(f"Child of test_menu: {c.ControlTypeName} '{c.Name}'")

for ctrl, depth in auto.WalkControl(studio, maxDepth=8):
    if ctrl.ControlTypeName == "MenuItemControl" and ctrl.Name != "Test":
        print(f"  MenuItem: '{ctrl.Name}' (AutoId='{ctrl.AutomationId}', Shortcut='{ctrl.AcceleratorKey}')")
