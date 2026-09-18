local Workspace = game:GetService("Workspace")

local BanditVillage = {}

--------------------------------------------------------------------------------
-- Color & Material Palette for Bandit Stronghold (黑风寨)
--------------------------------------------------------------------------------
local PALETTE = {
	DirtGround = Color3.fromRGB(56, 44, 34),
	DarkWood = Color3.fromRGB(52, 36, 26),
	RoughWood = Color3.fromRGB(78, 54, 38),
	SpikeWood = Color3.fromRGB(92, 65, 45),
	TentCloth = Color3.fromRGB(130, 40, 40),
	TentDark = Color3.fromRGB(35, 30, 32),
	Leather = Color3.fromRGB(115, 75, 45),
	StoneGrey = Color3.fromRGB(70, 72, 75),
	TorchFire = Color3.fromRGB(255, 140, 30),
	BloodRed = Color3.fromRGB(140, 20, 20),
	IronMetal = Color3.fromRGB(45, 48, 55),
	GoldTreasure = Color3.fromRGB(230, 185, 45),
}

local function makePart(parent, name, size, cframe, color, material)
	local p = Instance.new("Part")
	p.Name = name or "BanditPart"
	p.Size = size
	p.CFrame = cframe
	p.Color = color or PALETTE.RoughWood
	p.Material = material or Enum.Material.WoodPlanks
	p.Anchored = true
	p.CanCollide = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function makeWedge(parent, name, size, cframe, color, material)
	local w = Instance.new("WedgePart")
	w.Name = name or "BanditWedge"
	w.Size = size
	w.CFrame = cframe
	w.Color = color or PALETTE.RoughWood
	w.Material = material or Enum.Material.WoodPlanks
	w.Anchored = true
	w.CanCollide = true
	w.TopSurface = Enum.SurfaceType.Smooth
	w.BottomSurface = Enum.SurfaceType.Smooth
	w.Parent = parent
	return w
end

--------------------------------------------------------------------------------
-- Torch / Fire Brazier
--------------------------------------------------------------------------------
local function createBrazier(parent, cframe)
	local model = Instance.new("Model")
	model.Name = "BanditTorch"

	-- Wooden Post
	makePart(model, "Post", Vector3.new(0.8, 5, 0.8), cframe * CFrame.new(0, 2.5, 0), PALETTE.DarkWood, Enum.Material.Wood)
	-- Iron Bowl
	local bowl = makePart(model, "Bowl", Vector3.new(2, 0.8, 2), cframe * CFrame.new(0, 5.2, 0), PALETTE.IronMetal, Enum.Material.CorrodedMetal)

	-- Fire Particle
	local fire = Instance.new("ParticleEmitter")
	fire.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 80)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 120, 20)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 20, 0))
	})
	fire.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.6, 1.6),
		NumberSequenceKeypoint.new(1, 0)
	})
	fire.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.4),
		NumberSequenceKeypoint.new(1, 1)
	})
	fire.Lifetime = NumberRange.new(0.6, 1.2)
	fire.Rate = 22
	fire.Speed = NumberRange.new(3, 6)
	fire.SpreadAngle = Vector2.new(20, 20)
	fire.Acceleration = Vector3.new(0, 3, 0)
	fire.Parent = bowl

	-- Point Light
	local light = Instance.new("PointLight")
	light.Color = PALETTE.TorchFire
	light.Brightness = 3
	light.Range = 22
	light.Parent = bowl

	model.Parent = parent
	return model
end

