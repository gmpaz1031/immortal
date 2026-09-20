-- scratch/apply_all_swords.luau
-- Authoritative builder for all 6 Xianxia swords on DestroyedVillage_Enemies in Studio

local enemiesFolder = workspace:FindFirstChild("DestroyedVillage_Enemies")
if not enemiesFolder then return "DestroyedVillage_Enemies not found!" end

local function makeWeld(part0: BasePart, part1: BasePart, c0: CFrame?, c1: CFrame?)
    local w = Instance.new("Weld")
    w.Part0 = part0
    w.Part1 = part1
    w.C0 = c0 or CFrame.new()
    w.C1 = c1 or CFrame.new()
    w.Parent = part0
    return w
end

local function cleanOldWeapons(model: Model)
    for _, child in ipairs(model:GetChildren()) do
        local n = child.Name:lower()
        if child:IsA("BasePart") and (n:find("hilt") or n:find("tsuba") or n:find("blade") or n:find("guard") or n:find("weapon") or n:find("katana") or n:find("dao") or n:find("cleaver") or n:find("jian")) then
            child:Destroy()
        end
    end
    local oldModel = model:FindFirstChild("EquippedWeapon")
    if oldModel then oldModel:Destroy() end
end

-- ============================================================================
-- 1. SHADOW KATANA (Swordsman_1)
-- ============================================================================
local function buildShadowKatana(model: Model)
    cleanOldWeapons(model)
    local rightArm = model:FindFirstChild("Right Arm") :: BasePart?
    if not rightArm then return end

    local weaponModel = Instance.new("Model")
    weaponModel.Name = "EquippedWeapon"
    weaponModel.Parent = model

    -- Grip in right palm
    local grip = Instance.new("Part")
    grip.Name = "KatanaHilt"
    grip.Size = Vector3.new(0.24, 0.95, 0.24)
    grip.Color = Color3.fromRGB(30, 30, 36)
    grip.Material = Enum.Material.SmoothPlastic
    grip.CanCollide = false
    grip.Parent = weaponModel
    local gm = Instance.new("SpecialMesh", grip)
    gm.MeshType = Enum.MeshType.Cylinder

    -- Natural upright grip: sits in hand (Y = -0.85), blade points along arm/forward
    makeWeld(rightArm, grip, CFrame.new(0, -0.85, 0) * CFrame.Angles(math.rad(15), 0, math.rad(-5)))

    -- Pommel cap
    local pommel = Instance.new("Part")
    pommel.Name = "KatanaPommel"
    pommel.Size = Vector3.new(0.32, 0.15, 0.32)
    pommel.Color = Color3.fromRGB(180, 145, 75)
    pommel.Material = Enum.Material.Metal
    pommel.CanCollide = false
    pommel.Parent = weaponModel
    local pm = Instance.new("SpecialMesh", pommel)
    pm.MeshType = Enum.MeshType.Cylinder
    makeWeld(grip, pommel, CFrame.new(0, -0.5, 0))

    -- Tsuba (disc guard)
    local tsuba = Instance.new("Part")
    tsuba.Name = "KatanaTsuba"
    tsuba.Size = Vector3.new(0.72, 0.1, 0.72)
    tsuba.Color = Color3.fromRGB(150, 120, 65)
    tsuba.Material = Enum.Material.Metal
    tsuba.CanCollide = false
    tsuba.Parent = weaponModel
    local tm = Instance.new("SpecialMesh", tsuba)
    tm.MeshType = Enum.MeshType.Cylinder
    makeWeld(grip, tsuba, CFrame.new(0, 0.5, 0))

    -- Habaki (collar)
    local habaki = Instance.new("Part")
    habaki.Name = "KatanaHabaki"
    habaki.Size = Vector3.new(0.2, 0.22, 0.3)
    habaki.Color = Color3.fromRGB(210, 175, 85)
    habaki.Material = Enum.Material.Metal
    habaki.CanCollide = false
    habaki.Parent = weaponModel
    makeWeld(tsuba, habaki, CFrame.new(0, 0.14, 0))

    -- Blade
    local blade = Instance.new("Part")
    blade.Name = "WeaponBlade"
    blade.Size = Vector3.new(0.12, 3.2, 0.36)
    blade.Color = Color3.fromRGB(38, 40, 48)
    blade.Material = Enum.Material.Metal
    blade.CanCollide = false
    blade.CastShadow = true
    blade.Parent = weaponModel
    makeWeld(habaki, blade, CFrame.new(0, 1.7, 0))

    -- Sharp Wedge Tip
    local tip = Instance.new("WedgePart")
    tip.Name = "BladeTip"
    tip.Size = Vector3.new(0.12, 0.55, 0.36)
    tip.Color = Color3.fromRGB(55, 58, 68)
    tip.Material = Enum.Material.Metal
    tip.CanCollide = false
    tip.Parent = weaponModel
    makeWeld(blade, tip, CFrame.new(0, 1.85, 0) * CFrame.Angles(math.rad(180), 0, 0))

    -- Shadow Mist Particles
    local fx = Instance.new("ParticleEmitter")
    fx.Name = "ShadowMist"
    fx.Color = ColorSequence.new(Color3.fromRGB(60, 25, 85), Color3.fromRGB(20, 15, 30))
    fx.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.5) })
    fx.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
    fx.Lifetime = NumberRange.new(0.4, 0.8)
    fx.Rate = 12
    fx.Speed = NumberRange.new(0.4, 1.2)
    fx.LightEmission = 0.2
    fx.Parent = blade
