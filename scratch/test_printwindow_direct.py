import ctypes
import win32gui
import win32ui
from PIL import Image
from pathlib import Path

user32 = ctypes.windll.user32
hwinsta = user32.OpenWindowStationW("WinSta0", False, 0x10000000)
if hwinsta: user32.SetProcessWindowStation(hwinsta)
hdesk = user32.OpenDesktopW("Default", 0, False, 0x10000000)
if hdesk: user32.SetThreadDesktop(hdesk)

hwnd = 132588
if not win32gui.IsWindow(hwnd):
    # Find dynamically
    def cb(h, extra):
        if win32gui.IsWindowVisible(h) and "Roblox Studio" in win32gui.GetWindowText(h):
            extra.append(h)
    lst = []
    win32gui.EnumWindows(cb, lst)
    hwnd = lst[0] if lst else 0

print("HWND:", hwnd, win32gui.GetWindowText(hwnd))
rect = win32gui.GetWindowRect(hwnd)
w = rect[2] - rect[0]
h = rect[3] - rect[1]
print(f"Rect: {rect}, Size: {w}x{h}")

hwndDC = win32gui.GetWindowDC(hwnd)
mfcDC = win32ui.CreateDCFromHandle(hwndDC)
saveDC = mfcDC.CreateCompatibleDC()

saveBitMap = win32ui.CreateBitmap()
saveBitMap.CreateCompatibleBitmap(mfcDC, w, h)
saveDC.SelectObject(saveBitMap)

PW_RENDERFULLCONTENT = 2
result = user32.PrintWindow(hwnd, saveDC.GetSafeHdc(), PW_RENDERFULLCONTENT)
print("PrintWindow result:", result)

bmpinfo = saveBitMap.GetInfo()
bmpstr = saveBitMap.GetBitmapBits(True)
im = Image.frombuffer('RGB', (bmpinfo['bmWidth'], bmpinfo['bmHeight']), bmpstr, 'raw', 'BGRX', 0, 1)

out_path = Path(__file__).resolve().parent / "printwindow_direct.png"
im.save(out_path)
print("Saved to", out_path)

win32gui.DeleteObject(saveBitMap.GetHandle())
saveDC.DeleteDC()
mfcDC.DeleteDC()
win32gui.ReleaseDC(hwnd, hwndDC)
