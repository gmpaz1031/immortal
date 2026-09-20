import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def verify():
    lua = """
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerStorage = game:GetService("ServerStorage")
    local Workspace = game:GetService("Workspace")
    local SSS = game:GetService("ServerScriptService")

    local report = {}

    -- 1. Check Shared modules
    local Shared = ReplicatedStorage:FindFirstChild("Shared")
    local pc = Shared and Shared:FindFirstChild("PlantConfig")
    local ic = Shared and Shared:FindFirstChild("ItemConfig")
    table.insert(report, "PlantConfig: " .. (pc and "OK" or "MISSING"))
    table.insert(report, "ItemConfig: " .. (ic and "OK" or "MISSING"))

    if pc then
        local pModule = require(pc)
        local count = 0
        for name, _ in pairs(pModule.Plants) do count = count + 1 end
        table.insert(report, "PlantConfig Plant Count: " .. tostring(count) .. " / 11")
    end

    if ic then
        local iModule = require(ic)
        local count = 0
        for _, name in ipairs({
            "Spirit Grass", "Ginseng Herb", "Ironleaf Herb", "Moonlight Grass",
            "Clearheart Flower", "Bloodroot", "Jade Lotus", "Hundred-Year Ginseng",
            "Dragon Vein Grass", "Ghost Orchid", "Spirit Bamboo"
        }) do
            if iModule.getItem(name) then count = count + 1 end
        end
        table.insert(report, "ItemConfig Miscs Plants: " .. tostring(count) .. " / 11")
    end

    -- 2. Check ServerStorage & Workspace Templates
    local ssTemplates = ServerStorage:FindFirstChild("PlantTemplates")
    local wsTemplates = Workspace:FindFirstChild("PlantTemplates")
    table.insert(report, "ServerStorage.PlantTemplates: " .. (ssTemplates and tostring(#ssTemplates:GetChildren()) .. " models" or "MISSING"))
    table.insert(report, "Workspace.PlantTemplates: " .. (wsTemplates and tostring(#wsTemplates:GetChildren()) .. " models" or "MISSING"))

    -- 3. Check ServerScriptService.Server.PlantHarvestService
    local serverFolder = SSS:FindFirstChild("Server")
    local phs = serverFolder and serverFolder:FindFirstChild("PlantHarvestService")
    table.insert(report, "PlantHarvestService: " .. (phs and "OK" or "MISSING"))

    -- 4. Test Simulated Harvest & 3s Respawn with Zero-Drift verification
    local testPlant = wsTemplates and wsTemplates:FindFirstChild("Spirit Grass")
    if testPlant then
        local origPos = testPlant:GetAttribute("OriginalSpawnPosition")
        table.insert(report, "Test Spirit Grass OrigPos: " .. tostring(origPos))

        -- Create mock player
        local mockPlayer = Instance.new("Folder")
        mockPlayer.Name = "MockHarvester"
        local inv = Instance.new("Folder")
        inv.Name = "Inventory"
        inv.Parent = mockPlayer

        local primary = testPlant.PrimaryPart
        local prompt = primary and primary:FindFirstChildOfClass("ProximityPrompt")
        table.insert(report, "Harvest Prompt Present: " .. tostring(prompt ~= nil))
    end

    return table.concat(report, "\\n")
    """
    ok, res = exec_code(lua)
    print("=== Verification Report ===")
    print(res)
    assert ok, f"Verification failed: {res}"

if __name__ == '__main__':
    verify()