end

-- ============================================================================
-- 2. CRIMSON FLAME DAO (Swordsman_2)
-- ============================================================================
local function buildCrimsonDao(model: Model)
    cleanOldWeapons(model)
    local rightArm = model:FindFirstChild("Right Arm") :: BasePart?
    if not rightArm then return end

    local weaponModel = Instance.new("Model")
    weaponModel.Name = "EquippedWeapon"
    weaponModel.Parent = model

    -- Grip
    local grip = Instance.new("Part")
    grip.Name = "DaoHilt"
    grip.Size = Vector3.new(0.24, 0.95, 0.24)
    grip.Color = Color3.fromRGB(150, 30, 35)
    grip.Material = Enum.Material.Fabric
    grip.CanCollide = false
    grip.Parent = weaponModel
    local gm = Instance.new("SpecialMesh", grip)
    gm.MeshType = Enum.MeshType.Cylinder
    makeWeld(rightArm, grip, CFrame.new(0, -0.85, 0) * CFrame.Angles(math.rad(15), 0, math.rad(-5)))

    -- Brass Ring Pommel with Red Tassel
    local pommel = Instance.new("Part")
    pommel.Name = "DaoPommel"
    pommel.Size = Vector3.new(0.36, 0.15, 0.36)
    pommel.Color = Color3.fromRGB(215, 175, 55)
    pommel.Material = Enum.Material.Metal
    pommel.CanCollide = false
    pommel.Parent = weaponModel
    local pm = Instance.new("SpecialMesh", pommel)
    pm.MeshType = Enum.MeshType.Cylinder
    makeWeld(grip, pommel, CFrame.new(0, -0.52, 0))

    local tassel = Instance.new("Part")
    tassel.Name = "RedTassel"
    tassel.Size = Vector3.new(0.18, 0.65, 0.18)
    tassel.Color = Color3.fromRGB(200, 25, 30)
    tassel.Material = Enum.Material.Fabric
    tassel.CanCollide = false
    tassel.Parent = weaponModel
    local tm = Instance.new("SpecialMesh", tassel)
    tm.MeshType = Enum.MeshType.Cylinder
    makeWeld(pommel, tassel, CFrame.new(0, -0.4, 0))

    -- Flared Brass Disc Guard
    local guard = Instance.new("Part")
    guard.Name = "DaoGuard"
    guard.Size = Vector3.new(0.85, 0.12, 0.85)
    guard.Color = Color3.fromRGB(215, 175, 55)
    guard.Material = Enum.Material.Metal
    guard.CanCollide = false
    guard.Parent = weaponModel
    local gdm = Instance.new("SpecialMesh", guard)
    gdm.MeshType = Enum.MeshType.Cylinder
    makeWeld(grip, guard, CFrame.new(0, 0.5, 0))

    -- Broad Curved Dao Blade
    local blade = Instance.new("Part")
    blade.Name = "WeaponBlade"
    blade.Size = Vector3.new(0.14, 3.4, 0.52)
    blade.Color = Color3.fromRGB(180, 45, 45)
    blade.Material = Enum.Material.Metal
    blade.CanCollide = false
    blade.CastShadow = true
    blade.Parent = weaponModel
    makeWeld(guard, blade, CFrame.new(0, 1.75, 0))

    -- Glowing Fuller Groove (Center of blade)
    local fuller = Instance.new("Part")
    fuller.Name = "BladeFuller"
    fuller.Size = Vector3.new(0.16, 2.8, 0.1)
    fuller.Color = Color3.fromRGB(255, 75, 45)
    fuller.Material = Enum.Material.Neon
    fuller.CanCollide = false
    fuller.Parent = weaponModel
    makeWeld(blade, fuller, CFrame.new(0, -0.1, 0))

    -- Swept Wedge Tip
    local tip = Instance.new("WedgePart")
    tip.Name = "BladeTip"
    tip.Size = Vector3.new(0.14, 0.65, 0.52)
    tip.Color = Color3.fromRGB(215, 55, 55)
    tip.Material = Enum.Material.Metal
    tip.CanCollide = false
    tip.Parent = weaponModel
    makeWeld(blade, tip, CFrame.new(0, 2.0, 0) * CFrame.Angles(math.rad(180), 0, 0))

    -- Smoldering Embers FX
    local fx = Instance.new("ParticleEmitter")
    fx.Name = "FlameEmbers"
    fx.Color = ColorSequence.new(Color3.fromRGB(255, 120, 30), Color3.fromRGB(255, 30, 10))
    fx.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0.05) })
    fx.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
    fx.Lifetime = NumberRange.new(0.3, 0.7)
    fx.Rate = 14
    fx.Speed = NumberRange.new(1, 2.5)
    fx.LightEmission = 0.8
    fx.Parent = blade
