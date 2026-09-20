"""
scratch/test_tk_overlay.py
Tests opening a transparent Tkinter overlay on WinSta0\\Default.
"""
import ctypes
import tkinter as tk
import time

user32 = ctypes.windll.user32
hwinsta = user32.OpenWindowStationW("WinSta0", False, 0x10000000)
if hwinsta: user32.SetProcessWindowStation(hwinsta)
hdesk = user32.OpenDesktopW("Default", 0, False, 0x10000000)
if hdesk: user32.SetThreadDesktop(hdesk)

root = tk.Tk()
root.title("OverlayTest")
root.geometry("300x200+100+100")
root.update()
print(f"Tkinter window created successfully! HWND={root.winfo_id()}")
time.sleep(1)
root.destroy()
print("Destroyed successfully!")
