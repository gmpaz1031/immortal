import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

lua = """
local StarterGui = game:GetService("StarterGui")
local CultivationUI = StarterGui:WaitForChild("CultivationUI")
local GuofengTheme = require(game:GetService("ReplicatedStorage").Shared.GuofengTheme)

-- Check if DestinyAwardPopup already exists
local ex = CultivationUI:FindFirstChild("DestinyAwardPopup")
if ex then ex:Destroy() end

-- Full-screen modal overlay
local popup = Instance.new("Frame")
popup.Name = "DestinyAwardPopup"
popup.BackgroundColor3 = Color3.fromRGB(5, 10, 8)
popup.BackgroundTransparency = 0.45
popup.Position = UDim2.new(0, 0, 0, 0)
popup.Size = UDim2.new(1, 0, 1, 0)
popup.Visible = false
popup.ZIndex = 100
popup.Parent = CultivationUI

-- Centered Grand Card
local card = Instance.new("Frame")
card.Name = "Card"
card.BackgroundColor3 = GuofengTheme.Colors.DarkJadeCard
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Position = UDim2.new(0.5, 0, 0.5, 0)
card.Size = UDim2.new(0, 480, 0, 320)
card.ZIndex = 101
card.Parent = popup

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 12)
cardCorner.Parent = card

local cardStroke = Instance.new("UIStroke")
cardStroke.Name = "Stroke"
cardStroke.Color = GuofengTheme.Colors.GoldBorder
cardStroke.Thickness = 2.5
cardStroke.Parent = card

-- Close button 'X' in top-right
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

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeBtn

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

-- Giant Name
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

-- Multiplier Callout Banner
local multBanner = Instance.new("Frame")
multBanner.Name = "MultBanner"
multBanner.BackgroundColor3 = GuofengTheme.Colors.DarkJadeElevated
multBanner.Position = UDim2.new(0.1, 0, 0, 114)
multBanner.Size = UDim2.new(0.8, 0, 0, 36)
multBanner.ZIndex = 102
multBanner.Parent = card

local bannerCorner = Instance.new("UICorner")
bannerCorner.CornerRadius = UDim.new(0, 6)
bannerCorner.Parent = multBanner

local bannerStroke = Instance.new("UIStroke")
bannerStroke.Color = GuofengTheme.Colors.GoldBorderDim
bannerStroke.Thickness = 1
bannerStroke.Parent = multBanner

local multLabel = Instance.new("TextLabel")
multLabel.Name = "MultLabel"
multLabel.BackgroundTransparency = 1
multLabel.Size = UDim2.new(1, 0, 1, 0)
multLabel.Font = GuofengTheme.Fonts.Header
multLabel.Text = "Cultivation Qi Gather Speed: x25.0 Multiplier"
multLabel.TextColor3 = GuofengTheme.Colors.GoldLight
multLabel.TextSize = 14
multLabel.ZIndex = 103
multLabel.Parent = multBanner

-- Rarity / Chance Badge
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

return "Pre-placed DestinyAwardPopup in StarterGui.CultivationUI successfully!"
"""

ok, res = exec_code(lua)
print("Deploy popup:", ok, res)