end

-- ============================================================================
-- 3. IRON MOUNTAIN CLEAVER (Swordsman_3)
-- ============================================================================
local function buildIronCleaver(model: Model)
    cleanOldWeapons(model)
    local rightArm = model:FindFirstChild("Right Arm") :: BasePart?
    if not rightArm then return end

    local weaponModel = Instance.new("Model")
    weaponModel.Name = "EquippedWeapon"
    weaponModel.Parent = model

    -- Grip
    local grip = Instance.new("Part")
    grip.Name = "CleaverHilt"
    grip.Size = Vector3.new(0.28, 1.1, 0.28)
    grip.Color = Color3.fromRGB(45, 50, 55)
    grip.Material = Enum.Material.Metal
    grip.CanCollide = false
    grip.Parent = weaponModel
    local gm = Instance.new("SpecialMesh", grip)
    gm.MeshType = Enum.MeshType.Cylinder
    makeWeld(rightArm, grip, CFrame.new(0, -0.85, 0) * CFrame.Angles(math.rad(15), 0, math.rad(-5)))

    -- Solid Iron Pommel
    local pommel = Instance.new("Part")
    pommel.Name = "CleaverPommel"
    pommel.Size = Vector3.new(0.45, 0.25, 0.45)
    pommel.Color = Color3.fromRGB(30, 33, 38)
    pommel.Material = Enum.Material.Metal
    pommel.CanCollide = false
    pommel.Parent = weaponModel
    local pm = Instance.new("SpecialMesh", pommel)
    pm.MeshType = Enum.MeshType.Cylinder
    makeWeld(grip, pommel, CFrame.new(0, -0.65, 0))

    -- Heavy Rectangular Crossguard
    local guard = Instance.new("Part")
    guard.Name = "CleaverGuard"
    guard.Size = Vector3.new(0.9, 0.2, 0.5)
    guard.Color = Color3.fromRGB(80, 85, 95)
    guard.Material = Enum.Material.DiamondPlate
    guard.CanCollide = false
    guard.Parent = weaponModel
    makeWeld(grip, guard, CFrame.new(0, 0.6, 0))

    -- Massive Broad Cleaver Blade
    local blade = Instance.new("Part")
    blade.Name = "WeaponBlade"
    blade.Size = Vector3.new(0.2, 3.8, 0.85)
    blade.Color = Color3.fromRGB(130, 135, 145)
    blade.Material = Enum.Material.Metal
    blade.CanCollide = false
    blade.CastShadow = true
    blade.Parent = weaponModel
    makeWeld(guard, blade, CFrame.new(0, 2.0, 0))

    -- Heavy Bevel Edge
    local edge = Instance.new("Part")
    edge.Name = "CleaverEdge"
    edge.Size = Vector3.new(0.22, 3.7, 0.15)
    edge.Color = Color3.fromRGB(190, 195, 205)
    edge.Material = Enum.Material.Metal
    edge.CanCollide = false
    edge.Parent = weaponModel
    makeWeld(blade, edge, CFrame.new(0, 0, 0.45))

    -- Armor-Piercing Wedge Tip
    local tip = Instance.new("WedgePart")
    tip.Name = "BladeTip"
    tip.Size = Vector3.new(0.2, 0.7, 0.85)
    tip.Color = Color3.fromRGB(160, 165, 175)
    tip.Material = Enum.Material.Metal
    tip.CanCollide = false
    tip.Parent = weaponModel
    makeWeld(blade, tip, CFrame.new(0, 2.25, 0) * CFrame.Angles(math.rad(180), 0, 0))
