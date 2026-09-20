"""
scratch/test_uia_play.py
Uses UIAutomation to find and click the 'Play' button in Roblox Studio.
"""
import uiautomation as auto
import time
import ctypes

user32 = ctypes.windll.user32
hwinsta = user32.OpenWindowStationW("WinSta0", False, 0x10000000)
if hwinsta: user32.SetProcessWindowStation(hwinsta)
hdesk = user32.OpenDesktopW("Default", 0, False, 0x10000000)
if hdesk: user32.SetThreadDesktop(hdesk)

studio = auto.ControlFromHandle(132588)
print(f"Studio Control: {studio.Exists(0, 0)}")
if studio.Exists(0, 0):
    print(f"Studio Name: {studio.Name}, Handle: {studio.NativeWindowHandle}")
    
    # Search for Play button
    play_btn = studio.ButtonControl(Name="Play")
    if not play_btn.Exists(0, 1):
        # Search anywhere in descendants
        for btn in studio.GetChildren():
            print(f"  Child: {btn.ControlTypeName} '{btn.Name}'")
            if btn.Name == "Play":
                play_btn = btn
                break

    print(f"Play button found: {play_btn.Exists(0, 0)}")
    if play_btn.Exists(0, 0):
        print(f"Clicking Play button via UIA pattern...")
        # InvokePattern triggers the button action WITHOUT moving the mouse cursor!
        invoke = play_btn.GetInvokePattern()
        if invoke:
            invoke.Invoke()
            print("Invoked successfully!")
        else:
            play_btn.Click(simulateMove=False)
            print("Clicked via UIA!")
