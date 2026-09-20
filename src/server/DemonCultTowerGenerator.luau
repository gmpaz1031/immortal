--!strict
--[[
    DemonCultTowerGenerator.luau
    Generates the Heavenly Demon Cult Tower — a tall imposing structure
    north of the village with multiple combat floors and a throne room apex.

    Tower center: (-50, 0, 160)  (north of village at -50, 0, 350)
    Floor layout:
      Floor 1  (Y~8)  : FlameDemoness arena
      Floor 2  (Y~22) : PoisonDemoness arena
      Floor 3  (Y~36) : FistDemon arena
      Floor 4  (Y~50) : SwordDemon arena
      Floor 5  (Y~66) : BloodDemon throne chamber (Standby)
      Apex     (Y~82) : SupremeDemon throne (Standby)

    Architecture: square black-stone tower with crimson trim,
    each floor accessible via internal stairs. Thick outer walls,
    arched windows, glowing red rune pillars.
]]

local Workspace = game:GetService("Workspace")

local DemonCultTowerGenerator = {}

-- Tower center world position
local TOWER_CENTER = Vector3.new(-50, 0, 160)

-- ============================================================
-- Floor plate spawn positions (world Y of each floor's ground)
-- These are read by DemonCultManager to place enemies
-- ============================================================
DemonCultTowerGenerator.FloorPositions = {
	Floor1  = Vector3.new(-50, 8.5,  160),  -- FlameDemoness
	Floor2  = Vector3.new(-50, 22.5, 160),  -- PoisonDemoness
	Floor3  = Vector3.new(-50, 36.5, 160),  -- FistDemon
	Floor4  = Vector3.new(-50, 50.5, 160),  -- SwordDemon
	Floor5  = Vector3.new(-50, 66.5, 160),  -- BloodDemon (Standby)
	Apex    = Vector3.new(-50, 82.5, 160),  -- SupremeDemon (Standby)
}

local C = {
	BlackStone   = Color3.fromRGB(12, 8, 8),
	DarkStone    = Color3.fromRGB(22, 14, 14),
	CrimsonTrim  = Color3.fromRGB(100, 10, 10),
	RedNeon      = Color3.fromRGB(255, 18, 18),
	OrangeNeon   = Color3.fromRGB(255, 90, 10),
	Gold         = Color3.fromRGB(160, 120, 25),
	DarkWood     = Color3.fromRGB(18, 10, 8),
	CrimsonRoof  = Color3.fromRGB(90, 10, 10),
	SmokeBlack   = Color3.fromRGB(8, 6, 6),
}

local function part(parent, name, size, cf, color, mat, transparent)
	local p = Instance.new("Part")
	p.Name = name or "P"
	p.Size = size
	p.CFrame = cf
	p.Color = color or C.BlackStone
	p.Material = mat or Enum.Material.Slate
	p.Anchored = true
	p.CanCollide = true
	p.Transparency = transparent or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function wedge(parent, name, size, cf, color, mat)
	local w = Instance.new("WedgePart")
	w.Name = name or "W"
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

local function addLight(p, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness
	l.Range = range
	l.Parent = p
end

local function addFlame(p, color1, color2, rate)
	local em = Instance.new("ParticleEmitter")
	em.Color = ColorSequence.new(color1, color2)
	em.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) })
	em.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	em.Lifetime = NumberRange.new(0.3, 0.6)
	em.Rate = rate
	em.Speed = NumberRange.new(2, 5)
	em.SpreadAngle = Vector2.new(25, 25)
	em.Parent = p
end

local function addSmoke(p, color1, color2, rate)
	local em = Instance.new("ParticleEmitter")
	em.Color = ColorSequence.new(color1, color2)
	em.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 3) })
	em.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
	em.Lifetime = NumberRange.new(1.5, 2.5)
	em.Rate = rate
	em.Speed = NumberRange.new(2, 4)
	em.SpreadAngle = Vector2.new(20, 20)
	em.Parent = p
