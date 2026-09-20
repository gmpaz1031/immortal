import sys
from pathlib import Path
import ctypes
import win32gui
import win32ui
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from test_find_studio import get_studio_hwnd

hwnd, title = get_studio_hwnd()
print(f"Studio HWND: {hwnd}, Title: {title}")

rect = win32gui.GetWindowRect(hwnd)
w = rect[2] - rect[0]
h = rect[3] - rect[1]
print(f"Dimensions: {w}x{h}")

hwndDC = win32gui.GetWindowDC(hwnd)
mfcDC = win32ui.CreateDCFromHandle(hwndDC)
saveDC = mfcDC.CreateCompatibleDC()

saveBitMap = win32ui.CreateBitmap()
saveBitMap.CreateCompatibleBitmap(mfcDC, w, h)
saveDC.SelectObject(saveBitMap)

user32 = ctypes.windll.user32
PW_RENDERFULLCONTENT = 2
result = user32.PrintWindow(hwnd, saveDC.GetSafeHdc(), PW_RENDERFULLCONTENT)
print("PrintWindow result:", result)

bmpinfo = saveBitMap.GetInfo()
bmpstr = saveBitMap.GetBitmapBits(True)
im = Image.frombuffer('RGB', (bmpinfo['bmWidth'], bmpinfo['bmHeight']), bmpstr, 'raw', 'BGRX', 0, 1)

out_path = Path(__file__).resolve().parent / "printwindow_test.png"
im.save(out_path)
print("Saved to", out_path)

win32gui.DeleteObject(saveBitMap.GetHandle())
saveDC.DeleteDC()
mfcDC.DeleteDC()
win32gui.ReleaseDC(hwnd, hwndDC)
