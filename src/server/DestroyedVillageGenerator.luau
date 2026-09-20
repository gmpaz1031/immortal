--!strict
--[[
    DestroyedVillageGenerator.luau
    Generates the atmospheric Destroyed Village combat area:
    - Ruined Eastern wooden houses with broken walls and collapsed roofs
    - Scattered debris, splintered wood, charred barrels, broken stone lanterns
    - Scorched pathways and smoldering braziers
    - Central Landmark: Ancient Damaged Eastern Shrine & Boss Dais
]]

local Workspace = game:GetService("Workspace")

local DestroyedVillageGenerator = {}

local PALETTE = {
	ScorchedGround = Color3.fromRGB(42, 36, 32),
	BurntWood = Color3.fromRGB(38, 30, 26),
	CharredPlanks = Color3.fromRGB(50, 40, 34),
	AshPlanks = Color3.fromRGB(68, 62, 58),
	BrokenTiles = Color3.fromRGB(55, 45, 45),
	AncientStone = Color3.fromRGB(75, 78, 82),
	WeatheredStone = Color3.fromRGB(90, 92, 95),
	VermillionRed = Color3.fromRGB(150, 35, 30),
	GoldAccent = Color3.fromRGB(180, 140, 45),
	EmberGlow = Color3.fromRGB(255, 95, 25),
	SmokeBlack = Color3.fromRGB(25, 20, 20),
}

