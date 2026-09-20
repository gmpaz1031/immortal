--!strict
-- src/server/MiningService.server.luau
-- Comprehensive Server Mining Service for Immortal Xianxia RPG
-- Controls 5 handcrafted ore deposits, exact-placement respawns, pickaxe hits, and inventory sync

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local OreConfig = require(Shared:WaitForChild("OreConfig"))
local ItemConfig = require(Shared:WaitForChild("ItemConfig"))

local cultivationRemote = ReplicatedStorage:WaitForChild("CultivationRemote") :: RemoteEvent

-- Ensure MiningRemote exists
local miningRemote = ReplicatedStorage:FindFirstChild("MiningRemote") :: RemoteEvent?
if not miningRemote then
	miningRemote = Instance.new("RemoteEvent")
	miningRemote.Name = "MiningRemote"
	miningRemote.Parent = ReplicatedStorage
end

-- Cache folder for harvested ores during their respawn period
local harvestedCache = ServerStorage:FindFirstChild("HarvestedOresCache") :: Folder?
if not harvestedCache then
	harvestedCache = Instance.new("Folder")
	harvestedCache.Name = "HarvestedOresCache"
	harvestedCache.Parent = ServerStorage
end

local registeredOres: { [Model]: boolean } = {}
local lastHitTimes: { [Player]: number } = {}

-- ============================================================================
-- HELPER: PLAY SOUND & PARTICLES AT LOCATION
-- ============================================================================
local function playOreEffect(cf: CFrame, soundId: string, colorSeq: ColorSequence?, count: number)
	local fxPart = Instance.new("Part")
	fxPart.Name = "MiningFX"
	fxPart.Size = Vector3.new(0.5, 0.5, 0.5)
	fxPart.CFrame = cf
	fxPart.Transparency = 1
	fxPart.CanCollide = false
	fxPart.Anchored = true
	fxPart.Parent = workspace

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = 0.9
	sound.RollOffMaxDistance = 60
	sound.Parent = fxPart
	sound:Play()

	if colorSeq then
		local pe = Instance.new("ParticleEmitter")
		pe.Color = colorSeq
		pe.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(0.6, 0.6),
			NumberSequenceKeypoint.new(1, 0.1),
		})
		pe.Lifetime = NumberRange.new(0.4, 0.8)
		pe.Speed = NumberRange.new(4, 10)
		pe.SpreadAngle = Vector2.new(60, 60)
		pe.Rate = 0
		pe.Parent = fxPart
		pe:Emit(count)
	end

	Debris:AddItem(fxPart, 1.8)
end

-- ============================================================================
-- FINISH MINING ORE & AWARD DROPS
-- ============================================================================
local function completeMining(ore: Model, player: Player, oreDef: any)
	if ore:GetAttribute("Mined") == true then
		return
	end
	ore:SetAttribute("Mined", true)

	local primary = ore.PrimaryPart or ore:FindFirstChildWhichIsA("BasePart")
	local prompt = primary and primary:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Enabled = false
	end

	local oreCenter = ore:GetPivot()
	playOreEffect(oreCenter, oreDef.BreakSoundId or "rbxassetid://9114223789", oreDef.ParticleColor, 24)

	-- 1. Award drops directly into player.Inventory (flat structure for DataStore persistence)
	local inventory = player:FindFirstChild("Inventory")
	if inventory then
		local dropQty = math.random(oreDef.DropMinQty or 1, oreDef.DropMaxQty or 1)
		local itemVal = inventory:FindFirstChild(oreDef.DropsItem) :: IntValue?
		if not itemVal then
			itemVal = Instance.new("IntValue")
			itemVal.Name = oreDef.DropsItem
			itemVal.Value = dropQty
			itemVal.Parent = inventory
		else
			itemVal.Value += dropQty
		end

		-- Award Spiritual Qi if applicable (e.g. Spirit Stone or high tier)
		if oreDef.QiReward and oreDef.QiReward > 0 then
			local curQi = (player:GetAttribute("Qi") or 0) :: number
			player:SetAttribute("Qi", curQi + oreDef.QiReward)
			local leaderstats = player:FindFirstChild("leaderstats")
			local qiVal = leaderstats and leaderstats:FindFirstChild("Qi") :: IntValue?
			if qiVal then
				qiVal.Value = curQi + oreDef.QiReward
			end
			cultivationRemote:FireClient(player, "QiGainTick", oreDef.QiReward)
		end

		-- Notify client of inventory update & toast notification
		cultivationRemote:FireClient(player, "InventoryUpdated")
		cultivationRemote:FireClient(player, "Notification", string.format("Mined %s x%d!", oreDef.DropsItem, dropQty), true)
	end

	-- 2. Move model to cache during respawn delay
	local originalParent = ore.Parent or workspace
	ore.Parent = harvestedCache

	-- 3. Exact respawn after delay: Respawns precisely where developer placed it!
	local respawnDelay = oreDef.RespawnTime or 5
	task.delay(respawnDelay, function()
		if not ore or not ore:IsDescendantOf(game) then
			return
		end

		local origCF = ore:GetAttribute("OriginalSpawnCFrame") :: CFrame?
		if typeof(origCF) == "CFrame" then
			ore:PivotTo(origCF)
		else
			local origPos = ore:GetAttribute("OriginalSpawnPosition") :: Vector3?
			if origPos then
				ore:PivotTo(CFrame.new(origPos))
			end
		end

		ore.Parent = originalParent
		ore:SetAttribute("CurrentHits", 0)
		ore:SetAttribute("Mined", false)

		if prompt then
			prompt.Enabled = true
		end
	end)
