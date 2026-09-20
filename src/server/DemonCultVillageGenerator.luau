--!strict
--[[
    DemonCultVillageGenerator.luau
    Generates the Heavenly Demon Cult Village map area.

    Visual target: dark red & black cultivation aesthetic,
    demonic buildings with curved upturned eaves, red lanterns,
    torches, banners, statues, and a central demonic shrine.

    Village center: approximately (-50, 0, 350) on the world map
    (distinct from destroyed village at ~-650, 7, 220)
]]

local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local DemonCultVillageGenerator = {}

local ORIGIN = Vector3.new(-50, 0, 350)

local C = {
	DarkWood     = Color3.fromRGB(18, 10, 8),
	CharredBeam  = Color3.fromRGB(25, 14, 10),
	CrimsonRoof  = Color3.fromRGB(95, 12, 12),
	BlackStone   = Color3.fromRGB(15, 12, 12),
	DarkStone    = Color3.fromRGB(28, 20, 20),
	RedNeon      = Color3.fromRGB(255, 18, 18),
	OrangeNeon   = Color3.fromRGB(255, 90, 10),
	Gold         = Color3.fromRGB(180, 130, 30),
	CrimsonBanner= Color3.fromRGB(120, 10, 10),
	SmokeBlack   = Color3.fromRGB(12, 10, 10),
	GroundTile   = Color3.fromRGB(32, 25, 22),
	PathStone    = Color3.fromRGB(40, 32, 28),
}

local function p(parent, name, size, cf, color, mat, canCollide)
	local part = Instance.new("Part")
	part.Name = name or "Part"
	part.Size = size
	part.CFrame = cf
	part.Color = color or C.BlackStone
	part.Material = mat or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = (canCollide ~= false)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function wedge(parent, name, size, cf, color, mat)
	local w = Instance.new("WedgePart")
	w.Name = name or "Wedge"
	w.Size = size
	w.CFrame = cf
	w.Color = color or C.CrimsonRoof
	w.Material = mat or Enum.Material.SmoothPlastic
	w.Anchored = true
	w.CanCollide = true
	w.TopSurface = Enum.SurfaceType.Smooth
	w.BottomSurface = Enum.SurfaceType.Smooth
	w.Parent = parent
	return w
end