local function makePart(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.CanCollide = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function makeWedge(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material): WedgePart
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Size = size
	w.CFrame = cf
	w.Color = color
	w.Material = material
	w.Anchored = true
	w.CanCollide = true
	w.TopSurface = Enum.SurfaceType.Smooth
	w.BottomSurface = Enum.SurfaceType.Smooth
	w.Parent = parent
	return w
end

--------------------------------------------------------------------------------
-- 1. Smoldering Brazier / Torch
--------------------------------------------------------------------------------
local function createBrazier(parent: Instance, cf: CFrame)
	local bModel = Instance.new("Model")
	bModel.Name = "RuinedBrazier"

	-- Stone pillar
	makePart(bModel, "Post", Vector3.new(1.2, 3.5, 1.2), cf * CFrame.new(0, 1.75, 0), PALETTE.AncientStone, Enum.Material.Slate)
	-- Iron Bowl
	local bowl = makePart(bModel, "Bowl", Vector3.new(2.4, 0.8, 2.4), cf * CFrame.new(0, 3.8, 0), PALETTE.BurntWood, Enum.Material.Metal)

	-- Ember Fire Light
	local light = Instance.new("PointLight")
	light.Color = PALETTE.EmberGlow
	light.Brightness = 2.8
	light.Range = 22
	light.Parent = bowl

	-- Floating glowing embers
	local embers = Instance.new("ParticleEmitter")
	embers.Color = ColorSequence.new(PALETTE.EmberGlow, Color3.fromRGB(255, 40, 10))
	embers.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
	embers.Lifetime = NumberRange.new(1.0, 1.8)
	embers.Rate = 12
	embers.Speed = NumberRange.new(2, 5)
	embers.SpreadAngle = Vector2.new(30, 30)
	embers.Parent = bowl

	bModel.Parent = parent
end

--------------------------------------------------------------------------------
-- 2. Destroyed Wooden House with Collapsed Roof
--------------------------------------------------------------------------------
local function buildDestroyedHouse(parent: Instance, centerCF: CFrame, isLarge: boolean)
	local hModel = Instance.new("Model")
	hModel.Name = isLarge and "LargeRuinedHouse" or "RuinedHouse"

	local width = isLarge and 32 or 24
	local depth = isLarge and 26 or 20
	local height = isLarge and 12 or 10

	-- Foundation (cracked dark stone)
	makePart(hModel, "Foundation", Vector3.new(width + 2, 1.2, depth + 2), centerCF * CFrame.new(0, 0.6, 0), PALETTE.AncientStone, Enum.Material.Cobblestone)

	-- Surviving Pillars (tilted, broken)
	local pillarPositions = {
		Vector3.new(-width/2 + 1, height/2 + 1, -depth/2 + 1),
		Vector3.new(width/2 - 1, (height/2) * 0.6 + 1, -depth/2 + 1), -- broken half-pillar
		Vector3.new(-width/2 + 1, (height/2) * 0.75 + 1, depth/2 - 1),
		Vector3.new(width/2 - 1, height/2 + 1, depth/2 - 1),
	}

	for i, pos in ipairs(pillarPositions) do
		local tilt = (i % 2 == 0) and math.rad(12) or math.rad(-6)
		local pHeight = (i == 2) and (height * 0.6) or height
		makePart(hModel, "Pillar_" .. i, Vector3.new(1.6, pHeight, 1.6),
			centerCF * CFrame.new(pos) * CFrame.Angles(tilt, 0, tilt * 0.5),
			PALETTE.BurntWood, Enum.Material.Wood)
	end

	-- Partial / Broken Walls (wood planks with large breaches)
	-- Back wall (partially standing)
	makePart(hModel, "BackWall_Left", Vector3.new(width * 0.45, height * 0.8, 1.0),
		centerCF * CFrame.new(-width * 0.25, height * 0.4 + 1, -depth/2 + 1),
		PALETTE.CharredPlanks, Enum.Material.WoodPlanks)

	-- Broken collapsed wall section (slanted on ground)
	makePart(hModel, "CollapsedWall_Right", Vector3.new(width * 0.45, height * 0.7, 1.0),
		centerCF * CFrame.new(width * 0.25, 2.0, -depth/2 + 1) * CFrame.Angles(math.rad(65), math.rad(15), 0),
		PALETTE.AshPlanks, Enum.Material.WoodPlanks)

	-- Left side wall
	makePart(hModel, "LeftWall", Vector3.new(1.0, height * 0.7, depth * 0.6),
		centerCF * CFrame.new(-width/2 + 1, height * 0.35 + 1, -depth * 0.15),
		PALETTE.CharredPlanks, Enum.Material.WoodPlanks)

	-- Collapsed Roof Rafters & Broken Shingles
	local roofTilt = math.rad(-22)
	local roofWidth = width * 0.7
	makePart(hModel, "CollapsedRoof_Slab", Vector3.new(roofWidth, 1.2, depth + 2),
		centerCF * CFrame.new(-width * 0.1, height * 0.75 + 1, 0) * CFrame.Angles(0, 0, roofTilt),
		PALETTE.BrokenTiles, Enum.Material.Slate)

	-- Loose fallen rafters fallen into the room
	for r = 1, 3 do
		makePart(hModel, "FallenRafter_" .. r, Vector3.new(1.2, 1.2, depth * 0.7),
			centerCF * CFrame.new((r - 2) * 5, 1.5, 0) * CFrame.Angles(math.rad(math.random(-15, 15)), math.rad(math.random(-30, 30)), math.rad(math.random(-25, 25))),
			PALETTE.BurntWood, Enum.Material.Wood)
	end

	-- Scattered debris piles inside house
	for d = 1, 4 do
		makePart(hModel, "DebrisPlank_" .. d, Vector3.new(math.random(2, 5), 0.6, math.random(1, 3)),
			centerCF * CFrame.new(math.random(-width/3, width/3), 1.2, math.random(-depth/3, depth/3)) * CFrame.Angles(0, math.rad(math.random(0, 180)), math.rad(math.random(-10, 10))),
			PALETTE.AshPlanks, Enum.Material.WoodPlanks)
	end

	hModel.Parent = parent
end

--------------------------------------------------------------------------------
-- 3. Central Ancient Damaged Eastern Shrine (Main Focal Landmark & Boss Arena)
--------------------------------------------------------------------------------
local function buildCentralShrine(parent: Instance, centerCF: CFrame)
	local sModel = Instance.new("Model")
	sModel.Name = "CentralAncientShrine"

	-- 1. Multi-tier Grand Stone Dais (Platform for Swordmaster Boss)
	-- Base Tier
	makePart(sModel, "Dais_Tier1", Vector3.new(50, 2.0, 50), centerCF * CFrame.new(0, 1.0, 0), PALETTE.AncientStone, Enum.Material.Cobblestone)
	-- Mid Tier
	makePart(sModel, "Dais_Tier2", Vector3.new(42, 2.0, 42), centerCF * CFrame.new(0, 3.0, 0), PALETTE.WeatheredStone, Enum.Material.Cobblestone)
	-- Top Arena Tier
	makePart(sModel, "Dais_TopPlatform", Vector3.new(34, 1.5, 34), centerCF * CFrame.new(0, 4.75, 0), PALETTE.AncientStone, Enum.Material.Slate)

	-- 4 Grand Ceremonial Stairways leading up from four compass directions
	for _, rot in ipairs({ 0, 90, 180, 270 }) do
		local stairCF = centerCF * CFrame.Angles(0, math.rad(rot), 0) * CFrame.new(0, 0, 22)
		for step = 1, 4 do
			makePart(sModel, "ShrineStair_" .. rot .. "_" .. step, Vector3.new(10, 1.1, 2.0),
				stairCF * CFrame.new(0, step * 1.0, -step * 1.8),
				PALETTE.WeatheredStone, Enum.Material.Cobblestone)
		end
	end

	-- 2. Weathered Shrine Vermillion Pillars (Partially broken/chipped)
	local pillarOffsets = {
		Vector3.new(-12, 5.5, -12),
		Vector3.new(12, 5.5, -12),
		Vector3.new(-12, 5.5, 12),
		Vector3.new(12, 5.5, 12),
		Vector3.new(-6, 5.5, -12),
		Vector3.new(6, 5.5, -12),
	}

	for i, off in ipairs(pillarOffsets) do
		local isBroken = (i == 2 or i == 5)
		local pHeight = isBroken and 8 or 16
		local pCF = centerCF * CFrame.new(off.X, 5.5 + pHeight/2, off.Z)
		if isBroken then
			pCF = pCF * CFrame.Angles(math.rad(10), 0, math.rad(6))
		end

		makePart(sModel, "ShrinePillar_" .. i, Vector3.new(2.4, pHeight, 2.4), pCF, PALETTE.VermillionRed, Enum.Material.Wood)

		-- Pillar Base Stone Pedestal
		makePart(sModel, "PillarBase_" .. i, Vector3.new(3.2, 1.2, 3.2), centerCF * CFrame.new(off.X, 6.0, off.Z), PALETTE.AncientStone, Enum.Material.Slate)
	end

	-- 3. Damaged Curved Pagoda Roof Section (Slanted with missing tiles)
	local roofCenter = centerCF * CFrame.new(0, 22, 0)
	makePart(sModel, "ShrineRoof_MainBeam", Vector3.new(30, 2.0, 3.0), roofCenter * CFrame.new(0, 0, -6), PALETTE.BurntWood, Enum.Material.Wood)
	makePart(sModel, "ShrineRoof_LeftSlab", Vector3.new(16, 1.2, 28), roofCenter * CFrame.new(-7, -2, 0) * CFrame.Angles(0, 0, math.rad(18)), PALETTE.BrokenTiles, Enum.Material.Slate)

	-- Broken Pagoda Eaves
	local eaveLeft = makeWedge(sModel, "PagodaEave_L", Vector3.new(4, 2, 28), roofCenter * CFrame.new(-15, -4, 0) * CFrame.Angles(0, 0, math.rad(180)), PALETTE.GoldAccent, Enum.Material.Metal)

	-- 4. Ancient Altar & Incense Brazier (Focal point behind Boss Spawn)
	local altarCF = centerCF * CFrame.new(0, 5.5, -8)
	makePart(sModel, "AltarTable", Vector3.new(10, 2.5, 4), altarCF * CFrame.new(0, 1.25, 0), PALETTE.WeatheredStone, Enum.Material.Slate)
	makePart(sModel, "AltarTop", Vector3.new(12, 0.8, 5), altarCF * CFrame.new(0, 2.8, 0), PALETTE.VermillionRed, Enum.Material.Wood)

	-- Ancient Bronze Urn on Altar
	local urn = makePart(sModel, "AncientUrn", Vector3.new(2.4, 2.8, 2.4), altarCF * CFrame.new(0, 4.4, 0), Color3.fromRGB(55, 75, 65), Enum.Material.Metal)
	local urnMesh = Instance.new("SpecialMesh")
	urnMesh.MeshType = Enum.MeshType.Cylinder
	urnMesh.Parent = urn

	-- Incense Smoke Emitter
	local smoke = Instance.new("ParticleEmitter")
	smoke.Color = ColorSequence.new(Color3.fromRGB(200, 200, 210), Color3.fromRGB(80, 80, 90))
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 2.5) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	smoke.Lifetime = NumberRange.new(2.0, 3.5)
	smoke.Rate = 8
	smoke.Speed = NumberRange.new(2, 4)
	smoke.SpreadAngle = Vector2.new(15, 15)
	smoke.Parent = urn

	-- 4 Corner Ceremonial Braziers on the Shrine Platform
	for _, cornerPos in ipairs({
		Vector3.new(-15, 5.5, -15),
		Vector3.new(15, 5.5, -15),
		Vector3.new(-15, 5.5, 15),
		Vector3.new(15, 5.5, 15),
	}) do
		createBrazier(sModel, centerCF * CFrame.new(cornerPos))
	end

	sModel.Parent = parent