end

-- ============================================================
-- 1. TOWER FLOOR (outer walls + floor plate)
-- ============================================================
local function buildFloor(parent, o, floorY, floorIndex)
	local halfW = 14  -- half-width of tower interior
	local wallThick = 3
	local wallH = 14
	local totalW = halfW * 2 + wallThick * 2

	-- Floor plate
	part(parent, "Floor"..floorIndex, Vector3.new(totalW, 1.5, totalW),
		CFrame.new(o + Vector3.new(0, floorY, 0)), C.DarkStone, Enum.Material.Slate)

	-- 4 outer walls
	part(parent, "WallN"..floorIndex, Vector3.new(totalW, wallH, wallThick),
		CFrame.new(o + Vector3.new(0, floorY + wallH/2 + 0.75, -(halfW + wallThick/2))), C.BlackStone, Enum.Material.Slate)
	part(parent, "WallS"..floorIndex, Vector3.new(totalW, wallH, wallThick),
		CFrame.new(o + Vector3.new(0, floorY + wallH/2 + 0.75,  halfW + wallThick/2)), C.BlackStone, Enum.Material.Slate)
	part(parent, "WallE"..floorIndex, Vector3.new(wallThick, wallH, totalW),
		CFrame.new(o + Vector3.new( halfW + wallThick/2, floorY + wallH/2 + 0.75, 0)), C.BlackStone, Enum.Material.Slate)
	part(parent, "WallW"..floorIndex, Vector3.new(wallThick, wallH, totalW),
		CFrame.new(o + Vector3.new(-(halfW + wallThick/2), floorY + wallH/2 + 0.75, 0)), C.BlackStone, Enum.Material.Slate)

	-- Crimson trim ledge at top of each floor
	part(parent, "Trim"..floorIndex, Vector3.new(totalW + 2, 1, totalW + 2),
		CFrame.new(o + Vector3.new(0, floorY + wallH + 1.25, 0)), C.CrimsonTrim, Enum.Material.SmoothPlastic)

	-- Arched windows (left & right sides, neon glow slits)
	for _, zOff in ipairs({ -5, 5 }) do
		local win = part(parent, "Window"..floorIndex, Vector3.new(2, 4, 0.5),
			CFrame.new(o + Vector3.new(halfW + wallThick, floorY + wallH/2 + 0.75, zOff)), C.RedNeon, Enum.Material.Neon)
		win.CanCollide = false
		addLight(win, C.RedNeon, 1.5, 14)
	end
	for _, zOff in ipairs({ -5, 5 }) do
		local win = part(parent, "Window"..floorIndex.."W", Vector3.new(2, 4, 0.5),
			CFrame.new(o + Vector3.new(-(halfW + wallThick), floorY + wallH/2 + 0.75, zOff)), C.RedNeon, Enum.Material.Neon)
		win.CanCollide = false
		addLight(win, C.RedNeon, 1.5, 14)
	end

	-- Rune pillars at 4 corners inside
	for _, xz in ipairs({ {-10, -10}, {10, -10}, {-10, 10}, {10, 10} }) do
		local pillar = part(parent, "RunePillar"..floorIndex, Vector3.new(1.5, wallH, 1.5),
			CFrame.new(o + Vector3.new(xz[1], floorY + wallH/2 + 0.75, xz[2])), C.DarkWood, Enum.Material.Wood)
		-- Rune glow stripe
		local rune = part(parent, "Rune"..floorIndex, Vector3.new(0.4, wallH * 0.6, 0.4),
			CFrame.new(o + Vector3.new(xz[1], floorY + wallH/2 + 0.75, xz[2])), C.RedNeon, Enum.Material.Neon)
		rune.CanCollide = false
		rune.Transparency = 0.3
	end
end

