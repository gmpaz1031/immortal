local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local VillageGenerator = {}

--------------------------------------------------------------------------------
-- Color & Material Palette for Chinese Cultivation (Xianxia)
--------------------------------------------------------------------------------
local PALETTE = {
	RedPillar = Color3.fromRGB(165, 38, 28),
	DarkWood = Color3.fromRGB(45, 32, 25),
	GoldRoof = Color3.fromRGB(225, 170, 45),
	JadeRoof = Color3.fromRGB(38, 105, 92),
	GreyRoof = Color3.fromRGB(75, 80, 88),
	WhiteWall = Color3.fromRGB(240, 235, 225),
	StoneFloor = Color3.fromRGB(120, 125, 135),
	DarkStone = Color3.fromRGB(70, 72, 78),
	Bronze = Color3.fromRGB(150, 105, 55),
	LanternGlow = Color3.fromRGB(255, 150, 40),
	Water = Color3.fromRGB(30, 140, 180),
	PeachPink = Color3.fromRGB(255, 160, 195),
	BambooGreen = Color3.fromRGB(75, 140, 50)
}

--------------------------------------------------------------------------------
-- Builder Helper Functions
--------------------------------------------------------------------------------
local function makePart(parent, name, size, cframe, color, material)
	local p = Instance.new("Part")
	p.Name = name or "Part"
	p.Size = size
	p.CFrame = cframe
	p.Color = color or PALETTE.StoneFloor
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function makeWedge(parent, name, size, cframe, color, material)
	local w = Instance.new("WedgePart")
	w.Name = name or "Wedge"
	w.Size = size
	w.CFrame = cframe
	w.Color = color or PALETTE.GoldRoof
	w.Material = material or Enum.Material.SmoothPlastic
	w.Anchored = true
	w.CanCollide = true
	w.TopSurface = Enum.SurfaceType.Smooth
	w.BottomSurface = Enum.SurfaceType.Smooth
	w.Parent = parent
	return w
end

--------------------------------------------------------------------------------
-- Street Lantern (石灯笼)
--------------------------------------------------------------------------------
local function createStoneLantern(parent, cframe)
	local model = Instance.new("Model")
	model.Name = "StoneLantern"

	-- Base
	makePart(model, "Base", Vector3.new(2, 0.6, 2), cframe * CFrame.new(0, 0.3, 0), PALETTE.DarkStone, Enum.Material.Cobblestone)
	-- Pillar
	makePart(model, "Pillar", Vector3.new(1, 3, 1), cframe * CFrame.new(0, 2.1, 0), PALETTE.DarkStone, Enum.Material.Cobblestone)
	-- Housing Platform
	makePart(model, "Platform", Vector3.new(2.2, 0.4, 2.2), cframe * CFrame.new(0, 3.8, 0), PALETTE.DarkStone, Enum.Material.Cobblestone)

	-- Glowing Core
	local core = makePart(model, "GlowCore", Vector3.new(1.2, 1.4, 1.2), cframe * CFrame.new(0, 4.7, 0), PALETTE.LanternGlow, Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Color = PALETTE.LanternGlow
	light.Brightness = 2.5
	light.Range = 18
	light.Parent = core

	-- Lantern Roof Cap
	makePart(model, "RoofCap", Vector3.new(2.8, 0.5, 2.8), cframe * CFrame.new(0, 5.6, 0), PALETTE.DarkWood, Enum.Material.WoodPlanks)
	makePart(model, "RoofFinial", Vector3.new(0.6, 0.8, 0.6), cframe * CFrame.new(0, 6.2, 0), PALETTE.GoldRoof, Enum.Material.SmoothPlastic)

	model.Parent = parent
	return model
end

--------------------------------------------------------------------------------
-- Peach Blossom Tree (桃花树)
--------------------------------------------------------------------------------
local function createPeachBlossomTree(parent, cframe)
	local model = Instance.new("Model")
	model.Name = "PeachBlossomTree"

	-- Trunk segments
	local t1 = makePart(model, "Trunk1", Vector3.new(1.6, 6, 1.6), cframe * CFrame.new(0, 3, 0) * CFrame.Angles(math.rad(4), 0, math.rad(-3)), PALETTE.DarkWood, Enum.Material.Wood)
	local t2 = makePart(model, "Trunk2", Vector3.new(1.3, 5, 1.3), cframe * CFrame.new(-0.4, 7, 0.2) * CFrame.Angles(math.rad(-10), math.rad(15), math.rad(12)), PALETTE.DarkWood, Enum.Material.Wood)
	local t3 = makePart(model, "Branch", Vector3.new(1, 4, 1), cframe * CFrame.new(0.8, 8, -0.4) * CFrame.Angles(math.rad(14), math.rad(-25), math.rad(-18)), PALETTE.DarkWood, Enum.Material.Wood)

	-- Pink foliage spheres
	local foliagePositions = {
		Vector3.new(-0.8, 10, 0.5),
		Vector3.new(1.4, 10.5, -0.6),
		Vector3.new(0, 11.5, 0),
		Vector3.new(-1.8, 9, 1.2),
		Vector3.new(1.8, 9.2, 0.8)
	}

	for idx, offset in ipairs(foliagePositions) do
		local f = Instance.new("Part")
		f.Name = "Blossoms" .. idx
		f.Shape = Enum.PartType.Ball
		f.Size = Vector3.new(5.5, 4.5, 5.5)
		f.CFrame = cframe * CFrame.new(offset)
		f.Color = PALETTE.PeachPink
		f.Material = Enum.Material.Grass
		f.Anchored = true
		f.CanCollide = false
		f.Parent = model
	end

	-- Falling Petal Emitter
	local emitterPart = Instance.new("Part")
	emitterPart.Name = "PetalEmitterPart"
	emitterPart.Size = Vector3.new(2, 0.2, 2)
	emitterPart.CFrame = cframe * CFrame.new(0, 10, 0)
	emitterPart.Transparency = 1
	emitterPart.Anchored = true
	emitterPart.CanCollide = false
	emitterPart.Parent = model

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(PALETTE.PeachPink)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 0.3)
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.8, 0.4),
		NumberSequenceKeypoint.new(1, 1)
	})
	emitter.Lifetime = NumberRange.new(3, 5)
	emitter.Rate = 4
	emitter.Speed = NumberRange.new(1, 2.5)
	emitter.SpreadAngle = Vector2.new(45, 180)
	emitter.Acceleration = Vector3.new(1.5, -3, 0.8)
	emitter.Parent = emitterPart

	model.Parent = parent
	return model
