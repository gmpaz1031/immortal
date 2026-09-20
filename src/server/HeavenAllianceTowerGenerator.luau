--!strict
--[[
    HeavenAllianceTowerGenerator.luau
    Phase E — Generates the Heavenly Alliance Tower.
    White marble tower with gold trim, 5 combat floors + apex.

    Tower center: (300, 0, 160) — north of Alliance village
    Floor layout:
      Floor 1 (Y~8)  : Heaven Flame Pillar
      Floor 2 (Y~22) : Heaven Thunder Pillar
      Floor 3 (Y~36) : Heaven Palm Pillar
      Floor 4 (Y~50) : Heaven Sword Pillar
      Apex    (Y~66) : Supreme Heaven (Standby)
]]

local Workspace = game:GetService("Workspace")
local HeavenAllianceTowerGenerator = {}

local TOWER_CENTER = Vector3.new(300, 0, 160)

HeavenAllianceTowerGenerator.FloorPositions = {
	Floor1 = Vector3.new(300, 8.5,  160),
	Floor2 = Vector3.new(300, 22.5, 160),
	Floor3 = Vector3.new(300, 36.5, 160),
	Floor4 = Vector3.new(300, 50.5, 160),
	Apex   = Vector3.new(300, 66.5, 160),
}

local C = {
	WhiteMarble  = Color3.fromRGB(235, 232, 225),
	GoldTrim     = Color3.fromRGB(220, 170, 40),
	JadeTrim     = Color3.fromRGB(38, 108, 90),
	RedPillar    = Color3.fromRGB(165, 38, 28),
	DarkWood     = Color3.fromRGB(55, 38, 25),
	GoldenNeon   = Color3.fromRGB(255, 215, 60),
	WhiteNeon    = Color3.fromRGB(240, 250, 255),
	GoldRoof     = Color3.fromRGB(210, 160, 35),
	CreamWall    = Color3.fromRGB(242, 237, 220),
}

local function p(parent, name, size, cf, color, mat, canCollide)
	local part = Instance.new("Part")
	part.Name = name; part.Size = size; part.CFrame = cf
	part.Color = color or C.WhiteMarble; part.Material = mat or Enum.Material.SmoothPlastic
	part.Anchored = true; part.CanCollide = (canCollide ~= false)
	part.TopSurface = Enum.SurfaceType.Smooth; part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent; return part
end

local function addLight(part, color, brightness, range)
	local l = Instance.new("PointLight"); l.Color = color; l.Brightness = brightness; l.Range = range; l.Parent = part
end

local function addParticle(part, color1, color2, rate, speed, size)
	local em = Instance.new("ParticleEmitter")
	em.Color = ColorSequence.new(color1, color2)
	em.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	em.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	em.Lifetime = NumberRange.new(0.8, 1.4); em.Rate = rate
	em.Speed = NumberRange.new(speed * 0.5, speed); em.SpreadAngle = Vector2.new(180, 180)
	em.Parent = part
end