-- ============================================================
-- 2. INTERNAL STAIRCASE
-- ============================================================
local function buildStairs(parent, fromY, toY, basePos, side)
	-- Spiral stairs: alternating left/right between floors
	local numSteps = 14
	local stepH = (toY - fromY) / numSteps
	local stepLen = 4.5
	local startX = side == "east" and 8 or -8
	local startZ = -8
	for i = 0, numSteps - 1 do
		local t = i / numSteps
		local angle = (side == "east" and 1 or -1) * t * math.rad(180)
		local xOff = startX + math.sin(angle) * 6
		local zOff = startZ + math.cos(angle) * 6
		part(parent, "Stair", Vector3.new(stepLen, 0.8, 2),
			CFrame.new(basePos + Vector3.new(xOff, fromY + i * stepH + 0.4, zOff))
			* CFrame.Angles(0, angle, 0),
			C.DarkStone, Enum.Material.Slate)
	end
end

-- ============================================================
-- 3. FLOOR ARENA DETAIL (unique decoration per floor)
-- ============================================================
local function addFloorDecor(parent, o, floorY, floorType)
	if floorType == "Flame" then
		-- Burning braziers at corners
		for _, xz in ipairs({ {-8, -8}, {8, -8}, {-8, 8}, {8, 8} }) do
			local braz = part(parent, "FlameBrazier", Vector3.new(1.5, 3, 1.5),
				CFrame.new(o + Vector3.new(xz[1], floorY + 3, xz[2])), C.DarkStone, Enum.Material.Slate)
			local flame = part(parent, "BrazierFlame", Vector3.new(1.2, 1.2, 1.2),
				CFrame.new(o + Vector3.new(xz[1], floorY + 5, xz[2])), C.OrangeNeon, Enum.Material.Neon)
			flame.CanCollide = false
			addLight(flame, C.OrangeNeon, 4, 18)
			addFlame(flame, Color3.fromRGB(255, 100, 10), Color3.fromRGB(180, 40, 5), 18)
		end
		-- Lava-like floor center glow
		local lava = part(parent, "LavaCenter", Vector3.new(8, 0.3, 8),
			CFrame.new(o + Vector3.new(0, floorY + 0.75, 0)), Color3.fromRGB(220, 60, 10), Enum.Material.Neon)
		lava.CanCollide = false
		lava.Transparency = 0.4
		addLight(lava, Color3.fromRGB(255, 80, 10), 3, 24)

	elseif floorType == "Poison" then
		-- Poison pools in corners
		for _, xz in ipairs({ {-7, -7}, {7, -7}, {-7, 7}, {7, 7} }) do
			local pool = part(parent, "PoisonPool", Vector3.new(4, 0.4, 4),
				CFrame.new(o + Vector3.new(xz[1], floorY + 0.95, xz[2])), Color3.fromRGB(40, 180, 40), Enum.Material.Neon)
			pool.CanCollide = false
			pool.Transparency = 0.3
			addLight(pool, Color3.fromRGB(60, 220, 60), 2, 14)
			addSmoke(pool, Color3.fromRGB(40, 180, 40), Color3.fromRGB(15, 60, 15), 8)
		end

	elseif floorType == "Fist" then
		-- Cracked floor slab effect (darker patches)
		for _, xz in ipairs({ {-5, 0}, {5, 0}, {0, -5}, {0, 5} }) do
			local crack = part(parent, "FloorCrack", Vector3.new(5, 0.3, 2),
				CFrame.new(o + Vector3.new(xz[1], floorY + 0.76, xz[2])), C.SmokeBlack, Enum.Material.Slate)
			crack.CanCollide = false
		end
		-- Heavy chain columns
		for _, xz in ipairs({ {-10, 0}, {10, 0} }) do
			part(parent, "ChainPillar", Vector3.new(2, 12, 2),
				CFrame.new(o + Vector3.new(xz[1], floorY + 7, xz[2])), C.DarkStone, Enum.Material.Metal)
		end

	elseif floorType == "Sword" then
		-- Spectral blue floor center
		local blueFloor = part(parent, "SwordArenaCenter", Vector3.new(10, 0.3, 10),
			CFrame.new(o + Vector3.new(0, floorY + 0.76, 0)), Color3.fromRGB(30, 60, 180), Enum.Material.Neon)
		blueFloor.CanCollide = false
		blueFloor.Transparency = 0.4
		addLight(blueFloor, Color3.fromRGB(60, 100, 255), 2, 22)
		-- Sword statues on sides
		for _, side in ipairs({ -1, 1 }) do
			-- Embedded sword hilt
			part(parent, "SwordStat", Vector3.new(0.6, 6, 0.6),
				CFrame.new(o + Vector3.new(side * 10, floorY + 4, 0)), Color3.fromRGB(80, 120, 255), Enum.Material.Neon)
		end

	elseif floorType == "Blood" then
		-- Dark red throne dais
		part(parent, "ThroneBase", Vector3.new(6, 1, 6), CFrame.new(o + Vector3.new(0, floorY + 1.25, -6)), C.DarkStone, Enum.Material.Slate)
		part(parent, "Throne", Vector3.new(3, 5, 1.5),   CFrame.new(o + Vector3.new(0, floorY + 4.25, -7.5)), C.BlackStone, Enum.Material.Metal)
		-- Armrests
		part(parent, "ArmL", Vector3.new(0.8, 1.5, 3), CFrame.new(o + Vector3.new(-1.7, floorY + 4, -6)), C.BlackStone, Enum.Material.Metal)
		part(parent, "ArmR", Vector3.new(0.8, 1.5, 3), CFrame.new(o + Vector3.new( 1.7, floorY + 4, -6)), C.BlackStone, Enum.Material.Metal)
		local bloodLight = part(parent, "BloodLight", Vector3.new(1, 1, 1),
			CFrame.new(o + Vector3.new(0, floorY + 8, -6.5)), Color3.fromRGB(255, 10, 10), Enum.Material.Neon)
		bloodLight.CanCollide = false
		bloodLight.Transparency = 0.5
		addLight(bloodLight, Color3.fromRGB(255, 10, 10), 5, 35)

	elseif floorType == "Supreme" then
		-- Grand throne room apex
		part(parent, "SupremeThroneDais", Vector3.new(10, 2, 8), CFrame.new(o + Vector3.new(0, floorY + 1.5, -6)), C.DarkStone, Enum.Material.Slate)
		part(parent, "SupremeThrone", Vector3.new(4, 7, 2),       CFrame.new(o + Vector3.new(0, floorY + 5.5, -8.5)), C.BlackStone, Enum.Material.Metal)
		-- Gold trim on throne
		part(parent, "ThroneGoldL", Vector3.new(0.4, 7, 2.5), CFrame.new(o + Vector3.new(-2.2, floorY + 5.5, -8.5)), Color3.fromRGB(160, 120, 25), Enum.Material.Metal)
		part(parent, "ThroneGoldR", Vector3.new(0.4, 7, 2.5), CFrame.new(o + Vector3.new( 2.2, floorY + 5.5, -8.5)), Color3.fromRGB(160, 120, 25), Enum.Material.Metal)
		-- Massive purple aura light
		local apex = part(parent, "ApexCore", Vector3.new(2, 2, 2),
			CFrame.new(o + Vector3.new(0, floorY + 10, -8.5)), Color3.fromRGB(160, 20, 255), Enum.Material.Neon)
		apex.CanCollide = false
		apex.Transparency = 0.2
		addLight(apex, Color3.fromRGB(160, 20, 255), 6, 50)
		addSmoke(apex, Color3.fromRGB(100, 10, 180), Color3.fromRGB(30, 5, 60), 15)
	end
