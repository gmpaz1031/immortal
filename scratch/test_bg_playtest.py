import sys
import time
from pathlib import Path
import ctypes
import win32gui
import win32ui
import win32con
import win32api
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "bridge"))
from exec import exec_code

user32 = ctypes.windll.user32
hwinsta = user32.OpenWindowStationW("WinSta0", False, 0x10000000)
if hwinsta: user32.SetProcessWindowStation(hwinsta)
hdesk = user32.OpenDesktopW("Default", 0, False, 0x10000000)
if hdesk: user32.SetThreadDesktop(hdesk)

hwnd = 132588
ribbon_hwnd = 459852

def capture_window_pure(hwnd: int, save_path: Path):
    rect = win32gui.GetWindowRect(hwnd)
    w = rect[2] - rect[0]
    h = rect[3] - rect[1]

    hwndDC = win32gui.GetWindowDC(hwnd)
    mfcDC = win32ui.CreateDCFromHandle(hwndDC)
    saveDC = mfcDC.CreateCompatibleDC()

    saveBitMap = win32ui.CreateBitmap()
    saveBitMap.CreateCompatibleBitmap(mfcDC, w, h)
    saveDC.SelectObject(saveBitMap)

    PW_RENDERFULLCONTENT = 2
    user32.PrintWindow(hwnd, saveDC.GetSafeHdc(), PW_RENDERFULLCONTENT)

    bmpinfo = saveBitMap.GetInfo()
    bmpstr = saveBitMap.GetBitmapBits(True)
    im = Image.frombuffer('RGB', (bmpinfo['bmWidth'], bmpinfo['bmHeight']), bmpstr, 'raw', 'BGRX', 0, 1)

    im.save(save_path)

    win32gui.DeleteObject(saveBitMap.GetHandle())
    saveDC.DeleteDC()
    mfcDC.DeleteDC()
    win32gui.ReleaseDC(hwnd, hwndDC)

print("[1] Starting Playtest in background via PostMessage...")
c_rect = win32gui.GetWindowRect(ribbon_hwnd)
play_rel_x = 121 - c_rect[0]
play_rel_y = 68 - c_rect[1]
lParam_play = win32api.MAKELONG(play_rel_x, play_rel_y)

win32api.PostMessage(ribbon_hwnd, win32con.WM_LBUTTONDOWN, win32con.MK_LBUTTON, lParam_play)
time.sleep(0.05)
win32api.PostMessage(ribbon_hwnd, win32con.WM_LBUTTONUP, 0, lParam_play)

print("  -> Waiting 4s for simulation to initialize...")
time.sleep(4.0)

# Check status
ok, out = exec_code("local r = game:GetService('RunService'); return 'IsRunning=' .. tostring(r:IsRunning()) .. ' IsEdit=' .. tostring(r:IsEdit())")
print(f"  -> Studio status: {out}")

cap1 = Path(__file__).resolve().parent / "bg_playtest_active.png"
capture_window_pure(hwnd, cap1)
print(f"  -> Captured pure window: {cap1.name}")

# Move character in world
print("[2] Moving character in background...")
exec_code("""
for _, c in ipairs(workspace:GetChildren()) do
    local hum = c:FindFirstChildOfClass("Humanoid")
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if hum and hrp and c.Name ~= "Zombie" and not string.find(c.Name, "ENEMY") then
        hum:MoveTo(hrp.Position + hrp.CFrame.LookVector * 15)
        task.delay(0.5, function() hum.Jump = true end)
    end
end
""")
time.sleep(1.5)

# Cast Sword Slash
print("[3] Casting Sword Slash...")
exec_code("""
local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("SkillRemotes")
local req = remotes and remotes:FindFirstChild("SkillRequest")
if req then req:FireServer({ skillName = "Sword Slash" }) end
""")
time.sleep(1.0)

cap2 = Path(__file__).resolve().parent / "bg_sword_slash.png"
capture_window_pure(hwnd, cap2)
print(f"  -> Captured pure window: {cap2.name}")

# Stop simulation in background via PostMessage
print("[4] Stopping simulation in background via PostMessage...")
stop_rel_x = 196 - c_rect[0]
stop_rel_y = 68 - c_rect[1]
lParam_stop = win32api.MAKELONG(stop_rel_x, stop_rel_y)

win32api.PostMessage(ribbon_hwnd, win32con.WM_LBUTTONDOWN, win32con.MK_LBUTTON, lParam_stop)
time.sleep(0.05)
win32api.PostMessage(ribbon_hwnd, win32con.WM_LBUTTONUP, 0, lParam_stop)
time.sleep(3.0)

ok, out = exec_code("local r = game:GetService('RunService'); return 'IsRunning=' .. tostring(r:IsRunning()) .. ' IsEdit=' .. tostring(r:IsEdit())")
print(f"  -> Final Studio status: {out}")

cap3 = Path(__file__).resolve().parent / "bg_test_complete.png"
capture_window_pure(hwnd, cap3)
print(f"  -> Captured pure window: {cap3.name}")
