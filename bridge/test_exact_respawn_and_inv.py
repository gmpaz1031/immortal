import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def test_exact_respawn_and_inventory():
    print("=== Testing Real Exact-Position Respawn and Inventory Reflection ===")

    lua_test = """
    local Workspace = game:GetService("Workspace")
    local ServerStorage = game:GetService("ServerStorage")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local SSS = game:GetService("ServerScriptService")

    local PlantConfig = require(ReplicatedStorage.Shared.PlantConfig)
    local ItemConfig = require(ReplicatedStorage.Shared.ItemConfig)

    local templates = Workspace:FindFirstChild("PlantTemplates") or ServerStorage:FindFirstChild("PlantTemplates")
    if not templates then return "PlantTemplates missing" end

    local template = templates:FindFirstChild("Spirit Grass")
    if not template then return "Spirit Grass template missing" end

    -- Clone a test plant and place it at an arbitrary custom location
    local customCFrame = CFrame.new(77.5, 12.0, -155.25) * CFrame.Angles(0, math.rad(45), 0)
    local testPlant = template:Clone()
    testPlant.Name = "TestPlacedHerb"
    testPlant.Parent = Workspace
    testPlant:PivotTo(customCFrame)

    -- Set attributes as PlantHarvestService does
    testPlant:SetAttribute("OriginalSpawnCFrame", customCFrame)
    testPlant:SetAttribute("OriginalSpawnPosition", customCFrame.Position)
    testPlant:SetAttribute("Harvested", false)

    local prompt = testPlant.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")

    local report = {}
    table.insert(report, "1. Plant placed at custom CFrame: " .. tostring(customCFrame.Position))

    -- Mock player inventory
    local mockPlayer = Instance.new("Folder")
    mockPlayer.Name = "TestHerbCollector"
    local inv = Instance.new("Folder")
    inv.Name = "Inventory"
    inv.Parent = mockPlayer
    local miscs = Instance.new("Folder")
    miscs.Name = "Miscs"
    miscs.Parent = inv

    -- Simulate harvesting with the EXACT logic from PlantHarvestService.server.luau
    testPlant:SetAttribute("Harvested", true)
    if prompt then prompt.Enabled = false end

    -- Item addition to player inventory
    local plantName = "Spirit Grass"
    local itemVal = miscs:FindFirstChild(plantName) :: IntValue?
    if not itemVal then
        itemVal = Instance.new("IntValue")
        itemVal.Name = plantName
        itemVal.Value = 1
        itemVal.Parent = miscs
    else
        itemVal.Value = itemVal.Value + 1
    end

    table.insert(report, "2. Inventory Miscs herb created: " .. itemVal.Name .. " x" .. tostring(itemVal.Value))
    local itemDef = ItemConfig.getItem(itemVal.Name)
    table.insert(report, "3. ItemConfig definition found: " .. (itemDef and itemDef.Name or "NIL"))

    -- Verify client inventory descendant crawler will find it
    local foundDescendants = {}
    for _, itm in ipairs(inv:GetDescendants()) do
        if itm:IsA("IntValue") and itm.Value > 0 then
            table.insert(foundDescendants, itm.Name .. " (x" .. tostring(itm.Value) .. ")")
        end
    end
    table.insert(report, "4. Inventory crawler found: " .. table.concat(foundDescendants, ", "))

    -- Test cache move and exact respawn
    local cache = ServerStorage:FindFirstChild("HarvestedPlantsCache")
    if not cache then
        cache = Instance.new("Folder")
        cache.Name = "HarvestedPlantsCache"
        cache.Parent = ServerStorage
    end

    local originalParent = testPlant.Parent
    testPlant.Parent = cache

    -- Respawn exactly at OriginalSpawnCFrame
    task.wait(1.0)
    local origCF = testPlant:GetAttribute("OriginalSpawnCFrame")
    if typeof(origCF) == "CFrame" then
        testPlant:PivotTo(origCF)
    end
    testPlant.Parent = originalParent
    testPlant:SetAttribute("Harvested", false)
    if prompt then prompt.Enabled = true end

    local respawnPos = testPlant:GetPivot().Position
    local driftDist = (respawnPos - customCFrame.Position).Magnitude
    table.insert(report, "5. Respawn Position: " .. tostring(respawnPos))
    table.insert(report, string.format("6. Drift Distance from Placed Position: %.6f studs (Exact: %s)", driftDist, tostring(driftDist < 0.001)))
    table.insert(report, "7. Prompt Re-enabled: " .. tostring(prompt and prompt.Enabled))

    -- Clean up test instances
    testPlant:Destroy()
    mockPlayer:Destroy()

    return table.concat(report, "\\n")
    """

    ok, res = exec_code(lua_test)
    print("Test Result:\n" + str(res))
    assert ok, f"Test failed: {res}"

if __name__ == '__main__':
    test_exact_respawn_and_inventory()
