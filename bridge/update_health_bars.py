"""
bridge/update_health_bars.py
Updates all enemy health bars and names across DestroyedVillage_Enemies,
CaveEnemies_Templates, and ServerStorage backups:
- AlwaysOnTop = false (occluded by terrain/walls, not seen through obstacles)
- MaxDistance = 45 studs for normal enemies, 60 studs for boss (not visible from afar)
- Stud-based Size (UDim2 Scale, 0 Offset) so the bar scales naturally with perspective
  and NEVER increases in relative size as the player walks away.
- TextScaled = true with sharp PixelsPerStud for crisp typography.
"""

import sys
from exec import exec_code

LUA_CODE = r'''
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

local function reconfigureHealthBar(model, isBoss)
    local bbg = model:FindFirstChild("EnemyHealthGui")
    if not bbg then
        -- Also check if named differently or under Head
        bbg = model:FindFirstChildWhichIsA("BillboardGui", true)
    end
    if not bbg then return false end

    local isBossActual = isBoss or model.Name:find("Boss") ~= nil or (bbg:FindFirstChild("NameLabel") and bbg.NameLabel.Text:find("BOSS") ~= nil)

    -- 1. AlwaysOnTop disabled: occluded by walls, obstacles, terrain
    bbg.AlwaysOnTop = false

    -- 2. MaxDistance: not seen from afar
    bbg.MaxDistance = isBossActual and 58 or 44

    -- 3. World Stud Size: scales with 3D perspective, never stays fixed pixel size or balloons from afar
    bbg.Size = isBossActual and UDim2.new(5.6, 0, 1.15, 0) or UDim2.new(4.2, 0, 0.88, 0)
    bbg.StudsOffset = Vector3.new(0, isBossActual and 3.8 or 2.7, 0)

    -- 4. Reconfigure internal frames to proportional scale
    local nameLbl = bbg:FindFirstChild("NameLabel")
    if nameLbl then
        nameLbl.Size = UDim2.new(1, 0, 0.48, 0)
        nameLbl.Position = UDim2.new(0, 0, 0, 0)
        nameLbl.TextScaled = true
        local stroke = nameLbl:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Thickness = 1.2
        end
    end

    local hpFrame = bbg:FindFirstChild("HpBar")
    if hpFrame then
        hpFrame.Size = UDim2.new(1, 0, 0.38, 0)
        hpFrame.Position = UDim2.new(0, 0, 0.54, 0)
        
        local corner = hpFrame:FindFirstChildOfClass("UICorner")
        if corner then
            corner.CornerRadius = UDim.new(0.3, 0)
        end

        local hpFill = hpFrame:FindFirstChild("Fill")
        if hpFill then
            local fCorner = hpFill:FindFirstChildOfClass("UICorner")
            if fCorner then
                fCorner.CornerRadius = UDim.new(0.3, 0)
            end
        end

        local hpText = hpFrame:FindFirstChild("Value")
        if hpText then
            hpText.Size = UDim2.new(1, 0, 1, 0)
            hpText.Position = UDim2.new(0, 0, 0, 0)
            hpText.TextScaled = true
        end
    end

    return true
end

local updatedCount = 0
local list = {}

-- 1. Update Workspace.DestroyedVillage_Enemies
local villageFolder = Workspace:FindFirstChild("DestroyedVillage_Enemies")
if villageFolder then
    for _, m in ipairs(villageFolder:GetChildren()) do
        if reconfigureHealthBar(m, m.Name == "Swordmaster_Boss") then
            updatedCount = updatedCount + 1
            table.insert(list, "Workspace.DestroyedVillage_Enemies." .. m.Name)
        end
    end
end

-- 2. Update ServerStorage.DestroyedVillage_EnemyTemplates
local ssVillage = ServerStorage:FindFirstChild("DestroyedVillage_EnemyTemplates")
if ssVillage then
    for _, m in ipairs(ssVillage:GetChildren()) do
        if reconfigureHealthBar(m, m.Name == "Swordmaster_Boss") then
            updatedCount = updatedCount + 1
            table.insert(list, "ServerStorage.DestroyedVillage_EnemyTemplates." .. m.Name)
        end
    end
end

-- 3. Update Workspace.CaveEnemies_Templates
local caveFolder = Workspace:FindFirstChild("CaveEnemies_Templates")
if caveFolder then
    for _, m in ipairs(caveFolder:GetChildren()) do
        if reconfigureHealthBar(m, m.Name:find("Mother") ~= nil or m.Name:find("Supreme") ~= nil) then
            updatedCount = updatedCount + 1
            table.insert(list, "Workspace.CaveEnemies_Templates." .. m.Name)
        end
    end
end

-- 4. Update ServerStorage.CaveEnemies_Templates
local ssCave = ServerStorage:FindFirstChild("CaveEnemies_Templates")
if ssCave then
    for _, m in ipairs(ssCave:GetChildren()) do
        if reconfigureHealthBar(m, m.Name:find("Mother") ~= nil or m.Name:find("Supreme") ~= nil) then
            updatedCount = updatedCount + 1
            table.insert(list, "ServerStorage.CaveEnemies_Templates." .. m.Name)
        end
    end
end

return string.format("SUCCESS: Updated %d enemy health bars across Workspace and ServerStorage.\nAlwaysOnTop: false\nMaxDistance: 44 studs (58 for bosses)\nSize: Proportional 3D world studs (no ballooning from afar)", updatedCount)
'''

def run_update():
    print("Sending health bar configuration payload to Roblox Studio...")
    success, output = exec_code(LUA_CODE, timeout=25.0)
    print(f"Success: {success}")
    print(f"Output:\n{output}")
    return success

if __name__ == "__main__":
    ok = run_update()
    sys.exit(0 if ok else 1)
