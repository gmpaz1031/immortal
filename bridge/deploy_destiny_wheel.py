import sys
import os
import json
import urllib.request
from pathlib import Path

PORT = 34875
BASE_URL = f"http://127.0.0.1:{PORT}"

def exec_code(code: str, timeout: float = 20.0):
    url = f"{BASE_URL}/exec"
    payload = json.dumps({"code": code}).encode("utf-8")
    req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode("utf-8"))
        cmd_id = data.get("id")
    
    import time
    start_time = time.time()
    while time.time() - start_time < timeout:
        res_url = f"{BASE_URL}/result?id={cmd_id}"
        try:
            with urllib.request.urlopen(res_url) as resp:
                res_data = json.loads(resp.read().decode("utf-8"))
                return res_data.get("success", False), res_data.get("output") or res_data.get("error")
        except urllib.error.HTTPError as e:
            if e.code == 404:
                time.sleep(0.1)
                continue
            return False, f"HTTP Error {e.code}"
        except Exception:
            time.sleep(0.1)
            continue
    return False, "Timeout"

destiny_config_path = Path("src/shared/DestinyConfig.luau")
destiny_config_source = destiny_config_path.read_text(encoding="utf-8")

# Step 1: Inject DestinyConfig into ReplicatedStorage.Shared
print("Step 1: Injecting DestinyConfig...")
lua_destiny_config = f"""
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local ex = Shared:FindFirstChild("DestinyConfig")
if ex then ex:Destroy() end

local m = Instance.new("ModuleScript")
m.Name = "DestinyConfig"
m.Source = [====[{destiny_config_source}]====]
m.Parent = Shared
return "Injected DestinyConfig into ReplicatedStorage.Shared"
"""
ok, res = exec_code(lua_destiny_config)
print("  DestinyConfig result:", ok, res)