local function addPointLight(part, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness
	l.Range = range
	l.Parent = part
	return l
end

-- ============================================================
-- 1. GROUND TILE
-- ============================================================
local function buildGround(parent, origin)
	-- Dark scorched earth base
	p(parent, "VillageGround", Vector3.new(200, 1, 200),
		CFrame.new(origin - Vector3.new(0, 0.5, 0)),
		C.GroundTile, Enum.Material.Slate)

	-- Stone path grid (3 paths)
	for _, offset in ipairs({
		{Vector3.new(0, 0, 0), Vector3.new(120, 0.6, 8)},   -- E-W central road
		{Vector3.new(0, 0, 0), Vector3.new(8, 0.6, 120)},   -- N-S central road
		{Vector3.new(-35, 0, 35), Vector3.new(8, 0.6, 70)},  -- side alley
	}) do
		p(parent, "Road", offset[2],
			CFrame.new(origin + offset[1] + Vector3.new(0, 0.3, 0)),
			C.PathStone, Enum.Material.Cobblestone)
	end
end

-- ============================================================
-- 2. CURVED ROOF BUILDING (Eastern Style)
-- ============================================================
local function buildBuilding(parent, origin, width, depth, label)
	local o = origin
	local model = Instance.new("Model")
	model.Name = label or "DemonicBuilding"

	-- Walls
	p(model, "WallN", Vector3.new(width, 8, 1.5), CFrame.new(o + Vector3.new(0, 4, -depth/2)), C.DarkWood, Enum.Material.Wood)
	p(model, "WallS", Vector3.new(width, 8, 1.5), CFrame.new(o + Vector3.new(0, 4,  depth/2)), C.DarkWood, Enum.Material.Wood)
	p(model, "WallE", Vector3.new(1.5, 8, depth), CFrame.new(o + Vector3.new( width/2, 4, 0)), C.DarkWood, Enum.Material.Wood)
	p(model, "WallW", Vector3.new(1.5, 8, depth), CFrame.new(o + Vector3.new(-width/2, 4, 0)), C.DarkWood, Enum.Material.Wood)
	-- Floor
	p(model, "Floor", Vector3.new(width, 1, depth), CFrame.new(o + Vector3.new(0, 0.5, 0)), C.CharredBeam, Enum.Material.Wood)

	-- Timber support beams (4 corners)
	for _, xz in ipairs({ {-width/2+1, -depth/2+1}, {width/2-1, -depth/2+1}, {-width/2+1, depth/2-1}, {width/2-1, depth/2-1} }) do
		p(model, "Beam", Vector3.new(1.2, 9.5, 1.2),
			CFrame.new(o + Vector3.new(xz[1], 4.75, xz[2])), C.CharredBeam, Enum.Material.Wood)
	end

	-- Roof: dual-slope wedge
	local roofH = 4
	-- Front slope
	wedge(model, "RoofFront", Vector3.new(width + 4, roofH, depth/2 + 2),
		CFrame.new(o + Vector3.new(0, 8 + roofH/2, depth/4 + 1)) * CFrame.Angles(0, math.rad(180), 0),
		C.CrimsonRoof, Enum.Material.Wood)
	-- Back slope
	wedge(model, "RoofBack", Vector3.new(width + 4, roofH, depth/2 + 2),
		CFrame.new(o + Vector3.new(0, 8 + roofH/2, -(depth/4 + 1))),
		C.CrimsonRoof, Enum.Material.Wood)
	-- Ridge cap
	p(model, "RoofRidge", Vector3.new(width + 4, 1, 2),
		CFrame.new(o + Vector3.new(0, 8 + roofH + 0.5, 0)),
		C.SmokeBlack, Enum.Material.Wood)

	model.Parent = parent
	return model
end

-- ============================================================
-- 3. RED GLOWING LANTERN
-- ============================================================
local function buildLantern(parent, cf)
	local m = Instance.new("Model")
	m.Name = "DemonicLantern"

	p(m, "Post",  Vector3.new(0.8, 5, 0.8), cf * CFrame.new(0, 2.5, 0), C.DarkWood, Enum.Material.Wood)
	p(m, "Cap",   Vector3.new(1.8, 0.4, 1.8), cf * CFrame.new(0, 5.4, 0), C.CrimsonRoof, Enum.Material.Wood)

	local glow = p(m, "GlowCore", Vector3.new(1, 1.8, 1), cf * CFrame.new(0, 4.6, 0), C.RedNeon, Enum.Material.Neon)
	addPointLight(glow, C.RedNeon, 3, 20)

	m.Parent = parent
end

-- ============================================================
-- 4. TORCH
-- ============================================================
local function buildTorch(parent, cf)
	local m = Instance.new("Model")
	m.Name = "DemonicTorch"

	p(m, "Stick", Vector3.new(0.5, 4, 0.5), cf * CFrame.new(0, 2, 0), C.CharredBeam, Enum.Material.Wood)
	local flame = p(m, "Flame", Vector3.new(0.7, 0.7, 0.7), cf * CFrame.new(0, 4.4, 0), C.OrangeNeon, Enum.Material.Neon)
	addPointLight(flame, Color3.fromRGB(255, 80, 10), 3.5, 16)

	local em = Instance.new("ParticleEmitter", flame)
	em.Color = ColorSequence.new(Color3.fromRGB(255, 90, 10), Color3.fromRGB(255, 30, 10))
	em.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	em.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	em.Lifetime = NumberRange.new(0.3, 0.6)
	em.Rate = 20
	em.Speed = NumberRange.new(3, 6)
	em.SpreadAngle = Vector2.new(30, 30)

	m.Parent = parent
end

-- ============================================================
-- 5. DEMONIC BANNER
-- ============================================================
local function buildBanner(parent, cf)
	local m = Instance.new("Model")
	m.Name = "DemonicBanner"

	p(m, "Pole", Vector3.new(0.5, 12, 0.5), cf * CFrame.new(0, 6, 0), C.DarkWood, Enum.Material.Wood)
	p(m, "Flag", Vector3.new(0.3, 7, 4.5), cf * CFrame.new(2.5, 10, 0), C.CrimsonBanner, Enum.Material.Fabric)
	local sym = p(m, "Symbol", Vector3.new(0.2, 3, 1.2), cf * CFrame.new(2.5, 10, 0), C.RedNeon, Enum.Material.Neon)
	sym.Transparency = 0.2

	m.Parent = parent
end

-- ============================================================
-- 6. DEMONIC STATUE
-- ============================================================
local function buildStatue(parent, cf)
	local m = Instance.new("Model")
	m.Name = "DemonicStatue"

	p(m, "Base",  Vector3.new(3, 1, 3),   cf * CFrame.new(0, 0.5, 0), C.DarkStone, Enum.Material.Slate)
	p(m, "Body",  Vector3.new(2, 5, 2),   cf * CFrame.new(0, 3.5, 0), C.DarkStone, Enum.Material.Slate)
	p(m, "Head",  Vector3.new(1.8, 1.8, 1.8), cf * CFrame.new(0, 7, 0), C.DarkStone, Enum.Material.Slate)

	-- Eyes glow red
	for _, xOff in ipairs({ -0.4, 0.4 }) do
		local eye = p(m, "Eye", Vector3.new(0.3, 0.3, 0.3), cf * CFrame.new(xOff, 7.3, -0.95), C.RedNeon, Enum.Material.Neon)
		addPointLight(eye, C.RedNeon, 2, 8)
	end

	-- Horns
	for _, side in ipairs({ -1, 1 }) do
		p(m, "Horn", Vector3.new(0.4, 1.5, 0.4),
			cf * CFrame.new(side * 0.7, 8.3, 0) * CFrame.Angles(0, 0, math.rad(side * -15)),
			C.DarkStone, Enum.Material.Slate)
	end

	m.Parent = parent
end

-- ============================================================
-- 7. CENTRAL DEMONIC SHRINE
-- ============================================================
local function buildShrine(parent, origin)
	local m = Instance.new("Model")
	m.Name = "DemonicShrine"

	local o = origin + Vector3.new(0, 0, 0)

	-- Raised platform (3 tiers)
	p(m, "Tier1", Vector3.new(30, 2, 30), CFrame.new(o + Vector3.new(0, 1, 0)), C.BlackStone, Enum.Material.Slate)
	p(m, "Tier2", Vector3.new(22, 2, 22), CFrame.new(o + Vector3.new(0, 3, 0)), C.DarkStone, Enum.Material.Slate)
	p(m, "Tier3", Vector3.new(14, 2, 14), CFrame.new(o + Vector3.new(0, 5, 0)), C.DarkStone, Enum.Material.Slate)

	-- Stone stairs facing south
	for i = 1, 3 do
		p(m, "Stair"..i, Vector3.new(6, 0.7, 3),
			CFrame.new(o + Vector3.new(0, i * 0.7, 15 - (i * 3))),
			C.BlackStone, Enum.Material.Slate)
	end

	-- Main shrine building
	p(m, "ShrineWallN",  Vector3.new(14, 10, 1.5), CFrame.new(o + Vector3.new(0, 11, -7.25)), C.DarkWood, Enum.Material.Wood)
	p(m, "ShrineWallS",  Vector3.new(14, 10, 1.5), CFrame.new(o + Vector3.new(0, 11,  7.25)), C.DarkWood, Enum.Material.Wood)
	p(m, "ShrineWallE",  Vector3.new(1.5, 10, 14), CFrame.new(o + Vector3.new( 7.25, 11, 0)), C.DarkWood, Enum.Material.Wood)
	p(m, "ShrineWallW",  Vector3.new(1.5, 10, 14), CFrame.new(o + Vector3.new(-7.25, 11, 0)), C.DarkWood, Enum.Material.Wood)

	-- Tall roof
	wedge(m, "ShrineFront", Vector3.new(18, 6, 8),
		CFrame.new(o + Vector3.new(0, 22, 4)) * CFrame.Angles(0, math.rad(180), 0),
		C.CrimsonRoof, Enum.Material.Wood)
	wedge(m, "ShrineBack", Vector3.new(18, 6, 8),
		CFrame.new(o + Vector3.new(0, 22, -4)),
		C.CrimsonRoof, Enum.Material.Wood)
	p(m, "ShrineRidge", Vector3.new(18, 1.5, 2.5),
		CFrame.new(o + Vector3.new(0, 27.5, 0)),
		C.SmokeBlack, Enum.Material.Wood)

	-- Corner eave flares (upturned tips)
	for _, xz in ipairs({ {-9, -4.5}, {9, -4.5}, {-9, 4.5}, {9, 4.5} }) do
		p(m, "Eave", Vector3.new(2, 1.5, 2),
			CFrame.new(o + Vector3.new(xz[1], 20, xz[2])) * CFrame.Angles(math.rad(30), 0, 0),
			C.CrimsonRoof, Enum.Material.Wood)
	end

	-- Central glowing altar
	p(m, "Altar",  Vector3.new(4, 2, 4), CFrame.new(o + Vector3.new(0, 7, 0)), C.DarkStone, Enum.Material.Slate)
	local altarGem = p(m, "AltarCore", Vector3.new(1.5, 1.5, 1.5), CFrame.new(o + Vector3.new(0, 9, 0)), C.RedNeon, Enum.Material.Neon)
	addPointLight(altarGem, C.RedNeon, 5, 40)

	-- Smoke rising from altar
	local smoke = Instance.new("ParticleEmitter", altarGem)
	smoke.Color = ColorSequence.new(Color3.fromRGB(60, 5, 5), Color3.fromRGB(15, 8, 8))
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 4) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	smoke.Lifetime = NumberRange.new(1.5, 2.5)
	smoke.Rate = 12
	smoke.Speed = NumberRange.new(3, 6)
	smoke.SpreadAngle = Vector2.new(20, 20)

	-- 4 shrine pillars
	for _, xz in ipairs({ {-6, -6}, {6, -6}, {-6, 6}, {6, 6} }) do
		p(m, "ShrinePillar", Vector3.new(1.5, 12, 1.5),
			CFrame.new(o + Vector3.new(xz[1], 12, xz[2])),
			C.CharredBeam, Enum.Material.Wood)
	end

	m.Parent = parent
