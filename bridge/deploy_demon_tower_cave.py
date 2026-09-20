import sys
import os

sys.path.append(os.path.dirname(__file__))
from exec import exec_code

ENV_LUA = """
local Workspace = game:GetService("Workspace")

local function createPart(name, size, color, material, pos, parent)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Color = color
    p.Material = material
    p.Position = pos
    p.Anchored = true
    p.CanCollide = true
    p.Parent = parent
    return p
end

--------------------------------------------------------------------------------
-- 1. DEMON CULT TOWER
--------------------------------------------------------------------------------
local towerFolder = Workspace:FindFirstChild("DemonCultTower")
if towerFolder then towerFolder:Destroy() end
towerFolder = Instance.new("Model")
towerFolder.Name = "DemonCultTower"
towerFolder.Parent = Workspace

local tCenter = Vector3.new(1000, 0, 1500)

-- Ground
createPart("TowerGround", Vector3.new(200, 1, 200), Color3.fromRGB(20, 15, 15), Enum.Material.Slate, tCenter - Vector3.new(0, 0.5, 0), towerFolder)

-- Multi-tiered Pagoda
local baseSize = 60
local heightOffset = 0
for tier = 1, 5 do
    -- Tier Base
    createPart("TierBase"..tier, Vector3.new(baseSize, 10, baseSize), Color3.fromRGB(15, 10, 10), Enum.Material.Wood, tCenter + Vector3.new(0, heightOffset + 5, 0), towerFolder)
    
    -- Tier Roof (Crimson)
    local roof = createPart("TierRoof"..tier, Vector3.new(baseSize + 10, 4, baseSize + 10), Color3.fromRGB(90, 10, 10), Enum.Material.Wood, tCenter + Vector3.new(0, heightOffset + 12, 0), towerFolder)
    
    -- Red glowing lanterns on corners
    for _, x in ipairs({-1, 1}) do
        for _, z in ipairs({-1, 1}) do
            local lx = (baseSize/2 + 2) * x
            local lz = (baseSize/2 + 2) * z
            local lantern = createPart("Lantern", Vector3.new(2, 3, 2), Color3.fromRGB(255, 30, 30), Enum.Material.Neon, tCenter + Vector3.new(lx, heightOffset + 9, lz), towerFolder)
            local ptLight = Instance.new("PointLight", lantern)
            ptLight.Color = Color3.fromRGB(255, 30, 30)
            ptLight.Range = 30
            ptLight.Brightness = 2
        end
    end
    
    heightOffset = heightOffset + 14
    baseSize = baseSize - 8
end

-- Blood Moon Skybox Effect (Local to Tower area via Atmosphere if possible, but we'll use a huge neon red sphere above it)
local bloodMoon = createPart("BloodMoon", Vector3.new(150, 150, 150), Color3.fromRGB(255, 10, 10), Enum.Material.Neon, tCenter + Vector3.new(0, 400, 300), towerFolder)
bloodMoon.Shape = Enum.PartType.Ball
bloodMoon.CanCollide = false
local mLight = Instance.new("PointLight", bloodMoon)
mLight.Color = Color3.fromRGB(255, 10, 10)
mLight.Range = 1000
mLight.Brightness = 1

--------------------------------------------------------------------------------
-- 2. DEMON CULT CAVE (Empty)
--------------------------------------------------------------------------------
local caveFolder = Workspace:FindFirstChild("DemonCultCave")
if caveFolder then caveFolder:Destroy() end
caveFolder = Instance.new("Model")
caveFolder.Name = "DemonCultCave"
caveFolder.Parent = Workspace

local cCenter = Vector3.new(1500, 0, 1000)

-- Cave Floor
createPart("CaveFloor", Vector3.new(250, 2, 250), Color3.fromRGB(25, 25, 30), Enum.Material.Slate, cCenter - Vector3.new(0, 1, 0), caveFolder)

-- Cave Walls (Simple Blocky Enclosure)
createPart("WallN", Vector3.new(250, 60, 20), Color3.fromRGB(25, 25, 30), Enum.Material.Slate, cCenter + Vector3.new(0, 30, -125), caveFolder)
createPart("WallS", Vector3.new(250, 60, 20), Color3.fromRGB(25, 25, 30), Enum.Material.Slate, cCenter + Vector3.new(0, 30, 125), caveFolder)
createPart("WallE", Vector3.new(20, 60, 250), Color3.fromRGB(25, 25, 30), Enum.Material.Slate, cCenter + Vector3.new(125, 30, 0), caveFolder)
createPart("WallW", Vector3.new(20, 60, 250), Color3.fromRGB(25, 25, 30), Enum.Material.Slate, cCenter + Vector3.new(-125, 30, 0), caveFolder)

-- Cave Ceiling
createPart("CaveCeiling", Vector3.new(250, 20, 250), Color3.fromRGB(25, 25, 30), Enum.Material.Slate, cCenter + Vector3.new(0, 60, 0), caveFolder)

-- Cyan Crystal Formations
for i = 1, 15 do
    local cx = cCenter.X + math.random(-100, 100)
    local cz = cCenter.Z + math.random(-100, 100)
    local height = math.random(10, 30)
    
    local crystal = createPart("CyanCrystal", Vector3.new(math.random(4, 8), height, math.random(4, 8)), Color3.fromRGB(30, 200, 255), Enum.Material.Neon, Vector3.new(cx, height/2, cz), caveFolder)
    crystal.Orientation = Vector3.new(math.random(-15, 15), math.random(0, 360), math.random(-15, 15))
    
    local cl = Instance.new("PointLight", crystal)
    cl.Color = Color3.fromRGB(30, 200, 255)
    cl.Range = 40
    cl.Brightness = 1.5
end

return "Tower & Cave generated successfully!"
"""

def generate_environments():
    print("Sending Tower and Cave payload...")
    success, output = exec_code(ENV_LUA, timeout=15.0)
    print(f"Success: {success}")
    print(f"Output:\n{output}")
    return success

if __name__ == "__main__":
    generate_environments()
