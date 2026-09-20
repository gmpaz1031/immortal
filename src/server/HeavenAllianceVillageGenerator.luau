--!strict
--[[
    HeavenAllianceVillageGenerator.luau
    Phase E — Generates the Heavenly Alliance Village.
    Aesthetic: white marble/stone, gold/jade roofs, golden lanterns,
    peach blossom trees, fountains, clean cultivation world.

    Village center: (300, 0, 350) — east of Demon Cult village
]]

local Workspace = game:GetService("Workspace")

local HeavenAllianceVillageGenerator = {}

local ORIGIN = Vector3.new(300, 0, 350)

local C = {
	WhiteMarble  = Color3.fromRGB(235, 232, 225),
	CreamWall    = Color3.fromRGB(242, 237, 220),
	GoldRoof     = Color3.fromRGB(220, 170, 40),
	JadeRoof     = Color3.fromRGB(38, 108, 90),
	WhiteStone   = Color3.fromRGB(210, 208, 200),
	DarkWood     = Color3.fromRGB(55, 38, 25),
	GoldenNeon   = Color3.fromRGB(255, 215, 60),
	JadeNeon     = Color3.fromRGB(60, 220, 160),
	WhiteNeon    = Color3.fromRGB(240, 250, 255),
	PathStone    = Color3.fromRGB(170, 168, 160),
	WaterBlue    = Color3.fromRGB(80, 180, 220),
	PeachPink    = Color3.fromRGB(255, 160, 180),
	RedPillar    = Color3.fromRGB(165, 38, 28),
	Ground       = Color3.fromRGB(145, 150, 130),
}

local function p(parent, name, size, cf, color, mat, canCollide)
	local part = Instance.new("Part")
	part.Name = name; part.Size = size; part.CFrame = cf
	part.Color = color or C.WhiteMarble
	part.Material = mat or Enum.Material.SmoothPlastic
	part.Anchored = true; part.CanCollide = (canCollide ~= false)
	part.TopSurface = Enum.SurfaceType.Smooth; part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent; return part
end

local function wedge(parent, name, size, cf, color, mat)
	local w = Instance.new("WedgePart")
	w.Name = name; w.Size = size; w.CFrame = cf
	w.Color = color or C.GoldRoof
	w.Material = mat or Enum.Material.SmoothPlastic
	w.Anchored = true; w.CanCollide = true
	w.TopSurface = Enum.SurfaceType.Smooth; w.BottomSurface = Enum.SurfaceType.Smooth
	w.Parent = parent; return w
end

local function addLight(part, color, brightness, range)
	local l = Instance.new("PointLight"); l.Color = color; l.Brightness = brightness; l.Range = range; l.Parent = part
end

local function addParticle(part, color1, color2, rate, speed, lifetime, size)
	local em = Instance.new("ParticleEmitter")
	em.Color = ColorSequence.new(color1, color2)
	em.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	em.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	em.Lifetime = NumberRange.new(lifetime * 0.7, lifetime); em.Rate = rate
	em.Speed = NumberRange.new(speed * 0.5, speed); em.SpreadAngle = Vector2.new(180, 180)
	em.Parent = part
end

