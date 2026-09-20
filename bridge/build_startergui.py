"""
bridge/build_startergui.py
Constructs the Xianxia RPG UI directly in StarterGui inside Roblox Studio,
faithfully matching the Dark Jade, Imperial Gold Filigree, and Luminous Cyan Spiritual Qi
design language from the attached development roadmap.
Zero Chinese text, pure English UI.
"""

import sys
import json
import urllib.request
import time

PORT = 34875

def exec_code(code: str):
    url = f"http://127.0.0.1:{PORT}/exec"
    payload = json.dumps({"code": code}).encode("utf-8")
    req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode("utf-8"))
        cmd_id = data.get("id")
        
    start = time.time()
    while time.time() - start < 20:
        try:
            with urllib.request.urlopen(f"http://127.0.0.1:{PORT}/result?id={cmd_id}") as r:
                res = json.loads(r.read().decode("utf-8"))
                return res.get("success"), res.get("output") or res.get("error")
        except Exception:
            time.sleep(0.25)
    return False, "Timeout"

BUILD_SCRIPT = r"""
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

-- 1. Remove redundant StarterGui.UI folder if present
local oldUIFolder = StarterGui:FindFirstChild("UI")
if oldUIFolder then
    oldUIFolder:Destroy()
end

-- ============================================================================
-- THEME DEFINITION
-- ============================================================================
local Colors = {
    DarkJadeBg       = Color3.fromRGB(10, 22, 19),
    DarkJadeCard     = Color3.fromRGB(13, 31, 26),
    DarkJadeElevated = Color3.fromRGB(20, 46, 39),
    DarkJadeHeader   = Color3.fromRGB(16, 38, 32),
    
    GoldBorder       = Color3.fromRGB(214, 178, 68),
    GoldBorderDim    = Color3.fromRGB(142, 116, 44),
    GoldLight        = Color3.fromRGB(250, 226, 140),
    GoldAmber        = Color3.fromRGB(240, 192, 91),
    
    CyanGlow         = Color3.fromRGB(66, 216, 186),
    CyanBright       = Color3.fromRGB(132, 248, 228),
    CyanDark         = Color3.fromRGB(28, 92, 79),
    CyanMist         = Color3.fromRGB(180, 246, 236),
    
    ParchmentLight   = Color3.fromRGB(244, 240, 230),
    ParchmentDark    = Color3.fromRGB(224, 214, 198),
    
    InkDark          = Color3.fromRGB(26, 22, 20),
    InkMedium        = Color3.fromRGB(56, 48, 44),
    TextWhite        = Color3.fromRGB(246, 252, 250),
    TextMuted        = Color3.fromRGB(168, 196, 188),
    
    Cinnabar         = Color3.fromRGB(186, 46, 36),
    CinnabarHover    = Color3.fromRGB(214, 62, 50),
    Crimson          = Color3.fromRGB(184, 40, 46),
}

local Fonts = {
    Title  = Enum.Font.GothamBlack,
    Header = Enum.Font.GothamBold,
    Body   = Enum.Font.GothamMedium,
}

local function createPanel(parent, size, pos, title, subtitle)
    local panel = Instance.new("Frame")
    panel.Name = "XianxiaPanel"
    panel.BackgroundColor3 = Colors.DarkJadeCard
    panel.Size = size
    panel.Position = pos
    panel.BorderSizePixel = 0
    panel.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = panel

    local s = Instance.new("UIStroke")
    s.Color = Colors.GoldBorder
    s.Thickness = 2
    s.Parent = panel

    local trim = Instance.new("Frame")
    trim.Name = "InnerTrim"
    trim.BackgroundTransparency = 1
    trim.Position = UDim2.new(0, 4, 0, 4)
    trim.Size = UDim2.new(1, -8, 1, -8)
    trim.BorderSizePixel = 0
    trim.Parent = panel

    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 6)
    tc.Parent = trim

    local ts = Instance.new("UIStroke")
    ts.Color = Colors.CyanGlow
    ts.Thickness = 1
    ts.Transparency = 0.65
    ts.Parent = trim

    if title and #title > 0 then
        local hb = Instance.new("Frame")
        hb.Name = "HeaderBanner"
        hb.BackgroundColor3 = Colors.DarkJadeHeader
        hb.Size = UDim2.new(1, -24, 0, subtitle and 44 or 36)
        hb.Position = UDim2.new(0, 12, 0, 8)
        hb.BorderSizePixel = 0
        hb.Parent = panel

        local hbc = Instance.new("UICorner")
        hbc.CornerRadius = UDim.new(0, 5)
        hbc.Parent = hb

        local hbs = Instance.new("UIStroke")
        hbs.Color = Colors.GoldBorderDim
        hbs.Thickness = 1.2
        hbs.Parent = hb

        local tLab = Instance.new("TextLabel")
        tLab.Name = "TitleText"
        tLab.BackgroundTransparency = 1
        tLab.Size = UDim2.new(1, 0, 0, 22)
        tLab.Position = UDim2.new(0, 0, 0, 2)
        tLab.Font = Fonts.Title
        tLab.Text = title
        tLab.TextColor3 = Colors.GoldLight
        tLab.TextSize = 14
        tLab.Parent = hb

        if subtitle and #subtitle > 0 then
            local sLab = Instance.new("TextLabel")
            sLab.Name = "SubtitleText"
            sLab.BackgroundTransparency = 1
            sLab.Size = UDim2.new(1, 0, 0, 16)
            sLab.Position = UDim2.new(0, 0, 0, 22)
            sLab.Font = Fonts.Body
            sLab.Text = subtitle
            sLab.TextColor3 = Colors.CyanGlow
            sLab.TextSize = 10
            sLab.Parent = hb
        end
    end
    return panel
end

local function createOrb(parent, sizePx, pos, keybind)
    local orb = Instance.new("Frame")
    orb.Name = "GlowingCyanOrb"
    orb.BackgroundColor3 = Colors.DarkJadeElevated
    orb.Size = UDim2.new(0, sizePx, 0, sizePx)
    orb.Position = pos
    orb.BorderSizePixel = 0
    orb.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = orb

    local s = Instance.new("UIStroke")
    s.Color = Colors.GoldBorder
    s.Thickness = 2.2
    s.Parent = orb

    local inner = Instance.new("Frame")
    inner.Name = "InnerRing"
    inner.BackgroundTransparency = 1
    inner.Size = UDim2.new(1, -8, 1, -8)
    inner.Position = UDim2.new(0, 4, 0, 4)
    inner.BorderSizePixel = 0
    inner.Active = false
    inner.Parent = orb

    local ic = Instance.new("UICorner")
    ic.CornerRadius = UDim.new(1, 0)
    ic.Parent = inner

    local is_ = Instance.new("UIStroke")
    is_.Color = Colors.CyanGlow
    is_.Thickness = 1.2
    is_.Transparency = 0.2
    is_.Parent = inner

    if keybind and #keybind > 0 then
        local bg = Instance.new("Frame")
        bg.Name = "KeybindBadge"
        bg.BackgroundColor3 = Colors.GoldAmber
        bg.Size = UDim2.new(0, 22, 0, 22)
        bg.Position = UDim2.new(1, -12, 0, -4)
        bg.BorderSizePixel = 0
        bg.ZIndex = 8
        bg.Active = false
        bg.Parent = orb

        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(1, 0)
        bc.Parent = bg

        local bs = Instance.new("UIStroke")
        bs.Color = Colors.DarkJadeBg
        bs.Thickness = 1.5
        bs.Parent = bg

        local bl = Instance.new("TextLabel")
        bl.BackgroundTransparency = 1
        bl.Size = UDim2.new(1, 0, 1, 0)
        bl.Font = Fonts.Title
        bl.Text = keybind
        bl.TextColor3 = Colors.DarkJadeBg
        bl.TextSize = 12
        bl.ZIndex = 9
        bl.Active = false
        bl.Parent = bg
    end
    return orb
end

local function createBar(parent, size, pos, color, labelText)
    local c = Instance.new("Frame")
    c.Name = "BarContainer"
    c.BackgroundColor3 = Colors.DarkJadeBg
    c.Size = size
    c.Position = pos
    c.BorderSizePixel = 0
    c.Parent = parent

    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 5)
    cc.Parent = c

    local cs = Instance.new("UIStroke")
    cs.Color = Colors.GoldBorderDim
    cs.Thickness = 1.2
    cs.Parent = c

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.BackgroundColor3 = color
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BorderSizePixel = 0
    fill.Parent = c

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 5)
    fc.Parent = fill

    local t = Instance.new("TextLabel")
    t.Name = "Text"
    t.BackgroundTransparency = 1
    t.Size = UDim2.new(1, 0, 1, 0)
    t.Font = Fonts.Header
    t.Text = labelText or ""
    t.TextColor3 = Colors.TextWhite
    t.TextSize = 11
    t.ZIndex = 3
    t.Parent = c

    local ts = Instance.new("UIStroke")
    ts.Color = Colors.DarkJadeBg
    ts.Thickness = 1.2
    ts.Parent = t

    return c, fill, t
end

-- ============================================================================
-- 1. SETUP CultivationUI
-- ============================================================================
local cultScreen = StarterGui:FindFirstChild("CultivationUI")
if not cultScreen then
    cultScreen = Instance.new("ScreenGui")
    cultScreen.Name = "CultivationUI"
    cultScreen.ResetOnSpawn = false
    cultScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    cultScreen.Parent = StarterGui
else
    cultScreen.ResetOnSpawn = false
    cultScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    for _, name in ipairs({"GuofengHUD", "RoadmapModal", "CultivationScrollModal", "InventoryScrollModal", "ShopScrollModal", "Panel"}) do
        local old = cultScreen:FindFirstChild(name)
        if old then old:Destroy() end
    end
end

-- ============================================================================
-- A. TOP HUD (Dark Jade Slate & Imperial Gold Filigree)
-- ============================================================================
local hud = createPanel(cultScreen, UDim2.new(0, 560, 0, 114), UDim2.new(0, 18, 0, 16))
hud.Name = "GuofengHUD"

-- Circular Cyan/Gold Avatar Orb
local portraitSlot = createOrb(hud, 56, UDim2.new(0, 10, 0, 8))
portraitSlot.Name = "PortraitSlot"
local avatar = Instance.new("ImageLabel")
avatar.Name = "Avatar"
avatar.BackgroundTransparency = 1
avatar.Size = UDim2.new(1, -6, 1, -6)
avatar.Position = UDim2.new(0, 3, 0, 3)
avatar.Image = "rbxassetid://10849911874"
avatar.Parent = portraitSlot
local avc = Instance.new("UICorner")
avc.CornerRadius = UDim.new(1, 0)
avc.Parent = avatar

-- Realm Banner
local realmBanner = Instance.new("Frame")
realmBanner.Name = "RealmBanner"
realmBanner.BackgroundColor3 = Colors.DarkJadeElevated
realmBanner.Position = UDim2.new(0, 76, 0, 8)
realmBanner.Size = UDim2.new(0, 270, 0, 24)
realmBanner.BorderSizePixel = 0
realmBanner.Parent = hud

local rbc = Instance.new("UICorner")
rbc.CornerRadius = UDim.new(0, 5)
rbc.Parent = realmBanner

local rbs = Instance.new("UIStroke")
rbs.Color = Colors.GoldBorder
rbs.Thickness = 1.2
rbs.Parent = realmBanner

local realmLabel = Instance.new("TextLabel")
realmLabel.Name = "RealmLabel"
realmLabel.BackgroundTransparency = 1
realmLabel.Size = UDim2.new(1, 0, 1, 0)
realmLabel.Font = Fonts.Header
realmLabel.Text = "✦ QI CONDENSATION · LEVEL 0 ✦"
realmLabel.TextColor3 = Colors.GoldLight
realmLabel.TextSize = 11
realmLabel.Parent = realmBanner

-- Gold Coin Banner
local goldBanner = Instance.new("Frame")
goldBanner.Name = "GoldBanner"
goldBanner.BackgroundColor3 = Colors.DarkJadeElevated
goldBanner.Position = UDim2.new(0, 356, 0, 8)
goldBanner.Size = UDim2.new(0, 190, 0, 24)
goldBanner.BorderSizePixel = 0
goldBanner.Parent = hud

local gbc = Instance.new("UICorner")
gbc.CornerRadius = UDim.new(0, 5)
gbc.Parent = goldBanner

local gbs = Instance.new("UIStroke")
gbs.Color = Colors.GoldBorder
gbs.Thickness = 1.2
gbs.Parent = goldBanner

local goldLabel = Instance.new("TextLabel")
goldLabel.Name = "GoldLabel"
goldLabel.BackgroundTransparency = 1
goldLabel.Size = UDim2.new(1, 0, 1, 0)
goldLabel.Font = Fonts.Header
goldLabel.Text = "50 SPIRIT STONES"
goldLabel.TextColor3 = Colors.GoldLight
goldLabel.TextSize = 11
goldLabel.Parent = goldBanner

-- Progress Bars (HP & Luminous Cyan Qi Stream)
local hpBar = createBar(hud, UDim2.new(0, 226, 0, 16), UDim2.new(0, 76, 0, 38), Colors.Crimson, "HP: 100 / 100")
hpBar.Name = "HPBar"

local qiBar = createBar(hud, UDim2.new(0, 238, 0, 16), UDim2.new(0, 308, 0, 38), Colors.CyanGlow, "QI: 0 / 100")
qiBar.Name = "QiBar"

-- Navigation Row (4 Pure English Action Buttons)
local navRow = Instance.new("Frame")
navRow.Name = "NavRow"
navRow.BackgroundTransparency = 1
navRow.Position = UDim2.new(0, 10, 0, 68)
navRow.Size = UDim2.new(1, -20, 0, 34)
navRow.Parent = hud

local navLayout = Instance.new("UIListLayout")
navLayout.FillDirection = Enum.FillDirection.Horizontal
navLayout.Padding = UDim.new(0, 8)
navLayout.Parent = navRow

local function createNavBtn(name, text)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.BackgroundColor3 = Colors.DarkJadeElevated
    btn.Size = UDim2.new(0.235, 0, 0, 32)
    btn.BorderSizePixel = 0
    btn.Font = Fonts.Header
    btn.Text = text
    btn.TextColor3 = Colors.GoldLight
    btn.TextSize = 11
    btn.AutoButtonColor = false
    btn.Parent = navRow

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 5)
    c.Parent = btn

    local s = Instance.new("UIStroke")
    s.Color = Colors.GoldBorderDim
    s.Thickness = 1.2
    s.Parent = btn
    return btn
end

createNavBtn("RoadmapNavBtn", "ROADMAP (M)")
createNavBtn("CultNavBtn",    "CULTIVATE (C)")
createNavBtn("InvNavBtn",     "INVENTORY (B)")
createNavBtn("ShopNavBtn",    "MARKET (N)")

-- ============================================================================
-- B. FULL-SCREEN ROADMAP MODAL (Pure English)
-- ============================================================================
local roadModal = createPanel(
    cultScreen,
    UDim2.new(0.94, 0, 0.90, 0),
    UDim2.new(0.5, 0, 0.5, 0),
    "✦ XIANXIA RPG — DEVELOPMENT ROADMAP ✦",
    "CELESTIAL PROGRESSION VEIN · IMMORTAL PATHWAY"
)
roadModal.Name = "RoadmapModal"
roadModal.AnchorPoint = Vector2.new(0.5, 0.5)
roadModal.Visible = false
roadModal.ZIndex = 20

local closeRoad = Instance.new("TextButton")
closeRoad.Name = "CloseBtn"
closeRoad.BackgroundTransparency = 1
closeRoad.Size = UDim2.new(0, 30, 0, 30)
closeRoad.Position = UDim2.new(1, -38, 0, 10)
closeRoad.Font = Fonts.Title
closeRoad.Text = "✕"
closeRoad.TextColor3 = Colors.GoldLight
closeRoad.TextSize = 18
closeRoad.ZIndex = 25
closeRoad.Parent = roadModal

-- 1. LEFT PANEL: "CURRENT STATE (AS OF MAY 2026)" & "ENGINE SYSTEMS"
local leftPlaque = Instance.new("Frame")
leftPlaque.Name = "LeftPlaque"
leftPlaque.BackgroundColor3 = Colors.DarkJadeElevated
leftPlaque.Size = UDim2.new(0, 220, 1, -165)
leftPlaque.Position = UDim2.new(0, 14, 0, 58)
leftPlaque.BorderSizePixel = 0
leftPlaque.ZIndex = 21
leftPlaque.Parent = roadModal

local lpc = Instance.new("UICorner")
lpc.CornerRadius = UDim.new(0, 6)
lpc.Parent = leftPlaque

local lps = Instance.new("UIStroke")
lps.Color = Colors.GoldBorder
lps.Thickness = 1.2
lps.Parent = leftPlaque

local csTitle = Instance.new("TextLabel")
csTitle.Name = "CurrentStateTitle"
csTitle.BackgroundTransparency = 1
csTitle.Size = UDim2.new(1, 0, 0, 20)
csTitle.Position = UDim2.new(0, 0, 0, 8)
csTitle.Font = Fonts.Title
csTitle.Text = "CURRENT STATE"
csTitle.TextColor3 = Colors.GoldLight
csTitle.TextSize = 12
csTitle.ZIndex = 22
csTitle.Parent = leftPlaque

local csSub = Instance.new("TextLabel")
csSub.BackgroundTransparency = 1
csSub.Size = UDim2.new(1, 0, 0, 14)
csSub.Position = UDim2.new(0, 0, 0, 26)
csSub.Font = Fonts.Body
csSub.Text = "(AS OF MAY 2026)"
csSub.TextColor3 = Colors.TextMuted
csSub.TextSize = 9
csSub.ZIndex = 22
csSub.Parent = leftPlaque

local chkMedal = Instance.new("Frame")
chkMedal.Name = "CheckMedallion"
chkMedal.BackgroundColor3 = Colors.DarkJadeCard
chkMedal.Size = UDim2.new(0, 36, 0, 36)
chkMedal.Position = UDim2.new(0.5, 0, 0, 62)
chkMedal.AnchorPoint = Vector2.new(0.5, 0.5)
chkMedal.ZIndex = 22
chkMedal.Parent = leftPlaque

local cmc = Instance.new("UICorner")
cmc.CornerRadius = UDim.new(1, 0)
cmc.Parent = chkMedal

local cms = Instance.new("UIStroke")
cms.Color = Colors.GoldBorder
cms.Thickness = 1.8
cms.Parent = chkMedal

local chkTxt = Instance.new("TextLabel")
chkTxt.BackgroundTransparency = 1
chkTxt.Size = UDim2.new(1, 0, 1, 0)
chkTxt.Font = Fonts.Title
chkTxt.Text = "✓"
chkTxt.TextColor3 = Colors.GoldLight
chkTxt.TextSize = 18
chkTxt.ZIndex = 23
chkTxt.Parent = chkMedal

local esTitle = Instance.new("TextLabel")
esTitle.Name = "EngineSystemsTitle"
esTitle.BackgroundTransparency = 1
esTitle.Size = UDim2.new(1, -16, 0, 20)
esTitle.Position = UDim2.new(0, 10, 0, 86)
esTitle.Font = Fonts.Header
esTitle.Text = "ENGINE SYSTEMS"
esTitle.TextColor3 = Colors.GoldLight
esTitle.TextSize = 11
esTitle.TextXAlignment = Enum.TextXAlignment.Left
esTitle.ZIndex = 22
esTitle.Parent = leftPlaque

local sysList = Instance.new("ScrollingFrame")
sysList.Name = "SystemsList"
sysList.BackgroundTransparency = 1
sysList.Size = UDim2.new(1, -16, 1, -114)
sysList.Position = UDim2.new(0, 8, 0, 108)
sysList.ScrollBarThickness = 3
sysList.ScrollBarImageColor3 = Colors.GoldBorderDim
sysList.ZIndex = 22
sysList.Parent = leftPlaque

local sysLayout = Instance.new("UIListLayout")
sysLayout.Padding = UDim.new(0, 4)
sysLayout.Parent = sysList

local systems = {
    "Scene Engine (flags, outcomes)",
    "Combat System (data-driven)",
    "Quest System (multi-stage)",
    "Skill System (4 arts)",
    "Technique System (passives)",
    "Breakthrough System",
    "Elemental Essence (Qi)",
    "NPC Journal & Relations",
    "Social Scores (reputation)",
    "Interactive Quest Board",
    "Room Base System",
}

for _, sysItem in ipairs(systems) do
    local sl = Instance.new("TextLabel")
    sl.BackgroundTransparency = 1
    sl.Size = UDim2.new(1, 0, 0, 16)
    sl.Font = Fonts.Body
    sl.Text = sysItem
    sl.TextColor3 = Colors.TextMuted
    sl.TextSize = 9
    sl.TextXAlignment = Enum.TextXAlignment.Left
    sl.ZIndex = 23
    sl.Parent = sysList
end

-- 2. CENTER SERPENTINE PROGRESSION CANVAS (7 Phases)
local centerCanvas = Instance.new("Frame")
centerCanvas.Name = "CenterCanvas"
centerCanvas.BackgroundColor3 = Colors.DarkJadeBg
centerCanvas.Size = UDim2.new(1, -256, 1, -165)
centerCanvas.Position = UDim2.new(0, 242, 0, 58)
centerCanvas.BorderSizePixel = 0
centerCanvas.ZIndex = 21
centerCanvas.ClipsDescendants = true
centerCanvas.Parent = roadModal

local ccc = Instance.new("UICorner")
ccc.CornerRadius = UDim.new(0, 6)
ccc.Parent = centerCanvas

local ccs = Instance.new("UIStroke")
ccs.Color = Colors.GoldBorderDim
ccs.Thickness = 1.2
ccs.Parent = centerCanvas

local lineBanner = Instance.new("TextLabel")
lineBanner.Name = "LineBanner"
lineBanner.BackgroundTransparency = 1
lineBanner.Size = UDim2.new(1, 0, 0, 18)
lineBanner.Position = UDim2.new(0, 0, 0, 6)
lineBanner.Font = Fonts.Header
lineBanner.Text = "✦ DEVELOPMENT PROGRESS LINE · SPIRITUAL QI PATHWAY ✦"
lineBanner.TextColor3 = Colors.CyanGlow
lineBanner.TextSize = 10
lineBanner.ZIndex = 22
lineBanner.Parent = centerCanvas

local phases = {
    { num = "PHASE 1", title = "ENEMY ROSTER", status = "✓ COMPLETE", statusColor = Colors.CyanGlow, icon = "1", desc = "Spirit Boar · Viper · Bandit Scout", pos = UDim2.new(0.06, 0, 0.45, 0), active = false },
    { num = "PHASE 2", title = "TECHNIQUE EXP.", status = "✓ COMPLETE", statusColor = Colors.CyanGlow, icon = "2", desc = "Iron Body · Wind Blade · Void Step", pos = UDim2.new(0.21, 0, 0.28, 0), active = false },
    { num = "PHASE 3", title = "FIRST DUNGEON", status = "✓ COMPLETE", statusColor = Colors.CyanGlow, icon = "3", desc = "Black-Thread Hollow · Bone Hound", pos = UDim2.new(0.36, 0, 0.52, 0), active = false },
    { num = "PHASE 4", title = "NEARBY TOWN", status = "✓ COMPLETE", statusColor = Colors.CyanGlow, icon = "4", desc = "Iron Bridge Town · Market · Smith", pos = UDim2.new(0.51, 0, 0.32, 0), active = false },
    { num = "PHASE 5", title = "CRAFTING EXP.", status = "★ ACTIVE FOCUS", statusColor = Colors.GoldAmber, icon = "5", desc = "Alchemy Cauldron · Anvil · 13 Recipes", pos = UDim2.new(0.66, 0, 0.48, 0), active = true },
    { num = "PHASE 6", title = "MORTAL PEAK", status = "UPCOMING", statusColor = Colors.TextMuted, icon = "6", desc = "Sunder-Heart Palm · Ghost · Ascent", pos = UDim2.new(0.81, 0, 0.26, 0), active = false },
    { num = "PHASE 7", title = "INNER SECT", status = "FUTURE", statusColor = Colors.TextMuted, icon = "7", desc = "Celestial Pagoda · Qi Ascent", pos = UDim2.new(0.94, 0, 0.45, 0), active = false }
}

local energyStream = Instance.new("Frame")
energyStream.Name = "EnergyStream"
energyStream.BackgroundColor3 = Colors.CyanGlow
energyStream.BackgroundTransparency = 0.35
energyStream.Size = UDim2.new(0.92, 0, 0, 5)
energyStream.Position = UDim2.new(0.04, 0, 0.42, 0)
energyStream.BorderSizePixel = 0
energyStream.ZIndex = 22
energyStream.Parent = centerCanvas

local esCorner = Instance.new("UICorner")
esCorner.CornerRadius = UDim.new(1, 0)
esCorner.Parent = energyStream

for i, p in ipairs(phases) do
    local node = Instance.new("Frame")
    node.Name = "PhaseNode_" .. i
    node.BackgroundColor3 = Colors.DarkJadeElevated
    node.Size = UDim2.new(0, 106, 0, 128)
    node.Position = p.pos
    node.AnchorPoint = Vector2.new(0.5, 0.5)
    node.BorderSizePixel = 0
    node.ZIndex = 23
    node.Parent = centerCanvas

    local nc = Instance.new("UICorner")
    nc.CornerRadius = UDim.new(0, 6)
    nc.Parent = node

    local ns = Instance.new("UIStroke")
    ns.Color = p.active and Colors.GoldAmber or Colors.GoldBorderDim
    ns.Thickness = p.active and 2.2 or 1.2
    ns.Parent = node

    local tok = createOrb(node, 36, UDim2.new(0.5, 0, 0, 24))
    tok.AnchorPoint = Vector2.new(0.5, 0.5)
    tok.ZIndex = 24

    local tIcon = Instance.new("TextLabel")
    tIcon.BackgroundTransparency = 1
    tIcon.Size = UDim2.new(1, 0, 1, 0)
    tIcon.Font = Fonts.Title
    tIcon.Text = p.icon
    tIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    tIcon.TextSize = 18
    tIcon.ZIndex = 25
    tIcon.Parent = tok

    local pNum = Instance.new("TextLabel")
    pNum.BackgroundTransparency = 1
    pNum.Size = UDim2.new(1, 0, 0, 16)
    pNum.Position = UDim2.new(0, 0, 0, 48)
    pNum.Font = Fonts.Header
    pNum.Text = p.num
    pNum.TextColor3 = Colors.GoldLight
    pNum.TextSize = 11
    pNum.ZIndex = 24
    pNum.Parent = node

    local pTit = Instance.new("TextLabel")
    pTit.BackgroundTransparency = 1
    pTit.Size = UDim2.new(1, 0, 0, 16)
    pTit.Position = UDim2.new(0, 0, 0, 64)
    pTit.Font = Fonts.Title
    pTit.Text = p.title
    pTit.TextColor3 = Colors.TextWhite
    pTit.TextSize = 11
    pTit.ZIndex = 24
    pTit.Parent = node

    local pStat = Instance.new("TextLabel")
    pStat.BackgroundTransparency = 1
    pStat.Size = UDim2.new(1, 0, 0, 14)
    pStat.Position = UDim2.new(0, 0, 0, 80)
    pStat.Font = Fonts.Body
    pStat.Text = p.status
    pStat.TextColor3 = p.statusColor
    pStat.TextSize = 11
    pStat.ZIndex = 24
    pStat.Parent = node

    local pDesc = Instance.new("TextLabel")
    pDesc.BackgroundTransparency = 1
    pDesc.Size = UDim2.new(1, -6, 0, 30)
    pDesc.Position = UDim2.new(0, 3, 0, 94)
    pDesc.Font = Fonts.Body
    pDesc.Text = p.desc
    pDesc.TextColor3 = Colors.CyanMist
    pDesc.TextSize = 10
    pDesc.TextWrapped = true
    pDesc.ZIndex = 24
    pDesc.Parent = node
end

-- 3. BOTTOM TRAY: "DESIGN PRINCIPLES"
local bottomTray = Instance.new("Frame")
bottomTray.Name = "BottomPrinciplesTray"
bottomTray.BackgroundColor3 = Colors.DarkJadeElevated
bottomTray.Size = UDim2.new(1, -28, 0, 98)
bottomTray.Position = UDim2.new(0, 14, 1, -108)
bottomTray.BorderSizePixel = 0
bottomTray.ZIndex = 21
bottomTray.Parent = roadModal

local btc = Instance.new("UICorner")
btc.CornerRadius = UDim.new(0, 6)
btc.Parent = bottomTray

local bts = Instance.new("UIStroke")
bts.Color = Colors.GoldBorder
bts.Thickness = 1.2
bts.Parent = bottomTray

local dpPill = Instance.new("Frame")
dpPill.Name = "PrinciplesTitlePill"
dpPill.BackgroundColor3 = Colors.DarkJadeCard
dpPill.Size = UDim2.new(0, 110, 1, -12)
dpPill.Position = UDim2.new(0, 6, 0, 6)
dpPill.BorderSizePixel = 0
dpPill.ZIndex = 22
dpPill.Parent = bottomTray

local dpc = Instance.new("UICorner")
dpc.CornerRadius = UDim.new(0, 5)
dpc.Parent = dpPill

local dps = Instance.new("UIStroke")
dps.Color = Colors.GoldBorderDim
dps.Thickness = 1
dps.Parent = dpPill

local dpLabel = Instance.new("TextLabel")
dpLabel.BackgroundTransparency = 1
dpLabel.Size = UDim2.new(1, -8, 1, 0)
dpLabel.Position = UDim2.new(0, 4, 0, 0)
dpLabel.Font = Fonts.Title
dpLabel.Text = "DESIGN\nPRINCIPLES"
dpLabel.TextColor3 = Colors.GoldLight
dpLabel.TextSize = 11
dpLabel.ZIndex = 23
dpLabel.Parent = dpPill

local cardRow = Instance.new("Frame")
cardRow.Name = "CardsRow"
cardRow.BackgroundTransparency = 1
cardRow.Size = UDim2.new(1, -126, 1, -12)
cardRow.Position = UDim2.new(0, 120, 0, 6)
cardRow.ZIndex = 22
cardRow.Parent = bottomTray

local cLayout = Instance.new("UIListLayout")
cLayout.FillDirection = Enum.FillDirection.Horizontal
cLayout.Padding = UDim.new(0, 6)
cLayout.Parent = cardRow

local principles = {
    { n = "1. Valid Paths", sub = "Hermit vs Explorer" },
    { n = "2. Technique Parity", sub = "Standard vs Variants" },
    { n = "3. Faction Scores", sub = "Reputation & Rage" },
    { n = "4. Large World", sub = "Always more to find" },
    { n = "5. Story Over Grinding", sub = "Stat gains with sense" },
    { n = "6. Breakthrough Chapters", sub = "Narrative milestones" },
    { n = "7. Visible Power", sub = "Auras & reactions" },
}

for _, p in ipairs(principles) do
    local pc = Instance.new("Frame")
    pc.Name = "PrincipleCard"
    pc.BackgroundColor3 = Colors.ParchmentLight
    pc.Size = UDim2.new(0.134, 0, 1, 0)
    pc.BorderSizePixel = 0
    pc.ZIndex = 23
    pc.Parent = cardRow

    local pcc = Instance.new("UICorner")
    pcc.CornerRadius = UDim.new(0, 4)
    pcc.Parent = pc

    local pcs = Instance.new("UIStroke")
    pcs.Color = Colors.GoldBorderDim
    pcs.Thickness = 1.2
    pcs.Parent = pc

    local ptl = Instance.new("TextLabel")
    ptl.BackgroundTransparency = 1
    ptl.Size = UDim2.new(1, -4, 0, 26)
    ptl.Position = UDim2.new(0, 2, 0, 4)
    ptl.Font = Fonts.Header
    ptl.Text = p.n
    ptl.TextColor3 = Colors.InkDark
    ptl.TextSize = 11
    ptl.TextWrapped = true
    ptl.ZIndex = 24
    ptl.Parent = pc

    local psub = Instance.new("TextLabel")
    psub.BackgroundTransparency = 1
    psub.Size = UDim2.new(1, -4, 0, 42)
    psub.Position = UDim2.new(0, 2, 0, 32)
    psub.Font = Fonts.Body
    psub.Text = p.sub
    psub.TextColor3 = Colors.InkMedium
    psub.TextSize = 10
    psub.TextWrapped = true
    psub.ZIndex = 24
    psub.Parent = pc
end

-- ============================================================================
-- C. CULTIVATION MEDITATION MODAL (Pure English)
-- ============================================================================
local cultScroll = createPanel(
    cultScreen,
    UDim2.new(0, 520, 0, 510),
    UDim2.new(0.5, 0, 0.5, 0),
    "✦ XIANXIA RPG — CULTIVATION & TECHNIQUES ✦",
    "PROGRESSION PATHWAY · ACTIVE MEDITATION FOCUS"
)
cultScroll.Name = "CultivationScrollModal"
cultScroll.AnchorPoint = Vector2.new(0.5, 0.5)
cultScroll.Visible = false
cultScroll.ZIndex = 15

local closeCult = Instance.new("TextButton")
closeCult.Name = "CloseBtn"
closeCult.BackgroundTransparency = 1
closeCult.Size = UDim2.new(0, 26, 0, 26)
closeCult.Position = UDim2.new(1, -34, 0, 12)
closeCult.Font = Fonts.Title
closeCult.Text = "✕"
closeCult.TextColor3 = Colors.GoldLight
closeCult.TextSize = 16
closeCult.ZIndex = 17
closeCult.Parent = cultScroll

local taiji = Instance.new("Frame")
taiji.Name = "TaijiVortex"
taiji.BackgroundColor3 = Colors.DarkJadeElevated
taiji.Size = UDim2.new(0, 110, 0, 110)
taiji.Position = UDim2.new(0.5, 0, 0, 140)
taiji.AnchorPoint = Vector2.new(0.5, 0.5)
taiji.ZIndex = 16
taiji.Parent = cultScroll

local tc = Instance.new("UICorner")
tc.CornerRadius = UDim.new(1, 0)
tc.Parent = taiji

local ts = Instance.new("UIStroke")
ts.Color = Colors.CyanGlow
ts.Thickness = 2.5
ts.Parent = taiji

local tjIcon = Instance.new("TextLabel")
tjIcon.Name = "TaijiSymbol"
tjIcon.BackgroundTransparency = 1
tjIcon.Size = UDim2.new(1, 0, 1, 0)
tjIcon.Font = Fonts.Title
tjIcon.Text = "☯"
tjIcon.TextColor3 = Colors.GoldLight
tjIcon.TextSize = 58
tjIcon.ZIndex = 17
tjIcon.Parent = taiji

local statNodes = Instance.new("Frame")
statNodes.Name = "StatNodes"
statNodes.BackgroundTransparency = 1
statNodes.Size = UDim2.new(1, -36, 0, 134)
statNodes.Position = UDim2.new(0, 18, 0, 218)
statNodes.ZIndex = 16
statNodes.Parent = cultScroll

local sGrid = Instance.new("UIGridLayout")
sGrid.CellSize = UDim2.new(0.315, 0, 0, 58)
sGrid.CellPadding = UDim2.new(0.027, 0, 0, 10)
sGrid.Parent = statNodes

local stats = {
    { id = "QiGather", name = "QI GATHERING", val = "5.0/s" },
    { id = "Health",   name = "BODY HEALTH", val = "100" },
    { id = "Defense",  name = "IRON DEFENSE", val = "5" },
    { id = "Damage",   name = "TECHNIQUE POWER", val = "15" },
    { id = "Weapon",   name = "SPIRIT WEAPON", val = "None" },
    { id = "Armor",    name = "CELESTIAL ROBE", val = "None" },
}

for _, st in ipairs(stats) do
    local card = Instance.new("Frame")
    card.Name = st.id
    card.BackgroundColor3 = Colors.ParchmentLight
    card.Size = UDim2.new(1, 0, 1, 0)
    card.BorderSizePixel = 0
    card.ZIndex = 17
    card.Parent = statNodes

    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 6)
    cc.Parent = card

    local cs = Instance.new("UIStroke")
    cs.Color = Colors.GoldBorder
    cs.Thickness = 1.2
    cs.Parent = card

    local nl = Instance.new("TextLabel")
    nl.BackgroundTransparency = 1
    nl.Size = UDim2.new(1, 0, 0, 20)
    nl.Position = UDim2.new(0, 0, 0, 4)
    nl.Font = Fonts.Header
    nl.Text = st.name
    nl.TextColor3 = Color3.fromRGB(30, 95, 80)
    nl.TextSize = 11
    nl.ZIndex = 18
    nl.Parent = card

    local vl = Instance.new("TextLabel")
    vl.Name = "Val"
    vl.BackgroundTransparency = 1
    vl.Size = UDim2.new(1, 0, 0, 24)
    vl.Position = UDim2.new(0, 0, 0, 26)
    vl.Font = Fonts.Title
    vl.Text = st.val
    vl.TextColor3 = Color3.fromRGB(15, 20, 20)
    vl.TextSize = 14
    vl.ZIndex = 18
    vl.Parent = card
end

local breakProg = Instance.new("TextLabel")
breakProg.Name = "BreakProgressText"
breakProg.BackgroundTransparency = 1
breakProg.Size = UDim2.new(1, -36, 0, 22)
breakProg.Position = UDim2.new(0, 18, 0, 362)
breakProg.Font = Fonts.Title
breakProg.Text = "✦ BREAKTHROUGH REQUIREMENT: 0 / 100 QI ✦"
breakProg.TextColor3 = Colors.CyanGlow
breakProg.TextSize = 13
breakProg.ZIndex = 16
breakProg.Parent = cultScroll

local scrollQi = createBar(cultScroll, UDim2.new(1, -36, 0, 18), UDim2.new(0, 18, 0, 390), Colors.CyanGlow, "")
scrollQi.Name = "ScrollQiBar"
scrollQi.ZIndex = 16

local cultBtn = Instance.new("TextButton")
cultBtn.Name = "CinnabarActionBtn"
cultBtn.BackgroundColor3 = Colors.Cinnabar
cultBtn.Size = UDim2.new(1, -36, 0, 46)
cultBtn.Position = UDim2.new(0, 18, 0, 426)
cultBtn.BorderSizePixel = 0
cultBtn.Font = Fonts.Title
cultBtn.Text = "BEGIN MEDITATION"
cultBtn.TextColor3 = Colors.GoldLight
cultBtn.TextSize = 14
cultBtn.AutoButtonColor = false
cultBtn.ZIndex = 17
cultBtn.Parent = cultScroll

local cbc = Instance.new("UICorner")
cbc.CornerRadius = UDim.new(0, 6)
cbc.Parent = cultBtn

local cbs = Instance.new("UIStroke")
cbs.Color = Colors.GoldBorder
cbs.Thickness = 1.5
cbs.Parent = cultBtn

-- ============================================================================
-- D. INVENTORY & SHOP MODALS (Pure English)
-- ============================================================================
local invScroll = createPanel(
    cultScreen,
    UDim2.new(0, 480, 0, 460),
    UDim2.new(0.5, 0, 0.5, 0),
    "STOWED TREASURES & EQUIPMENT",
    "INVENTORY STORAGE · SPIRITUAL ARTIFACTS"
)
invScroll.Name = "InventoryScrollModal"
invScroll.AnchorPoint = Vector2.new(0.5, 0.5)
invScroll.Visible = false
invScroll.ZIndex = 15

local closeInv = Instance.new("TextButton")
closeInv.Name = "CloseBtn"
closeInv.BackgroundTransparency = 1
closeInv.Size = UDim2.new(0, 26, 0, 26)
closeInv.Position = UDim2.new(1, -34, 0, 12)
closeInv.Font = Fonts.Title
closeInv.Text = "✕"
closeInv.TextColor3 = Colors.GoldLight
closeInv.TextSize = 16
closeInv.ZIndex = 17
closeInv.Parent = invScroll

local invList = Instance.new("ScrollingFrame")
invList.Name = "ItemList"
invList.BackgroundTransparency = 1
invList.Size = UDim2.new(1, -30, 0, 370)
invList.Position = UDim2.new(0, 15, 0, 68)
invList.ScrollBarThickness = 4
invList.ScrollBarImageColor3 = Colors.GoldBorderDim
invList.ZIndex = 16
invList.Parent = invScroll
local invLyt = Instance.new("UIListLayout")
invLyt.Padding = UDim.new(0, 8)
invLyt.Parent = invList

local shopScroll = createPanel(
    cultScreen,
    UDim2.new(0, 480, 0, 480),
    UDim2.new(0.5, 0, 0.5, 0),
    "SPIRIT MARKETPLACE & APOTHECARY",
    "TOWN MERCHANT · ALCHEMY PILLS & WEAPONS"
)
shopScroll.Name = "ShopScrollModal"
shopScroll.AnchorPoint = Vector2.new(0.5, 0.5)
shopScroll.Visible = false
shopScroll.ZIndex = 15

local closeShop = Instance.new("TextButton")
closeShop.Name = "CloseBtn"
closeShop.BackgroundTransparency = 1
closeShop.Size = UDim2.new(0, 26, 0, 26)
closeShop.Position = UDim2.new(1, -34, 0, 12)
closeShop.Font = Fonts.Title
closeShop.Text = "✕"
closeShop.TextColor3 = Colors.GoldLight
closeShop.TextSize = 16
closeShop.ZIndex = 17
closeShop.Parent = shopScroll

local shopList = Instance.new("ScrollingFrame")
shopList.Name = "ShopItemList"
shopList.BackgroundTransparency = 1
shopList.Size = UDim2.new(1, -30, 0, 390)
shopList.Position = UDim2.new(0, 15, 0, 68)
shopList.ScrollBarThickness = 4
shopList.ScrollBarImageColor3 = Colors.GoldBorderDim
shopList.ZIndex = 16
shopList.Parent = shopScroll
local shopLyt = Instance.new("UIListLayout")
shopLyt.Padding = UDim.new(0, 8)
shopLyt.Parent = shopList

-- ============================================================================
-- 2. SETUP SkillUI (Hotbar & Martial Arts Book)
-- ============================================================================
local skillScreen = StarterGui:FindFirstChild("SkillUI")
if not skillScreen then
    skillScreen = Instance.new("ScreenGui")
    skillScreen.Name = "SkillUI"
    skillScreen.ResetOnSpawn = false
    skillScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    skillScreen.Parent = StarterGui
else
    skillScreen.ResetOnSpawn = false
    skillScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local oldHB = skillScreen:FindFirstChild("GuofengSkillHotbar")
    if oldHB then oldHB:Destroy() end
    local oldBK = skillScreen:FindFirstChild("MartialArtsBookModal")
    if oldBK then oldBK:Destroy() end
end

local hotbar = Instance.new("Frame")
hotbar.Name = "GuofengSkillHotbar"
hotbar.BackgroundTransparency = 1
hotbar.Size = UDim2.new(0, 390, 0, 84)
hotbar.Position = UDim2.new(0.5, 0, 1, -94)
hotbar.AnchorPoint = Vector2.new(0.5, 0)
hotbar.Parent = skillScreen

local hbLayout = Instance.new("UIListLayout")
hbLayout.FillDirection = Enum.FillDirection.Horizontal
hbLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
hbLayout.VerticalAlignment = Enum.VerticalAlignment.Center
hbLayout.Padding = UDim.new(0, 18)
hbLayout.Parent = hotbar

local skillDefaults = {
    { icon = "", name = "Sword Slash", bind = "1", cost = "0 QI", image = "rbxassetid://123519897558803" },
    { icon = "", name = "Flame Ball", bind = "2", cost = "15 QI", image = "rbxassetid://120346215585475" },
    { icon = "", name = "Palm Art", bind = "3", cost = "10 QI", image = "rbxassetid://103990413563680" },
    { icon = "", name = "Thunder Strike", bind = "4", cost = "25 QI", image = "rbxassetid://95852143249219" },
}

for i = 1, 4 do
    local d = skillDefaults[i]
    local orb = createOrb(hotbar, 72, UDim2.new(0, 0, 0, 0), d.bind)
    orb.Name = "SkillSlot_" .. i

    -- Button on top layer to ensure 100% click reliability
    local btn = Instance.new("TextButton")
    btn.Name = "Btn"
    btn.BackgroundTransparency = 1
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.Text = ""
    btn.ZIndex = 20
    btn.Active = true
    btn.Selectable = true
    btn.Parent = orb

    -- Qi Cost Pill (Bottom-left)
    local qp = Instance.new("Frame")
    qp.Name = "QiPill"
    qp.BackgroundColor3 = Colors.DarkJadeBg
    qp.Size = UDim2.new(0, 38, 0, 16)
    qp.Position = UDim2.new(0, -6, 1, -12)
    qp.BorderSizePixel = 0
    qp.ZIndex = 8
    qp.Active = false
    qp.Parent = orb

    local qpc = Instance.new("UICorner")
    qpc.CornerRadius = UDim.new(0, 4)
    qpc.Parent = qp

    local qps = Instance.new("UIStroke")
    qps.Color = Colors.CyanGlow
    qps.Thickness = 1
    qps.Parent = qp

    local qpt = Instance.new("TextLabel")
    qpt.BackgroundTransparency = 1
    qpt.Size = UDim2.new(1, 0, 1, 0)
    qpt.Font = Fonts.Header
    qpt.Text = d.cost
    qpt.TextColor3 = Colors.CyanBright
    qpt.TextSize = 9
    qpt.ZIndex = 9
    qpt.Active = false
    qpt.Parent = qp

    local icn = Instance.new("TextLabel")
    icn.Name = "Icon"
    icn.BackgroundTransparency = 1
    icn.Size = UDim2.new(1, 0, 0.58, 0)
    icn.Position = UDim2.new(0, 0, 0, 4)
    icn.Font = Fonts.Title
    icn.Text = d.icon
    icn.TextColor3 = Color3.fromRGB(255, 255, 255)
    icn.TextSize = 28
    icn.ZIndex = 4
    icn.Active = false
    icn.Parent = orb

    if d.image then
        local icnImg = Instance.new("ImageLabel")
        icnImg.Name = "IconImage"
        icnImg.BackgroundTransparency = 1
        icnImg.Size = UDim2.new(0.75, 0, 0.75, 0)
        icnImg.Position = UDim2.new(0.125, 0, 0.05, 0)
        icnImg.Image = d.image
        icnImg.ScaleType = Enum.ScaleType.Fit
        icnImg.ZIndex = 4
        icnImg.Parent = orb
        icn.Visible = false
    end

    local nl = Instance.new("TextLabel")
    nl.Name = "Name"
    nl.BackgroundTransparency = 1
    nl.Size = UDim2.new(1, 16, 0, 18)
    nl.Position = UDim2.new(0, -8, 0.65, 0)
    nl.Font = Fonts.Header
    nl.Text = d.name
    nl.TextColor3 = Colors.GoldLight
    nl.TextSize = 10
    nl.ZIndex = 5
    nl.Active = false
    nl.Parent = orb

    local ns = Instance.new("UIStroke")
    ns.Color = Colors.DarkJadeBg
    ns.Thickness = 1.2
    ns.Parent = nl

    local cdO = Instance.new("Frame")
    cdO.Name = "CDOverlay"
    cdO.BackgroundColor3 = Colors.DarkJadeBg
    cdO.BackgroundTransparency = 0.4
    cdO.Size = UDim2.new(1, 0, 0, 0)
    cdO.Position = UDim2.new(0, 0, 1, 0)
    cdO.AnchorPoint = Vector2.new(0, 1)
    cdO.BorderSizePixel = 0
    cdO.Visible = false
    cdO.ZIndex = 12
    cdO.Active = false
    cdO.Parent = orb

    local cdc = Instance.new("UICorner")
    cdc.CornerRadius = UDim.new(1, 0)
    cdc.Parent = cdO

    local cdt = Instance.new("TextLabel")
    cdt.Name = "CDText"
    cdt.BackgroundTransparency = 1
    cdt.Size = UDim2.new(1, 0, 1, 0)
    cdt.Font = Fonts.Title
    cdt.TextColor3 = Colors.GoldLight
    cdt.TextSize = 18
    cdt.ZIndex = 14
    cdt.Visible = false
    cdt.Active = false
    cdt.Parent = orb

    local cdts = Instance.new("UIStroke")
    cdts.Color = Colors.DarkJadeBg
    cdts.Thickness = 1.5
    cdts.Parent = cdt
end

local bookScroll = createPanel(
    skillScreen,
    UDim2.new(0, 500, 0, 480),
    UDim2.new(0.5, 0, 0.5, 0),
    "MARTIAL TECHNIQUES CODEX",
    "TECHNIQUE MASTERY · PASSIVE BONUSES AT RANK 5"
)
bookScroll.Name = "MartialArtsBookModal"
bookScroll.AnchorPoint = Vector2.new(0.5, 0.5)
bookScroll.Visible = false
bookScroll.ZIndex = 15

local closeBook = Instance.new("TextButton")
closeBook.Name = "CloseBtn"
closeBook.BackgroundTransparency = 1
closeBook.Size = UDim2.new(0, 26, 0, 26)
closeBook.Position = UDim2.new(1, -34, 0, 12)
closeBook.Font = Fonts.Title
closeBook.Text = "✕"
closeBook.TextColor3 = Colors.GoldLight
closeBook.TextSize = 16
closeBook.ZIndex = 17
closeBook.Parent = bookScroll

local bookList = Instance.new("ScrollingFrame")
bookList.Name = "SkillList"
bookList.BackgroundTransparency = 1
bookList.Size = UDim2.new(1, -30, 0, 390)
bookList.Position = UDim2.new(0, 15, 0, 68)
bookList.ScrollBarThickness = 4
bookList.ScrollBarImageColor3 = Colors.GoldBorderDim
bookList.ZIndex = 16
bookList.Parent = bookScroll
local bkLayout = Instance.new("UIListLayout")
bkLayout.Padding = UDim.new(0, 8)
bkLayout.Parent = bookList

return "SUCCESS: Xianxia RPG UI constructed completely in StarterGui (Pure English)!"
"""

if __name__ == "__main__":
    ok, out = exec_code(BUILD_SCRIPT)
    print(f"Success: {ok}\nOutput: {out}")
    sys.exit(0 if ok else 1)
