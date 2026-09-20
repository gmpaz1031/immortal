"""
scratch/test_click_play.py
Clicks the play action MenuItem.
"""
import uiautomation as auto
import ctypes
import time
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from bridge.exec import exec_code

user32 = ctypes.windll.user32
hwinsta = user32.OpenWindowStationW("WinSta0", False, 0x10000000)
if hwinsta: user32.SetProcessWindowStation(hwinsta)
hdesk = user32.OpenDesktopW("Default", 0, False, 0x10000000)
if hdesk: user32.SetThreadDesktop(hdesk)

studio = auto.ControlFromHandle(132588)

test_menu = studio.MenuItemControl(Name="Test")
test_menu.GetExpandCollapsePattern().Expand()
time.sleep(0.15)

session_item = studio.MenuItemControl(Name="Start Test Session")
session_item.GetExpandCollapsePattern().Expand()
time.sleep(0.15)

play_action = session_item.MenuItemControl(AutomationId="RibbonMainWindow.simulationPlayAction")
rect = play_action.BoundingRectangle
print(f"Play action rect: {rect}")

# Click it directly
play_action.Click(simulateMove=False)
print("Clicked Play Action!")

time.sleep(5.0)

code = """
local rs = game:GetService("RunService")
return "IsRunning=" .. tostring(rs:IsRunning())
"""
ok, out = exec_code(code)
print(f"IsRunning: {ok} | {out}")