end

--------------------------------------------------------------------------------
-- Bamboo Cluster (青竹林)
--------------------------------------------------------------------------------
local function createBambooCluster(parent, cframe)
	local model = Instance.new("Model")
	model.Name = "BambooCluster"

	local offsets = {
		Vector3.new(0, 0, 0),
		Vector3.new(1.2, 0, 0.8),
		Vector3.new(-1, 0, 1),
		Vector3.new(0.8, 0, -1.2),
		Vector3.new(-0.7, 0, -0.9)
	}

	for _, off in ipairs(offsets) do
		local height = math.random(11, 15)
		local stalk = Instance.new("Part")
		stalk.Name = "Stalk"
		stalk.Shape = Enum.PartType.Cylinder
		stalk.Size = Vector3.new(height, 0.5, 0.5)
		stalk.CFrame = cframe * CFrame.new(off) * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.rad(90))
		stalk.Color = PALETTE.BambooGreen
		stalk.Material = Enum.Material.SmoothPlastic
		stalk.Anchored = true
		stalk.Parent = model

		local leaves = Instance.new("Part")
		leaves.Name = "Leaves"
		leaves.Shape = Enum.PartType.Ball
		leaves.Size = Vector3.new(3, 4, 3)
		leaves.CFrame = cframe * CFrame.new(off) * CFrame.new(0, height + 1, 0)
		leaves.Color = PALETTE.BambooGreen
		leaves.Material = Enum.Material.Grass
		leaves.Anchored = true
		leaves.CanCollide = false
		leaves.Parent = model
	end

	model.Parent = parent
	return model
end

--------------------------------------------------------------------------------
-- Paifang Mountain Gate (仙缘牌坊 / 山门)
--------------------------------------------------------------------------------
local function createPaifangGate(parent, cframe, width)
	width = width or 28
	local height = 18
	local model = Instance.new("Model")
	model.Name = "PaifangGate"

	-- 2 Main Stone Bases
	local colX = width * 0.35
	makePart(model, "PedestalL", Vector3.new(3.5, 2, 3.5), cframe * CFrame.new(-colX, 1, 0), PALETTE.DarkStone, Enum.Material.Cobblestone)
	makePart(model, "PedestalR", Vector3.new(3.5, 2, 3.5), cframe * CFrame.new(colX, 1, 0), PALETTE.DarkStone, Enum.Material.Cobblestone)

	-- 2 Outer Pedestals
	local outX = width * 0.48
	makePart(model, "PedestalOutL", Vector3.new(2.8, 1.5, 2.8), cframe * CFrame.new(-outX, 0.75, 0), PALETTE.DarkStone, Enum.Material.Cobblestone)
	makePart(model, "PedestalOutR", Vector3.new(2.8, 1.5, 2.8), cframe * CFrame.new(outX, 0.75, 0), PALETTE.DarkStone, Enum.Material.Cobblestone)

	-- 4 Vermilion Columns
	makePart(model, "ColMainL", Vector3.new(2, height, 2), cframe * CFrame.new(-colX, height / 2 + 2, 0), PALETTE.RedPillar, Enum.Material.WoodPlanks)
	makePart(model, "ColMainR", Vector3.new(2, height, 2), cframe * CFrame.new(colX, height / 2 + 2, 0), PALETTE.RedPillar, Enum.Material.WoodPlanks)
	makePart(model, "ColOutL", Vector3.new(1.6, height * 0.75, 1.6), cframe * CFrame.new(-outX, (height * 0.75) / 2 + 1.5, 0), PALETTE.RedPillar, Enum.Material.WoodPlanks)
	makePart(model, "ColOutR", Vector3.new(1.6, height * 0.75, 1.6), cframe * CFrame.new(outX, (height * 0.75) / 2 + 1.5, 0), PALETTE.RedPillar, Enum.Material.WoodPlanks)

	-- Main Crossbeam & Sub Beams
	makePart(model, "MainBeam", Vector3.new(width * 0.8, 1.8, 2.4), cframe * CFrame.new(0, height + 0.5, 0), PALETTE.DarkWood, Enum.Material.WoodPlanks)
	makePart(model, "LowerBeam", Vector3.new(width * 0.76, 1.2, 1.8), cframe * CFrame.new(0, height - 3.5, 0), PALETTE.DarkWood, Enum.Material.WoodPlanks)

	-- Calligraphy Plaque
	local plaque = makePart(model, "Plaque", Vector3.new(width * 0.45, 2.8, 0.6), cframe * CFrame.new(0, height - 1.5, 0), PALETTE.DarkWood, Enum.Material.WoodPlanks)
	local bbg = Instance.new("BillboardGui")
	bbg.Name = "Sign"
	bbg.AlwaysOnTop = true
	bbg.Size = UDim2.new(0, 260, 0, 50)
	bbg.Adornee = plaque
	bbg.Parent = plaque

	local txt = Instance.new("TextLabel")
	txt.BackgroundTransparency = 1
	txt.Size = UDim2.new(1, 0, 1, 0)
	txt.Font = Enum.Font.GothamBlack
	txt.Text = "仙 缘 古 镇"
	txt.TextColor3 = PALETTE.GoldRoof
	txt.TextScaled = true
	txt.Parent = bbg

	-- Curved Tiled Pagoda Roof
	local roofWidth = width * 0.95
	makePart(model, "RoofMain", Vector3.new(roofWidth, 1, 7), cframe * CFrame.new(0, height + 2, 0), PALETTE.JadeRoof, Enum.Material.SmoothPlastic)
	makePart(model, "RoofRidge", Vector3.new(roofWidth + 2, 1.2, 1.5), cframe * CFrame.new(0, height + 2.8, 0), PALETTE.GoldRoof, Enum.Material.SmoothPlastic)

	-- Upturned Eaves on Left and Right
	makeWedge(model, "EaveL", Vector3.new(3, 1.4, 7), cframe * CFrame.new(-roofWidth / 2 - 1, height + 2.5, 0) * CFrame.Angles(0, math.rad(90), math.rad(15)), PALETTE.GoldRoof)
	makeWedge(model, "EaveR", Vector3.new(3, 1.4, 7), cframe * CFrame.new(roofWidth / 2 + 1, height + 2.5, 0) * CFrame.Angles(0, math.rad(-90), math.rad(15)), PALETTE.GoldRoof)

	-- 2 Hanging Red Lanterns
	for _, xSide in ipairs({ -colX + 3, colX - 3 }) do
		local lantern = makePart(model, "Lantern", Vector3.new(1.4, 2, 1.4), cframe * CFrame.new(xSide, height - 4.5, 0), PALETTE.LanternGlow, Enum.Material.Neon)
		local lgt = Instance.new("PointLight")
		lgt.Color = PALETTE.LanternGlow
		lgt.Brightness = 3
		lgt.Range = 16
		lgt.Parent = lantern
	end

	model.Parent = parent
	return model
