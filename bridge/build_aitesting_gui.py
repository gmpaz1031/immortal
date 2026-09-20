"""
bridge/build_aitesting_gui.py
Constructs StarterGui.AITestingUI in Roblox Studio in Edit Mode.
Complies with GEMINI.md pre-execution checklist:
  - Zero artificial parents (script.script = 0)
  - Pre-placed in StarterGui in Edit Mode
  - Pure English text, zero emojis
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from exec import exec_code

CURSOR_ASSET_ID = "rbxassetid://137737273376606"

def build_gui():
    script_source = Path("src/gui/AITestingUI/AITestingClient.client.luau").read_text(encoding="utf-8")

    lua_code = f"""
    local sg = game:GetService("StarterGui")

    -- Remove existing if present to ensure clean rebuild
    local existing = sg:FindFirstChild("AITestingUI")
    if existing then
        existing:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "AITestingUI"
    gui.DisplayOrder = 9999
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- 1. Red Border (4 solid edge bars ensuring 100% viewport visibility)
    local border = Instance.new("Frame")
    border.Name = "RedBorder"
    border.Size = UDim2.new(1, 0, 1, 0)
    border.Position = UDim2.new(0, 0, 0, 0)
    border.BackgroundTransparency = 1
    border.Visible = false
    border.ZIndex = 40
    border.Parent = gui

    local function makeBar(name, size, pos)
        local bar = Instance.new("Frame")
        bar.Name = name
        bar.Size = size
        bar.Position = pos
        bar.BackgroundColor3 = Color3.fromRGB(245, 35, 35)
        bar.BorderSizePixel = 0
        bar.ZIndex = 45
        bar.Parent = border
        return bar
    end

    makeBar("TopBar", UDim2.new(1, 0, 0, 8), UDim2.new(0, 0, 0, 0))
    makeBar("BottomBar", UDim2.new(1, 0, 0, 8), UDim2.new(0, 0, 1, -8))
    makeBar("LeftBar", UDim2.new(0, 8, 1, 0), UDim2.new(0, 0, 0, 0))
    makeBar("RightBar", UDim2.new(0, 8, 1, 0), UDim2.new(1, -8, 0, 0))

    -- 2. Input Lockout Blocker
    local blocker = Instance.new("TextButton")
    blocker.Name = "InputBlocker"
    blocker.Size = UDim2.new(1, 0, 1, 0)
    blocker.Position = UDim2.new(0, 0, 0, 0)
    blocker.BackgroundTransparency = 1
    blocker.Text = ""
    blocker.Active = true
    blocker.Selectable = false
    blocker.Visible = false
    blocker.ZIndex = 50
    blocker.Parent = gui

    -- 3. Notification Banner ("AI is currently testing, please wait...")
    local banner = Instance.new("Frame")
    banner.Name = "NotificationBanner"
    banner.Size = UDim2.new(0, 360, 0, 46)
    banner.Position = UDim2.new(0.5, 0, 0, -60)
    banner.AnchorPoint = Vector2.new(0.5, 0)
    banner.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
    banner.BackgroundTransparency = 0.15
    banner.Visible = false
    banner.ZIndex = 90
    banner.Parent = gui

    local bannerCorner = Instance.new("UICorner")
    bannerCorner.CornerRadius = UDim.new(0, 10)
    bannerCorner.Parent = banner

    local bannerStroke = Instance.new("UIStroke")
    bannerStroke.Name = "BannerStroke"
    bannerStroke.Color = Color3.fromRGB(245, 50, 50)
    bannerStroke.Thickness = 2
    bannerStroke.Parent = banner

    local bannerText = Instance.new("TextLabel")
    bannerText.Name = "BannerText"
    bannerText.Size = UDim2.new(1, -20, 1, 0)
    bannerText.Position = UDim2.new(0, 10, 0, 0)
    bannerText.BackgroundTransparency = 1
    bannerText.Text = "AI is currently testing, please wait..."
    bannerText.TextColor3 = Color3.fromRGB(255, 255, 255)
    bannerText.Font = Enum.Font.GothamBold
    bannerText.TextSize = 15
    bannerText.ZIndex = 91
    bannerText.Parent = banner

    -- 4. Virtual Cursor
    local cursor = Instance.new("ImageLabel")
    cursor.Name = "VirtualCursor"
    cursor.Size = UDim2.new(0, 36, 0, 36)
    cursor.Position = UDim2.new(0.5, 0, 0.5, 0)
    cursor.AnchorPoint = Vector2.new(0.18, 0.18)
    cursor.BackgroundTransparency = 1
    cursor.Image = "{CURSOR_ASSET_ID}"
    cursor.Visible = false
    cursor.ZIndex = 100
    cursor.Parent = gui

    -- 5. Click Ripple
    local ripple = Instance.new("Frame")
    ripple.Name = "ClickRipple"
    ripple.Size = UDim2.new(0, 10, 0, 10)
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.BackgroundTransparency = 1
    ripple.Visible = false
    ripple.ZIndex = 99
    ripple.Parent = gui

    local rippleCorner = Instance.new("UICorner")
    rippleCorner.CornerRadius = UDim.new(1, 0)
    rippleCorner.Parent = ripple

    local rippleStroke = Instance.new("UIStroke")
    rippleStroke.Name = "RippleStroke"
    rippleStroke.Color = Color3.fromRGB(255, 215, 65)
    rippleStroke.Thickness = 2.5
    rippleStroke.Parent = ripple

    -- 6. BindableEvent for Click Simulation
    local clickEvent = Instance.new("BindableEvent")
    clickEvent.Name = "SimulateClickEvent"
    clickEvent.Parent = gui

    -- 7. Client Script (Directly under ScreenGui - ZERO artificial parents)
    local clientScript = Instance.new("LocalScript")
    clientScript.Name = "AITestingClient"
    clientScript.Source = [==[{script_source}]==]
    clientScript.Parent = gui

    gui.Parent = sg
    return "SUCCESS: StarterGui.AITestingUI built successfully"
    """

    print("Building StarterGui.AITestingUI in Studio...")
    ok, out = exec_code(lua_code, timeout=12.0)
    print(f"Result: {ok} | {out}")
    return ok

if __name__ == "__main__":
    build_gui()