end

-- ============================================================
-- 4. TOWER EXTERIOR DECORATIONS
-- ============================================================
local function buildExterior(parent, o)
	local totalW = 34  -- outer wall width

	-- Large base plinth
	part(parent, "TowerBase", Vector3.new(totalW + 6, 4, totalW + 6),
		CFrame.new(o + Vector3.new(0, 2, 0)), C.BlackStone, Enum.Material.Slate)
	part(parent, "TowerPlinth", Vector3.new(totalW + 2, 2, totalW + 2),
		CFrame.new(o + Vector3.new(0, 5, 0)), C.DarkStone, Enum.Material.Slate)

	-- Corner buttresses (4 corners, full height)
	local towerHeight = 96  -- total tower height
	for _, xz in ipairs({ {-17, -17}, {17, -17}, {-17, 17}, {17, 17} }) do
		part(parent, "Buttress", Vector3.new(5, towerHeight, 5),
			CFrame.new(o + Vector3.new(xz[1], towerHeight/2, xz[2])), C.DarkStone, Enum.Material.Slate)
		-- Neon rune on each buttress
		local rune = part(parent, "ButtressRune", Vector3.new(0.5, towerHeight * 0.6, 0.5),
			CFrame.new(o + Vector3.new(xz[1], towerHeight/2, xz[2])), C.RedNeon, Enum.Material.Neon)
		rune.CanCollide = false
		rune.Transparency = 0.3
	end

	-- Main entrance arch (south side)
	part(parent, "ArchLeft",  Vector3.new(3, 10, 3.5), CFrame.new(o + Vector3.new(-5.5, 10, 17.5)), C.DarkStone, Enum.Material.Slate)
	part(parent, "ArchRight", Vector3.new(3, 10, 3.5), CFrame.new(o + Vector3.new( 5.5, 10, 17.5)), C.DarkStone, Enum.Material.Slate)
	part(parent, "ArchTop",   Vector3.new(14, 2.5, 3.5), CFrame.new(o + Vector3.new(0, 15.25, 17.5)), C.CrimsonTrim, Enum.Material.SmoothPlastic)
	-- Arch glow
	local archGlow = part(parent, "ArchGlow", Vector3.new(11, 0.5, 0.5),
		CFrame.new(o + Vector3.new(0, 14.5, 17.6)), C.RedNeon, Enum.Material.Neon)
	archGlow.CanCollide = false
	addLight(archGlow, C.RedNeon, 4, 28)

	-- Tower cap / spire
	local capY = towerHeight
	part(parent, "TowerCap", Vector3.new(totalW, 4, totalW),
		CFrame.new(o + Vector3.new(0, capY + 2, 0)), C.CrimsonTrim, Enum.Material.SmoothPlastic)
	-- Four corner spires
	for _, xz in ipairs({ {-14, -14}, {14, -14}, {-14, 14}, {14, 14} }) do
		part(parent, "CornerSpire",   Vector3.new(2.5, 12, 2.5),
			CFrame.new(o + Vector3.new(xz[1], capY + 10, xz[2])), C.BlackStone, Enum.Material.Slate)
		part(parent, "SpireTip", Vector3.new(1, 4, 1),
			CFrame.new(o + Vector3.new(xz[1], capY + 17, xz[2])), C.RedNeon, Enum.Material.Neon)
	end
	-- Central spire
	part(parent, "CentralSpire",  Vector3.new(5, 20, 5),
		CFrame.new(o + Vector3.new(0, capY + 12, 0)), C.DarkStone, Enum.Material.Slate)
	local spireTip = part(parent, "CentralSpireTip", Vector3.new(2, 6, 2),
		CFrame.new(o + Vector3.new(0, capY + 24, 0)), C.RedNeon, Enum.Material.Neon)
	addLight(spireTip, C.RedNeon, 8, 60)
	addSmoke(spireTip, Color3.fromRGB(80, 5, 5), Color3.fromRGB(20, 5, 5), 20)

	-- Hanging demonic banners on exterior
	for _, data in ipairs({ {-10, 40}, {10, 40}, {-10, 60}, {10, 60} }) do
		local flag = part(parent, "TowerBanner", Vector3.new(0.3, 12, 4.5),
			CFrame.new(o + Vector3.new(data[1], data[2], 17.7)), Color3.fromRGB(70, 5, 5), Enum.Material.Fabric)
		flag.CanCollide = false
		part(parent, "BannerSymbol", Vector3.new(0.2, 5, 1.2),
			CFrame.new(o + Vector3.new(data[1], data[2], 17.7)), C.RedNeon, Enum.Material.Neon).CanCollide = false
	end