end

-- ============================================================================
-- 4. AZURE WIND JIAN (Swordsman_4)
-- ============================================================================
local function buildAzureJian(model: Model)
    cleanOldWeapons(model)
    local rightArm = model:FindFirstChild("Right Arm") :: BasePart?
    if not rightArm then return end

    local weaponModel = Instance.new("Model")
    weaponModel.Name = "EquippedWeapon"
    weaponModel.Parent = model

    -- Grip
    local grip = Instance.new("Part")
    grip.Name = "JianHilt"
    grip.Size = Vector3.new(0.22, 0.95, 0.22)
    grip.Color = Color3.fromRGB(240, 245, 250)
    grip.Material = Enum.Material.SmoothPlastic
    grip.CanCollide = false
    grip.Parent = weaponModel
    local gm = Instance.new("SpecialMesh", grip)
    gm.MeshType = Enum.MeshType.Cylinder
    makeWeld(rightArm, grip, CFrame.new(0, -0.85, 0) * CFrame.Angles(math.rad(15), 0, math.rad(-5)))

    -- Jade Pommel Stone
    local pommel = Instance.new("Part")
    pommel.Name = "JianPommel"
    pommel.Size = Vector3.new(0.35, 0.18, 0.35)
    pommel.Color = Color3.fromRGB(80, 220, 180)
    pommel.Material = Enum.Material.Neon
    pommel.CanCollide = false
    pommel.Parent = weaponModel
    local pm = Instance.new("SpecialMesh", pommel)
    pm.MeshType = Enum.MeshType.Sphere
    makeWeld(grip, pommel, CFrame.new(0, -0.55, 0))

    -- Winged Eastern Jian Guard
    local guard = Instance.new("Part")
    guard.Name = "JianGuard"
    guard.Size = Vector3.new(0.8, 0.15, 0.32)
    guard.Color = Color3.fromRGB(60, 175, 170)
    guard.Material = Enum.Material.Metal
    guard.CanCollide = false
    guard.Parent = weaponModel
    makeWeld(grip, guard, CFrame.new(0, 0.52, 0))

    -- Double-Edged Straight Blade
    local blade = Instance.new("Part")
    blade.Name = "WeaponBlade"
    blade.Size = Vector3.new(0.12, 3.4, 0.36)
    blade.Color = Color3.fromRGB(200, 230, 240)
    blade.Material = Enum.Material.Metal
    blade.CanCollide = false
    blade.CastShadow = true
    blade.Parent = weaponModel
    makeWeld(guard, blade, CFrame.new(0, 1.75, 0))

    -- Luminous Cyan Core
    local core = Instance.new("Part")
    core.Name = "SpiritualCore"
    core.Size = Vector3.new(0.14, 3.1, 0.08)
    core.Color = Color3.fromRGB(110, 240, 255)
    core.Material = Enum.Material.Neon
    core.CanCollide = false
    core.Parent = weaponModel
    makeWeld(blade, core, CFrame.new(0, 0, 0))

    -- Symmetrical Needle-Point Wedge Tip
    local tip = Instance.new("WedgePart")
    tip.Name = "BladeTip"
    tip.Size = Vector3.new(0.12, 0.6, 0.36)
    tip.Color = Color3.fromRGB(220, 240, 250)
    tip.Material = Enum.Material.Metal
    tip.CanCollide = false
    tip.Parent = weaponModel
    makeWeld(blade, tip, CFrame.new(0, 1.95, 0) * CFrame.Angles(math.rad(180), 0, 0))

    -- Wind Ripple Particles
    local fx = Instance.new("ParticleEmitter")
    fx.Name = "WindRipples"
    fx.Color = ColorSequence.new(Color3.fromRGB(150, 245, 255), Color3.fromRGB(90, 200, 230))
    fx.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.45) })
    fx.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
    fx.Lifetime = NumberRange.new(0.3, 0.6)
    fx.Rate = 10
    fx.Speed = NumberRange.new(1, 3)
    fx.LightEmission = 0.5
    fx.Parent = blade
