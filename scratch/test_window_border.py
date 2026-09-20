"""
scratch/test_window_border.py
Tests drawing a red border around the ENTIRE Roblox Studio window using a Tkinter transparent overlay.
"""
import ctypes
import time
import tkinter as tk
from PIL import Image, ImageTk
import win32gui

user32 = ctypes.windll.user32
hwinsta = user32.OpenWindowStationW("WinSta0", False, 0x10000000)
if hwinsta: user32.SetProcessWindowStation(hwinsta)
hdesk = user32.OpenDesktopW("Default", 0, False, 0x10000000)
if hdesk: user32.SetThreadDesktop(hdesk)

studio_hwnd = None
def enum_cb(hwnd, _):
    global studio_hwnd
    if win32gui.IsWindowVisible(hwnd):
        t = win32gui.GetWindowText(hwnd)
        if "Roblox Studio" in t:
            studio_hwnd = hwnd

win32gui.EnumWindows(enum_cb, None)
if not studio_hwnd:
    print("Studio window not found!")
    exit(1)

rect = win32gui.GetWindowRect(studio_hwnd)
print(f"Studio Rect: {rect}")
x, y, r, b = rect
w = r - x
h = b - y

# If maximized, Windows offsets by -8, -8
# We adjust to fit the visible screen
x_adj = max(0, x)
y_adj = max(0, y)
w_adj = w - (x_adj - x)
h_adj = h - (y_adj - y)

root = tk.Tk()
root.title("StudioAIOverlay")
root.overrideredirect(True) # No OS window frame
root.wm_attributes("-topmost", True)
root.wm_attributes("-transparentcolor", "#010101")
root.geometry(f"{w_adj}x{h_adj}+{x_adj}+{y_adj}")
root.configure(bg="#010101")

canvas = tk.Canvas(root, width=w_adj, height=h_adj, bg="#010101", highlightthickness=0)
canvas.pack(fill="both", expand=True)

# 1. Red Border around the ENTIRE Roblox Studio window
BORDER_THICKNESS = 8
canvas.create_rectangle(
    BORDER_THICKNESS // 2,
    BORDER_THICKNESS // 2,
    w_adj - BORDER_THICKNESS // 2,
    h_adj - BORDER_THICKNESS // 2,
    outline="#ff2323",
    width=BORDER_THICKNESS
)

# 2. Notification Banner at top center of Studio window
banner_w = 380
banner_h = 44
bx1 = (w_adj - banner_w) // 2
by1 = 28
bx2 = bx1 + banner_w
by2 = by1 + banner_h

# Draw banner background & red outline
canvas.create_rectangle(bx1, by1, bx2, by2, fill="#12161c", outline="#ff3333", width=2)
canvas.create_text(
    (bx1 + bx2) // 2,
    (by1 + by2) // 2,
    text="AI is currently testing, please wait...",
    fill="#ffffff",
    font=("Segoe UI", 12, "bold")
)

# 3. Virtual Cursor
cursor_pil = Image.open("assets/icons/ai_cursor.png").resize((36, 36), Image.Resampling.LANCZOS)
cursor_tk = ImageTk.PhotoImage(cursor_pil)
cursor_item = canvas.create_image(w_adj // 2, h_adj // 2, image=cursor_tk, anchor="nw")

print("Overlay displayed! Running for 4 seconds...")
root.update()
time.sleep(4.0)

root.destroy()
print("Test completed successfully!")
