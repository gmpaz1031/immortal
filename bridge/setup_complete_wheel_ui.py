import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

setup_lua = """
local StarterGui = game:GetService("StarterGui")
local CultivationUI = StarterGui:WaitForChild("CultivationUI")
local GuofengTheme = require(game:GetService("ReplicatedStorage").Shared.GuofengTheme)

-- 1. Ensure WheelDisc is a CanvasGroup
local wheelModal = CultivationUI:WaitForChild("DestinyWheelModal")
local leftCol = wheelModal:WaitForChild("LeftColumn")
local wheelRim = leftCol:WaitForChild("WheelRim")

local existingDisc = wheelRim:FindFirstChild("WheelDisc")
if existingDisc then
    existingDisc:Destroy()
end

local wheelDisc = Instance.new("CanvasGroup")
wheelDisc.Name = "WheelDisc"
wheelDisc.BackgroundColor3 = GuofengTheme.Colors.DarkJadeBg
wheelDisc.AnchorPoint = Vector2.new(0.5, 0.5)
wheelDisc.Position = UDim2.new(0.5, 0, 0.5, 0)
wheelDisc.Size = UDim2.new(0.92, 0, 0.92, 0)
wheelDisc.BorderSizePixel = 0
wheelDisc.ZIndex = 32
wheelDisc.Parent = wheelRim

local discCorner = Instance.new("UICorner")
discCorner.CornerRadius = UDim.new(1, 0)
discCorner.Parent = wheelDisc

-- Ensure Pointer is styled and at 12 o'clock
local pointer = wheelRim:FindFirstChild("Pointer")
if not pointer then
    pointer = Instance.new("Frame")
    pointer.Name = "Pointer"
    pointer.Parent = wheelRim
end
pointer.BackgroundColor3 = GuofengTheme.Colors.GoldLight
pointer.AnchorPoint = Vector2.new(0.5, 0.5)
pointer.Position = UDim2.new(0.5, 0, 0, 0)
pointer.Size = UDim2.new(0, 16, 0, 16)
pointer.Rotation = 45
pointer.ZIndex = 36

local pStroke = pointer:FindFirstChildOfClass("UIStroke")
if not pStroke then
    pStroke = Instance.new("UIStroke")
    pStroke.Parent = pointer
end
pStroke.Color = Color3.fromRGB(255, 255, 255)
pStroke.Thickness = 1.5

-- 2. Build or update DestinyAwardPopup in StarterGui.CultivationUI
local existingPopup = CultivationUI:FindFirstChild("DestinyAwardPopup")
if existingPopup then
    existingPopup:Destroy()
end

local awardPopup = Instance.new("Frame")
awardPopup.Name = "DestinyAwardPopup"
awardPopup.BackgroundColor3 = Color3.fromRGB(4, 8, 7)
awardPopup.BackgroundTransparency = 0.4
awardPopup.Position = UDim2.new(0, 0, 0, 0)
awardPopup.Size = UDim2.new(1, 0, 1, 0)
awardPopup.Visible = false
awardPopup.ZIndex = 100
awardPopup.Parent = CultivationUI

-- Centered Grand Card
local card = Instance.new("Frame")
card.Name = "Card"
card.BackgroundColor3 = GuofengTheme.Colors.DarkJadeCard
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Position = UDim2.new(0.5, 0, 0.5, 0)
card.Size = UDim2.new(0, 480, 0, 320)
card.ZIndex = 101
card.Parent = awardPopup

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 12)
cardCorner.Parent = card

local cardStroke = Instance.new("UIStroke")
cardStroke.Name = "Stroke"
cardStroke.Color = GuofengTheme.Colors.GoldBorder
cardStroke.Thickness = 2.5
cardStroke.Parent = card

-- Top Header Pill
local headerPill = Instance.new("Frame")
headerPill.Name = "HeaderPill"
headerPill.BackgroundColor3 = GuofengTheme.Colors.DarkJadeHeader
headerPill.AnchorPoint = Vector2.new(0.5, 0)
headerPill.Position = UDim2.new(0.5, 0, 0, 16)
headerPill.Size = UDim2.new(0, 260, 0, 28)
headerPill.ZIndex = 102
headerPill.Parent = card

local pillCorner = Instance.new("UICorner")
pillCorner.CornerRadius = UDim.new(0, 6)
pillCorner.Parent = headerPill

local pillStroke = Instance.new("UIStroke")
pillStroke.Color = GuofengTheme.Colors.GoldBorderDim
pillStroke.Thickness = 1
pillStroke.Parent = headerPill

local headerLabel = Instance.new("TextLabel")
headerLabel.Name = "HeaderLabel"
headerLabel.BackgroundTransparency = 1
headerLabel.Size = UDim2.new(1, 0, 1, 0)
headerLabel.Font = GuofengTheme.Fonts.Title
headerLabel.Text = "DESTINY AWAKENED"
headerLabel.TextColor3 = GuofengTheme.Colors.GoldLight
headerLabel.TextSize = 13
headerLabel.ZIndex = 103
headerLabel.Parent = headerPill

-- Giant Title
local nameLabel = Instance.new("TextLabel")
nameLabel.Name = "NameLabel"
nameLabel.BackgroundTransparency = 1
nameLabel.Position = UDim2.new(0, 20, 0, 56)
nameLabel.Size = UDim2.new(1, -40, 0, 48)
nameLabel.Font = GuofengTheme.Fonts.Title
nameLabel.Text = "Heaven-Defying Talent"
nameLabel.TextColor3 = GuofengTheme.Colors.CyanBright
nameLabel.TextScaled = true
nameLabel.ZIndex = 102
nameLabel.Parent = card

-- Multiplier Banner
local multBanner = Instance.new("Frame")
multBanner.Name = "MultBanner"
multBanner.BackgroundColor3 = GuofengTheme.Colors.DarkJadeElevated
multBanner.Position = UDim2.new(0.08, 0, 0, 114)
multBanner.Size = UDim2.new(0.84, 0, 0, 36)
multBanner.ZIndex = 102
multBanner.Parent = card

local bCorner = Instance.new("UICorner")
bCorner.CornerRadius = UDim.new(0, 6)
bCorner.Parent = multBanner

local bStroke = Instance.new("UIStroke")
bStroke.Color = GuofengTheme.Colors.GoldBorderDim
bStroke.Thickness = 1
bStroke.Parent = multBanner

local multLabel = Instance.new("TextLabel")
multLabel.Name = "MultLabel"
multLabel.BackgroundTransparency = 1
multLabel.Size = UDim2.new(1, 0, 1, 0)
multLabel.Font = GuofengTheme.Fonts.Header
multLabel.Text = "Cultivation Qi Speed: x25.0 Multiplier"
multLabel.TextColor3 = GuofengTheme.Colors.GoldLight
multLabel.TextSize = 14
multLabel.ZIndex = 103
multLabel.Parent = multBanner

-- Rarity & Chance Label
local chanceLabel = Instance.new("TextLabel")
chanceLabel.Name = "ChanceLabel"
chanceLabel.BackgroundTransparency = 1
chanceLabel.Position = UDim2.new(0, 20, 0, 158)
chanceLabel.Size = UDim2.new(1, -40, 0, 20)
chanceLabel.Font = GuofengTheme.Fonts.Header
chanceLabel.Text = "Rarity: Supreme Chaos | Probability: 0.05%"
chanceLabel.TextColor3 = GuofengTheme.Colors.CyanBright
chanceLabel.TextSize = 11
chanceLabel.ZIndex = 102
chanceLabel.Parent = card

-- Description Box
local descBox = Instance.new("TextLabel")
descBox.Name = "DescBox"
descBox.BackgroundTransparency = 1
descBox.Position = UDim2.new(0, 24, 0, 184)
descBox.Size = UDim2.new(1, -48, 0, 50)
descBox.Font = GuofengTheme.Fonts.Body
descBox.Text = "Defies destiny itself. Infinite cultivation potential unmatched in the universe."
descBox.TextColor3 = GuofengTheme.Colors.TextMuted
descBox.TextSize = 12
descBox.TextWrapped = true
descBox.ZIndex = 102
descBox.Parent = card

-- Claim Button
local claimBtn = Instance.new("TextButton")
claimBtn.Name = "ClaimBtn"
claimBtn.BackgroundColor3 = GuofengTheme.Colors.Cinnabar
claimBtn.AnchorPoint = Vector2.new(0.5, 0)
claimBtn.Position = UDim2.new(0.5, 0, 0, 248)
claimBtn.Size = UDim2.new(0, 220, 0, 42)
claimBtn.Font = GuofengTheme.Fonts.Header
claimBtn.Text = "CLAIM DESTINY"
claimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
claimBtn.TextSize = 14
claimBtn.AutoButtonColor = true
claimBtn.ZIndex = 103
claimBtn.Parent = card

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = claimBtn

local btnStroke = Instance.new("UIStroke")
btnStroke.Color = GuofengTheme.Colors.GoldBorder
btnStroke.Thickness = 1.5
btnStroke.Parent = claimBtn

-- Close Button 'X'
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.BackgroundColor3 = GuofengTheme.Colors.DarkJadeElevated
closeBtn.Position = UDim2.new(1, -38, 0, 12)
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Font = GuofengTheme.Fonts.Header
closeBtn.Text = "X"
closeBtn.TextColor3 = GuofengTheme.Colors.GoldLight
closeBtn.TextSize = 13
closeBtn.ZIndex = 105
closeBtn.Parent = card

local cCorner = Instance.new("UICorner")
cCorner.CornerRadius = UDim.new(0, 4)
cCorner.Parent = closeBtn

return "Complete Wheel UI setup verified in StarterGui!"
"""

ok, res = exec_code(setup_lua)
print("UI Setup result:", ok, res)
assert ok, f"UI Setup failed: {res}"