local function buildFloor(parent, o, floorY, idx)
	local halfW, wallThick, wallH = 14, 3, 14
	local totalW = halfW * 2 + wallThick * 2

	p(parent, "Floor"..idx, Vector3.new(totalW, 1.5, totalW), CFrame.new(o + Vector3.new(0, floorY, 0)), C.WhiteMarble, Enum.Material.SmoothPlastic)
	p(parent, "WallN"..idx, Vector3.new(totalW, wallH, wallThick), CFrame.new(o + Vector3.new(0, floorY+wallH/2+0.75, -(halfW+wallThick/2))), C.CreamWall, Enum.Material.SmoothPlastic)
	p(parent, "WallS"..idx, Vector3.new(totalW, wallH, wallThick), CFrame.new(o + Vector3.new(0, floorY+wallH/2+0.75,  halfW+wallThick/2)), C.CreamWall, Enum.Material.SmoothPlastic)
	p(parent, "WallE"..idx, Vector3.new(wallThick, wallH, totalW), CFrame.new(o + Vector3.new( halfW+wallThick/2, floorY+wallH/2+0.75, 0)), C.CreamWall, Enum.Material.SmoothPlastic)
	p(parent, "WallW"..idx, Vector3.new(wallThick, wallH, totalW), CFrame.new(o + Vector3.new(-(halfW+wallThick/2), floorY+wallH/2+0.75, 0)), C.CreamWall, Enum.Material.SmoothPlastic)
	p(parent, "Trim"..idx, Vector3.new(totalW+2, 1, totalW+2), CFrame.new(o + Vector3.new(0, floorY+wallH+1.25, 0)), C.GoldTrim, Enum.Material.SmoothPlastic)

	for _, zOff in ipairs({ -5, 5 }) do
		local win = p(parent, "WindowE"..idx, Vector3.new(2, 4, 0.5), CFrame.new(o + Vector3.new(halfW+wallThick, floorY+wallH/2+0.75, zOff)), C.GoldenNeon, Enum.Material.Neon)
		win.CanCollide = false; addLight(win, C.GoldenNeon, 1.5, 14)
		local winW = p(parent, "WindowW"..idx, Vector3.new(2, 4, 0.5), CFrame.new(o + Vector3.new(-(halfW+wallThick), floorY+wallH/2+0.75, zOff)), C.GoldenNeon, Enum.Material.Neon)
		winW.CanCollide = false; addLight(winW, C.GoldenNeon, 1.5, 14)
	end

	for _, xz in ipairs({ {-10,-10},{10,-10},{-10,10},{10,10} }) do
		p(parent, "Pillar"..idx, Vector3.new(1.5, wallH, 1.5), CFrame.new(o + Vector3.new(xz[1], floorY+wallH/2+0.75, xz[2])), C.RedPillar, Enum.Material.SmoothPlastic)
		local rune = p(parent, "Rune"..idx, Vector3.new(0.4, wallH*0.6, 0.4), CFrame.new(o + Vector3.new(xz[1], floorY+wallH/2+0.75, xz[2])), C.GoldenNeon, Enum.Material.Neon)
		rune.CanCollide = false; rune.Transparency = 0.3
	end
end

local function buildStairs(parent, fromY, toY, basePos, side)
	local numSteps = 14
	local stepH = (toY - fromY) / numSteps
	for i = 0, numSteps - 1 do
		local t = i / numSteps
		local angle = (side == "east" and 1 or -1) * t * math.rad(180)
		local xOff = (side == "east" and 8 or -8) + math.sin(angle) * 6
		local zOff = -8 + math.cos(angle) * 6
		p(parent, "Stair", Vector3.new(4.5, 0.8, 2), CFrame.new(basePos + Vector3.new(xOff, fromY + i*stepH + 0.4, zOff)) * CFrame.Angles(0, angle, 0), C.WhiteMarble, Enum.Material.SmoothPlastic)
	end
end