--------------------------------------------------------------------------------
-- Watchtower (瞭望哨)
--------------------------------------------------------------------------------
local function createWatchtower(parent, cframe)
	local model = Instance.new("Model")
	model.Name = "Watchtower"

	local towerHeight = 18

	-- 4 Main Stilts
	local offsets = {
		Vector3.new(-4, towerHeight / 2, -4),
		Vector3.new(4, towerHeight / 2, -4),
		Vector3.new(-4, towerHeight / 2, 4),
		Vector3.new(4, towerHeight / 2, 4),
	}
	for _, off in ipairs(offsets) do
		makePart(model, "Stilt", Vector3.new(1.4, towerHeight, 1.4), cframe * CFrame.new(off), PALETTE.DarkWood, Enum.Material.Wood)
	end

	-- Cross braces
	makePart(model, "Brace1", Vector3.new(9, 0.8, 0.8), cframe * CFrame.new(0, 8, -4), PALETTE.RoughWood)
	makePart(model, "Brace2", Vector3.new(9, 0.8, 0.8), cframe * CFrame.new(0, 8, 4), PALETTE.RoughWood)
	makePart(model, "Brace3", Vector3.new(0.8, 0.8, 9), cframe * CFrame.new(-4, 8, 0), PALETTE.RoughWood)
	makePart(model, "Brace4", Vector3.new(0.8, 0.8, 9), cframe * CFrame.new(4, 8, 0), PALETTE.RoughWood)

	-- Upper Guard Platform
	makePart(model, "Platform", Vector3.new(11, 1, 11), cframe * CFrame.new(0, towerHeight, 0), PALETTE.RoughWood, Enum.Material.WoodPlanks)

	-- Railings
	makePart(model, "RailF", Vector3.new(11, 2.5, 0.6), cframe * CFrame.new(0, towerHeight + 1.25, 5.2), PALETTE.DarkWood)
	makePart(model, "RailB", Vector3.new(11, 2.5, 0.6), cframe * CFrame.new(0, towerHeight + 1.25, -5.2), PALETTE.DarkWood)
	makePart(model, "RailL", Vector3.new(0.6, 2.5, 11), cframe * CFrame.new(-5.2, towerHeight + 1.25, 0), PALETTE.DarkWood)
	makePart(model, "RailR", Vector3.new(0.6, 2.5, 11), cframe * CFrame.new(5.2, towerHeight + 1.25, 0), PALETTE.DarkWood)

	-- Roof canopy on the tower
	makePart(model, "RoofPost1", Vector3.new(0.8, 6, 0.8), cframe * CFrame.new(-4.5, towerHeight + 3.5, -4.5), PALETTE.DarkWood)
	makePart(model, "RoofPost2", Vector3.new(0.8, 6, 0.8), cframe * CFrame.new(4.5, towerHeight + 3.5, -4.5), PALETTE.DarkWood)
	makePart(model, "RoofPost3", Vector3.new(0.8, 6, 0.8), cframe * CFrame.new(-4.5, towerHeight + 3.5, 4.5), PALETTE.DarkWood)
	makePart(model, "RoofPost4", Vector3.new(0.8, 6, 0.8), cframe * CFrame.new(4.5, towerHeight + 3.5, 4.5), PALETTE.DarkWood)
	makePart(model, "WatchRoof", Vector3.new(13, 0.8, 13), cframe * CFrame.new(0, towerHeight + 6.8, 0), PALETTE.TentCloth, Enum.Material.Fabric)

	-- Torch on platform
	createBrazier(model, cframe * CFrame.new(3.8, towerHeight + 0.5, 3.8))

	model.Parent = parent
	return model
end

--------------------------------------------------------------------------------
-- Bandit Tent (强盗帐篷)
--------------------------------------------------------------------------------
local function createBanditTent(parent, cframe, width, length)
	width = width or 14
	length = length or 16
	local height = 8

	local model = Instance.new("Model")
	model.Name = "BanditTent"

	-- Dirt / Hide Floor
	makePart(model, "Floor", Vector3.new(width, 0.4, length), cframe * CFrame.new(0, 0.2, 0), PALETTE.Leather, Enum.Material.Slate)

	-- Central Ridge Pole
	makePart(model, "RidgePole", Vector3.new(0.8, 0.8, length), cframe * CFrame.new(0, height, 0), PALETTE.DarkWood, Enum.Material.Wood)
	makePart(model, "FrontPost", Vector3.new(0.8, height, 0.8), cframe * CFrame.new(0, height / 2, length / 2), PALETTE.DarkWood, Enum.Material.Wood)
	makePart(model, "BackPost", Vector3.new(0.8, height, 0.8), cframe * CFrame.new(0, height / 2, -length / 2), PALETTE.DarkWood, Enum.Material.Wood)

	-- Left and Right slanted fabric roofs
	local slantAngle = math.rad(48)
	local roofWidth = math.sqrt((width / 2) ^ 2 + height ^ 2)

	local leftRoof = makePart(model, "RoofL", Vector3.new(roofWidth + 1, 0.5, length), cframe * CFrame.new(-width / 4, height / 2 + 0.5, 0) * CFrame.Angles(0, 0, -slantAngle), PALETTE.TentCloth, Enum.Material.Fabric)
	local rightRoof = makePart(model, "RoofR", Vector3.new(roofWidth + 1, 0.5, length), cframe * CFrame.new(width / 4, height / 2 + 0.5, 0) * CFrame.Angles(0, 0, slantAngle), PALETTE.TentDark, Enum.Material.Fabric)

	-- Weapon Rack or Loot Box inside tent
	local crate = makePart(model, "LootCrate", Vector3.new(2.8, 2.5, 2.8), cframe * CFrame.new(-2.2, 1.4, -2.5), PALETTE.RoughWood)
	local crateStripe = makePart(model, "CrateIron", Vector3.new(3, 0.4, 3), cframe * CFrame.new(-2.2, 1.4, -2.5), PALETTE.IronMetal, Enum.Material.Metal)

	model.Parent = parent
	return model