end

-- ============================================================================
-- 5. PHANTOM SOUL BLADE (Swordsman_5)
-- ============================================================================
local function buildGhostBlade(model: Model)
    cleanOldWeapons(model)
    local rightArm = model:FindFirstChild("Right Arm") :: BasePart?
    if not rightArm then return end

    local weaponModel = Instance.new("Model")
    weaponModel.Name = "EquippedWeapon"
    weaponModel.Parent = model

    -- Grip
    local grip = Instance.new("Part")
    grip.Name = "GhostHilt"
    grip.Size = Vector3.new(0.24, 0.95, 0.24)
    grip.Color = Color3.fromRGB(55, 45, 65)
    grip.Material = Enum.Material.SmoothPlastic
    grip.CanCollide = false
    grip.Parent = weaponModel
    local gm = Instance.new("SpecialMesh", grip)
    gm.MeshType = Enum.MeshType.Cylinder
    makeWeld(rightArm, grip, CFrame.new(0, -0.85, 0) * CFrame.Angles(math.rad(15), 0, math.rad(-5)))

    -- Skull Pommel
    local pommel = Instance.new("Part")
    pommel.Name = "SkullPommel"
    pommel.Size = Vector3.new(0.38, 0.3, 0.38)
    pommel.Color = Color3.fromRGB(175, 165, 185)
    pommel.Material = Enum.Material.SmoothPlastic
    pommel.CanCollide = false
    pommel.Parent = weaponModel
    local pm = Instance.new("SpecialMesh", pommel)
    pm.MeshType = Enum.MeshType.Sphere
    makeWeld(grip, pommel, CFrame.new(0, -0.58, 0))

    -- Demonic Winged Guard
    local guard = Instance.new("Part")
    guard.Name = "GhostGuard"
    guard.Size = Vector3.new(0.85, 0.15, 0.45)
    guard.Color = Color3.fromRGB(90, 55, 125)
    guard.Material = Enum.Material.Metal
    guard.CanCollide = false
    guard.Parent = weaponModel
    makeWeld(grip, guard, CFrame.new(0, 0.52, 0))

    -- Amethyst Soul Blade
    local blade = Instance.new("Part")
    blade.Name = "WeaponBlade"
    blade.Size = Vector3.new(0.14, 3.4, 0.44)
    blade.Color = Color3.fromRGB(130, 65, 200)
    blade.Material = Enum.Material.Neon
    blade.CanCollide = false
    blade.CastShadow = true
    blade.Parent = weaponModel
    makeWeld(guard, blade, CFrame.new(0, 1.75, 0))

    -- Reverse-Tapered Fang Wedge Tip
    local tip = Instance.new("WedgePart")
    tip.Name = "BladeTip"
    tip.Size = Vector3.new(0.14, 0.6, 0.44)
    tip.Color = Color3.fromRGB(160, 90, 235)
    tip.Material = Enum.Material.Neon
    tip.CanCollide = false
    tip.Parent = weaponModel
    makeWeld(blade, tip, CFrame.new(0, 1.95, 0) * CFrame.Angles(math.rad(180), 0, 0))

    -- Ghostly Purple & Teal Soul Flames
    local fx = Instance.new("ParticleEmitter")
    fx.Name = "SoulFlames"
    fx.Color = ColorSequence.new(Color3.fromRGB(180, 80, 255), Color3.fromRGB(70, 235, 205))
    fx.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.4) })
    fx.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1) })
    fx.Lifetime = NumberRange.new(0.4, 0.8)
    fx.Rate = 12
    fx.Speed = NumberRange.new(0.8, 2.0)
    fx.LightEmission = 0.9
    fx.Parent = blade