end

-- ============================================================
-- 8. TORII GATE (Village Entrance)
-- ============================================================
local function buildTorii(parent, cf)
	local m = Instance.new("Model")
	m.Name = "DemonicTorii"

	-- Posts
	p(m, "PostL", Vector3.new(1.5, 14, 1.5), cf * CFrame.new(-5, 7, 0), C.DarkWood, Enum.Material.Wood)
	p(m, "PostR", Vector3.new(1.5, 14, 1.5), cf * CFrame.new( 5, 7, 0), C.DarkWood, Enum.Material.Wood)
	-- Top beam
	p(m, "TopBeam", Vector3.new(14, 1.5, 1.5), cf * CFrame.new(0, 14.75, 0), C.CrimsonRoof, Enum.Material.Wood)
	p(m, "UpperBeam", Vector3.new(12, 1.2, 1.2), cf * CFrame.new(0, 12.5, 0), C.DarkWood, Enum.Material.Wood)

	-- Hanging red lanterns
	for _, xOff in ipairs({ -2, 2 }) do
		local lan = p(m, "GateLantern", Vector3.new(0.8, 1.5, 0.8),
			cf * CFrame.new(xOff, 13.5, 0), C.RedNeon, Enum.Material.Neon)
		addPointLight(lan, C.RedNeon, 2.5, 14)
	end

	m.Parent = parent