end

--------------------------------------------------------------------------------
-- Palisade Wall Segment with Spikes (木栅栏拒马)
--------------------------------------------------------------------------------
local function createPalisadeSegment(parent, cframe, length)
	length = length or 24
	local model = Instance.new("Model")
	model.Name = "PalisadeWall"

	local count = math.floor(length / 2)
	for i = 1, count do
		local x = -length / 2 + (i - 0.5) * 2
		local logH = 7.5 + (math.sin(i * 1.5) * 1.2)
		local log = makePart(model, "Log" .. i, Vector3.new(1.8, logH, 1.8), cframe * CFrame.new(x, logH / 2, 0), PALETTE.DarkWood, Enum.Material.Wood)

		-- Sharpened Spike on top
		local spike = makeWedge(model, "Spike" .. i, Vector3.new(1.8, 2, 1.8), cframe * CFrame.new(x, logH + 1, 0), PALETTE.SpikeWood, Enum.Material.Wood)
	end

	-- Horizontal binding logs
	makePart(model, "CrossbeamLower", Vector3.new(length, 0.8, 0.8), cframe * CFrame.new(0, 2.5, -1), PALETTE.RoughWood)
	makePart(model, "CrossbeamUpper", Vector3.new(length, 0.8, 0.8), cframe * CFrame.new(0, 6, -1), PALETTE.RoughWood)

	model.Parent = parent
	return model
end

--------------------------------------------------------------------------------
-- Stronghold Gate (山寨大门)
--------------------------------------------------------------------------------
local function createBanditGate(parent, cframe, width)
	width = width or 20
	local model = Instance.new("Model")
	model.Name = "BanditGate"

	local postH = 14
	-- 2 Giant Gate Posts
	makePart(model, "PostL", Vector3.new(2.4, postH, 2.4), cframe * CFrame.new(-width / 2, postH / 2, 0), PALETTE.DarkWood, Enum.Material.Wood)
	makePart(model, "PostR", Vector3.new(2.4, postH, 2.4), cframe * CFrame.new(width / 2, postH / 2, 0), PALETTE.DarkWood, Enum.Material.Wood)

	-- Top Heavy Cross Timber
	makePart(model, "TopTimber", Vector3.new(width + 4, 2, 2.4), cframe * CFrame.new(0, postH - 1, 0), PALETTE.RoughWood, Enum.Material.Wood)

	-- Spikes on Top
	for s = -4, 4 do
		makeWedge(model, "GateSpike", Vector3.new(1.5, 2.5, 1.5), cframe * CFrame.new(s * 2, postH + 1.2, 0), PALETTE.SpikeWood, Enum.Material.Wood)
	end

	-- Gate Banner / Sign: 黑风寨 (Black Wind Stronghold)
	local sign = makePart(model, "GateSign", Vector3.new(12, 2.8, 0.6), cframe * CFrame.new(0, postH - 3.5, 0), PALETTE.DarkWood)
	local bbg = Instance.new("BillboardGui")
	bbg.Name = "GateLabel"
	bbg.AlwaysOnTop = true
	bbg.Size = UDim2.new(0, 220, 0, 48)
	bbg.Adornee = sign
	bbg.Parent = sign

	local txt = Instance.new("TextLabel")
	txt.BackgroundTransparency = 1
	txt.Size = UDim2.new(1, 0, 1, 0)
	txt.Font = Enum.Font.GothamBlack
	txt.Text = "☠ 黑 风 寨 ☠"
	txt.TextColor3 = Color3.fromRGB(255, 65, 65)
	txt.TextScaled = true
	txt.Parent = bbg

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(30, 10, 10)
	stroke.Thickness = 2
	stroke.Parent = txt

	-- Hanging Torches on both gate posts
	createBrazier(model, cframe * CFrame.new(-width / 2 - 2, 2, 1.5))
	createBrazier(model, cframe * CFrame.new(width / 2 + 2, 2, 1.5))

	model.Parent = parent
	return model
