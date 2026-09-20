--!strict
--[[
    DemonCultCaveGenerator.luau
    Phase D — Demon Cult Cave environment only.
    NO enemies are placed. User places them manually.

    Creates a dark underground cave system accessible via a
    tunnel entrance near the Tower (north side).
    Uses Terrain FillBlock and atmospheric cave geometry.

    Cave entrance: approximately (-50, 0, 80) — north of the tower
    Cave interior: underground at (-50, -30 to -10, 80 to 40)
]]

local Workspace = game:GetService("Workspace")
local Terrain   = Workspace.Terrain

local DemonCultCaveGenerator = {}

local CAVE_ORIGIN = Vector3.new(-50, 0, 80)

local C = {
	CaveRock     = Color3.fromRGB(18, 12, 12),
	DarkStone    = Color3.fromRGB(28, 18, 16),
	BlackStone   = Color3.fromRGB(10, 7, 7),
	CrimsonVein  = Color3.fromRGB(90, 8, 8),
	RedNeon      = Color3.fromRGB(255, 18, 18),
	PurpleNeon   = Color3.fromRGB(120, 10, 180),
	GoldVein     = Color3.fromRGB(140, 100, 20),
	LavaGlow     = Color3.fromRGB(255, 70, 10),
}

local function p(parent, name, size, cf, color, mat, canCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Color = color or C.CaveRock
	part.Material = mat or Enum.Material.Slate
	part.Anchored = true
	part.CanCollide = (canCollide ~= false)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function addLight(part, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color = color; l.Brightness = brightness; l.Range = range
	l.Parent = part
end

local function addMist(part, color1, color2, rate)
	local em = Instance.new("ParticleEmitter")
	em.Color = ColorSequence.new(color1, color2)
	em.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 5) })
	em.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
	em.Lifetime = NumberRange.new(2, 4); em.Rate = rate
	em.Speed = NumberRange.new(0.5, 2); em.SpreadAngle = Vector2.new(180, 180)
	em.Parent = part
end

local function fillCave()
	-- Carve main cave chamber (air pocket)
	Terrain:FillBlock(
		CFrame.new(CAVE_ORIGIN + Vector3.new(0, -22, -20)),
		Vector3.new(60, 28, 70),
		Enum.Material.Air
	)
	-- Side tunnel east
	Terrain:FillBlock(
		CFrame.new(CAVE_ORIGIN + Vector3.new(35, -20, -20)),
		Vector3.new(35, 18, 30),
		Enum.Material.Air
	)
	-- Side tunnel west
	Terrain:FillBlock(
		CFrame.new(CAVE_ORIGIN + Vector3.new(-35, -20, -20)),
		Vector3.new(35, 18, 30),
		Enum.Material.Air
	)
	-- Deep pit
	Terrain:FillBlock(
		CFrame.new(CAVE_ORIGIN + Vector3.new(0, -38, -30)),
		Vector3.new(25, 20, 25),
		Enum.Material.Air
	)
	-- Entrance tunnel
	Terrain:FillBlock(
		CFrame.new(CAVE_ORIGIN + Vector3.new(0, -8, 25)),
		Vector3.new(14, 12, 20),
		Enum.Material.Air
	)
end

