import sys
from pathlib import Path
import uiautomation as auto

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "bridge"))
from window_overlay import find_studio_window, attach_desktop

attach_desktop()
hwnd, title = find_studio_window()
print(f"Studio HWND: {hwnd}, Title: {title}")

studio = auto.ControlFromHandle(hwnd)
print("Studio Control:", studio)

# Search for play buttons or simulation controls
play_btn = studio.ButtonControl(AutomationId="RibbonMainWindow.simulationPlayAction")
if play_btn.Exists(maxSearchSeconds=1):
    print("Found simulationPlayAction:", play_btn.BoundingRectangle)
else:
    print("simulationPlayAction not found by AutomationId, searching buttons...")
    for btn, depth in auto.WalkTree(studio, getChildren=auto.GetChildren):
        if btn.ControlType == auto.ControlType.ButtonControl:
            name = btn.Name
            auto_id = btn.AutomationId
            if "play" in name.lower() or "play" in auto_id.lower() or "simulation" in auto_id.lower():
                print(f"Candidate Button: Name='{name}', AutomationId='{auto_id}', Rect={btn.BoundingRectangle}")
