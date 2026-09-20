import sys
import os
import time
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def verify():
    print("=== Verifying All 3 User Improvements in Studio ===")
    
    lua_test = """
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerStorage = game:GetService("ServerStorage")
    local Workspace = game:GetService("Workspace")
    local SSS = game:GetService("ServerScriptService")
    local StarterGui = game:GetService("StarterGui")

    local report = {}

    -- 1. VERIFY UNIQUE PILL SHOP & COMPACT NAMEPLATE
    local pavilion = Workspace:FindFirstChild("PillRefiningPavilion") or Workspace:FindFirstChild("ShopMerchant")
    if not pavilion then
        table.insert(report, "FAIL: PillRefiningPavilion not found in Workspace")
    else
        table.insert(report, "SUCCESS: Found " .. pavilion.Name .. " in Workspace")
        local bbg = pavilion:FindFirstChild("ShopLabel", true)
        if bbg and bbg:IsA("BillboardGui") then
            local dist = bbg.MaxDistance
            local isCompact = dist > 0 and dist <= 40
            table.insert(report, string.format("ShopLabel BillboardGui MaxDistance: %s (Compact/Non-Giant: %s)", tostring(dist), tostring(isCompact)))
            local title = bbg:FindFirstChild("Title", true)
            local sub = bbg:FindFirstChild("Subtitle", true)
            if title and sub then
                table.insert(report, "ShopLabel Title: '" .. title.Text .. "'")
                table.insert(report, "ShopLabel Subtitle: '" .. sub.Text .. "'")
                -- Check for unicode emojis
                local hasEmoji = string.find(title.Text, "[^\x20-\x7E]") or string.find(sub.Text, "[^\x20-\x7E]")
                table.insert(report, "Zero Emojis in ShopLabel: " .. tostring(not hasEmoji))
            end
        else
            table.insert(report, "WARNING: ShopLabel BillboardGui not found directly")
        end

        local prompt = pavilion:FindFirstChildWhichIsA("ProximityPrompt", true)
        table.insert(report, "Shop ProximityPrompt: " .. (prompt and ("OK (" .. prompt.ActionText .. ")") or "MISSING"))
        local cd = pavilion:FindFirstChildWhichIsA("ClickDetector", true)
        table.insert(report, "Shop ClickDetector: " .. (cd and "OK" or "MISSING"))
    end

    -- 2. VERIFY HERB EXACT-POSITION RESPAWN
    local templates = Workspace:FindFirstChild("PlantTemplates") or ServerStorage:FindFirstChild("PlantTemplates")
    if templates then
        local herbCount = #templates:GetChildren()
        table.insert(report, "Plant Templates Count: " .. tostring(herbCount) .. " / 11")
        
        local spiritGrass = templates:FindFirstChild("Spirit Grass")
        if spiritGrass then
            local origPos = spiritGrass:GetAttribute("OriginalSpawnPosition")
            local origCF = spiritGrass:GetAttribute("OriginalSpawnCFrame")
            table.insert(report, "Spirit Grass OriginalSpawnCFrame attribute: " .. (origCF and "EXISTS" or "NIL"))
            table.insert(report, "Spirit Grass OriginalSpawnPosition attribute: " .. tostring(origPos))
        end
    else
        table.insert(report, "FAIL: PlantTemplates not found")
    end

    -- 3. VERIFY INVENTORY CODE LOGIC
    local clientScript = StarterGui.CultivationUI:FindFirstChild("CultivationClient")
    if clientScript then
        local src = clientScript.Source
        local hasDescendants = string.find(src, "inventory:GetDescendants()") ~= nil
        local hasInvUpdated = string.find(src, 'event == "InventoryUpdated"') ~= nil
        local hasOpenShop = string.find(src, 'event == "OpenShop"') ~= nil
        local hasAutoCanvas = string.find(src, "invItemList.AutomaticCanvasSize = Enum.AutomaticSize.Y") ~= nil
        
        table.insert(report, "CultivationClient has inventory:GetDescendants(): " .. tostring(hasDescendants))
        table.insert(report, "CultivationClient handles InventoryUpdated event: " .. tostring(hasInvUpdated))
        table.insert(report, "CultivationClient handles OpenShop event: " .. tostring(hasOpenShop))
        table.insert(report, "CultivationClient sets AutomaticCanvasSize: " .. tostring(hasAutoCanvas))
    else
        table.insert(report, "FAIL: CultivationClient not found in StarterGui.CultivationUI")
    end

    -- 4. VERIFY PLANT HARVEST SERVICE EXACT RESPAWN CODE
    local sss = SSS:FindFirstChild("Server")
    local phs = sss and sss:FindFirstChild("PlantHarvestService")
    if phs then
        local psrc = phs.Source
        local exactRespawn = string.find(psrc, 'plant:PivotTo(origCF)', 1, true) ~= nil or string.find(psrc, 'plant:PivotTo(CFrame.new(origPos))', 1, true) ~= nil
        local fireInvUpdated = string.find(psrc, 'remote:FireClient(player, "InventoryUpdated")', 1, true) ~= nil
        table.insert(report, "PlantHarvestService Exact CFrame Respawn Logic: " .. tostring(exactRespawn))
        table.insert(report, "PlantHarvestService fires InventoryUpdated: " .. tostring(fireInvUpdated))
    else
        table.insert(report, "FAIL: PlantHarvestService not found")
    end

    return table.concat(report, "\\n")
    """

    ok, res = exec_code(lua_test)
    print("Verification Result:\n" + str(res))

if __name__ == '__main__':
    verify()