end

--------------------------------------------------------------------------------
-- 4. Village Pathways & Scattered Debris
--------------------------------------------------------------------------------
local function buildVillagePathsAndDebris(parent: Instance, centerCF: CFrame)
	local dModel = Instance.new("Model")
	dModel.Name = "VillagePathsAndDebris"

	-- Main Damaged Stone Pathway (leading north-south and east-west)
	for z = -60, 60, 6 do
		if math.abs(z) > 22 then -- Leave center shrine area clear
			makePart(dModel, "Path_Stone_NS_" .. z, Vector3.new(12, 0.4, 5.2),
				centerCF * CFrame.new(0, 0.2, z) * CFrame.Angles(0, math.rad(math.random(-3, 3)), 0),
				PALETTE.AncientStone, Enum.Material.Cobblestone)
		end
	end

	for x = -60, 60, 6 do
		if math.abs(x) > 22 then
			makePart(dModel, "Path_Stone_EW_" .. x, Vector3.new(5.2, 0.4, 12),
				centerCF * CFrame.new(x, 0.2, 0) * CFrame.Angles(0, math.rad(math.random(-3, 3)), 0),
				PALETTE.AncientStone, Enum.Material.Cobblestone)
		end
	end

	-- Scattered Debris: Charred Crates, Broken Wheels, Splintered Beams
	local debrisLocations = {
		Vector3.new(-25, 0.5, -35),
		Vector3.new(30, 0.5, -28),
		Vector3.new(-32, 0.5, 30),
		Vector3.new(28, 0.5, 32),
		Vector3.new(-15, 0.5, 45),
		Vector3.new(18, 0.5, -50),
	}

	for i, pos in ipairs(debrisLocations) do
		-- Broken crate
		makePart(dModel, "Crate_" .. i, Vector3.new(3.5, 3.5, 3.5),
			centerCF * CFrame.new(pos) * CFrame.Angles(math.rad(15), math.rad(math.random(0, 180)), 0),
			PALETTE.BurntWood, Enum.Material.WoodPlanks)

		-- Broken planks nearby
		for p = 1, 3 do
			makePart(dModel, "Plank_" .. i .. "_" .. p, Vector3.new(4, 0.4, 1.2),
				centerCF * CFrame.new(pos + Vector3.new(p * 2, 0, (p-2)*1.5)) * CFrame.Angles(0, math.rad(math.random(0, 180)), 0),
				PALETTE.AshPlanks, Enum.Material.WoodPlanks)
		end
	end

	dModel.Parent = parent