end

--------------------------------------------------------------------------------
-- Central Bonfire & Roasting Pit (山寨篝火)
--------------------------------------------------------------------------------
local function createCentralCampfire(parent, cframe)
	local model = Instance.new("Model")
	model.Name = "BanditCampfire"

	-- Stone Fire Ring
	local stoneCount = 12
	local radius = 5
	for i = 1, stoneCount do
		local angle = (i / stoneCount) * math.pi * 2
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local stone = makePart(model, "FireStone" .. i, Vector3.new(1.8, 1.2, 1.8), cframe * CFrame.new(x, 0.6, z), PALETTE.StoneGrey, Enum.Material.Slate)
	end

	-- Ash Bed
	makePart(model, "AshBed", Vector3.new(8, 0.4, 8), cframe * CFrame.new(0, 0.2, 0), Color3.fromRGB(30, 28, 28), Enum.Material.Basalt)

	-- Stacked Firewood Logs
	for rot = 0, 120, 60 do
		makePart(model, "Log" .. rot, Vector3.new(1.2, 1.2, 7), cframe * CFrame.new(0, 0.8, 0) * CFrame.Angles(0, math.rad(rot), 0), PALETTE.DarkWood, Enum.Material.Wood)
	end

	-- Roaring Bonfire Center
	local firePart = makePart(model, "FireCore", Vector3.new(3, 2, 3), cframe * CFrame.new(0, 1.5, 0), PALETTE.TorchFire, Enum.Material.Neon)
	firePart.Transparency = 0.3
	firePart.CanCollide = false

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 150)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 120, 20)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 30, 0))
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.2),
		NumberSequenceKeypoint.new(0.6, 3.5),
		NumberSequenceKeypoint.new(1, 0)
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	emitter.Lifetime = NumberRange.new(0.8, 1.6)
	emitter.Rate = 50
	emitter.Speed = NumberRange.new(4, 9)
	emitter.SpreadAngle = Vector2.new(25, 25)
	emitter.Acceleration = Vector3.new(0, 8, 0)
	emitter.Parent = firePart

	-- Smoke
	local smoke = Instance.new("ParticleEmitter")
	smoke.Color = ColorSequence.new(Color3.fromRGB(70, 70, 75))
	smoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.5),
		NumberSequenceKeypoint.new(1, 6)
	})
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 1)
	})
	smoke.Lifetime = NumberRange.new(2, 4)
	smoke.Rate = 14
	smoke.Speed = NumberRange.new(5, 10)
	smoke.SpreadAngle = Vector2.new(20, 20)
	smoke.Acceleration = Vector3.new(2, 6, 1)
	smoke.Parent = firePart

	-- Light
	local light = Instance.new("PointLight")
	light.Color = PALETTE.TorchFire
	light.Brightness = 5
	light.Range = 36
	light.Parent = firePart

	-- Surrounding Log Benches
	makePart(model, "Bench1", Vector3.new(8, 1.2, 1.6), cframe * CFrame.new(0, 0.6, -8), PALETTE.RoughWood, Enum.Material.Wood)
	makePart(model, "Bench2", Vector3.new(8, 1.2, 1.6), cframe * CFrame.new(0, 0.6, 8), PALETTE.RoughWood, Enum.Material.Wood)
	makePart(model, "Bench3", Vector3.new(1.6, 1.2, 8), cframe * CFrame.new(-8, 0.6, 0), PALETTE.RoughWood, Enum.Material.Wood)

	model.Parent = parent
	return model
end

