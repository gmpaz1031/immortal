"""
scratch/inspect_start_test.py
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
if session_item.Exists(0, 0):
    print("Found 'Start Test Session'!")
    exp = session_item.GetExpandCollapsePattern()
    if exp:
        exp.Expand()
        time.sleep(0.2)
    for c in session_item.GetChildren():
        print(f"  Child: {c.ControlTypeName} '{c.Name}' (AutoId='{c.AutomationId}')")

for ctrl, _ in auto.WalkControl(studio, maxDepth=10):
    if "play" in ctrl.Name.lower():
        print(f"  Play Match: {ctrl.ControlTypeName} '{ctrl.Name}' (AutoId='{ctrl.AutomationId}')")
