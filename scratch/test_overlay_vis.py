import sys
import time
from pathlib import Path
from PIL import ImageGrab
import win32gui

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "bridge"))
from window_overlay import find_studio_window, StudioWindowOverlay, attach_desktop

attach_desktop()
hwnd, title = find_studio_window()
print(f"Studio HWND={hwnd}, Title='{title}'")

overlay = StudioWindowOverlay(hwnd)
print("Starting overlay...")
overlay.start()
time.sleep(1.0)

print("Capturing desktop screenshot while overlay is up...")
rect = win32gui.GetWindowRect(hwnd)
img = ImageGrab.grab(bbox=rect, all_screens=True)
out_path = Path(__file__).resolve().parent / "overlay_test.png"
img.save(out_path)
print(f"Saved to {out_path}")

time.sleep(1.0)
overlay.stop()
print("Done!")