end

--------------------------------------------------------------------------------
-- Grand Sect Cultivation Pavilion / Main Hall (宗门大殿)
--------------------------------------------------------------------------------
local function createGrandSectPavilion(parent, cframe, size)
	size = size or Vector3.new(48, 26, 38)
	local model = Instance.new("Model")
	model.Name = "GrandSectPavilion"

	local sx = size.X
	local sy = size.Y
	local sz = size.Z

	-- 1. Grand Elevated Stone Foundation
	local baseHeight = 3.5
	makePart(model, "BaseDais", Vector3.new(sx + 8, baseHeight, sz + 8), cframe * CFrame.new(0, baseHeight / 2, 0), PALETTE.DarkStone, Enum.Material.Cobblestone)
	makePart(model, "UpperDais", Vector3.new(sx + 4, 1, sz + 4), cframe * CFrame.new(0, baseHeight + 0.5, 0), PALETTE.StoneFloor, Enum.Material.Granite)

	-- Grand Entrance Steps in Front
	local stepCount = 6
	for i = 1, stepCount do
		local stepDepth = 1.6
		local stepY = (baseHeight / stepCount) * i
		makePart(model, "Step" .. i, Vector3.new(sx * 0.45, baseHeight / stepCount, stepDepth), cframe * CFrame.new(0, stepY - (baseHeight / stepCount / 2), (sz / 2 + 4) + (stepCount - i) * stepDepth), PALETTE.StoneFloor, Enum.Material.Cobblestone)
	end

	-- 2. Enclosed Walls
	local wallY = baseHeight + 1 + (sy * 0.4) / 2
	local wallH = sy * 0.4
	makePart(model, "BackWall", Vector3.new(sx - 2, wallH, 1.5), cframe * CFrame.new(0, wallY, -sz / 2 + 1), PALETTE.WhiteWall, Enum.Material.SmoothPlastic)
	makePart(model, "LeftWall", Vector3.new(1.5, wallH, sz - 2), cframe * CFrame.new(-sx / 2 + 1, wallY, 0), PALETTE.WhiteWall, Enum.Material.SmoothPlastic)
	makePart(model, "RightWall", Vector3.new(1.5, wallH, sz - 2), cframe * CFrame.new(sx / 2 - 1, wallY, 0), PALETTE.WhiteWall, Enum.Material.SmoothPlastic)

	-- Front Wall with Grand Entrance Opening
	local doorOpening = sx * 0.35
	local sideWallW = (sx - doorOpening) / 2
	makePart(model, "FrontWallL", Vector3.new(sideWallW, wallH, 1.5), cframe * CFrame.new(-sx / 2 + sideWallW / 2, wallY, sz / 2 - 1), PALETTE.WhiteWall, Enum.Material.SmoothPlastic)
	makePart(model, "FrontWallR", Vector3.new(sideWallW, wallH, 1.5), cframe * CFrame.new(sx / 2 - sideWallW / 2, wallY, sz / 2 - 1), PALETTE.WhiteWall, Enum.Material.SmoothPlastic)

	-- 3. Vermilion Pillars (Colonnade)
	local colH = sy * 0.75
	local colY = baseHeight + 1 + colH / 2
	local colXOffsets = { -sx / 2 + 2, -sx * 0.2, sx * 0.2, sx / 2 - 2 }
	local colZOffsets = { -sz / 2 + 2, sz / 2 - 2 }

	for _, cx in ipairs(colXOffsets) do
		for _, cz in ipairs(colZOffsets) do
			makePart(model, "Pillar", Vector3.new(2, colH, 2), cframe * CFrame.new(cx, colY, cz), PALETTE.RedPillar, Enum.Material.WoodPlanks)
		end
	end

	-- 4. Tier 1 Pagoda Roof (Overhanging)
	local t1Y = baseHeight + 1 + wallH + 1
	makePart(model, "RoofTier1", Vector3.new(sx + 10, 1.5, sz + 10), cframe * CFrame.new(0, t1Y, 0), PALETTE.GoldRoof, Enum.Material.SmoothPlastic)

	-- 5. Tier 2 Upper Pavilion Story
	local upperH = sy * 0.35
	local upperY = t1Y + 1 + upperH / 2
	makePart(model, "UpperHall", Vector3.new(sx * 0.65, upperH, sz * 0.65), cframe * CFrame.new(0, upperY, 0), PALETTE.DarkWood, Enum.Material.WoodPlanks)

	-- 6. Tier 2 Top Pagoda Roof with Golden Spire
	local t2Y = upperY + upperH / 2 + 1
	makePart(model, "RoofTier2", Vector3.new(sx * 0.85, 1.8, sz * 0.85), cframe * CFrame.new(0, t2Y, 0), PALETTE.GoldRoof, Enum.Material.SmoothPlastic)

	-- Central Golden Ridge Spire
	makePart(model, "GoldenSpire", Vector3.new(2, 6, 2), cframe * CFrame.new(0, t2Y + 4, 0), PALETTE.GoldRoof, Enum.Material.SmoothPlastic)
	local pearl = Instance.new("Part")
	pearl.Name = "SpiritOrb"
	pearl.Shape = Enum.PartType.Ball
	pearl.Size = Vector3.new(3, 3, 3)
	pearl.CFrame = cframe * CFrame.new(0, t2Y + 7.5, 0)
	pearl.Color = Color3.fromRGB(0, 235, 255)
	pearl.Material = Enum.Material.Neon
	pearl.Anchored = true
	pearl.Parent = model

	-- Plaque inside / above door
	local plaque = makePart(model, "HallPlaque", Vector3.new(12, 2.5, 0.5), cframe * CFrame.new(0, t1Y - 1.5, sz / 2 - 0.4), PALETTE.DarkWood)
	local bbg = Instance.new("BillboardGui")
	bbg.Name = "HallSign"
	bbg.AlwaysOnTop = true
	bbg.Size = UDim2.new(0, 220, 0, 45)
	bbg.Adornee = plaque
	bbg.Parent = plaque

	local txt = Instance.new("TextLabel")
	txt.BackgroundTransparency = 1
	txt.Size = UDim2.new(1, 0, 1, 0)
	txt.Font = Enum.Font.GothamBlack
	txt.Text = "宗 门 大 殿"
	txt.TextColor3 = PALETTE.GoldRoof
	txt.TextScaled = true
	txt.Parent = bbg

	model.Parent = parent
	return model
