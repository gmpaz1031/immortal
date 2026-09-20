import sys
import os

sys.path.append(os.path.dirname(__file__))
from exec import exec_code

MAPS_LUA = """
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local mapFolder = Workspace:FindFirstChild("Map")
if not mapFolder then
    mapFolder = Instance.new("Folder")
    mapFolder.Name = "Map"
    mapFolder.Parent = Workspace
end

-- Clear out previous attempts
local oldDV = mapFolder:FindFirstChild("DemonCultVillage")
if oldDV then oldDV:Destroy() end
local oldDT = mapFolder:FindFirstChild("DemonCultTower")
if oldDT then oldDT:Destroy() end
local oldDC = mapFolder:FindFirstChild("DemonCultCave")
if oldDC then oldDC:Destroy() end

--------------------------------------------------------------------------------
-- 1. Demon Cult Village
--------------------------------------------------------------------------------
local village = Instance.new("Model")
village.Name = "DemonCultVillage"
village.Parent = mapFolder

local sourceVillage = Workspace:FindFirstChild("ChineseCultivationVillage")
if sourceVillage then
    for _, c in ipairs(sourceVillage:GetChildren()) do
        local clone = c:Clone()
        clone.Parent = village
        -- Color it red/dark
        for _, p in ipairs(clone:GetDescendants()) do
            if p:IsA("BasePart") then
                p.Color = Color3.fromRGB(150, 20, 20)
                p.Material = Enum.Material.Wood
            end
        end
    end
end
-- Add some red glowing lanterns
local vCenter = Vector3.new(1000, 0, 1000)
village:PivotTo(CFrame.new(vCenter))

--------------------------------------------------------------------------------
-- 2. Demon Cult Tower
--------------------------------------------------------------------------------
local towerFolder = Instance.new("Model")
towerFolder.Name = "DemonCultTower"
towerFolder.Parent = mapFolder

local sourcePagoda = nil
local fantasyVillage = Workspace:FindFirstChild("ChineseFantasyVillage")
if fantasyVillage then
    for _, c in ipairs(fantasyVillage:GetChildren()) do
        if c.Name:match("pagoda") or c.Name:match("tower") then
            sourcePagoda = c:Clone()
            break
        end
    end
    if not sourcePagoda then
        sourcePagoda = fantasyVillage:GetChildren()[1]:Clone()
    end
end

if sourcePagoda then
    sourcePagoda.Parent = towerFolder
    -- Color crimson
    for _, p in ipairs(sourcePagoda:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Color = Color3.fromRGB(90, 10, 10)
        end
    end
    local tCenter = Vector3.new(1000, 0, 1500)
    sourcePagoda:PivotTo(CFrame.new(tCenter))
    
    local bloodMoon = Instance.new("Part")
    bloodMoon.Name = "BloodMoon"
    bloodMoon.Shape = Enum.PartType.Ball
    bloodMoon.Size = Vector3.new(150, 150, 150)
    bloodMoon.Color = Color3.fromRGB(255, 0, 0)
    bloodMoon.Material = Enum.Material.Neon
    bloodMoon.Position = tCenter + Vector3.new(0, 300, 250)
    bloodMoon.Anchored = true
    bloodMoon.CanCollide = false
    bloodMoon.Parent = towerFolder
    
    local bl = Instance.new("PointLight", bloodMoon)
    bl.Color = Color3.fromRGB(255, 0, 0)
    bl.Range = 1000
    bl.Brightness = 2
end

--------------------------------------------------------------------------------
-- 3. Demon Cult Cave (Terrain Tools)
--------------------------------------------------------------------------------
local caveCenter = Vector3.new(1500, 40, 1000)
Workspace.Terrain:FillBlock(CFrame.new(caveCenter), Vector3.new(250, 80, 250), Enum.Material.Slate)
Workspace.Terrain:FillBlock(CFrame.new(caveCenter), Vector3.new(230, 70, 230), Enum.Material.Air)

local caveFolder = Instance.new("Model")
caveFolder.Name = "DemonCultCave"
caveFolder.Parent = mapFolder

for i = 1, 20 do
    local cx = caveCenter.X + math.random(-100, 100)
    local cz = caveCenter.Z + math.random(-100, 100)
    local h = math.random(10, 30)
    local crystal = Instance.new("Part")
    crystal.Size = Vector3.new(math.random(4,10), h, math.random(4,10))
    crystal.Color = Color3.fromRGB(20, 200, 255)
    crystal.Material = Enum.Material.Neon
    crystal.Position = Vector3.new(cx, 15 + h/2, cz)
    crystal.Orientation = Vector3.new(math.random(-15,15), math.random(0,360), math.random(-15,15))
    crystal.Anchored = true
    crystal.Parent = caveFolder
    
    local pl = Instance.new("PointLight", crystal)
    pl.Color = Color3.fromRGB(20, 200, 255)
    pl.Range = 40
    pl.Brightness = 2
end

--------------------------------------------------------------------------------
-- 4. Lighting & Atmosphere
--------------------------------------------------------------------------------
local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
if not atmo then
    atmo = Instance.new("Atmosphere")
    atmo.Parent = Lighting
end
atmo.Density = 0.35
atmo.Color = Color3.fromRGB(150, 20, 20)

local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
if not cc then
    cc = Instance.new("ColorCorrectionEffect")
    cc.Parent = Lighting
end
cc.TintColor = Color3.fromRGB(255, 200, 200)
cc.Contrast = 0.2

return "Beautiful Maps generated!"
"""

def generate_maps():
    print("Sending map payload...")
    success, output = exec_code(MAPS_LUA, timeout=20.0)
    print(f"Success: {success}")
    print(f"Output:\n{output}")
    return success

if __name__ == "__main__":
    generate_maps()
