"""
scratch/test_invoke_play.py
Directly invokes 'RibbonMainWindow.simulationPlayAction' via UIAutomation.
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

print("Navigating to Play Action...")
test_menu = studio.MenuItemControl(Name="Test")
test_menu.GetExpandCollapsePattern().Expand()
time.sleep(0.15)

session_item = studio.MenuItemControl(Name="Start Test Session")
session_item.GetExpandCollapsePattern().Expand()
time.sleep(0.15)

play_action = session_item.MenuItemControl(AutomationId="RibbonMainWindow.simulationPlayAction")
print(f"Found play_action: {play_action.Exists(0, 0)}")

# Invoke Play!
invoke = play_action.GetInvokePattern()
if invoke:
    invoke.Invoke()
    print("[SUCCESS] Play action invoked via InvokePattern!")
else:
    play_action.Click(simulateMove=False)
    print("[SUCCESS] Play action clicked via UIA!")

print("Waiting 6 seconds for Play Mode to launch in Studio...")
time.sleep(6.0)

# Check status via bridge
code = """
local rs = game:GetService("RunService")
local Players = game:GetService("Players")
local p = Players.LocalPlayer
local char = p and p.Character
return "IsRunning=" .. tostring(rs:IsRunning()) .. ", Player=" .. tostring(p and p.Name) .. ", Char=" .. tostring(char and char.Name)
"""
ok, out = exec_code(code, timeout=10.0)
print(f"Studio Status: {ok} | {out}")