end

--------------------------------------------------------------------------------
-- Pill Pavilion & Alchemy Furnace (炼丹阁与炼丹炉)
--------------------------------------------------------------------------------
local function createPillPavilion(parent, cframe, size)
	size = size or Vector3.new(26, 18, 26)
	local model = Instance.new("Model")
	model.Name = "PillPavilion"

	local sx = size.X
	local sy = size.Y
	local sz = size.Z

	-- Octagonal / Stone Base
	makePart(model, "PillBase", Vector3.new(sx, 1.5, sz), cframe * CFrame.new(0, 0.75, 0), PALETTE.DarkStone, Enum.Material.Cobblestone)

	-- Open Pavilion Pillars
	local colH = sy * 0.7
	local colY = 1.5 + colH / 2
	local corners = {
		Vector3.new(-sx / 2 + 2, colY, -sz / 2 + 2),
		Vector3.new(sx / 2 - 2, colY, -sz / 2 + 2),
		Vector3.new(-sx / 2 + 2, colY, sz / 2 - 2),
		Vector3.new(sx / 2 - 2, colY, sz / 2 - 2),
		Vector3.new(0, colY, -sz / 2 + 2)
	}

	for _, pos in ipairs(corners) do
		makePart(model, "Pillar", Vector3.new(1.8, colH, 1.8), cframe * CFrame.new(pos), PALETTE.DarkWood, Enum.Material.WoodPlanks)
	end

	-- Jade Tiled Curved Roof
	local roofY = 1.5 + colH + 1.5
	makePart(model, "JadeRoof", Vector3.new(sx + 6, 2, sz + 6), cframe * CFrame.new(0, roofY, 0), PALETTE.JadeRoof, Enum.Material.SmoothPlastic)
	makePart(model, "RoofCap", Vector3.new(sx * 0.5, 1.5, sz * 0.5), cframe * CFrame.new(0, roofY + 1.8, 0), PALETTE.GoldRoof, Enum.Material.SmoothPlastic)

	-- Giant Bronze Alchemy Furnace (神农炼丹炉) in center
	local furnace = Instance.new("Part")
	furnace.Name = "AlchemyCauldron"
	furnace.Shape = Enum.PartType.Ball
	furnace.Size = Vector3.new(5.5, 5.5, 5.5)
	furnace.CFrame = cframe * CFrame.new(0, 4.2, 0)
	furnace.Color = PALETTE.Bronze
	furnace.Material = Enum.Material.CorrodedMetal
	furnace.Anchored = true
	furnace.Parent = model

	-- Furnace Legs
	makePart(model, "Leg1", Vector3.new(1, 2.5, 1), cframe * CFrame.new(-1.8, 1.8, -1.8) * CFrame.Angles(math.rad(15), 0, math.rad(-15)), PALETTE.Bronze)
	makePart(model, "Leg2", Vector3.new(1, 2.5, 1), cframe * CFrame.new(1.8, 1.8, -1.8) * CFrame.Angles(math.rad(15), 0, math.rad(15)), PALETTE.Bronze)
	makePart(model, "Leg3", Vector3.new(1, 2.5, 1), cframe * CFrame.new(0, 1.8, 2.2) * CFrame.Angles(math.rad(-20), 0, 0), PALETTE.Bronze)

	-- Mystical Purple / Golden Smoke Particles
	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "SpiritualFireSmoke"
	smoke.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 235, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 70, 240)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 215, 60))
	})
	smoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.6, 3),
		NumberSequenceKeypoint.new(1, 0)
	})
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.7, 0.6),
		NumberSequenceKeypoint.new(1, 1)
	})
	smoke.Lifetime = NumberRange.new(1.5, 3)
	smoke.Rate = 18
	smoke.Speed = NumberRange.new(3, 7)
	smoke.SpreadAngle = Vector2.new(20, 20)
	smoke.Acceleration = Vector3.new(0, 4, 0)
	smoke.Parent = furnace

	-- Cauldron Glow
	local cl = Instance.new("PointLight")
	cl.Color = Color3.fromRGB(180, 80, 240)
	cl.Brightness = 4
	cl.Range = 22
	cl.Parent = furnace

	-- Sign
	local plaque = makePart(model, "Plaque", Vector3.new(8, 2, 0.4), cframe * CFrame.new(0, roofY - 1.2, sz / 2 + 1), PALETTE.DarkWood)
	local bbg = Instance.new("BillboardGui")
	bbg.Name = "Sign"
	bbg.AlwaysOnTop = true
	bbg.Size = UDim2.new(0, 180, 0, 40)
	bbg.Adornee = plaque
	bbg.Parent = plaque

	local txt = Instance.new("TextLabel")
	txt.BackgroundTransparency = 1
	txt.Size = UDim2.new(1, 0, 1, 0)
	txt.Font = Enum.Font.GothamBlack
	txt.Text = "炼 丹 阁"
	txt.TextColor3 = PALETTE.JadeRoof
	txt.TextScaled = true
	txt.Parent = bbg

	model.Parent = parent
	return model