-- ============================================================
-- BUILDING: Eastern white/gold style
-- ============================================================
local function buildBuilding(parent, o, w, d, label)
	local m = Instance.new("Model"); m.Name = label

	-- Walls
	p(m, "WallN", Vector3.new(w, 8, 1.5), CFrame.new(o + Vector3.new(0, 4, -d/2)), C.CreamWall, Enum.Material.SmoothPlastic)
	p(m, "WallS", Vector3.new(w, 8, 1.5), CFrame.new(o + Vector3.new(0, 4,  d/2)), C.CreamWall, Enum.Material.SmoothPlastic)
	p(m, "WallE", Vector3.new(1.5, 8, d), CFrame.new(o + Vector3.new( w/2, 4, 0)), C.CreamWall, Enum.Material.SmoothPlastic)
	p(m, "WallW", Vector3.new(1.5, 8, d), CFrame.new(o + Vector3.new(-w/2, 4, 0)), C.CreamWall, Enum.Material.SmoothPlastic)
	p(m, "Floor", Vector3.new(w, 1, d), CFrame.new(o + Vector3.new(0, 0.5, 0)), C.WhiteStone, Enum.Material.SmoothPlastic)

	-- Red support pillars
	for _, xz in ipairs({ {-w/2+1, -d/2+1}, {w/2-1, -d/2+1}, {-w/2+1, d/2-1}, {w/2-1, d/2-1} }) do
		p(m, "Pillar", Vector3.new(1.2, 9.5, 1.2), CFrame.new(o + Vector3.new(xz[1], 4.75, xz[2])), C.RedPillar, Enum.Material.SmoothPlastic)
	end

	-- Gold curved roof
	local rH = 4
	wedge(m, "RoofFront", Vector3.new(w+4, rH, d/2+2), CFrame.new(o + Vector3.new(0, 8+rH/2, d/4+1)) * CFrame.Angles(0, math.rad(180), 0), C.GoldRoof, Enum.Material.SmoothPlastic)
	wedge(m, "RoofBack",  Vector3.new(w+4, rH, d/2+2), CFrame.new(o + Vector3.new(0, 8+rH/2, -(d/4+1))), C.GoldRoof, Enum.Material.SmoothPlastic)
	p(m, "Ridge", Vector3.new(w+4, 1, 2), CFrame.new(o + Vector3.new(0, 8+rH+0.5, 0)), C.DarkWood, Enum.Material.Wood)

	m.Parent = parent
end

-- ============================================================
-- GOLDEN LANTERN
-- ============================================================
local function buildLantern(parent, cf)
	local m = Instance.new("Model"); m.Name = "GoldenLantern"
	p(m, "Post", Vector3.new(0.8, 5, 0.8), cf * CFrame.new(0, 2.5, 0), C.DarkWood, Enum.Material.Wood)
	p(m, "Cap",  Vector3.new(1.8, 0.4, 1.8), cf * CFrame.new(0, 5.4, 0), C.GoldRoof, Enum.Material.SmoothPlastic)
	local glow = p(m, "Glow", Vector3.new(1.1, 1.8, 1.1), cf * CFrame.new(0, 4.6, 0), C.GoldenNeon, Enum.Material.Neon)
	addLight(glow, C.GoldenNeon, 2.5, 18); m.Parent = parent
end

-- ============================================================
-- PEACH BLOSSOM TREE
-- ============================================================
local function buildPeachTree(parent, cf)
	local m = Instance.new("Model"); m.Name = "PeachBlossomTree"
	p(m, "Trunk", Vector3.new(1.2, 7, 1.2), cf * CFrame.new(0, 3.5, 0), Color3.fromRGB(90, 55, 30), Enum.Material.Wood)
	-- Canopy
	local canopy = p(m, "Canopy", Vector3.new(8, 5, 8), cf * CFrame.new(0, 9, 0), C.PeachPink, Enum.Material.Neon)
	canopy.Transparency = 0.5; canopy.CanCollide = false
	-- Petals falling
	local em = Instance.new("ParticleEmitter", canopy)
	em.Color = ColorSequence.new(C.PeachPink, Color3.fromRGB(255, 200, 220))
	em.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	em.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	em.Lifetime = NumberRange.new(2, 4); em.Rate = 8
	em.Speed = NumberRange.new(1, 3); em.SpreadAngle = Vector2.new(180, 180)
	m.Parent = parent
end

-- ============================================================
-- JADE FOUNTAIN
-- ============================================================
local function buildFountain(parent, cf)
	local m = Instance.new("Model"); m.Name = "JadeFountain"
	p(m, "Basin",  Vector3.new(6, 1, 6),   cf * CFrame.new(0, 0.5, 0), C.WhiteMarble, Enum.Material.SmoothPlastic)
	p(m, "Column", Vector3.new(1.5, 4, 1.5), cf * CFrame.new(0, 2.5, 0), C.WhiteMarble, Enum.Material.SmoothPlastic)
	local top = p(m, "Top", Vector3.new(3, 1, 3), cf * CFrame.new(0, 4.5, 0), C.WhiteMarble, Enum.Material.SmoothPlastic)
	-- Water glow
	local water = p(m, "Water", Vector3.new(5.5, 0.4, 5.5), cf * CFrame.new(0, 1.2, 0), C.WaterBlue, Enum.Material.Neon)
	water.Transparency = 0.4; water.CanCollide = false
	addLight(water, C.JadeNeon, 2, 16)
	-- Water spray
	addParticle(top, C.WaterBlue, Color3.fromRGB(200, 240, 255), 15, 4, 1.2, 0.5)
	m.Parent = parent