end

-- ============================================================================
-- PROCESS HIT ON ORE (PICKAXE OR PROXIMITY PROMPT)
-- ============================================================================
local function processOreHit(ore: Model, player: Player)
	if not ore or not ore:IsDescendantOf(game) then return end
	if ore:GetAttribute("Mined") == true then return end

	-- Check distance
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local orePos = ore:GetPivot().Position
	if (hrp.Position - orePos).Magnitude > 14 then
		return
	end

	-- Anti-spam debounce
	local now = os.clock()
	local lastHit = lastHitTimes[player] or 0
	if now - lastHit < 0.22 then
		return
	end
	lastHitTimes[player] = now

	local oreName = tostring(ore:GetAttribute("OreName") or ore.Name)
	local oreDef = OreConfig.GetOre(oreName)
	if not oreDef then return end

	local curHits = (ore:GetAttribute("CurrentHits") or 0) :: number + 1
	ore:SetAttribute("CurrentHits", curHits)

	local primary = ore.PrimaryPart or ore:FindFirstChildWhichIsA("BasePart")
	local hitCf = primary and primary.CFrame or ore:GetPivot()

	-- Impact feedback: sound + rock shards
	playOreEffect(hitCf, oreDef.HitSoundId or "rbxassetid://9114223171", oreDef.ParticleColor, 6)

	-- Rock impact shake animation
	if primary then
		local origCf = ore:GetPivot()
		local shakeCf = origCf * CFrame.Angles(math.rad(math.random(-2, 2)), math.rad(math.random(-2, 2)), math.rad(math.random(-2, 2)))
		ore:PivotTo(shakeCf)
		task.delay(0.06, function()
			if ore and not ore:GetAttribute("Mined") then
				ore:PivotTo(origCf)
			end
		end)
	end

	-- Check if required hits reached
	local maxHits = ore:GetAttribute("MaxHits") or oreDef.HitsRequired or 4
	if curHits >= maxHits then
		completeMining(ore, player, oreDef)
	end
end

-- ============================================================================
-- REGISTER ORE INSTANCE IN WORLD
-- ============================================================================
local function registerOre(ore: Model)
	if registeredOres[ore] then return end

	local oreName = tostring(ore:GetAttribute("OreName") or ore.Name)
	local oreDef = OreConfig.GetOre(oreName)
	if not oreDef then return end

	registeredOres[ore] = true
	CollectionService:AddTag(ore, "MineableOre")

	local primary = ore.PrimaryPart or ore:FindFirstChildWhichIsA("BasePart")
	if not primary then
		primary = Instance.new("Part")
		primary.Name = "OreRoot"
		primary.Size = Vector3.new(1, 1, 1)
		primary.Transparency = 1
		primary.CanCollide = false
		primary.Anchored = true
		primary.Position = ore:GetPivot().Position
		primary.Parent = ore
		ore.PrimaryPart = primary
	else
		ore.PrimaryPart = primary
		primary.Anchored = true
	end

	-- Anchor all parts
	for _, part in ipairs(ore:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end

	-- Record permanent Original placement CFrame (Never overwritten by respawns)
	local existingCF = ore:GetAttribute("OriginalSpawnCFrame") :: CFrame?
	if not existingCF then
		local initialCF = ore:GetPivot()
		ore:SetAttribute("OriginalSpawnCFrame", initialCF)
		ore:SetAttribute("OriginalSpawnPosition", initialCF.Position)
	end
	ore:SetAttribute("OreName", oreDef.Name)
	ore:SetAttribute("MaxHits", oreDef.HitsRequired)
	ore:SetAttribute("CurrentHits", 0)
	ore:SetAttribute("Mined", false)

	-- Proximity Prompt Setup
	local prompt = primary:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "MinePrompt"
		prompt.Parent = primary
	end

	prompt.ActionText = "Mine"
	prompt.ObjectText = oreDef.Name
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 8.5
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true

	prompt.Triggered:Connect(function(player: Player)
		processOreHit(ore, player)
	end)

	ore.AncestryChanged:Connect(function(_, newParent)
		if newParent == nil then
			registeredOres[ore] = nil
		end
	end)
end

-- Listen to Pickaxe client hit events via MiningRemote
miningRemote.OnServerEvent:Connect(function(player: Player, action: string, ...)
	local args = { ... }
	if action == "MineHit" then
		local targetOre = args[1]
		if targetOre and typeof(targetOre) == "Instance" and targetOre:IsA("Model") then
			processOreHit(targetOre, player)
		end
	end
end)

-- Hook existing tagged ores and future placed ores
for _, inst in ipairs(CollectionService:GetTagged("MineableOre")) do
	if inst:IsA("Model") then
		registerOre(inst)
	end
end

CollectionService:GetInstanceAddedSignal("MineableOre"):Connect(function(inst)
	if inst:IsA("Model") then
		registerOre(inst)
	end
end)

workspace.DescendantAdded:Connect(function(desc)
	if desc:IsA("Model") and (desc:GetAttribute("OreName") or OreConfig.GetOre(desc.Name)) then
		registerOre(desc)
	end
end)

-- Scan Workspace.OreTemplates and any placed models
local wsTemplates = workspace:FindFirstChild("OreTemplates")
if wsTemplates then
	for _, m in ipairs(wsTemplates:GetChildren()) do
		if m:IsA("Model") then
			registerOre(m)
		end
	end
end

print("MiningService initialized successfully with 5 xianxia ore types.")
