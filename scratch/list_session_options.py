"""
scratch/list_session_options.py
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
test_menu.GetExpandCollapsePattern().Expand()
time.sleep(0.2)

session_item = studio.MenuItemControl(Name="Start Test Session")
session_item.GetExpandCollapsePattern().Expand()
time.sleep(0.2)

menu_ctrl = session_item.MenuControl(AutomationId="Test.StartTestSession")
for c in menu_ctrl.GetChildren():
    print(f"Option: {c.ControlTypeName} '{c.Name}' (AutoId='{c.AutomationId}')")
