import sys
import os

sys.path.append(os.path.dirname(__file__))
from exec import exec_code

VILLAGE_LUA = """
local Workspace = game:GetService("Workspace")

local villageFolder = Workspace:FindFirstChild("DemonCultVillage")
if villageFolder then
    villageFolder:Destroy()
end
villageFolder = Instance.new("Folder")
villageFolder.Name = "DemonCultVillage"
villageFolder.Parent = Workspace

local center = Vector3.new(1000, 0, 1000)

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

-- Ground foundation
local ground = createPart("CultGround", Vector3.new(300, 1, 300), Color3.fromRGB(30, 20, 20), Enum.Material.Slate, center - Vector3.new(0, 0.5, 0), villageFolder)

-- Main Demonic Shrine/Pagoda
local shrineFolder = Instance.new("Model")
shrineFolder.Name = "DemonicShrine"
shrineFolder.Parent = villageFolder

-- Shrine Base
createPart("ShrineBase", Vector3.new(40, 2, 40), Color3.fromRGB(20, 20, 20), Enum.Material.Cobblestone, center + Vector3.new(0, 1, 0), shrineFolder)
-- Shrine Pillars
for x = -1, 1, 2 do
    for z = -1, 1, 2 do
        createPart("ShrinePillar", Vector3.new(2, 20, 2), Color3.fromRGB(15, 10, 10), Enum.Material.Wood, center + Vector3.new(x*18, 11, z*18), shrineFolder)
    end
end
-- Shrine Roof
local roof = createPart("ShrineRoof", Vector3.new(44, 4, 44), Color3.fromRGB(80, 15, 15), Enum.Material.Wood, center + Vector3.new(0, 22, 0), shrineFolder)
local roofTop = createPart("ShrineRoofTop", Vector3.new(30, 6, 30), Color3.fromRGB(80, 15, 15), Enum.Material.Wood, center + Vector3.new(0, 27, 0), shrineFolder)

-- Glowing Core in Shrine
local core = createPart("DemonicCore", Vector3.new(6, 6, 6), Color3.fromRGB(255, 30, 30), Enum.Material.Neon, center + Vector3.new(0, 10, 0), shrineFolder)
local coreLight = Instance.new("PointLight")
coreLight.Color = Color3.fromRGB(255, 30, 30)
coreLight.Range = 60
coreLight.Brightness = 3
coreLight.Parent = core

-- Add Torii Gates leading to the shrine
local function createToriiGate(pos, rotY)
    local gate = Instance.new("Model")
    gate.Name = "DemonicTorii"
    local c = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY), 0)
    
    local p1 = createPart("Pillar", Vector3.new(1.5, 12, 1.5), Color3.fromRGB(60, 10, 10), Enum.Material.Wood, (c * CFrame.new(-6, 6, 0)).Position, gate)
    p1.CFrame = c * CFrame.new(-6, 6, 0)
    local p2 = createPart("Pillar", Vector3.new(1.5, 12, 1.5), Color3.fromRGB(60, 10, 10), Enum.Material.Wood, (c * CFrame.new(6, 6, 0)).Position, gate)
    p2.CFrame = c * CFrame.new(6, 6, 0)
    local top1 = createPart("TopBeam", Vector3.new(16, 1.5, 1.5), Color3.fromRGB(20, 20, 20), Enum.Material.Wood, (c * CFrame.new(0, 12, 0)).Position, gate)
    top1.CFrame = c * CFrame.new(0, 12, 0)
    local top2 = createPart("TopBeam2", Vector3.new(14, 1.5, 1.5), Color3.fromRGB(80, 15, 15), Enum.Material.Wood, (c * CFrame.new(0, 9.5, 0)).Position, gate)
    top2.CFrame = c * CFrame.new(0, 9.5, 0)
    gate.Parent = villageFolder
end

-- Path of gates
for i=1, 4 do
    createToriiGate(center + Vector3.new(0, 0, 40 + i*20), 0)
end

-- Some ruined dark houses around
local function createHouse(pos, rotY)
    local h = Instance.new("Model")
    h.Name = "CultHouse"
    local c = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY), 0)
    
    local base = createPart("Base", Vector3.new(24, 1, 20), Color3.fromRGB(25, 25, 25), Enum.Material.Wood, (c * CFrame.new(0, 0.5, 0)).Position, h)
    base.CFrame = c * CFrame.new(0, 0.5, 0)
    
    local wall1 = createPart("Wall", Vector3.new(24, 10, 1), Color3.fromRGB(30, 20, 20), Enum.Material.Wood, (c * CFrame.new(0, 5.5, -9.5)).Position, h)
    wall1.CFrame = c * CFrame.new(0, 5.5, -9.5)
    local wall2 = createPart("Wall", Vector3.new(24, 10, 1), Color3.fromRGB(30, 20, 20), Enum.Material.Wood, (c * CFrame.new(0, 5.5, 9.5)).Position, h)
    wall2.CFrame = c * CFrame.new(0, 5.5, 9.5)
    local wall3 = createPart("Wall", Vector3.new(1, 10, 20), Color3.fromRGB(30, 20, 20), Enum.Material.Wood, (c * CFrame.new(-11.5, 5.5, 0)).Position, h)
    wall3.CFrame = c * CFrame.new(-11.5, 5.5, 0)
    
    local roof = createPart("Roof", Vector3.new(26, 2, 22), Color3.fromRGB(15, 15, 15), Enum.Material.Wood, (c * CFrame.new(0, 11, 0)).Position, h)
    roof.CFrame = c * CFrame.new(0, 11, 0) * CFrame.Angles(0, 0, math.rad(5))

    -- Add a red lantern/light
    local lightPart = createPart("Lantern", Vector3.new(1, 1.5, 1), Color3.fromRGB(255, 50, 50), Enum.Material.Neon, (c * CFrame.new(0, 8, -10)).Position, h)
    lightPart.CFrame = c * CFrame.new(0, 8, -10.5)
    local ptLight = Instance.new("PointLight")
    ptLight.Color = Color3.fromRGB(255, 50, 50)
    ptLight.Range = 25
    ptLight.Parent = lightPart

    h.Parent = villageFolder
end

createHouse(center + Vector3.new(-60, 0, 0), 90)
createHouse(center + Vector3.new(60, 0, 0), -90)
createHouse(center + Vector3.new(-40, 0, -60), 0)
createHouse(center + Vector3.new(40, 0, -60), 0)
createHouse(center + Vector3.new(-80, 0, 40), 90)
createHouse(center + Vector3.new(80, 0, 40), -90)

return "Demon Cult Village generated at 1000, 0, 1000"
"""

def generate_village():
    print("Sending Demon Cult Village generation payload to Roblox Studio...")
    success, output = exec_code(VILLAGE_LUA, timeout=15.0)
    print(f"Success: {success}")
    print(f"Output:\n{output}")
    return success

if __name__ == "__main__":
    generate_village()