--------------------------------------------------------------------------------
-- Bandit Chieftain Dais & Arena (大头目寨主宝座擂台)
--------------------------------------------------------------------------------
local function createChieftainDais(parent, cframe, size)
	size = size or Vector3.new(32, 2.5, 28)
	local model = Instance.new("Model")
	model.Name = "ChieftainDais"

	local sx = size.X
	local sy = size.Y
	local sz = size.Z

	-- Elevated Stone & Timber Platform
	makePart(model, "BasePlatform", Vector3.new(sx, sy, sz), cframe * CFrame.new(0, sy / 2, 0), PALETTE.DarkWood, Enum.Material.WoodPlanks)

	-- Front Steps
	local stepCount = 4
	for i = 1, stepCount do
		local depth = 1.8
		local h = (sy / stepCount) * i
		makePart(model, "Step" .. i, Vector3.new(sx * 0.45, sy / stepCount, depth), cframe * CFrame.new(0, h - (sy / stepCount / 2), (sz / 2) + (stepCount - i) * depth), PALETTE.RoughWood)
	end

	-- Chieftain's Throne (寨主铁木交椅)
	local throneY = sy + 0.2
	local throneCF = cframe * CFrame.new(0, throneY, -sz * 0.3)
	makePart(model, "ThroneSeat", Vector3.new(6, 1.4, 4), throneCF * CFrame.new(0, 0.7, 0), PALETTE.DarkWood, Enum.Material.Wood)
	makePart(model, "ThroneBack", Vector3.new(6, 7, 1.2), throneCF * CFrame.new(0, 4.2, -1.8), PALETTE.DarkWood, Enum.Material.Wood)
	makePart(model, "ThroneArmL", Vector3.new(1.2, 2.8, 4), throneCF * CFrame.new(-3.2, 1.8, 0), PALETTE.BloodRed)
	makePart(model, "ThroneArmR", Vector3.new(1.2, 2.8, 4), throneCF * CFrame.new(3.2, 1.8, 0), PALETTE.BloodRed)

	-- Tiger / Wolf Pelt on Throne
	makePart(model, "PeltBack", Vector3.new(4.8, 5, 0.4), throneCF * CFrame.new(0, 4, -1.2), PALETTE.GoldTreasure, Enum.Material.Fabric)

	-- 2 War Banners flanking the throne
	for _, xSign in ipairs({ -1, 1 }) do
		local bannerCF = cframe * CFrame.new(xSign * (sx * 0.38), sy, -sz * 0.3)
		makePart(model, "BannerPole", Vector3.new(0.8, 14, 0.8), bannerCF * CFrame.new(0, 7, 0), PALETTE.DarkWood, Enum.Material.Wood)
		local cloth = makePart(model, "BannerCloth", Vector3.new(4, 9, 0.2), bannerCF * CFrame.new(xSign * 2, 8, 0), PALETTE.BloodRed, Enum.Material.Fabric)

		local bbg = Instance.new("BillboardGui")
		bbg.AlwaysOnTop = true
		bbg.Size = UDim2.new(0, 80, 0, 100)
		bbg.Adornee = cloth
		bbg.Parent = cloth

		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.new(1, 0, 1, 0)
		lbl.Font = Enum.Font.GothamBlack
		lbl.Text = "黑\n风"
		lbl.TextColor3 = Color3.fromRGB(255, 230, 80)
		lbl.TextScaled = true
		lbl.Parent = bbg
	end

	-- 4 Torch Braziers around the boss dais
	createBrazier(model, cframe * CFrame.new(-sx / 2 + 2, sy, -sz / 2 + 2))
	createBrazier(model, cframe * CFrame.new(sx / 2 - 2, sy, -sz / 2 + 2))
	createBrazier(model, cframe * CFrame.new(-sx / 2 + 2, sy, sz / 2 - 2))
	createBrazier(model, cframe * CFrame.new(sx / 2 - 2, sy, sz / 2 - 2))

	-- Gold Treasure Chests near the throne
	local chest1 = makePart(model, "Chest1", Vector3.new(3, 2, 2.2), throneCF * CFrame.new(-4.8, 1, 0.8) * CFrame.Angles(0, math.rad(25), 0), PALETTE.RoughWood)
	local chestLid1 = makePart(model, "ChestLid1", Vector3.new(3.2, 0.6, 2.4), chest1.CFrame * CFrame.new(0, 1.2, 0), PALETTE.GoldTreasure, Enum.Material.Metal)

	local chest2 = makePart(model, "Chest2", Vector3.new(3, 2, 2.2), throneCF * CFrame.new(4.8, 1, 0.8) * CFrame.Angles(0, math.rad(-20), 0), PALETTE.RoughWood)
	local chestLid2 = makePart(model, "ChestLid2", Vector3.new(3.2, 0.6, 2.4), chest2.CFrame * CFrame.new(0, 1.2, 0), PALETTE.GoldTreasure, Enum.Material.Metal)

	model.Parent = parent
	return model