end

-- ============================================================
-- 5. CONNECTING BRIDGE: Village -> Tower
-- ============================================================
local function buildBridge(parent, villageCenter, towerCenter)
	local startZ = villageCenter.Z - 20   -- south edge of village entrance area
	local endZ   = towerCenter.Z + 18     -- north edge of tower base
	local bridgeLen = startZ - endZ
	local cx = (villageCenter.X + towerCenter.X) / 2
	local cy = 0.5

	-- Stone road connecting them
	part(parent, "ConnectRoad", Vector3.new(8, 1, bridgeLen),
		CFrame.new(Vector3.new(cx, cy, (startZ + endZ) / 2)), Color3.fromRGB(35, 28, 22), Enum.Material.Cobblestone)

	-- Flanking lanterns every 20 studs
	local numLanterns = math.floor(bridgeLen / 20)
	for i = 0, numLanterns do
		local zPos = endZ + i * 20
		for _, xOff in ipairs({ -6, 6 }) do
			local post = part(parent, "BridgePost", Vector3.new(0.8, 6, 0.8),
				CFrame.new(Vector3.new(cx + xOff, 3, zPos)), C.DarkWood, Enum.Material.Wood)
			local glow = part(parent, "BridgeGlow", Vector3.new(1, 1.5, 1),
				CFrame.new(Vector3.new(cx + xOff, 6.5, zPos)), C.RedNeon, Enum.Material.Neon)
			glow.CanCollide = false
			addLight(glow, C.RedNeon, 2.5, 16)
		end
	end
