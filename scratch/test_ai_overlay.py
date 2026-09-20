"""
scratch/test_ai_overlay.py
Tests the AI Testing overlay:
- Enables Red Border, Notification banner, and Virtual Cursor
- Animates virtual cursor to click a skill button
- Captures screenshots of the visual state
- Turns it off cleanly
"""

import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "bridge"))
from exec import exec_code
from capture import capture

print("[1] Activating AI Testing Overlay in Studio...")
activate_code = """
local sg = game:GetService("StarterGui")
local ui = sg:FindFirstChild("AITestingUI")
if not ui then return "ERROR: AITestingUI not found" end

-- Show visual components for inspection
local border = ui:FindFirstChild("RedBorder")
local banner = ui:FindFirstChild("NotificationBanner")
local cursor = ui:FindFirstChild("VirtualCursor")
local blocker = ui:FindFirstChild("InputBlocker")

if border then border.Visible = true end
if blocker then blocker.Visible = true end
if cursor then
    cursor.Visible = true
    -- Position cursor over Skill Slot 2 (Flame Ball)
    cursor.Position = UDim2.new(0.5, -40, 0.9, 0)
end
if banner then
    banner.Visible = true
    banner.Position = UDim2.new(0.5, 0, 0, 24)
    banner.BackgroundTransparency = 0.15
    local txt = banner:FindFirstChild("BannerText")
    if txt then txt.TextTransparency = 0 end
    local st = banner:FindFirstChild("BannerStroke")
    if st then st.Transparency = 0.2 end
end

return "OK: Visual overlay activated"
"""

ok, out = exec_code(activate_code)
print(f"Activation result: {ok} | {out}")

print("\n[2] Capturing in-engine screenshot with AI Testing visual overlay...")
time.sleep(0.5)
screen_path = capture(region="full", label="ai_testing_active")
print(f"Captured: {screen_path}")

print("\n[3] Capturing cropped view of Notification Banner...")
banner_path = capture(region="hud", label="ai_banner")
print(f"Captured: {banner_path}")

print("\n[4] Capturing cropped view of Hotbar with Virtual Cursor...")
hotbar_path = capture(region="hotbar", label="ai_cursor_click")
print(f"Captured: {hotbar_path}")

print("\n[5] Deactivating overlay...")
deactivate_code = """
local sg = game:GetService("StarterGui")
local ui = sg:FindFirstChild("AITestingUI")
if not ui then return "OK" end

local border = ui:FindFirstChild("RedBorder")
local banner = ui:FindFirstChild("NotificationBanner")
local cursor = ui:FindFirstChild("VirtualCursor")
local blocker = ui:FindFirstChild("InputBlocker")

if border then border.Visible = false end
if blocker then blocker.Visible = false end
if cursor then cursor.Visible = false end
if banner then banner.Visible = false end

return "OK: Reset"
"""
ok, out = exec_code(deactivate_code)
print(f"Reset result: {ok} | {out}")