end

--------------------------------------------------------------------------------
-- Main Generation
--------------------------------------------------------------------------------
function BanditVillage.generate()
	local existing = Workspace:FindFirstChild("BanditVillage")
	if existing then
		print("🏰 [BanditVillage] Bandit Village already exists in Workspace.")
		return existing
	end

	local villageFolder = Instance.new("Folder")
	villageFolder.Name = "BanditVillage"

	-- Position the Bandit Stronghold on the Eastern area of the map
	-- Baseplate is 512x512 (-256 to 256). Main village is around (0,0,0).
	-- Bandit camp sits at X: 160, Z: -20, nicely isolated but easily reachable!
	local centerCF = CFrame.new(160, 0, -20)
	local campW = 110
	local campL = 120

	-- 1. Dark Trampled Dirt / Gravel Ground for the camp
	local ground = makePart(villageFolder, "BanditCampGround", Vector3.new(campW, 0.6, campL), centerCF * CFrame.new(0, 0.1, 0), PALETTE.DirtGround, Enum.Material.Mud)

	-- 2. Perimeter Palisade Walls
	-- South Wall with Central Gate
	local gateW = 22
	local wallSectionW = (campW - gateW) / 2
	createPalisadeSegment(villageFolder, centerCF * CFrame.new(-campW / 2 + wallSectionW / 2, 0, campL / 2), wallSectionW)
	createPalisadeSegment(villageFolder, centerCF * CFrame.new(campW / 2 - wallSectionW / 2, 0, campL / 2), wallSectionW)
	createBanditGate(villageFolder, centerCF * CFrame.new(0, 0, campL / 2), gateW)

	-- North Wall (Back)
	createPalisadeSegment(villageFolder, centerCF * CFrame.new(0, 0, -campL / 2), campW)
	-- West Wall
	createPalisadeSegment(villageFolder, centerCF * CFrame.new(-campW / 2, 0, 0) * CFrame.Angles(0, math.rad(90), 0), campL)
	-- East Wall
	createPalisadeSegment(villageFolder, centerCF * CFrame.new(campW / 2, 0, 0) * CFrame.Angles(0, math.rad(90), 0), campL)

	-- 3. Twin Watchtowers flanking the gate
	createWatchtower(villageFolder, centerCF * CFrame.new(-gateW / 2 - 7, 0, campL / 2 - 6))
	createWatchtower(villageFolder, centerCF * CFrame.new(gateW / 2 + 7, 0, campL / 2 - 6))

	-- 4. Central Bonfire
	createCentralCampfire(villageFolder, centerCF * CFrame.new(0, 0, 10))

	-- 5. Outlaw Tents along the West and East flanks
	createBanditTent(villageFolder, centerCF * CFrame.new(-campW * 0.32, 0, -campL * 0.1) * CFrame.Angles(0, math.rad(90), 0), 14, 18)
	createBanditTent(villageFolder, centerCF * CFrame.new(-campW * 0.32, 0, campL * 0.2) * CFrame.Angles(0, math.rad(75), 0), 14, 16)
	createBanditTent(villageFolder, centerCF * CFrame.new(campW * 0.32, 0, -campL * 0.1) * CFrame.Angles(0, math.rad(-90), 0), 14, 18)
	createBanditTent(villageFolder, centerCF * CFrame.new(campW * 0.32, 0, campL * 0.2) * CFrame.Angles(0, math.rad(-75), 0), 14, 16)

	-- 6. Bandit Chieftain Dais at the North end
	createChieftainDais(villageFolder, centerCF * CFrame.new(0, 0, -campL * 0.32), Vector3.new(36, 2.5, 30))

	villageFolder.Parent = Workspace
	print("🏰 [BanditVillage] Generated Bandit Village at " .. tostring(centerCF.Position))
	return centerCF
end

return BanditVillage
