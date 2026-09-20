-- scratch/test_sword_builder.luau
-- Builds a high-fidelity Eastern Katana on Swordsman_1 with proper grip and sharp kissaki tip

local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
if not enemies then return "No DestroyedVillage_Enemies" end
local s1 = enemies:FindFirstChild("Swordsman_1")
if not s1 then return "No Swordsman_1" end

local rightArm = s1:FindFirstChild("Right Arm")
if not rightArm then return "No Right Arm" end

-- 1. Remove old crude sword parts from Swordsman_1
for _, child in ipairs(s1:GetChildren()) do
    local n = child.Name:lower()
    if child:IsA("BasePart") and (n:find("hilt") or n:find("tsuba") or n:find("blade") or n:find("guard") or n:find("weapon") or n:find("katana")) then
        child:Destroy()
    end
end
local oldWeaponModel = s1:FindFirstChild("EquippedWeapon")
if oldWeaponModel then oldWeaponModel:Destroy() end

-- 2. Create Weapon Model
local weaponModel = Instance.new("Model")
weaponModel.Name = "EquippedWeapon"
weaponModel.Parent = s1

local function makeWeld(part0: BasePart, part1: BasePart, c0: CFrame?, c1: CFrame?)
    local w = Instance.new("Weld")
    w.Part0 = part0
    w.Part1 = part1
    w.C0 = c0 or CFrame.new()
    w.C1 = c1 or CFrame.new()
    w.Parent = part0
    return w
end

-- GRIP: Placed cleanly in the palm of Right Arm at (0, -1, 0)
-- Orientation: The hilt sits in the hand. The blade points forward along the striking direction (-Z when arm is forward)
local gripPart = Instance.new("Part")
gripPart.Name = "KatanaHilt"
gripPart.Size = Vector3.new(0.24, 0.95, 0.24)
gripPart.Color = Color3.fromRGB(30, 30, 36)
gripPart.Material = Enum.Material.SmoothPlastic
gripPart.CanCollide = false
gripPart.CastShadow = true
gripPart.Parent = weaponModel

local gripMesh = Instance.new("SpecialMesh")
gripMesh.MeshType = Enum.MeshType.Cylinder
gripMesh.Parent = gripPart

-- Weld Grip to Right Arm: Hand is at (0, -1, 0).
-- We align the hilt so the grip is in the hand, tilted forward so the blade extends forward/upward naturally
-- In Right Arm space: CFrame.new(0, -0.95, -0.1) * CFrame.Angles(math.rad(-90), 0, 0)
-- When rotated -90 on X, the cylinder's Y axis points along -Z (FORWARD)!
local gripC0 = CFrame.new(0, -0.95, -0.15) * CFrame.Angles(math.rad(-90), 0, 0)
makeWeld(rightArm, gripPart, gripC0)

-- POMMEL: End cap at the base of the hilt
local pommel = Instance.new("Part")
pommel.Name = "KatanaPommel"
pommel.Size = Vector3.new(0.32, 0.15, 0.32)
pommel.Color = Color3.fromRGB(180, 145, 75)
pommel.Material = Enum.Material.Metal
pommel.CanCollide = false
pommel.Parent = weaponModel

local pommelMesh = Instance.new("SpecialMesh")
pommelMesh.MeshType = Enum.MeshType.Cylinder
pommelMesh.Parent = pommel
makeWeld(gripPart, pommel, CFrame.new(0, -0.5, 0))

-- TSUBA (GUARD): Traditional Japanese disc guard at the top of the grip
local tsuba = Instance.new("Part")
tsuba.Name = "KatanaTsuba"
tsuba.Size = Vector3.new(0.7, 0.1, 0.7)
tsuba.Color = Color3.fromRGB(150, 120, 65)
tsuba.Material = Enum.Material.Metal
tsuba.CanCollide = false
tsuba.Parent = weaponModel

local tsubaMesh = Instance.new("SpecialMesh")
tsubaMesh.MeshType = Enum.MeshType.Cylinder
tsubaMesh.Parent = tsuba
makeWeld(gripPart, tsuba, CFrame.new(0, 0.5, 0))

-- HABAKI (Collar): Golden blade collar
local habaki = Instance.new("Part")
habaki.Name = "KatanaHabaki"
habaki.Size = Vector3.new(0.22, 0.25, 0.3)
habaki.Color = Color3.fromRGB(210, 175, 85)
habaki.Material = Enum.Material.Metal
habaki.CanCollide = false
habaki.Parent = weaponModel
makeWeld(tsuba, habaki, CFrame.new(0, 0.15, 0))

-- BLADE BODY: Sleek obsidian steel blade with sharp taper
local blade = Instance.new("Part")
blade.Name = "WeaponBlade"
blade.Size = Vector3.new(0.12, 3.2, 0.38)
blade.Color = Color3.fromRGB(40, 42, 48)
blade.Material = Enum.Material.Metal
blade.CanCollide = false
blade.CastShadow = true
blade.Parent = weaponModel
makeWeld(habaki, blade, CFrame.new(0, 1.7, 0))

-- BLADE TIP (KISSAKI): Razor-sharp angled wedge tip
local tip = Instance.new("WedgePart")
tip.Name = "BladeTip"
tip.Size = Vector3.new(0.12, 0.6, 0.38)
tip.Color = Color3.fromRGB(55, 58, 65)
tip.Material = Enum.Material.Metal
tip.CanCollide = false
tip.CastShadow = true
tip.Parent = weaponModel
-- Position wedge at top of blade, angled to form pointed kissaki
makeWeld(blade, tip, CFrame.new(0, 1.6 + 0.3, 0) * CFrame.Angles(math.rad(180), 0, 0))

-- SHADOW EMBER PARTICLES: Subtle dark shadow mist
local shadowFX = Instance.new("ParticleEmitter")
shadowFX.Name = "ShadowMist"
shadowFX.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 30, 95)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 15, 30)),
})
shadowFX.Size = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.15),
    NumberSequenceKeypoint.new(1, 0.4),
})
shadowFX.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.3),
    NumberSequenceKeypoint.new(0.7, 0.6),
    NumberSequenceKeypoint.new(1, 1),
})
shadowFX.Lifetime = NumberRange.new(0.4, 0.7)
shadowFX.Rate = 10
shadowFX.Speed = NumberRange.new(0.5, 1.5)
shadowFX.SpreadAngle = Vector2.new(20, 20)
shadowFX.LightEmission = 0.2
shadowFX.Parent = blade

return game:GetService("HttpService"):JSONEncode({
    success = true,
    weaponName = "ShadowKatana",
    partsCount = #weaponModel:GetChildren(),
    bladePosition = tostring(blade.Position),
    rightArmPosition = tostring(rightArm.Position),
})