local function addFloorDecor(parent, o, floorY, floorType)
	if floorType == "Flame" then
		for _, xz in ipairs({ {-8,-8},{8,-8},{-8,8},{8,8} }) do
			local flame = p(parent, "GoldFlame", Vector3.new(1.2,1.2,1.2), CFrame.new(o + Vector3.new(xz[1], floorY+5, xz[2])), C.GoldenNeon, Enum.Material.Neon)
			flame.CanCollide = false; addLight(flame, C.GoldenNeon, 4, 18)
			addParticle(flame, C.GoldenNeon, Color3.fromRGB(255, 240, 100), 18, 5, 0.8)
		end
		local center = p(parent, "FlameCenter", Vector3.new(8,0.3,8), CFrame.new(o + Vector3.new(0, floorY+0.75, 0)), Color3.fromRGB(255,200,50), Enum.Material.Neon)
		center.CanCollide = false; center.Transparency = 0.4; addLight(center, C.GoldenNeon, 3, 22)

	elseif floorType == "Thunder" then
		for _, xz in ipairs({ {-8,0},{8,0},{0,-8},{0,8} }) do
			local bolt = p(parent, "ThunderPillar", Vector3.new(0.8,10,0.8), CFrame.new(o + Vector3.new(xz[1], floorY+6, xz[2])), Color3.fromRGB(180,120,255), Enum.Material.Neon)
			bolt.CanCollide = false; addLight(bolt, Color3.fromRGB(180,120,255), 2.5, 16)
		end
		local thunderFloor = p(parent, "ThunderFloor", Vector3.new(10,0.3,10), CFrame.new(o + Vector3.new(0,floorY+0.75,0)), Color3.fromRGB(150,80,255), Enum.Material.Neon)
		thunderFloor.CanCollide = false; thunderFloor.Transparency = 0.4

	elseif floorType == "Palm" then
		for _, xz in ipairs({ {-10,0},{10,0} }) do
			p(parent, "IronChain", Vector3.new(2,12,2), CFrame.new(o + Vector3.new(xz[1], floorY+7, xz[2])), Color3.fromRGB(120,120,130), Enum.Material.Metal)
		end
		local goldenFloor = p(parent, "GoldFloor", Vector3.new(12,0.3,12), CFrame.new(o + Vector3.new(0,floorY+0.75,0)), C.GoldenNeon, Enum.Material.Neon)
		goldenFloor.CanCollide = false; goldenFloor.Transparency = 0.5; addLight(goldenFloor, C.GoldenNeon, 2, 20)

	elseif floorType == "Sword" then
		for _, side in ipairs({ -1, 1 }) do
			local swordStat = p(parent, "SwordStat", Vector3.new(0.6,7,0.6), CFrame.new(o + Vector3.new(side*10, floorY+4.5, 0)), C.GoldenNeon, Enum.Material.Neon)
			swordStat.CanCollide = false
		end
		local swordFloor = p(parent, "SwordFloor", Vector3.new(10,0.3,10), CFrame.new(o + Vector3.new(0,floorY+0.75,0)), Color3.fromRGB(200,220,255), Enum.Material.Neon)
		swordFloor.CanCollide = false; swordFloor.Transparency = 0.4

	elseif floorType == "Apex" then
		p(parent, "ApexDais", Vector3.new(10,2,8), CFrame.new(o + Vector3.new(0,floorY+1.5,-6)), C.WhiteMarble, Enum.Material.SmoothPlastic)
		p(parent, "ApexThrone", Vector3.new(4,7,2), CFrame.new(o + Vector3.new(0,floorY+5.5,-8.5)), C.WhiteMarble, Enum.Material.SmoothPlastic)
		p(parent, "ApexGoldL", Vector3.new(0.4,7,2.5), CFrame.new(o + Vector3.new(-2.2,floorY+5.5,-8.5)), C.GoldTrim, Enum.Material.SmoothPlastic)
		p(parent, "ApexGoldR", Vector3.new(0.4,7,2.5), CFrame.new(o + Vector3.new( 2.2,floorY+5.5,-8.5)), C.GoldTrim, Enum.Material.SmoothPlastic)
		local apexCore = p(parent, "ApexCore", Vector3.new(2,2,2), CFrame.new(o + Vector3.new(0,floorY+10,-8.5)), C.GoldenNeon, Enum.Material.Neon)
		apexCore.CanCollide = false; apexCore.Transparency = 0.2
		addLight(apexCore, C.GoldenNeon, 8, 55)
		addParticle(apexCore, C.GoldenNeon, Color3.fromRGB(255,250,200), 20, 4, 1.5)
	end
end

