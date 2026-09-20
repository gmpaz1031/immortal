"""
scratch/test_overlay_run.py
"""
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "bridge"))
from window_overlay import find_studio_window, StudioWindowOverlay

hwnd, title = find_studio_window()
print(f"Found Studio: HWND={hwnd}, Title='{title}'")

if not hwnd:
    print("Error: Studio not found")
    sys.exit(1)

overlay = StudioWindowOverlay(hwnd)
print("Starting overlay...")
overlay.start()

print("Gliding cursor to Play button area...")
overlay.glide_cursor(60, 60, duration=0.6)
overlay.play_click_animation(60, 60)

overlay.update_banner_text("AI Testing: Virtual Cursor Clicked!")
time.sleep(1.0)

print("Gliding cursor to bottom center (Hotbar area)...")
overlay.glide_cursor(700, 750, duration=0.6)
overlay.play_click_animation(700, 750)

time.sleep(2.0)
print("Stopping overlay...")
overlay.stop()
print("Done!")