end

-- ============================================================================
-- 6. HEAVENLY DRAGON MASTER BLADE (Swordmaster_Boss)
-- ============================================================================
local function buildMasterBlade(model: Model)
    cleanOldWeapons(model)
    local rightArm = model:FindFirstChild("Right Arm") :: BasePart?
    if not rightArm then return end

    local weaponModel = Instance.new("Model")
    weaponModel.Name = "EquippedWeapon"
    weaponModel.Parent = model

    -- Grandmaster Scale Grip (1.4x)
    local grip = Instance.new("Part")
    grip.Name = "MasterHilt"
    grip.Size = Vector3.new(0.35, 1.5, 0.35)
    grip.Color = Color3.fromRGB(45, 32, 20)
    grip.Material = Enum.Material.SmoothPlastic
    grip.CanCollide = false
    grip.Parent = weaponModel
    local gm = Instance.new("SpecialMesh", grip)
    gm.MeshType = Enum.MeshType.Cylinder
    makeWeld(rightArm, grip, CFrame.new(0, -1.2, 0) * CFrame.Angles(math.rad(15), 0, math.rad(-5)))

    -- Golden Dragon-Head Pommel
    local pommel = Instance.new("Part")
    pommel.Name = "DragonPommel"
    pommel.Size = Vector3.new(0.55, 0.4, 0.55)
    pommel.Color = Color3.fromRGB(245, 205, 60)
    pommel.Material = Enum.Material.Metal
    pommel.CanCollide = false
    pommel.Parent = weaponModel
    local pm = Instance.new("SpecialMesh", pommel)
    pm.MeshType = Enum.MeshType.Sphere
    makeWeld(grip, pommel, CFrame.new(0, -0.9, 0))

    -- Imperial Dragon-Wing Crossguard
    local guard = Instance.new("Part")
    guard.Name = "MasterGuard"
    guard.Size = Vector3.new(1.3, 0.25, 0.65)
    guard.Color = Color3.fromRGB(245, 205, 60)
    guard.Material = Enum.Material.Metal
    guard.CanCollide = false
    guard.Parent = weaponModel
    makeWeld(grip, guard, CFrame.new(0, 0.85, 0))

    -- Crimson Dragon Pearl Jewel (Embedded in guard)
    local jewel = Instance.new("Part")
    jewel.Name = "DragonPearl"
    jewel.Size = Vector3.new(0.35, 0.35, 0.35)
    jewel.Color = Color3.fromRGB(255, 50, 40)
    jewel.Material = Enum.Material.Neon
    jewel.CanCollide = false
    jewel.Parent = weaponModel
    local jm = Instance.new("SpecialMesh", jewel)
    jm.MeshType = Enum.MeshType.Sphere
    makeWeld(guard, jewel, CFrame.new(0, 0, 0.32))

    -- Celestial Broadsword Blade
    local blade = Instance.new("Part")
    blade.Name = "WeaponBlade"
    blade.Size = Vector3.new(0.22, 5.0, 0.75)
    blade.Color = Color3.fromRGB(235, 240, 250)
    blade.Material = Enum.Material.Metal
    blade.CanCollide = false
    blade.CastShadow = true
    blade.Parent = weaponModel
    makeWeld(guard, blade, CFrame.new(0, 2.6, 0))

    -- Golden Qi Runes along fuller
    local runes = Instance.new("Part")
    runes.Name = "CelestialRunes"
    runes.Size = Vector3.new(0.26, 4.2, 0.16)
    runes.Color = Color3.fromRGB(255, 215, 70)
    runes.Material = Enum.Material.Neon
    runes.CanCollide = false
    runes.Parent = weaponModel
    makeWeld(blade, runes, CFrame.new(0, -0.2, 0))

    -- Sharp Celestial Wedge Tip
    local tip = Instance.new("WedgePart")
    tip.Name = "BladeTip"
    tip.Size = Vector3.new(0.22, 0.9, 0.75)
    tip.Color = Color3.fromRGB(250, 250, 255)
    tip.Material = Enum.Material.Metal
    tip.CanCollide = false
    tip.Parent = weaponModel
    makeWeld(blade, tip, CFrame.new(0, 2.9, 0) * CFrame.Angles(math.rad(180), 0, 0))

    -- Radiant Golden Dragon Aura
    local fx = Instance.new("ParticleEmitter")
    fx.Name = "GoldenDragonAura"
    fx.Color = ColorSequence.new(Color3.fromRGB(255, 225, 90), Color3.fromRGB(255, 140, 20))
    fx.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0.8) })
    fx.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
    fx.Lifetime = NumberRange.new(0.5, 1.0)
    fx.Rate = 18
    fx.Speed = NumberRange.new(1.2, 3.0)
    fx.LightEmission = 1.0
    fx.Parent = blade
end

-- ============================================================================
-- Apply to All 6 Enemies
-- ============================================================================
local count = 0
local s1 = enemiesFolder:FindFirstChild("Swordsman_1")
if s1 then buildShadowKatana(s1); count = count + 1 end

local s2 = enemiesFolder:FindFirstChild("Swordsman_2")
if s2 then buildCrimsonDao(s2); count = count + 1 end

local s3 = enemiesFolder:FindFirstChild("Swordsman_3")
if s3 then buildIronCleaver(s3); count = count + 1 end

local s4 = enemiesFolder:FindFirstChild("Swordsman_4")
if s4 then buildAzureJian(s4); count = count + 1 end

local s5 = enemiesFolder:FindFirstChild("Swordsman_5")
if s5 then buildGhostBlade(s5); count = count + 1 end

local boss = enemiesFolder:FindFirstChild("Swordmaster_Boss")
if boss then buildMasterBlade(boss); count = count + 1 end

return game:GetService("HttpService"):JSONEncode({
    success = true,
    weaponsBuilt = count
})