end

-- ============================================================
-- HEAVENLY TORII GATE
-- ============================================================
local function buildTorii(parent, cf)
	local m = Instance.new("Model"); m.Name = "HeavenTorii"
	p(m, "PostL", Vector3.new(1.5, 14, 1.5), cf * CFrame.new(-5, 7, 0), C.RedPillar, Enum.Material.SmoothPlastic)
	p(m, "PostR", Vector3.new(1.5, 14, 1.5), cf * CFrame.new( 5, 7, 0), C.RedPillar, Enum.Material.SmoothPlastic)
	p(m, "TopBeam",   Vector3.new(14, 1.5, 1.5), cf * CFrame.new(0, 14.75, 0), C.GoldRoof, Enum.Material.SmoothPlastic)
	p(m, "UpperBeam", Vector3.new(12, 1.2, 1.2), cf * CFrame.new(0, 12.5, 0), C.DarkWood, Enum.Material.Wood)
	for _, xOff in ipairs({ -2, 2 }) do
		local lan = p(m, "Lantern", Vector3.new(0.8, 1.5, 0.8), cf * CFrame.new(xOff, 13.5, 0), C.GoldenNeon, Enum.Material.Neon)
		addLight(lan, C.GoldenNeon, 2.5, 14)
	end
	m.Parent = parent
end

-- ============================================================
-- HEAVENLY ALLIANCE SHRINE (Central)
-- ============================================================
local function buildShrine(parent, o)
	local m = Instance.new("Model"); m.Name = "HeavenShrine"

	-- Multi-tier platform
	p(m, "Tier1", Vector3.new(32, 2, 32), CFrame.new(o + Vector3.new(0, 1, 0)), C.WhiteMarble, Enum.Material.SmoothPlastic)
	p(m, "Tier2", Vector3.new(24, 2, 24), CFrame.new(o + Vector3.new(0, 3, 0)), C.WhiteStone, Enum.Material.SmoothPlastic)
	p(m, "Tier3", Vector3.new(16, 2, 16), CFrame.new(o + Vector3.new(0, 5, 0)), C.WhiteStone, Enum.Material.SmoothPlastic)

	-- Stairs south
	for i = 1, 3 do
		p(m, "Stair"..i, Vector3.new(6, 0.7, 3), CFrame.new(o + Vector3.new(0, i*0.7, 16-(i*3))), C.WhiteMarble, Enum.Material.SmoothPlastic)
	end

	-- Main shrine building
	p(m, "ShrineWallN", Vector3.new(16, 10, 1.5), CFrame.new(o + Vector3.new(0, 11, -8.25)), C.CreamWall, Enum.Material.SmoothPlastic)
	p(m, "ShrineWallS", Vector3.new(16, 10, 1.5), CFrame.new(o + Vector3.new(0, 11,  8.25)), C.CreamWall, Enum.Material.SmoothPlastic)
	p(m, "ShrineWallE", Vector3.new(1.5, 10, 16), CFrame.new(o + Vector3.new( 8.25, 11, 0)), C.CreamWall, Enum.Material.SmoothPlastic)
	p(m, "ShrineWallW", Vector3.new(1.5, 10, 16), CFrame.new(o + Vector3.new(-8.25, 11, 0)), C.CreamWall, Enum.Material.SmoothPlastic)

	-- Gold roof
	wedge(m, "ShrineRoofF", Vector3.new(20, 6, 9), CFrame.new(o + Vector3.new(0, 22, 4.5)) * CFrame.Angles(0, math.rad(180), 0), C.GoldRoof, Enum.Material.SmoothPlastic)
	wedge(m, "ShrineRoofB", Vector3.new(20, 6, 9), CFrame.new(o + Vector3.new(0, 22, -4.5)), C.GoldRoof, Enum.Material.SmoothPlastic)
	p(m, "ShrineRidge", Vector3.new(20, 1.5, 2.5), CFrame.new(o + Vector3.new(0, 27.5, 0)), C.DarkWood, Enum.Material.Wood)

	-- 4 red pillars
	for _, xz in ipairs({ {-7,-7},{7,-7},{-7,7},{7,7} }) do
		p(m, "ShrinePillar", Vector3.new(1.2, 12, 1.2), CFrame.new(o + Vector3.new(xz[1], 11, xz[2])), C.RedPillar, Enum.Material.SmoothPlastic)
	end

	-- Glowing golden altar
	p(m, "Altar", Vector3.new(4, 2, 4), CFrame.new(o + Vector3.new(0, 7, 0)), C.WhiteMarble, Enum.Material.SmoothPlastic)
	local altarCore = p(m, "AltarCore", Vector3.new(1.5, 2, 1.5), CFrame.new(o + Vector3.new(0, 9, 0)), C.GoldenNeon, Enum.Material.Neon)
	altarCore.CanCollide = false
	addLight(altarCore, C.GoldenNeon, 6, 45)
	addParticle(altarCore, C.GoldenNeon, Color3.fromRGB(255, 255, 200), 12, 3, 1.5, 0.8)

	m.Parent = parent