end

--------------------------------------------------------------------------------
-- Lotus Pond & Moon Bridge (青莲灵池)
--------------------------------------------------------------------------------
local function createLotusPond(parent, cframe, size)
	size = size or Vector3.new(30, 2, 24)
	local model = Instance.new("Model")
	model.Name = "LotusPond"

	local sx = size.X
	local sz = size.Z

	-- Stone Rim
	local rimThickness = 1.5
	makePart(model, "RimN", Vector3.new(sx, 1.2, rimThickness), cframe * CFrame.new(0, 0.6, -sz / 2), PALETTE.DarkStone, Enum.Material.Cobblestone)
	makePart(model, "RimS", Vector3.new(sx, 1.2, rimThickness), cframe * CFrame.new(0, 0.6, sz / 2), PALETTE.DarkStone, Enum.Material.Cobblestone)
	makePart(model, "RimW", Vector3.new(rimThickness, 1.2, sz), cframe * CFrame.new(-sx / 2, 0.6, 0), PALETTE.DarkStone, Enum.Material.Cobblestone)
	makePart(model, "RimE", Vector3.new(rimThickness, 1.2, sz), cframe * CFrame.new(sx / 2, 0.6, 0), PALETTE.DarkStone, Enum.Material.Cobblestone)

	-- Glowing Water
	local water = makePart(model, "WaterSurface", Vector3.new(sx - 2, 0.4, sz - 2), cframe * CFrame.new(0, 0.3, 0), PALETTE.Water, Enum.Material.Glass)
	water.Transparency = 0.35
	water.CanCollide = false

	-- Water Glow
	local wl = Instance.new("PointLight")
	wl.Color = Color3.fromRGB(0, 220, 255)
	wl.Brightness = 2
	wl.Range = 25
	wl.Parent = water

	-- Arched Wooden Moon Bridge crossing the pond
	local bridgeLen = sz + 2
	local segCount = 7
	for i = 1, segCount do
		local frac = (i - 1) / (segCount - 1)
		local zPos = -bridgeLen / 2 + frac * bridgeLen
		local archY = 0.8 + math.sin(frac * math.pi) * 2.2

		makePart(model, "BridgePlank" .. i, Vector3.new(4.5, 0.4, bridgeLen / segCount + 0.2), cframe * CFrame.new(0, archY, zPos), PALETTE.DarkWood, Enum.Material.WoodPlanks)
		-- Railing posts
		makePart(model, "RailL" .. i, Vector3.new(0.4, 1.8, 0.4), cframe * CFrame.new(-2.1, archY + 0.9, zPos), PALETTE.RedPillar)
		makePart(model, "RailR" .. i, Vector3.new(0.4, 1.8, 0.4), cframe * CFrame.new(2.1, archY + 0.9, zPos), PALETTE.RedPillar)
	end

	-- Water Lilies / Lotus Flowers
	local flowerOffsets = {
		Vector3.new(-6, 0.4, -4),
		Vector3.new(-8, 0.4, 5),
		Vector3.new(7, 0.4, -6),
		Vector3.new(8, 0.4, 4)
	}
	for idx, fOff in ipairs(flowerOffsets) do
		-- Green Lily Pad
		local pad = Instance.new("Part")
		pad.Name = "LilyPad" .. idx
		pad.Shape = Enum.PartType.Cylinder
		pad.Size = Vector3.new(0.1, 2.8, 2.8)
		pad.CFrame = cframe * CFrame.new(fOff) * CFrame.Angles(0, 0, math.rad(90))
		pad.Color = Color3.fromRGB(40, 140, 60)
		pad.Material = Enum.Material.Grass
		pad.Anchored = true
		pad.CanCollide = false
		pad.Parent = model

		-- Pink Lotus Flower
		local lotus = Instance.new("Part")
		lotus.Name = "LotusFlower" .. idx
		lotus.Shape = Enum.PartType.Ball
		lotus.Size = Vector3.new(1.2, 1, 1.2)
		lotus.CFrame = cframe * CFrame.new(fOff + Vector3.new(0, 0.4, 0))
		lotus.Color = PALETTE.PeachPink
		lotus.Material = Enum.Material.Neon
		lotus.Anchored = true
		lotus.CanCollide = false
		lotus.Parent = model
	end

	model.Parent = parent
	return model