local function buildCaveInterior(folder)
	local o = CAVE_ORIGIN

	-- Cave floor slabs (jagged look)
	local floorOffsets = {
		{Vector3.new(0, -35, -20), Vector3.new(60, 2, 70)},
		{Vector3.new(35, -31, -20), Vector3.new(30, 2, 28)},
		{Vector3.new(-35, -31, -20), Vector3.new(30, 2, 28)},
		{Vector3.new(0, -49, -30), Vector3.new(24, 2, 24)},
	}
	for i, fd in ipairs(floorOffsets) do
		p(folder, "CaveFloor"..i, fd[2], CFrame.new(o + fd[1]), C.DarkStone, Enum.Material.Slate)
	end

	-- Stalactites (ceiling spikes — just cosmetic parts)
	local stalagmites = {
		{-15, -22, -10}, {5, -22, -25}, {-5, -22, -40}, {18, -22, -15},
		{-20, -22, -35}, {10, -22, -50}, {-8, -22, -5},
		{30, -30, -15},  {-30, -30, -15}, {35, -30, -30}, {-35, -30, -30},
	}
	for i, s in ipairs(stalagmites) do
		local h = math.random(3, 9)
		local w = math.random(1, 3)
		p(folder, "Stalactite"..i,
			Vector3.new(w, h, w),
			CFrame.new(o + Vector3.new(s[1], s[2] + h/2, s[3])),
			C.CaveRock, Enum.Material.Slate)
	end

	-- Glowing crimson crystal veins
	local crystalPos = {
		{-20, -28, -15}, {15, -28, -35}, {-10, -28, -50}, {25, -28, -10},
		{-28, -28, -25}, {20, -28, -45},
	}
	for i, cp in ipairs(crystalPos) do
		local crystal = p(folder, "Crystal"..i,
			Vector3.new(1.5, 4, 1.5),
			CFrame.new(o + Vector3.new(cp[1], cp[2], cp[3])) * CFrame.Angles(math.random() * math.pi, math.random() * math.pi, 0),
			C.RedNeon, Enum.Material.Neon)
		crystal.CanCollide = false
		addLight(crystal, C.RedNeon, 2, 14)
	end

	-- Lava cracks in deep pit
	local lavaCracks = {
		{0, -49, -30}, {5, -49, -35}, {-5, -49, -25},
	}
	for i, lp in ipairs(lavaCracks) do
		local lava = p(folder, "LavaCrack"..i,
			Vector3.new(math.random(3,8), 0.4, math.random(2, 5)),
			CFrame.new(o + Vector3.new(lp[1], lp[2], lp[3])),
			C.LavaGlow, Enum.Material.Neon)
		lava.CanCollide = false
		lava.Transparency = 0.3
		addLight(lava, C.LavaGlow, 3, 18)
	end

	-- Underground shrine altar (boss spawn area hint)
	p(folder, "BossAltar", Vector3.new(8, 2, 8), CFrame.new(o + Vector3.new(0, -34, -40)), C.BlackStone, Enum.Material.Slate)
	p(folder, "BossAltarTop", Vector3.new(5, 0.5, 5), CFrame.new(o + Vector3.new(0, -32.75, -40)), C.DarkStone, Enum.Material.Slate)
	local altarCore = p(folder, "AltarCore", Vector3.new(1.5, 2, 1.5), CFrame.new(o + Vector3.new(0, -31, -40)), C.PurpleNeon, Enum.Material.Neon)
	altarCore.CanCollide = false
	addLight(altarCore, C.PurpleNeon, 5, 35)
	addMist(altarCore, Color3.fromRGB(80, 5, 120), Color3.fromRGB(20, 5, 40), 10)

	-- Purple demonic rune pillars around altar
	for _, xz in ipairs({ {-4, -36}, {4, -36}, {-4, -44}, {4, -44} }) do
		local rPillar = p(folder, "RunePillar", Vector3.new(1.2, 10, 1.2),
			CFrame.new(o + Vector3.new(xz[1], -29, xz[2])), C.BlackStone, Enum.Material.Slate)
		local rune = p(folder, "Rune", Vector3.new(0.4, 8, 0.4),
			CFrame.new(o + Vector3.new(xz[1], -29, xz[2])), C.PurpleNeon, Enum.Material.Neon)
		rune.CanCollide = false; rune.Transparency = 0.3
	end

	-- Cave entrance arch
	p(folder, "EntranceArchL", Vector3.new(2.5, 12, 3), CFrame.new(o + Vector3.new(-7, -4, 34)), C.DarkStone, Enum.Material.Slate)
	p(folder, "EntranceArchR", Vector3.new(2.5, 12, 3), CFrame.new(o + Vector3.new( 7, -4, 34)), C.DarkStone, Enum.Material.Slate)
	p(folder, "EntranceTop",   Vector3.new(17, 2.5, 3), CFrame.new(o + Vector3.new(0, 2, 34)), C.CrimsonVein, Enum.Material.Slate)
	local entGlow = p(folder, "EntranceGlow", Vector3.new(12, 0.5, 0.5), CFrame.new(o + Vector3.new(0, 1, 34.5)), C.RedNeon, Enum.Material.Neon)
	entGlow.CanCollide = false
	addLight(entGlow, C.RedNeon, 4, 25)

	-- Ambient mist cloud
	local mistPart = p(folder, "CaveMist", Vector3.new(1, 1, 1), CFrame.new(o + Vector3.new(0, -30, -20)), C.BlackStone, Enum.Material.Slate)
	mistPart.Transparency = 1; mistPart.CanCollide = false
	addMist(mistPart, Color3.fromRGB(30, 8, 8), Color3.fromRGB(10, 5, 5), 18)
end

-- ============================================================
-- PUBLIC: Generate the cave
-- ============================================================
function DemonCultCaveGenerator.generate(parent: Instance?)
	local folder = Workspace:FindFirstChild("DemonCultCave")
	if folder then folder:Destroy() end

	folder = Instance.new("Folder")
	folder.Name = "DemonCultCave"
	folder.Parent = parent or Workspace

	-- Carve terrain
	pcall(fillCave)

	-- Build interior geometry
	buildCaveInterior(folder)

	print("[DemonCultCaveGenerator] Cave generated. NO enemies placed — place manually.")
	return folder
end

return DemonCultCaveGenerator