# Step 2: Pre-place UI elements into StarterGui in Edit Mode (Zero runtime dynamic ScreenGui)
print("Step 2: Pre-placing Destiny Wheel UI into StarterGui.CultivationUI...")
lua_ui_build = """
local StarterGui = game:GetService("StarterGui")
local CultivationUI = StarterGui:WaitForChild("CultivationUI")
local GuofengTheme = require(game:GetService("ReplicatedStorage").Shared.GuofengTheme)

-- 1. In CultivationScrollModal: Update CinnabarActionBtn and Add DestinyWheelBtn
local cultModal = CultivationUI:WaitForChild("CultivationScrollModal")
local cinnabarBtn = cultModal:WaitForChild("CinnabarActionBtn")
cinnabarBtn.Size = UDim2.new(0.48, -10, 0, 46)
cinnabarBtn.Position = UDim2.new(0, 18, 0, 426)

local destinyBtn = cultModal:FindFirstChild("DestinyWheelBtn")
if not destinyBtn then
    destinyBtn = Instance.new("TextButton")
    destinyBtn.Name = "DestinyWheelBtn"
    destinyBtn.Size = UDim2.new(0.48, -10, 0, 46)
    destinyBtn.Position = UDim2.new(0.52, 2, 0, 426)
    destinyBtn.BackgroundColor3 = GuofengTheme.Colors.DarkJadeElevated
    destinyBtn.Font = GuofengTheme.Fonts.Header
    destinyBtn.Text = "DESTINY WHEEL"
    destinyBtn.TextColor3 = GuofengTheme.Colors.GoldLight
    destinyBtn.TextSize = 13
    destinyBtn.AutoButtonColor = true
    destinyBtn.ZIndex = 25
    destinyBtn.Parent = cultModal

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = destinyBtn

    local stroke = Instance.new("UIStroke")
    stroke.Color = GuofengTheme.Colors.GoldBorder
    stroke.Thickness = 1.5
    stroke.Parent = destinyBtn
end

-- 2. Add TalentCrest and RootCrest flanking TaijiVortex
local talentCrest = cultModal:FindFirstChild("TalentCrest")
if not talentCrest then
    talentCrest = Instance.new("Frame")
    talentCrest.Name = "TalentCrest"
    talentCrest.BackgroundColor3 = GuofengTheme.Colors.DarkJadeElevated
    talentCrest.Position = UDim2.new(0, 18, 0, 95)
    talentCrest.Size = UDim2.new(0, 140, 0, 90)
    talentCrest.ZIndex = 24
    talentCrest.Parent = cultModal

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = talentCrest

    local stroke = Instance.new("UIStroke")
    stroke.Color = GuofengTheme.Colors.GoldBorderDim
    stroke.Thickness = 1
    stroke.Parent = talentCrest

    local tag = Instance.new("TextLabel")
    tag.Name = "Tag"
    tag.BackgroundTransparency = 1
    tag.Position = UDim2.new(0, 8, 0, 6)
    tag.Size = UDim2.new(1, -16, 0, 16)
    tag.Font = GuofengTheme.Fonts.Header
    tag.Text = "TALENT"
    tag.TextColor3 = GuofengTheme.Colors.GoldLight
    tag.TextSize = 11
    tag.ZIndex = 25
    tag.Parent = talentCrest

    local val = Instance.new("TextLabel")
    val.Name = "Val"
    val.BackgroundTransparency = 1
    val.Position = UDim2.new(0, 8, 0, 26)
    val.Size = UDim2.new(1, -16, 0, 36)
    val.Font = GuofengTheme.Fonts.Title
    val.Text = "Mortal"
    val.TextColor3 = GuofengTheme.Colors.CyanBright
    val.TextScaled = true
    val.ZIndex = 25
    val.Parent = talentCrest

    local mult = Instance.new("TextLabel")
    mult.Name = "Mult"
    mult.BackgroundTransparency = 1
    mult.Position = UDim2.new(0, 8, 0, 66)
    mult.Size = UDim2.new(1, -16, 0, 18)
    mult.Font = GuofengTheme.Fonts.Body
    mult.Text = "x1.00 Qi Speed"
    mult.TextColor3 = GuofengTheme.Colors.TextMuted
    mult.TextSize = 11
    mult.ZIndex = 25
    mult.Parent = talentCrest
end

local rootCrest = cultModal:FindFirstChild("RootCrest")
if not rootCrest then
    rootCrest = Instance.new("Frame")
    rootCrest.Name = "RootCrest"
    rootCrest.BackgroundColor3 = GuofengTheme.Colors.DarkJadeElevated
    rootCrest.Position = UDim2.new(1, -158, 0, 95)
    rootCrest.Size = UDim2.new(0, 140, 0, 90)
    rootCrest.ZIndex = 24
    rootCrest.Parent = cultModal

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = rootCrest

    local stroke = Instance.new("UIStroke")
    stroke.Color = GuofengTheme.Colors.GoldBorderDim
    stroke.Thickness = 1
    stroke.Parent = rootCrest

    local tag = Instance.new("TextLabel")
    tag.Name = "Tag"
    tag.BackgroundTransparency = 1
    tag.Position = UDim2.new(0, 8, 0, 6)
    tag.Size = UDim2.new(1, -16, 0, 16)
    tag.Font = GuofengTheme.Fonts.Header
    tag.Text = "SPIRITUAL ROOT"
    tag.TextColor3 = GuofengTheme.Colors.GoldLight
    tag.TextSize = 10
    tag.ZIndex = 25
    tag.Parent = rootCrest

    local val = Instance.new("TextLabel")
    val.Name = "Val"
    val.BackgroundTransparency = 1
    val.Position = UDim2.new(0, 8, 0, 26)
    val.Size = UDim2.new(1, -16, 0, 36)
    val.Font = GuofengTheme.Fonts.Title
    val.Text = "None"
    val.TextColor3 = GuofengTheme.Colors.TextMuted
    val.TextScaled = true
    val.ZIndex = 25
    val.Parent = rootCrest

    local mult = Instance.new("TextLabel")
    mult.Name = "Mult"
    mult.BackgroundTransparency = 1
    mult.Position = UDim2.new(0, 8, 0, 66)
    mult.Size = UDim2.new(1, -16, 0, 18)
    mult.Font = GuofengTheme.Fonts.Body
    mult.Text = "Spin to Awaken"
    mult.TextColor3 = GuofengTheme.Colors.TextMuted
    mult.TextSize = 11
    mult.ZIndex = 25
    mult.Parent = rootCrest
end

-- 3. Create DestinyWheelModal inside StarterGui.CultivationUI
local exWheel = CultivationUI:FindFirstChild("DestinyWheelModal")
if exWheel then exWheel:Destroy() end

local wheelModal = Instance.new("Frame")
wheelModal.Name = "DestinyWheelModal"
wheelModal.BackgroundColor3 = GuofengTheme.Colors.DarkJadeBg
wheelModal.BorderSizePixel = 0
wheelModal.AnchorPoint = Vector2.new(0.5, 0.5)
wheelModal.Position = UDim2.new(0.5, 0, 0.5, 0)
wheelModal.Size = UDim2.new(0, 700, 0, 520)
wheelModal.Visible = false
wheelModal.ZIndex = 30
wheelModal.Parent = CultivationUI

local modalCorner = Instance.new("UICorner")
modalCorner.CornerRadius = UDim.new(0, 12)
modalCorner.Parent = wheelModal

local modalStroke = Instance.new("UIStroke")
modalStroke.Color = GuofengTheme.Colors.GoldBorder
modalStroke.Thickness = 2
modalStroke.Parent = wheelModal

-- Header Banner
local header = Instance.new("Frame")
header.Name = "HeaderBanner"
header.BackgroundColor3 = GuofengTheme.Colors.DarkJadeHeader
header.BorderSizePixel = 0
header.Position = UDim2.new(0, 12, 0, 10)
header.Size = UDim2.new(1, -24, 0, 44)
header.ZIndex = 31
header.Parent = wheelModal

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 6)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 16, 0, 4)
title.Size = UDim2.new(0.7, 0, 0, 20)
title.Font = GuofengTheme.Fonts.Title
title.Text = "DESTINY WHEEL"
title.TextColor3 = GuofengTheme.Colors.GoldLight
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 32
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.new(0, 16, 0, 24)
subtitle.Size = UDim2.new(0.7, 0, 0, 16)
subtitle.Font = GuofengTheme.Fonts.Body
subtitle.Text = "Awaken supreme cultivation talents and elemental spiritual roots"
subtitle.TextColor3 = GuofengTheme.Colors.TextMuted
subtitle.TextSize = 11
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.ZIndex = 32
subtitle.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.BackgroundColor3 = GuofengTheme.Colors.DarkJadeElevated
closeBtn.Position = UDim2.new(1, -34, 0, 9)
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Font = GuofengTheme.Fonts.Header
closeBtn.Text = "X"
closeBtn.TextColor3 = GuofengTheme.Colors.GoldLight
closeBtn.TextSize = 13
closeBtn.ZIndex = 33
closeBtn.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeBtn

-- Tab Row
local tabRow = Instance.new("Frame")
tabRow.Name = "TabRow"
tabRow.BackgroundTransparency = 1
tabRow.Position = UDim2.new(0, 20, 0, 62)
tabRow.Size = UDim2.new(1, -40, 0, 32)
tabRow.ZIndex = 31
tabRow.Parent = wheelModal

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 10)
tabLayout.Parent = tabRow

local talentTabBtn = Instance.new("TextButton")
talentTabBtn.Name = "TalentTab"
talentTabBtn.LayoutOrder = 1
talentTabBtn.BackgroundColor3 = GuofengTheme.Colors.DarkJadeElevated
talentTabBtn.Size = UDim2.new(0, 180, 0, 30)
talentTabBtn.Font = GuofengTheme.Fonts.Header
talentTabBtn.Text = "Talent Wheel (15 Tiers)"
talentTabBtn.TextColor3 = GuofengTheme.Colors.GoldLight
talentTabBtn.TextSize = 12
talentTabBtn.ZIndex = 32
talentTabBtn.Parent = tabRow

local tCorner = Instance.new("UICorner")
tCorner.CornerRadius = UDim.new(0, 6)
tCorner.Parent = talentTabBtn

local tStroke = Instance.new("UIStroke")
tStroke.Color = GuofengTheme.Colors.GoldBorder
tStroke.Thickness = 1.5
tStroke.Parent = talentTabBtn

local rootTabBtn = Instance.new("TextButton")
rootTabBtn.Name = "RootTab"
rootTabBtn.LayoutOrder = 2
rootTabBtn.BackgroundColor3 = GuofengTheme.Colors.DarkJadeCard
rootTabBtn.Size = UDim2.new(0, 210, 0, 30)
rootTabBtn.Font = GuofengTheme.Fonts.Header
rootTabBtn.Text = "Spiritual Root Wheel (9 Roots)"
rootTabBtn.TextColor3 = GuofengTheme.Colors.TextMuted
rootTabBtn.TextSize = 12
rootTabBtn.ZIndex = 32
rootTabBtn.Parent = tabRow

local rCorner = Instance.new("UICorner")
rCorner.CornerRadius = UDim.new(0, 6)
rCorner.Parent = rootTabBtn

local rStroke = Instance.new("UIStroke")
rStroke.Color = GuofengTheme.Colors.GoldBorderDim
rStroke.Thickness = 1
rStroke.Parent = rootTabBtn

-- Left Column: Wheel Display
local leftCol = Instance.new("Frame")
leftCol.Name = "LeftColumn"
leftCol.BackgroundTransparency = 1
leftCol.Position = UDim2.new(0, 20, 0, 102)
leftCol.Size = UDim2.new(0, 310, 0, 400)
leftCol.ZIndex = 31
leftCol.Parent = wheelModal

local wheelRim = Instance.new("Frame")
wheelRim.Name = "WheelRim"
wheelRim.BackgroundColor3 = GuofengTheme.Colors.DarkJadeCard
wheelRim.AnchorPoint = Vector2.new(0.5, 0)
wheelRim.Position = UDim2.new(0.5, 0, 0, 6)
wheelRim.Size = UDim2.new(0, 230, 0, 230)
wheelRim.ZIndex = 31
wheelRim.Parent = leftCol

local rimCorner = Instance.new("UICorner")
rimCorner.CornerRadius = UDim.new(1, 0)
rimCorner.Parent = wheelRim

local rimStroke = Instance.new("UIStroke")
rimStroke.Color = GuofengTheme.Colors.GoldBorder
rimStroke.Thickness = 3
rimStroke.Parent = wheelRim

-- Pointer Needle
local pointer = Instance.new("Frame")
pointer.Name = "Pointer"
pointer.BackgroundColor3 = GuofengTheme.Colors.GoldLight
pointer.AnchorPoint = Vector2.new(0.5, 0.5)
pointer.Position = UDim2.new(0.5, 0, 0, 0)
pointer.Size = UDim2.new(0, 16, 0, 16)
pointer.Rotation = 45
pointer.ZIndex = 36
pointer.Parent = wheelRim

local pointerStroke = Instance.new("UIStroke")
pointerStroke.Color = Color3.fromRGB(255, 255, 255)
pointerStroke.Thickness = 1.2
pointerStroke.Parent = pointer

-- Rotating Wheel Disc
local wheelDisc = Instance.new("Frame")
wheelDisc.Name = "WheelDisc"
wheelDisc.BackgroundColor3 = GuofengTheme.Colors.DarkJadeBg
wheelDisc.AnchorPoint = Vector2.new(0.5, 0.5)
wheelDisc.Position = UDim2.new(0.5, 0, 0.5, 0)
wheelDisc.Size = UDim2.new(0.92, 0, 0.92, 0)
wheelDisc.ZIndex = 32
wheelDisc.Parent = wheelRim

local discCorner = Instance.new("UICorner")
discCorner.CornerRadius = UDim.new(1, 0)
discCorner.Parent = wheelDisc

-- Center Hub
local wheelHub = Instance.new("Frame")
wheelHub.Name = "Hub"
wheelHub.BackgroundColor3 = GuofengTheme.Colors.DarkJadeHeader
wheelHub.AnchorPoint = Vector2.new(0.5, 0.5)
wheelHub.Position = UDim2.new(0.5, 0, 0.5, 0)
wheelHub.Size = UDim2.new(0, 56, 0, 56)
wheelHub.ZIndex = 34
wheelHub.Parent = wheelRim

local hubCorner = Instance.new("UICorner")
hubCorner.CornerRadius = UDim.new(1, 0)
hubCorner.Parent = wheelHub

local hubStroke = Instance.new("UIStroke")
hubStroke.Color = GuofengTheme.Colors.GoldBorder
hubStroke.Thickness = 2
hubStroke.Parent = wheelHub

local hubLabel = Instance.new("TextLabel")
hubLabel.Name = "HubLabel"
hubLabel.BackgroundTransparency = 1
hubLabel.Size = UDim2.new(1, 0, 1, 0)
hubLabel.Font = GuofengTheme.Fonts.Title
hubLabel.Text = "DAO"
hubLabel.TextColor3 = GuofengTheme.Colors.GoldLight
hubLabel.TextSize = 14
hubLabel.ZIndex = 35
hubLabel.Parent = wheelHub

-- Status & Info labels
local currentStatusLabel = Instance.new("TextLabel")
currentStatusLabel.Name = "CurrentStatus"
currentStatusLabel.BackgroundTransparency = 1
currentStatusLabel.Position = UDim2.new(0, 0, 0, 246)
currentStatusLabel.Size = UDim2.new(1, 0, 0, 24)
currentStatusLabel.Font = GuofengTheme.Fonts.Header
currentStatusLabel.Text = "Current Talent: Mortal (x1.00)"
currentStatusLabel.TextColor3 = GuofengTheme.Colors.GoldLight
currentStatusLabel.TextSize = 12
currentStatusLabel.ZIndex = 32
currentStatusLabel.Parent = leftCol

local costInfoLabel = Instance.new("TextLabel")
costInfoLabel.Name = "CostInfo"
costInfoLabel.BackgroundTransparency = 1
costInfoLabel.Position = UDim2.new(0, 0, 0, 272)
costInfoLabel.Size = UDim2.new(1, 0, 0, 20)
costInfoLabel.Font = GuofengTheme.Fonts.Body
costInfoLabel.Text = "Cost: 50 Spirit Stones · Balance: 50"
costInfoLabel.TextColor3 = GuofengTheme.Colors.TextMuted
costInfoLabel.TextSize = 11
costInfoLabel.ZIndex = 32
costInfoLabel.Parent = leftCol

local spinActionBtn = Instance.new("TextButton")
spinActionBtn.Name = "SpinActionBtn"
spinActionBtn.BackgroundColor3 = GuofengTheme.Colors.Cinnabar
spinActionBtn.Position = UDim2.new(0.05, 0, 0, 300)
spinActionBtn.Size = UDim2.new(0.9, 0, 0, 44)
spinActionBtn.Font = GuofengTheme.Fonts.Title
spinActionBtn.Text = "SPIN TALENT (50 STONES)"
spinActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
spinActionBtn.TextSize = 13
spinActionBtn.AutoButtonColor = true
spinActionBtn.ZIndex = 32
spinActionBtn.Parent = leftCol

local spinBtnCorner = Instance.new("UICorner")
spinBtnCorner.CornerRadius = UDim.new(0, 8)
spinBtnCorner.Parent = spinActionBtn

local spinBtnStroke = Instance.new("UIStroke")
spinBtnStroke.Color = GuofengTheme.Colors.GoldBorder
spinBtnStroke.Thickness = 1.5
spinBtnStroke.Parent = spinActionBtn

local badge = Instance.new("TextLabel")
badge.Name = "Badge"
badge.BackgroundTransparency = 1
badge.Position = UDim2.new(0, 0, 0, 350)
badge.Size = UDim2.new(1, 0, 0, 16)
badge.Font = GuofengTheme.Fonts.Body
badge.Text = "Guaranteed stat progression · Multiplies gathered Qi"
badge.TextColor3 = GuofengTheme.Colors.TextMuted
badge.TextSize = 10
badge.ZIndex = 32
badge.Parent = leftCol

-- Right Column: Tiers Table
local rightCol = Instance.new("Frame")
rightCol.Name = "RightColumn"
rightCol.BackgroundTransparency = 1
rightCol.Position = UDim2.new(0, 345, 0, 102)
rightCol.Size = UDim2.new(1, -365, 0, 400)
rightCol.ZIndex = 31
rightCol.Parent = wheelModal

local tierHeader = Instance.new("TextLabel")
tierHeader.Name = "Header"
tierHeader.BackgroundTransparency = 1
tierHeader.Position = UDim2.new(0, 0, 0, 0)
tierHeader.Size = UDim2.new(1, 0, 0, 20)
tierHeader.Font = GuofengTheme.Fonts.Header
tierHeader.Text = "TIER RATINGS, MULTIPLIERS & PROBABILITIES"
tierHeader.TextColor3 = GuofengTheme.Colors.GoldLight
tierHeader.TextSize = 11
tierHeader.TextXAlignment = Enum.TextXAlignment.Left
tierHeader.ZIndex = 32
tierHeader.Parent = rightCol

local tierScroll = Instance.new("ScrollingFrame")
tierScroll.Name = "TierScroll"
tierScroll.BackgroundTransparency = 1
tierScroll.BorderSizePixel = 0
tierScroll.Position = UDim2.new(0, 0, 0, 24)
tierScroll.Size = UDim2.new(1, 0, 1, -28)
tierScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
tierScroll.ScrollBarThickness = 4
tierScroll.ZIndex = 32
tierScroll.Parent = rightCol

local tierLayout = Instance.new("UIListLayout")
tierLayout.SortOrder = Enum.SortOrder.LayoutOrder
tierLayout.Padding = UDim.new(0, 4)
tierLayout.Parent = tierScroll

-- Winner Celebration Overlay
local winnerOverlay = Instance.new("Frame")
winnerOverlay.Name = "WinnerOverlay"
winnerOverlay.BackgroundColor3 = Color3.fromRGB(8, 14, 12)
winnerOverlay.BackgroundTransparency = 0.35
winnerOverlay.Position = UDim2.new(0, 0, 0, 0)
winnerOverlay.Size = UDim2.new(1, 0, 1, 0)
winnerOverlay.Visible = false
winnerOverlay.ZIndex = 50
winnerOverlay.Parent = wheelModal

local winCorner = Instance.new("UICorner")
winCorner.CornerRadius = UDim.new(0, 12)
winCorner.Parent = winnerOverlay

local winnerCard = Instance.new("Frame")
winnerCard.Name = "Card"
winnerCard.BackgroundColor3 = GuofengTheme.Colors.DarkJadeCard
winnerCard.AnchorPoint = Vector2.new(0.5, 0.5)
winnerCard.Position = UDim2.new(0.5, 0, 0.5, 0)
winnerCard.Size = UDim2.new(0, 420, 0, 230)
winnerCard.ZIndex = 51
winnerCard.Parent = winnerOverlay

local winCardCorner = Instance.new("UICorner")
winCardCorner.CornerRadius = UDim.new(0, 10)
winCardCorner.Parent = winnerCard

local winCardStroke = Instance.new("UIStroke")
winCardStroke.Color = GuofengTheme.Colors.GoldBorder
winCardStroke.Thickness = 2
winCardStroke.Parent = winnerCard

local winTag = Instance.new("TextLabel")
winTag.Name = "Tag"
winTag.BackgroundTransparency = 1
winTag.Position = UDim2.new(0, 0, 0, 16)
winTag.Size = UDim2.new(1, 0, 0, 22)
winTag.Font = GuofengTheme.Fonts.Title
winTag.Text = "DESTINY AWAKENED"
winTag.TextColor3 = GuofengTheme.Colors.GoldLight
winTag.TextSize = 16
winTag.ZIndex = 52
winTag.Parent = winnerCard

local winName = Instance.new("TextLabel")
winName.Name = "Name"
winName.BackgroundTransparency = 1
winName.Position = UDim2.new(0, 12, 0, 46)
winName.Size = UDim2.new(1, -24, 0, 36)
winName.Font = GuofengTheme.Fonts.Title
winName.Text = "Heavenly Genius"
winName.TextColor3 = GuofengTheme.Colors.CyanBright
winName.TextScaled = true
winName.ZIndex = 52
winName.Parent = winnerCard

local winMult = Instance.new("TextLabel")
winMult.Name = "Multiplier"
winMult.BackgroundTransparency = 1
winMult.Position = UDim2.new(0, 12, 0, 90)
winMult.Size = UDim2.new(1, -24, 0, 24)
winMult.Font = GuofengTheme.Fonts.Header
winMult.Text = "Cultivation Qi Gather Speed: x2.00"
winMult.TextColor3 = GuofengTheme.Colors.GoldLight
winMult.TextSize = 13
winMult.ZIndex = 52
winMult.Parent = winnerCard

local winDesc = Instance.new("TextLabel")
winDesc.Name = "Desc"
winDesc.BackgroundTransparency = 1
winDesc.Position = UDim2.new(0, 20, 0, 120)
winDesc.Size = UDim2.new(1, -40, 0, 40)
winDesc.Font = GuofengTheme.Fonts.Body
winDesc.Text = "Your inner core has been permanently enriched with celestial providence."
winDesc.TextColor3 = GuofengTheme.Colors.TextMuted
winDesc.TextSize = 12
winDesc.TextWrapped = true
winDesc.ZIndex = 52
winDesc.Parent = winnerCard

local winDismissBtn = Instance.new("TextButton")
winDismissBtn.Name = "DismissBtn"
winDismissBtn.BackgroundColor3 = GuofengTheme.Colors.Cinnabar
winDismissBtn.Position = UDim2.new(0.25, 0, 0, 174)
winDismissBtn.Size = UDim2.new(0.5, 0, 0, 36)
winDismissBtn.Font = GuofengTheme.Fonts.Header
winDismissBtn.Text = "ACCEPT DESTINY"
winDismissBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
winDismissBtn.TextSize = 13
winDismissBtn.ZIndex = 53
winDismissBtn.Parent = winnerCard

local winDismissCorner = Instance.new("UICorner")
winDismissCorner.CornerRadius = UDim.new(0, 6)
winDismissCorner.Parent = winDismissBtn

return "Pre-placed Destiny Wheel UI into StarterGui.CultivationUI successfully!"
"""
ok, res = exec_code(lua_ui_build)
print("  UI build result:", ok, res)

print("Pre-placement complete!")