end

--------------------------------------------------------------------------------
-- Village Siheyuan House / Residence (弟子居 / 瓦房)
--------------------------------------------------------------------------------
local function createVillageHouse(parent, cframe, width, depth)
	width = width or 20
	depth = depth or 18
	local height = 12
	local model = Instance.new("Model")
	model.Name = "VillageHouse"

	-- Stone Foundation
	makePart(model, "Foundation", Vector3.new(width + 1, 1, depth + 1), cframe * CFrame.new(0, 0.5, 0), PALETTE.DarkStone, Enum.Material.Cobblestone)

	-- White Plaster Walls with Timber Corner Posts
	local wallH = height * 0.65
	local wallY = 1 + wallH / 2
	makePart(model, "BackWall", Vector3.new(width - 1, wallH, 1), cframe * CFrame.new(0, wallY, -depth / 2 + 0.5), PALETTE.WhiteWall)
	makePart(model, "LeftWall", Vector3.new(1, wallH, depth - 1), cframe * CFrame.new(-width / 2 + 0.5, wallY, 0), PALETTE.WhiteWall)
	makePart(model, "RightWall", Vector3.new(1, wallH, depth - 1), cframe * CFrame.new(width / 2 - 0.5, wallY, 0), PALETTE.WhiteWall)

	-- Front Wall with Doorway
	local doorW = 5
	local sideW = (width - doorW) / 2
	makePart(model, "FrontL", Vector3.new(sideW, wallH, 1), cframe * CFrame.new(-width / 2 + sideW / 2, wallY, depth / 2 - 0.5), PALETTE.WhiteWall)
	makePart(model, "FrontR", Vector3.new(sideW, wallH, 1), cframe * CFrame.new(width / 2 - sideW / 2, wallY, depth / 2 - 0.5), PALETTE.WhiteWall)
	makePart(model, "DoorFrame", Vector3.new(doorW, wallH * 0.25, 1.2), cframe * CFrame.new(0, 1 + wallH - (wallH * 0.125), depth / 2 - 0.5), PALETTE.DarkWood)

	-- Timber Corner Columns
	for _, xOff in ipairs({ -width / 2 + 0.6, width / 2 - 0.6 }) do
		for _, zOff in ipairs({ -depth / 2 + 0.6, depth / 2 - 0.6 }) do
			makePart(model, "TimberPost", Vector3.new(1.2, wallH + 0.5, 1.2), cframe * CFrame.new(xOff, wallY, zOff), PALETTE.DarkWood, Enum.Material.WoodPlanks)
		end
	end

	-- Slanted Tiled Roof
	local roofY = 1 + wallH + 1.2
	makePart(model, "TiledRoof", Vector3.new(width + 4, 1.4, depth + 4), cframe * CFrame.new(0, roofY, 0), PALETTE.GreyRoof, Enum.Material.Slate)
	makePart(model, "RoofRidge", Vector3.new(width + 5, 1, 1.2), cframe * CFrame.new(0, roofY + 1.2, 0), PALETTE.DarkWood)

	-- Hanging Entrance Lantern
	local lantern = makePart(model, "PorchLantern", Vector3.new(1, 1.4, 1), cframe * CFrame.new(0, wallH, depth / 2 + 1.2), PALETTE.LanternGlow, Enum.Material.Neon)
	local lgt = Instance.new("PointLight")
	lgt.Color = PALETTE.LanternGlow
	lgt.Brightness = 2
	lgt.Range = 12
	lgt.Parent = lantern

	model.Parent = parent
	return model
end

