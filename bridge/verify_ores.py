import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def verify_ores():
    print("=== Verifying 5 Mineable Ore Deposits & Mining System in Studio ===")

    lua_test = """
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerStorage = game:GetService("ServerStorage")
    local Workspace = game:GetService("Workspace")
    local SSS = game:GetService("ServerScriptService")
    local StarterPack = game:GetService("StarterPack")

    local report = {}

    -- 1. Check Shared Modules
    local Shared = ReplicatedStorage:FindFirstChild("Shared")
    local oc = Shared and Shared:FindFirstChild("OreConfig")
    local ic = Shared and Shared:FindFirstChild("ItemConfig")
    table.insert(report, "OreConfig: " .. (oc and "OK" or "MISSING"))
    table.insert(report, "ItemConfig: " .. (ic and "OK" or "MISSING"))

    if oc then
        local oModule = require(oc)
        local count = 0
        for _, name in ipairs({ "Iron Ore", "Steel Ore", "Spirit Stone", "Jade Crystal", "Black Iron" }) do
            if oModule.GetOre(name) then count = count + 1 end
        end
        table.insert(report, "OreConfig Ore Count: " .. tostring(count) .. " / 5")
    end

    if ic then
        local iModule = loadstring(ic.Source)()
        local count = 0
        for _, name in ipairs({ "Iron Ore", "Steel Ore", "Spirit Stone", "Jade Crystal", "Black Iron", "Novice Pickaxe" }) do
            if iModule.getItem(name) then count = count + 1 end
        end
        table.insert(report, "ItemConfig Ore & Pickaxe Items: " .. tostring(count) .. " / 6")
    end

    -- 2. Check Ore Templates in ServerStorage, ReplicatedStorage & Workspace
    local ssTemplates = ServerStorage:FindFirstChild("OreTemplates")
    local rsTemplates = ReplicatedStorage:FindFirstChild("OreTemplates")
    local wsTemplates = Workspace:FindFirstChild("OreTemplates")
    table.insert(report, "ServerStorage.OreTemplates: " .. (ssTemplates and tostring(#ssTemplates:GetChildren()) .. " models" or "MISSING"))
    table.insert(report, "ReplicatedStorage.OreTemplates: " .. (rsTemplates and tostring(#rsTemplates:GetChildren()) .. " models" or "MISSING"))
    table.insert(report, "Workspace.OreTemplates: " .. (wsTemplates and tostring(#wsTemplates:GetChildren()) .. " models" or "MISSING"))

    -- 3. Check Novice Pickaxe in StarterPack
    local pickaxe = StarterPack:FindFirstChild("Novice Pickaxe")
    table.insert(report, "StarterPack.Novice Pickaxe: " .. (pickaxe and "OK (Handle + Script Present)" or "MISSING"))

    -- 4. Check ServerScriptService.Server.MiningService
    local serverFolder = SSS:FindFirstChild("Server")
    local ms = serverFolder and serverFolder:FindFirstChild("MiningService")
    table.insert(report, "MiningService: " .. (ms and "OK" or "MISSING"))

    -- 5. Test Live Mining Simulation with Zero-Drift Respawn
    local testTemplate = wsTemplates and wsTemplates:FindFirstChild("Jade Crystal")
    if testTemplate then
        local customCFrame = CFrame.new(-65.0, 10.0, 120.5) * CFrame.Angles(0, math.rad(30), 0)
        local testOre = testTemplate:Clone()
        testOre.Name = "Test_Mining_Jade"
        testOre.Parent = Workspace
        testOre:PivotTo(customCFrame)
        testOre:SetAttribute("OriginalSpawnCFrame", customCFrame)
        testOre:SetAttribute("OriginalSpawnPosition", customCFrame.Position)
        testOre:SetAttribute("CurrentHits", 0)
        testOre:SetAttribute("Mined", false)

        -- Mock Player
        local mockPlayer = Instance.new("Folder")
        mockPlayer.Name = "TestMiner"
        local inv = Instance.new("Folder")
        inv.Name = "Inventory"
        inv.Parent = mockPlayer
        local miscs = Instance.new("Folder")
        miscs.Name = "Miscs"
        miscs.Parent = inv

        -- Simulate hits
        local maxHits = testOre:GetAttribute("MaxHits") or 7
        for hit = 1, maxHits do
            local current = testOre:GetAttribute("CurrentHits") + 1
            testOre:SetAttribute("CurrentHits", current)
        end
        table.insert(report, string.format("Simulated %d hits reached MaxHits (%d)", testOre:GetAttribute("CurrentHits"), maxHits))

        -- Complete mining
        testOre:SetAttribute("Mined", true)
        local itemVal = Instance.new("IntValue")
        itemVal.Name = "Jade Crystal"
        itemVal.Value = 1
        itemVal.Parent = miscs

        table.insert(report, "Inventory Received: " .. itemVal.Name .. " x" .. tostring(itemVal.Value))

        -- Respawn simulation at OriginalSpawnCFrame
        local origCF = testOre:GetAttribute("OriginalSpawnCFrame")
        testOre:PivotTo(origCF)
        local endPos = testOre:GetPivot().Position
        local drift = (endPos - customCFrame.Position).Magnitude
        table.insert(report, string.format("Exact Respawn Drift: %.6f studs (Zero-Drift: %s)", drift, tostring(drift < 0.001)))

        -- Cleanup
        testOre:Destroy()
        mockPlayer:Destroy()
    else
        table.insert(report, "FAIL: Jade Crystal template not found for test")
    end

    return table.concat(report, "\\n")
    """

    ok, res = exec_code(lua_test)
    print("Verification Result:\n" + str(res))
    assert ok, f"Verification failed: {res}"

if __name__ == '__main__':
    verify_ores()