end

-- ============================================================
-- PUBLIC: Generate the entire Demon Cult Village
-- ============================================================
function DemonCultVillageGenerator.generate(parent: Instance?)
	local folder = Workspace:FindFirstChild("DemonCultVillage")
	if folder then folder:Destroy() end

	folder = Instance.new("Folder")
	folder.Name = "DemonCultVillage"
	folder.Parent = parent or Workspace

	local o = ORIGIN

	-- Ground
	buildGround(folder, o)

	-- Village entrance (Torii gates, north and south)
	buildTorii(folder, CFrame.new(o + Vector3.new(0, 0, -90)) * CFrame.Angles(0, 0, 0))
	buildTorii(folder, CFrame.new(o + Vector3.new(0, 0,  90)) * CFrame.Angles(0, math.rad(180), 0))

	-- Lanterns lining the main road
	for i = -3, 3 do
		buildLantern(folder, CFrame.new(o + Vector3.new(12, 0, i * 22)))
		buildLantern(folder, CFrame.new(o + Vector3.new(-12, 0, i * 22)))
	end

	-- Torches at buildings
	for _, pos in ipairs({
		Vector3.new(-40, 0, -30), Vector3.new(-40, 0, 30),
		Vector3.new( 40, 0, -30), Vector3.new( 40, 0, 30),
		Vector3.new(-40, 0, -60), Vector3.new( 40, 0, -60),
	}) do
		buildTorch(folder, CFrame.new(o + pos))
	end

	-- Demonic banners lining path
	for _, pos in ipairs({
		Vector3.new(-20, 0, -55), Vector3.new(20, 0, -55),
		Vector3.new(-20, 0,  55), Vector3.new(20, 0,  55),
		Vector3.new(-20, 0,   0), Vector3.new(20, 0,   0),
	}) do
		buildBanner(folder, CFrame.new(o + pos))
	end

	-- Buildings (west side, east side)
	buildBuilding(folder, o + Vector3.new(-55, 0, -35), 20, 16, "DemonicBarracks_W1")
	buildBuilding(folder, o + Vector3.new(-55, 0,  35), 20, 16, "DemonicBarracks_W2")
	buildBuilding(folder, o + Vector3.new( 55, 0, -35), 20, 16, "DemonicBarracks_E1")
	buildBuilding(folder, o + Vector3.new( 55, 0,  35), 20, 16, "DemonicBarracks_E2")
	buildBuilding(folder, o + Vector3.new(-55, 0,   0), 18, 14, "DemonicHall_W")
	buildBuilding(folder, o + Vector3.new( 55, 0,   0), 18, 14, "DemonicHall_E")
	buildBuilding(folder, o + Vector3.new( 0, 0, -70), 24, 14, "DemonicLodge_N")

	-- Statues flanking shrine approach
	buildStatue(folder, CFrame.new(o + Vector3.new(-10, 0, -20)))
	buildStatue(folder, CFrame.new(o + Vector3.new( 10, 0, -20)))
	buildStatue(folder, CFrame.new(o + Vector3.new(-10, 0,  20)))
	buildStatue(folder, CFrame.new(o + Vector3.new( 10, 0,  20)))

	-- Central Shrine
	buildShrine(folder, o)

	print("[DemonCultVillageGenerator] Village generated at", tostring(o))
	return folder
end

return DemonCultVillageGenerator