--------------------------------------------------------------------------------
-- Martial Arts Sparring Arena (演武场)
--------------------------------------------------------------------------------
local function createSparringArena(parent, cframe, size)
	size = size or Vector3.new(24, 1, 24)
	local model = Instance.new("Model")
	model.Name = "SparringArena"

	-- Octagonal or circular stone dais
	local dais = Instance.new("Part")
	dais.Name = "ArenaDais"
	dais.Shape = Enum.PartType.Cylinder
	dais.Size = Vector3.new(size.Y, size.X, size.Z)
	dais.CFrame = cframe * CFrame.new(0, size.Y / 2, 0) * CFrame.Angles(0, 0, math.rad(90))
	dais.Color = PALETTE.DarkStone
	dais.Material = Enum.Material.Cobblestone
	dais.Anchored = true
	dais.Parent = model

	-- Inner Yin-Yang / Cultivation Ring
	local ring = Instance.new("Part")
	ring.Name = "YinYangRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.2, size.X * 0.7, size.Z * 0.7)
	ring.CFrame = cframe * CFrame.new(0, size.Y + 0.1, 0) * CFrame.Angles(0, 0, math.rad(90))
	ring.Color = PALETTE.StoneFloor
	ring.Material = Enum.Material.Granite
	ring.Anchored = true
	ring.Parent = model

	-- 4 Boundary Torches
	local rad = size.X * 0.42
	local torchOffsets = {
		Vector3.new(rad, 0, 0),
		Vector3.new(-rad, 0, 0),
		Vector3.new(0, 0, rad),
		Vector3.new(0, 0, -rad)
	}

	for _, tOff in ipairs(torchOffsets) do
		makePart(model, "BrazierPost", Vector3.new(1, 4, 1), cframe * CFrame.new(tOff) * CFrame.new(0, 2, 0), PALETTE.DarkStone, Enum.Material.Cobblestone)
		local brazier = makePart(model, "BrazierBowl", Vector3.new(2, 0.8, 2), cframe * CFrame.new(tOff) * CFrame.new(0, 4.4, 0), PALETTE.Bronze)
		local fire = Instance.new("ParticleEmitter")
		fire.Color = ColorSequence.new(Color3.fromRGB(255, 180, 50))
		fire.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
		fire.Lifetime = NumberRange.new(0.5, 1)
		fire.Rate = 15
		fire.Speed = NumberRange.new(2, 5)
		fire.SpreadAngle = Vector2.new(15, 15)
		fire.Parent = brazier

		local fl = Instance.new("PointLight")
		fl.Color = PALETTE.LanternGlow
		fl.Brightness = 3
		fl.Range = 16
		fl.Parent = brazier
	end

	model.Parent = parent
	return model
end