end

-- ============================================================
-- PUBLIC: Generate Heavenly Alliance Village
-- ============================================================
function HeavenAllianceVillageGenerator.generate(parent: Instance?)
	local folder = Workspace:FindFirstChild("HeavenAllianceVillage")
	if folder then folder:Destroy() end

	folder = Instance.new("Folder"); folder.Name = "HeavenAllianceVillage"
	folder.Parent = parent or Workspace

	local o = ORIGIN

	-- Ground
	p(folder, "Ground", Vector3.new(220, 1, 220), CFrame.new(o - Vector3.new(0, 0.5, 0)), C.Ground, Enum.Material.Grass)
	-- Stone roads
	p(folder, "RoadNS", Vector3.new(8, 0.6, 130), CFrame.new(o + Vector3.new(0, 0.3, 0)), C.PathStone, Enum.Material.Cobblestone)
	p(folder, "RoadEW", Vector3.new(130, 0.6, 8), CFrame.new(o + Vector3.new(0, 0.3, 0)), C.PathStone, Enum.Material.Cobblestone)

	-- Torii gates
	buildTorii(folder, CFrame.new(o + Vector3.new(0, 0, -95)))
	buildTorii(folder, CFrame.new(o + Vector3.new(0, 0,  95)) * CFrame.Angles(0, math.rad(180), 0))

	-- Golden lanterns lining the road
	for i = -3, 3 do
		buildLantern(folder, CFrame.new(o + Vector3.new( 12, 0, i * 22)))
		buildLantern(folder, CFrame.new(o + Vector3.new(-12, 0, i * 22)))
	end

	-- Peach blossom trees scattered around
	for _, pos in ipairs({
		Vector3.new(-35, 0, -35), Vector3.new(35, 0, -35),
		Vector3.new(-35, 0,  35), Vector3.new(35, 0,  35),
		Vector3.new(-55, 0,  0),  Vector3.new(55, 0,  0),
		Vector3.new(-55, 0, -60), Vector3.new(55, 0, -60),
		Vector3.new(0,   0, -70),
	}) do
		buildPeachTree(folder, CFrame.new(o + pos))
	end

	-- Jade fountains
	buildFountain(folder, CFrame.new(o + Vector3.new(-18, 0, 0)))
	buildFountain(folder, CFrame.new(o + Vector3.new( 18, 0, 0)))

	-- Buildings
	buildBuilding(folder, o + Vector3.new(-55, 0, -35), 20, 16, "HeavenBarracks_W1")
	buildBuilding(folder, o + Vector3.new(-55, 0,  35), 20, 16, "HeavenBarracks_W2")
	buildBuilding(folder, o + Vector3.new( 55, 0, -35), 20, 16, "HeavenBarracks_E1")
	buildBuilding(folder, o + Vector3.new( 55, 0,  35), 20, 16, "HeavenBarracks_E2")
	buildBuilding(folder, o + Vector3.new(-55, 0,   0), 18, 14, "HeavenHall_W")
	buildBuilding(folder, o + Vector3.new( 55, 0,   0), 18, 14, "HeavenHall_E")
	buildBuilding(folder, o + Vector3.new(  0, 0, -75), 24, 14, "HeavenLodge_N")

	-- Central shrine
	buildShrine(folder, o)

	print("[HeavenAllianceVillageGenerator] Village generated at", tostring(o))
	return folder
end

return HeavenAllianceVillageGenerator