local function buildExterior(parent, o)
	local totalW, towerH = 34, 80
	p(parent, "TowerBase", Vector3.new(totalW+6, 4, totalW+6), CFrame.new(o + Vector3.new(0, 2, 0)), C.WhiteMarble, Enum.Material.SmoothPlastic)
	p(parent, "TowerPlinth", Vector3.new(totalW+2, 2, totalW+2), CFrame.new(o + Vector3.new(0, 5, 0)), C.GoldTrim, Enum.Material.SmoothPlastic)

	for _, xz in ipairs({ {-17,-17},{17,-17},{-17,17},{17,17} }) do
		p(parent, "Buttress", Vector3.new(5, towerH, 5), CFrame.new(o + Vector3.new(xz[1], towerH/2, xz[2])), C.WhiteMarble, Enum.Material.SmoothPlastic)
		local rune = p(parent, "ButtressRune", Vector3.new(0.5, towerH*0.6, 0.5), CFrame.new(o + Vector3.new(xz[1], towerH/2, xz[2])), C.GoldenNeon, Enum.Material.Neon)
		rune.CanCollide = false; rune.Transparency = 0.3
	end

	-- Entrance arch
	p(parent, "ArchL",  Vector3.new(3, 10, 3.5), CFrame.new(o + Vector3.new(-5.5, 10, 17.5)), C.WhiteMarble, Enum.Material.SmoothPlastic)
	p(parent, "ArchR",  Vector3.new(3, 10, 3.5), CFrame.new(o + Vector3.new( 5.5, 10, 17.5)), C.WhiteMarble, Enum.Material.SmoothPlastic)
	p(parent, "ArchTop",Vector3.new(14, 2.5, 3.5), CFrame.new(o + Vector3.new(0, 15.25, 17.5)), C.GoldTrim, Enum.Material.SmoothPlastic)
	local archGlow = p(parent, "ArchGlow", Vector3.new(11, 0.5, 0.5), CFrame.new(o + Vector3.new(0, 14.5, 17.6)), C.GoldenNeon, Enum.Material.Neon)
	archGlow.CanCollide = false; addLight(archGlow, C.GoldenNeon, 4, 28)

	-- Tower cap + spires
	p(parent, "TowerCap", Vector3.new(totalW, 4, totalW), CFrame.new(o + Vector3.new(0, towerH+2, 0)), C.GoldTrim, Enum.Material.SmoothPlastic)
	for _, xz in ipairs({ {-14,-14},{14,-14},{-14,14},{14,14} }) do
		p(parent, "CornerSpire",  Vector3.new(2.5,12,2.5), CFrame.new(o + Vector3.new(xz[1], towerH+10, xz[2])), C.WhiteMarble, Enum.Material.SmoothPlastic)
		p(parent, "SpireTip",     Vector3.new(1, 4, 1),    CFrame.new(o + Vector3.new(xz[1], towerH+17, xz[2])), C.GoldenNeon, Enum.Material.Neon)
	end
	p(parent, "CentralSpire", Vector3.new(5, 20, 5), CFrame.new(o + Vector3.new(0, towerH+12, 0)), C.WhiteMarble, Enum.Material.SmoothPlastic)
	local centralTip = p(parent, "CentralTip", Vector3.new(2, 6, 2), CFrame.new(o + Vector3.new(0, towerH+24, 0)), C.GoldenNeon, Enum.Material.Neon)
	addLight(centralTip, C.GoldenNeon, 10, 65)
	addParticle(centralTip, C.GoldenNeon, Color3.fromRGB(255,250,200), 20, 4, 1)

	-- Bridge to village
	local villageCenter = Vector3.new(300, 0, 350)
	local bridgeLen = villageCenter.Z - 20 - (o.Z + 18)
	local midZ = o.Z + 18 + bridgeLen / 2
	p(parent, "Bridge", Vector3.new(8, 1, bridgeLen), CFrame.new(Vector3.new(o.X, 0.5, midZ)), C.WhiteStone, Enum.Material.Cobblestone)
	for i = 0, math.floor(bridgeLen / 20) do
		local zPos = o.Z + 18 + i * 20
		for _, xOff in ipairs({ -6, 6 }) do
			local post = p(parent, "BridgePost", Vector3.new(0.8, 6, 0.8), CFrame.new(Vector3.new(o.X+xOff, 3, zPos)), C.DarkWood, Enum.Material.Wood)
			local glow = p(parent, "BridgeGlow", Vector3.new(1, 1.5, 1), CFrame.new(Vector3.new(o.X+xOff, 6.5, zPos)), C.GoldenNeon, Enum.Material.Neon)
			glow.CanCollide = false; addLight(glow, C.GoldenNeon, 2, 14)
		end
	end
end

function HeavenAllianceTowerGenerator.generate(parent: Instance?)
	local folder = Workspace:FindFirstChild("HeavenAllianceTower")
	if folder then folder:Destroy() end
	folder = Instance.new("Folder"); folder.Name = "HeavenAllianceTower"; folder.Parent = parent or Workspace

	local o = TOWER_CENTER
	buildExterior(folder, o)

	local floorDefs = {
		{y=7,  type="Flame"}, {y=21, type="Thunder"},
		{y=35, type="Palm"},  {y=49, type="Sword"},  {y=65, type="Apex"},
	}
	for i, def in ipairs(floorDefs) do
		buildFloor(folder, o, def.y, i)
		addFloorDecor(folder, o, def.y, def.type)
		if i < #floorDefs then
			buildStairs(folder, def.y+1.5, floorDefs[i+1].y, o, i%2==0 and "east" or "west")
		end
	end

	print("[HeavenAllianceTowerGenerator] Tower generated at", tostring(o))
	return folder
end

return HeavenAllianceTowerGenerator