--------------------------------------------------------------------------------
-- Main Village Generator Function
--------------------------------------------------------------------------------
function VillageGenerator.generate()
	-- 1. Find the target "Fantasy village" Part or Model in Workspace
	local targetPart = nil
	local targetModel = nil

	for _, child in ipairs(Workspace:GetDescendants()) do
		local lower = string.lower(child.Name)
		if lower == "fantasy village" or lower == "fantasyvillage" or (string.find(lower, "fantasy") and string.find(lower, "village")) then
			if child:IsA("BasePart") then
				targetPart = child
				break
			elseif child:IsA("Model") then
				targetModel = child
				targetPart = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
				if targetPart then break end
			end
		end
	end

	-- Extract dimensions
	local originCF = CFrame.new(0, 0, 0)
	local sizeX = 260
	local sizeZ = 260
	local topY = 0

	if targetPart then
		originCF = targetPart.CFrame
		sizeX = math.max(120, targetPart.Size.X)
		sizeZ = math.max(120, targetPart.Size.Z)
		topY = targetPart.Position.Y + (targetPart.Size.Y / 2)
		originCF = CFrame.new(targetPart.Position.X, topY, targetPart.Position.Z) * (originCF - originCF.Position)
	end

	-- Check if village already exists in Workspace (from edit mode)
	local existingVillage = Workspace:FindFirstChild("ChineseCultivationVillage")
	if existingVillage then
		print("🏛️ [VillageGenerator] Chinese Cultivation Village already exists in Workspace.")
		return existingVillage
	end

	local villageFolder = Instance.new("Folder")
	villageFolder.Name = "ChineseCultivationVillage"

	-- 2. Ancient Cobblestone Ground & Roads matching the part length
	local ground = makePart(villageFolder, "VillageGround", Vector3.new(sizeX, 1, sizeZ), originCF * CFrame.new(0, -0.5, 0), PALETTE.StoneFloor, Enum.Material.Cobblestone)

	-- Main Central Boulevard (Cobble / Stone Slab Avenue) running South to North
	local roadWidth = math.clamp(sizeX * 0.12, 14, 24)
	makePart(villageFolder, "MainAvenue", Vector3.new(roadWidth, 0.2, sizeZ * 0.95), originCF * CFrame.new(0, 0.1, 0), PALETTE.DarkStone, Enum.Material.Granite)

	-- Cross Avenue running East to West
	local crossRoadWidth = math.clamp(sizeZ * 0.1, 12, 20)
	makePart(villageFolder, "CrossAvenue", Vector3.new(sizeX * 0.9, 0.2, crossRoadWidth), originCF * CFrame.new(0, 0.12, 0), PALETTE.DarkStone, Enum.Material.Granite)

	-- 3. Landmark 1: Paifang Entrance Mountain Gate (South Edge)
	local gateZ = sizeZ * 0.44
	local gateWidth = math.clamp(sizeX * 0.18, 24, 36)
	createPaifangGate(villageFolder, originCF * CFrame.new(0, 0, gateZ), gateWidth)

	-- 4. Landmark 2: Grand Sect Cultivation Pavilion (North Focal Point)
	local pavilionZ = -sizeZ * 0.32
	local pavilionSize = Vector3.new(math.clamp(sizeX * 0.32, 45, 70), 28, math.clamp(sizeZ * 0.25, 36, 55))
	createGrandSectPavilion(villageFolder, originCF * CFrame.new(0, 0, pavilionZ), pavilionSize)

	-- 5. Landmark 3: Pill Refining Pavilion (North-West Quadrant, near Shop)
	local pillX = -sizeX * 0.3
	local pillZ = -sizeZ * 0.08
	createPillPavilion(villageFolder, originCF * CFrame.new(pillX, 0, pillZ) * CFrame.Angles(0, math.rad(45), 0))

	-- Relocate Shop Merchant into the Pill Courtyard if active
	local merchant = Workspace:FindFirstChild("ShopMerchant")
	local circle = Workspace:FindFirstChild("ShopCircle")
	if merchant and circle then
		local shopSpot = originCF * CFrame.new(pillX + 16, 0, pillZ + 4)
		merchant:SetPrimaryPartCFrame(shopSpot * CFrame.new(0, 3, 0))
		circle.CFrame = CFrame.new(shopSpot.Position + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
	end

	-- 6. Landmark 4: Lotus Pond & Moon Bridge (North-East Quadrant)
	local pondX = sizeX * 0.28
	local pondZ = -sizeZ * 0.08
	createLotusPond(villageFolder, originCF * CFrame.new(pondX, 0, pondZ), Vector3.new(sizeX * 0.22, 2, sizeZ * 0.2))

	-- 7. Landmark 5: Martial Arts Sparring Arena (South-West Quadrant)
	local arenaX = -sizeX * 0.28
	local arenaZ = sizeZ * 0.24
	createSparringArena(villageFolder, originCF * CFrame.new(arenaX, 0, arenaZ), Vector3.new(28, 1.2, 28))

	-- 8. Village Residential Houses & Siheyuan along the streets
	local housePlots = {
		-- South-East Residential Cluster
		originCF * CFrame.new(sizeX * 0.26, 0, sizeZ * 0.22) * CFrame.Angles(0, math.rad(-90), 0),
		originCF * CFrame.new(sizeX * 0.34, 0, sizeZ * 0.36) * CFrame.Angles(0, math.rad(180), 0),
		-- West Side Courtyards
		originCF * CFrame.new(-sizeX * 0.34, 0, -sizeZ * 0.25) * CFrame.Angles(0, math.rad(90), 0),
		originCF * CFrame.new(-sizeX * 0.36, 0, sizeZ * 0.06) * CFrame.Angles(0, math.rad(90), 0),
		-- East Side Courtyards
		originCF * CFrame.new(sizeX * 0.36, 0, -sizeZ * 0.26) * CFrame.Angles(0, math.rad(-90), 0),
	}

	for _, plotCF in ipairs(housePlots) do
		createVillageHouse(villageFolder, plotCF, 22, 18)
	end



	-- 10. Street Lanterns lining the avenues
	local avenueLen = sizeZ * 0.85
	local lanternSpacing = 30
	for z = -avenueLen / 2 + 10, avenueLen / 2 - 10, lanternSpacing do
		createStoneLantern(villageFolder, originCF * CFrame.new(-roadWidth / 2 - 2, 0, z))
		createStoneLantern(villageFolder, originCF * CFrame.new(roadWidth / 2 + 2, 0, z))
	end

	-- 11. Scenic Peach Blossom Trees & Bamboo Groves
	local treeSpots = {
		originCF * CFrame.new(-roadWidth / 2 - 7, 0, gateZ - 8),
		originCF * CFrame.new(roadWidth / 2 + 7, 0, gateZ - 8),
		originCF * CFrame.new(pondX + 16, 0, pondZ - 8),
		originCF * CFrame.new(pondX - 16, 0, pondZ + 12),
		originCF * CFrame.new(pillX - 14, 0, pillZ + 12),
		originCF * CFrame.new(0, 0, 0) * CFrame.new(-roadWidth / 2 - 8, 0, -8),
		originCF * CFrame.new(0, 0, 0) * CFrame.new(roadWidth / 2 + 8, 0, -8),
		originCF * CFrame.new(sizeX * 0.42, 0, sizeZ * 0.42),
		originCF * CFrame.new(-sizeX * 0.42, 0, sizeZ * 0.42)
	}

	for _, spot in ipairs(treeSpots) do
		createPeachBlossomTree(villageFolder, spot)
	end

	local bambooSpots = {
		originCF * CFrame.new(pondX + 14, 0, pondZ + 10),
		originCF * CFrame.new(pillX - 14, 0, pillZ - 10),
		originCF * CFrame.new(-sizeX * 0.42, 0, -sizeZ * 0.42),
		originCF * CFrame.new(sizeX * 0.42, 0, -sizeZ * 0.42)
	}

	for _, spot in ipairs(bambooSpots) do
		createBambooCluster(villageFolder, spot)
	end

	villageFolder.Parent = Workspace
	print(string.format("✅ [VillageGenerator] Successfully generated Chinese Cultivation Village (Bounds: %d x %d studs) on '%s'!", sizeX, sizeZ, targetPart and targetPart.Name or "Default Space"))
	return villageFolder
end

return VillageGenerator