end

--------------------------------------------------------------------------------
-- Main Generation Entry Point
--------------------------------------------------------------------------------
function DestroyedVillageGenerator.generate(customOrigin: Vector3?): Folder
	-- Default coordinates: an open, spacious area at (240, 0, -180)
	local origin = customOrigin or Vector3.new(240, 0, -180)
	local centerCF = CFrame.new(origin)

	-- Clean up existing DestroyedVillage if regenerating
	local existing = Workspace:FindFirstChild("DestroyedVillage")
	if existing then
		existing:Destroy()
	end

	local villageFolder = Instance.new("Folder")
	villageFolder.Name = "DestroyedVillage"

	-- 1. Dark Scorched Ground Area
	makePart(villageFolder, "VillageGround", Vector3.new(180, 1.0, 180), centerCF * CFrame.new(0, -0.5, 0), PALETTE.ScorchedGround, Enum.Material.Ground)

	-- 2. Central Ancient Damaged Shrine (Focal Point & Boss Arena)
	buildCentralShrine(villageFolder, centerCF)

	-- 3. 4 Ruined Houses positioned around the shrine
	buildDestroyedHouse(villageFolder, centerCF * CFrame.new(-45, 0, -45) * CFrame.Angles(0, math.rad(35), 0), true)
	buildDestroyedHouse(villageFolder, centerCF * CFrame.new(45, 0, -45) * CFrame.Angles(0, math.rad(-35), 0), false)
	buildDestroyedHouse(villageFolder, centerCF * CFrame.new(-45, 0, 45) * CFrame.Angles(0, math.rad(125), 0), false)
	buildDestroyedHouse(villageFolder, centerCF * CFrame.new(45, 0, 45) * CFrame.Angles(0, math.rad(-125), 0), true)

	-- 4. Damaged Pathways & Debris
	buildVillagePathsAndDebris(villageFolder, centerCF)

	villageFolder.Parent = Workspace
	print("⛩️ [DestroyedVillageGenerator] Destroyed Village successfully generated at:", origin)
	return villageFolder
end

return DestroyedVillageGenerator