end

-- ============================================================
-- PUBLIC: Generate the entire Demon Cult Tower
-- ============================================================
function DemonCultTowerGenerator.generate(parent: Instance?)
	local folder = Workspace:FindFirstChild("DemonCultTower")
	if folder then folder:Destroy() end

	folder = Instance.new("Folder")
	folder.Name = "DemonCultTower"
	folder.Parent = parent or Workspace

	local o = TOWER_CENTER

	-- Exterior shell
	buildExterior(folder, o)

	-- 6 floors
	local floorDefs = {
		{ y = 7,  label = "Flame",   floorType = "Flame"   },
		{ y = 21, label = "Poison",  floorType = "Poison"  },
		{ y = 35, label = "Fist",    floorType = "Fist"    },
		{ y = 49, label = "Sword",   floorType = "Sword"   },
		{ y = 65, label = "Blood",   floorType = "Blood"   },
		{ y = 81, label = "Supreme", floorType = "Supreme" },
	}

	for i, def in ipairs(floorDefs) do
		buildFloor(folder, o, def.y, i)
		addFloorDecor(folder, o, def.y, def.floorType)

		-- Stairs from this floor to next
		if i < #floorDefs then
			local nextY = floorDefs[i + 1].y
			local sideChoice = (i % 2 == 0) and "east" or "west"
			buildStairs(folder, def.y + 1.5, nextY, o, sideChoice)
		end
	end

	-- Connecting road bridge to village
	local villageCenter = Vector3.new(-50, 0, 350)
	buildBridge(folder, villageCenter, o)

	print("[DemonCultTowerGenerator] Tower generated at " .. tostring(o))
	return folder
end

return DemonCultTowerGenerator
