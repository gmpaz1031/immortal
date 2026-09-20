"""
bridge/clean_startergui_emojis.py
Removes all remaining emojis from StarterGui instances in Roblox Studio.
Replaces them with clean English text or prepares ImageLabels for icons.
"""

import sys
import json
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from exec import exec_code

CLEAN_CODE = """
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IconAssets = require(ReplicatedStorage.Shared.IconAssets)

local log = {}

-- 1. CultivationUI HUD GoldBanner
local cultUI = StarterGui:FindFirstChild("CultivationUI")
if cultUI then
    local hud = cultUI:FindFirstChild("GuofengHUD")
    if hud then
        -- GoldLabel
        local gb = hud:FindFirstChild("GoldBanner")
        if gb then
            local gl = gb:FindFirstChild("GoldLabel")
            if gl then
                gl.Text = "50 SPIRIT STONES"
                table.insert(log, "Cleaned GoldLabel text to '50 SPIRIT STONES'")
            end
        end
        
        -- NavRow buttons
        local nav = hud:FindFirstChild("NavRow")
        if nav then
            local btnMap = {
                RoadmapNavBtn = "ROADMAP (M)",
                CultNavBtn = "CULTIVATE (C)",
                InvNavBtn = "INVENTORY (B)",
                ShopNavBtn = "MARKET (N)",
            }
            for btnName, cleanText in pairs(btnMap) do
                local b = nav:FindFirstChild(btnName)
                if b then
                    b.Text = cleanText
                    table.insert(log, "Cleaned " .. btnName .. " to '" .. cleanText .. "'")
                end
            end
        end
    end
    
    -- Modals Header Titles
    local invModal = cultUI:FindFirstChild("InventoryScrollModal")
    if invModal then
        local hb = invModal:FindFirstChild("HeaderBanner")
        local tt = hb and hb:FindFirstChild("TitleText")
        if tt then
            tt.Text = "STOWED TREASURES & EQUIPMENT"
            table.insert(log, "Cleaned InventoryScrollModal TitleText")
        end
    end
    
    local shopModal = cultUI:FindFirstChild("ShopScrollModal")
    if shopModal then
        local hb = shopModal:FindFirstChild("HeaderBanner")
        local tt = hb and hb:FindFirstChild("TitleText")
        if tt then
            tt.Text = "SPIRIT MARKETPLACE & APOTHECARY"
            table.insert(log, "Cleaned ShopScrollModal TitleText")
        end
    end
    
    local roadmapModal = cultUI:FindFirstChild("RoadmapModal")
    if roadmapModal then
        local hb = roadmapModal:FindFirstChild("HeaderBanner")
        local tt = hb and hb:FindFirstChild("TitleText")
        if tt then
            tt.Text = "XIANXIA RPG - DEVELOPMENT ROADMAP"
            table.insert(log, "Cleaned RoadmapModal TitleText")
        end
        
        local lp = roadmapModal:FindFirstChild("LeftPlaque")
        if lp then
            local eTitle = lp:FindFirstChild("EngineSystemsTitle")
            if eTitle then
                eTitle.Text = "ENGINE SYSTEMS"
            end
            local sList = lp:FindFirstChild("SystemsList")
            if sList then
                local replacements = {
                    ["⚙️ Scene Engine (flags, outcomes)"] = "Scene Engine (flags, outcomes)",
                    ["⚔️ Combat System (data-driven)"] = "Combat System (data-driven)",
                    ["📜 Quest System (multi-stage)"] = "Quest System (multi-stage)",
                    ["🥋 Skill System (4 arts)"] = "Skill System (4 arts)",
                    ["📖 Technique System (passives)"] = "Technique System (passives)",
                    ["⚡ Breakthrough System"] = "Breakthrough System",
                    ["🔮 Elemental Essence (Qi)"] = "Elemental Essence (Qi)",
                    ["📔 NPC Journal & Relations"] = "NPC Journal & Relations",
                    ["⚖️ Social Scores (reputation)"] = "Social Scores (reputation)",
                    ["📋 Interactive Quest Board"] = "Interactive Quest Board",
                    ["🏠 Room Base System"] = "Room Base System",
                }
                for _, child in ipairs(sList:GetChildren()) do
                    if child:IsA("TextLabel") and replacements[child.Text] then
                        child.Text = replacements[child.Text]
                    end
                end
            end
        end
        
        local canvas = roadmapModal:FindFirstChild("CenterCanvas")
        if canvas then
            for i = 1, 7 do
                local node = canvas:FindFirstChild("PhaseNode_" .. i)
                if node then
                    local orb = node:FindFirstChild("GlowingCyanOrb")
                    local txt = orb and orb:FindFirstChild("TextLabel")
                    if txt then
                        txt.Text = tostring(i) -- Number instead of emoji
                    end
                end
            end
        end
    end
end

-- 2. SkillUI Hotbar & Book
local skillUI = StarterGui:FindFirstChild("SkillUI")
if skillUI then
    local hotbar = skillUI:FindFirstChild("GuofengSkillHotbar")
    if hotbar then
        local skillSlots = {
            SkillSlot_1 = "Sword Slash",
            SkillSlot_2 = "Flame Ball",
            SkillSlot_3 = "Palm Art",
            SkillSlot_4 = "Thunder Strike",
        }
        for slotName, skillName in pairs(skillSlots) do
            local slot = hotbar:FindFirstChild(slotName)
            if slot then
                local icn = slot:FindFirstChild("Icon")
                if icn then
                    icn.Visible = false
                    icn.Text = ""
                end
                
                local assetId = IconAssets.getSkillIcon(skillName)
                local icnImg = slot:FindFirstChild("IconImage")
                if not icnImg then
                    icnImg = Instance.new("ImageLabel")
                    icnImg.Name = "IconImage"
                    icnImg.BackgroundTransparency = 1
                    icnImg.Size = UDim2.new(0.75, 0, 0.75, 0)
                    icnImg.Position = UDim2.new(0.125, 0, 0.05, 0)
                    icnImg.ScaleType = Enum.ScaleType.Fit
                    icnImg.ZIndex = 4
                    icnImg.Parent = slot
                end
                if IconAssets.isUploaded(assetId) then
                    icnImg.Image = assetId
                    icnImg.Visible = true
                end
                table.insert(log, "Configured " .. slotName .. " with ImageLabel (" .. skillName .. ")")
            end
        end
    end
    
    local book = skillUI:FindFirstChild("MartialArtsBookModal")
    if book then
        local hb = book:FindFirstChild("HeaderBanner")
        local tt = hb and hb:FindFirstChild("TitleText")
        if tt then
            tt.Text = "MARTIAL TECHNIQUES CODEX"
            table.insert(log, "Cleaned MartialArtsBookModal TitleText")
        end
    end
end

return table.concat(log, "\\n")
"""

def clean():
    print("[Cleaning] Stripping emojis from StarterGui...")
    ok, res = exec_code(CLEAN_CODE, timeout=12.0)
    print(f"Result: {ok}\n{res}")

if __name__ == "__main__":
    clean()
