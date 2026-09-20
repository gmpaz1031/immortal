--!strict
-- src/server/MAINSERVER.server.luau
-- CultivationService: Seated Meditation, Dynamic Qi Generation, Elemental Synergy & Tribulation Thunder Cloud Breakthrough

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CultivationConfig = require(Shared:WaitForChild("CultivationConfig"))
local ItemConfig = require(Shared:WaitForChild("ItemConfig"))
local DestinyConfig = require(Shared:WaitForChild("DestinyConfig"))

local remote = ReplicatedStorage:WaitForChild("CultivationRemote") :: RemoteEvent

local ADMIN_USER_IDS = {
	[game.CreatorId] = true,
}

local function isPlayerAdmin(player: Player): boolean
	return RunService:IsStudio() or ADMIN_USER_IDS[player.UserId] == true
end

local function recalculateStats(player: Player)
	local realmName = player:GetAttribute("Realm") or "Qi Condensation"
	local level = player:GetAttribute("RealmLevel") or 1
	local realmDef = CultivationConfig.Realms[realmName]

	local baseDmg = (realmDef and realmDef.BaseDamage or 15) + (level * 3)
	local baseDef = (realmDef and realmDef.BaseDefense or 5) + (level * 2)
	local baseHp  = (realmDef and realmDef.BaseHealth or 100) + (level * 15)

	-- Weapon bonus
	local eqW = player:GetAttribute("EquippedWeapon")
	local wItem = eqW and ItemConfig.getItem(eqW)
	if wItem and wItem.DamageBonus then
		baseDmg = baseDmg + wItem.DamageBonus
	end

	-- Armor bonus
	local eqA = player:GetAttribute("EquippedArmor")
	local aItem = eqA and ItemConfig.getItem(eqA)
	if aItem and aItem.DefenseBonus then
		baseDef = baseDef + aItem.DefenseBonus
	end
	if aItem and aItem.MaxHealthBonus then
		baseHp = baseHp + aItem.MaxHealthBonus
	end

	-- Talent & Spiritual Root multipliers
	local talent = player:GetAttribute("Talent") or "Mortal"
	local root = player:GetAttribute("SpiritualRoot") or "None"
	local talentMult = DestinyConfig.GetTalentMultiplier(talent)
	local rootMult = DestinyConfig.GetRootMultiplier(root)

	-- Cultivation Manual & Elemental Synergy
	local eqM = player:GetAttribute("EquippedManual") or "None"
	local mItem = eqM ~= "None" and ItemConfig.getItem(eqM) or nil
	local manualElement = mItem and (mItem :: any).Element or nil
	local hasSynergy = CultivationConfig.isManualSynergy(manualElement, root)

	local baseQiRate = CultivationConfig.getBaseQiRate(realmName)
	local effectiveRootMult = hasSynergy and rootMult or 1.0
	local totalRate = CultivationConfig.calculateQiRate(baseQiRate, talentMult, effectiveRootMult, true)

	local maxQi = CultivationConfig.getRequiredQi(realmName, level)
	local currentQi = player:GetAttribute("Qi") or 0

	player:SetAttribute("Damage", baseDmg)
	player:SetAttribute("Defense", baseDef)
	player:SetAttribute("MaxHealth", baseHp)
	player:SetAttribute("Talent", talent)
	player:SetAttribute("TalentMultiplier", talentMult)
	player:SetAttribute("SpiritualRoot", root)
	player:SetAttribute("SpiritualRootMultiplier", rootMult)
	player:SetAttribute("EquippedManual", eqM)
	player:SetAttribute("ManualSynergy", hasSynergy)
	player:SetAttribute("BaseQiRate", baseQiRate)
	player:SetAttribute("QiRate", totalRate)
	player:SetAttribute("MaxQi", maxQi)
	player:SetAttribute("BreakthroughAvailable", currentQi >= maxQi)

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.MaxHealth = baseHp
	end
end

-- ============================================================================
-- TRIBULATION THUNDER CLOUD ENGINE
-- ============================================================================
local function createTribulationCloud(player: Player): Model?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return nil end

	local cloudModel = Instance.new("Model")
	cloudModel.Name = "TribulationCloud_" .. player.Name

	-- Main dark cloud cluster
	local cloudCenter = Instance.new("Part")
	cloudCenter.Name = "CloudCenter"
	cloudCenter.Shape = Enum.PartType.Ball
	cloudCenter.Size = Vector3.new(30, 10, 30)
	cloudCenter.Color = Color3.fromRGB(24, 20, 32)
	cloudCenter.Material = Enum.Material.Slate
	cloudCenter.CanCollide = false
	cloudCenter.Anchored = false
	cloudCenter.CFrame = root.CFrame * CFrame.new(0, 22, 0)
	cloudCenter.Parent = cloudModel

	-- Follow the player centered above head
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = cloudCenter
	weld.Parent = cloudCenter

	-- Overlapping billowy storm cloud puffs
	local puffOffsets = {
		Vector3.new(-9, 1, -7),
		Vector3.new(10, -1, 8),
		Vector3.new(-8, -1, 9),
		Vector3.new(9, 1, -8),
		Vector3.new(0, 3, 0),
	}
	for i, off in ipairs(puffOffsets) do
		local puff = Instance.new("Part")
		puff.Name = "CloudPuff_" .. i
		puff.Shape = Enum.PartType.Ball
		puff.Size = Vector3.new(20, 8, 20)
		puff.Color = Color3.fromRGB(18, 15, 26)
		puff.Material = Enum.Material.Slate
		puff.CanCollide = false
		puff.Anchored = false
		puff.CFrame = cloudCenter.CFrame * CFrame.new(off)
		puff.Parent = cloudModel

		local pw = Instance.new("WeldConstraint")
		pw.Part0 = cloudCenter
		pw.Part1 = puff
		pw.Parent = puff
	end

	-- Dark storm vapor emitter
	local stormEmitter = Instance.new("ParticleEmitter")
	stormEmitter.Name = "StormVapor"
	stormEmitter.Color = ColorSequence.new(Color3.fromRGB(35, 30, 48), Color3.fromRGB(15, 12, 22))
	stormEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 6),
		NumberSequenceKeypoint.new(1, 14),
	})
	stormEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	stormEmitter.Lifetime = NumberRange.new(1.5, 2.5)
	stormEmitter.Rate = 30
	stormEmitter.Speed = NumberRange.new(1, 4)
	stormEmitter.SpreadAngle = Vector2.new(180, 180)
	stormEmitter.Parent = cloudCenter

	-- Internal electrical flicker light
	local light = Instance.new("PointLight")
	light.Name = "LightningLight"
	light.Color = Color3.fromRGB(180, 220, 255)
	light.Range = 45
	light.Brightness = 0
	light.Parent = cloudCenter

	-- Thunder Boom Audio
	local sound = Instance.new("Sound")
	sound.Name = "ThunderBoom"
	sound.SoundId = "rbxassetid://9114223171"
	sound.Volume = 1.6
	sound.Parent = cloudCenter

	cloudModel.PrimaryPart = cloudCenter
	cloudModel.Parent = Workspace
	return cloudModel
end

local function fireLightningStrike(cloudModel: Model, targetPart: BasePart, isClimactic: boolean)
	local center = cloudModel:FindFirstChild("CloudCenter") :: BasePart?
	if not center or not targetPart then return end

	local light = center:FindFirstChild("LightningLight") :: PointLight?
	local sound = center:FindFirstChild("ThunderBoom") :: Sound?

	-- Flash light
	if light then
		light.Brightness = isClimactic and 10 or 5
		light.Color = isClimactic and Color3.fromRGB(255, 240, 180) or Color3.fromRGB(160, 215, 255)
		task.delay(0.25, function()
			if light and light.Parent then light.Brightness = 0 end
		end)
	end

	-- Play thunder sound
	if sound then
		pcall(function()
			sound.TimePosition = 0
			sound:Play()
		end)
	end

	-- Procedural jagged lightning bolt segments
	local startPos = center.Position + Vector3.new(math.random(-5, 5), -2, math.random(-5, 5))
	local endPos = targetPart.Position + Vector3.new(0, 1, 0)
	local segments = 6
	local prevPoint = startPos

	local boltFolder = Instance.new("Folder")
	boltFolder.Name = "LightningBolt"
	boltFolder.Parent = Workspace

	for i = 1, segments do
		local alpha = i / segments
		local basePoint = startPos:Lerp(endPos, alpha)
		local nextPoint = (i == segments) and endPos or (basePoint + Vector3.new(math.random(-2, 2), math.random(-1, 1), math.random(-2, 2)))

		local dist = (nextPoint - prevPoint).Magnitude
		local seg = Instance.new("Part")
		seg.Name = "Seg"
		seg.Material = Enum.Material.Neon
		seg.Color = isClimactic and Color3.fromRGB(255, 245, 190) or Color3.fromRGB(170, 225, 255)
		seg.Size = Vector3.new(isClimactic and 1.2 or 0.5, isClimactic and 1.2 or 0.5, dist)
		seg.CFrame = CFrame.lookAt(prevPoint:Lerp(nextPoint, 0.5), nextPoint)
		seg.CanCollide = false
		seg.Anchored = true
		seg.Parent = boltFolder

		prevPoint = nextPoint
	end

	task.delay(0.22, function()
		if boltFolder and boltFolder.Parent then
			boltFolder:Destroy()
		end
	end)
end

-- ============================================================================
-- 1. REMOTE EVENT DISPATCHER
-- ============================================================================
remote.OnServerEvent:Connect(function(player: Player, action: string, ...)
	local args = { ... }

	if action == "Cultivate" then
		local current = player:GetAttribute("Cultivating") or false
		local newState = not current
		player:SetAttribute("Cultivating", newState)

		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			if newState then
				hum.WalkSpeed = 0
				hum.JumpPower = 0
				hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
				remote:FireClient(player, "MeditationStart")
			else
				hum.WalkSpeed = 16
				hum.JumpPower = 50
				hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
				hum.Sit = false
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
				remote:FireClient(player, "MeditationStop")
			end
		end

	elseif action == "Breakthrough" then
		local realm = player:GetAttribute("Realm") or "Qi Condensation"
		local level = player:GetAttribute("RealmLevel") or 1
		local currentQi = player:GetAttribute("Qi") or 0
		local reqQi = CultivationConfig.getRequiredQi(realm, level)

		if currentQi < reqQi then
			remote:FireClient(player, "BreakthroughFailed", "Insufficient Qi! Reach Qi capacity first.")
			return
		end

		if player:GetAttribute("BreakingThrough") == true then
			return
		end

		player:SetAttribute("BreakingThrough", true)
		player:SetAttribute("Cultivating", true)

		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hum then
			hum.WalkSpeed = 0
			hum.JumpPower = 0
		end

		-- Spawn Tribulation Thunder Cloud above character head
		local cloud = createTribulationCloud(player)

		-- Phase 1: Deep Meditation State
		remote:FireAllClients("TribulationPhase", player, 1)

		task.delay(1.5, function()
			if not player.Parent or not char or not root then
				if cloud then cloud:Destroy() end
				return
			end

			-- Phase 2: Qi Surge & Cloud Gathering
			remote:FireAllClients("TribulationPhase", player, 2)

			task.delay(1.5, function()
				if not player.Parent or not char or not root then
					if cloud then cloud:Destroy() end
					return
				end

				-- Phase 3: Lightning Strikes
				remote:FireAllClients("TribulationPhase", player, 3)
				if cloud and root then
					fireLightningStrike(cloud, root, false)
				end

				task.delay(0.8, function()
					if cloud and root then fireLightningStrike(cloud, root, false) end
				end)

				task.delay(1.6, function()
					if cloud and root then fireLightningStrike(cloud, root, false) end
				end)

				-- Phase 4 & 5: Climactic Celestial Bolt, Breakthrough Shockwave & Success
				task.delay(2.6, function()
					if not player.Parent or not char or not root then
						if cloud then cloud:Destroy() end
						return
					end

					if cloud and root then
						fireLightningStrike(cloud, root, true)
					end

					-- Advance Stage
					local leftoverQi = math.max(0, currentQi - reqQi)
					local leaderstats = player:FindFirstChild("leaderstats")
					local qiVal = leaderstats and leaderstats:FindFirstChild("Qi") :: IntValue?
					if qiVal then
						qiVal.Value = leftoverQi
					end
					player:SetAttribute("Qi", leftoverQi)

					local realmDef = CultivationConfig.Realms[realm]
					local maxLevel = realmDef and realmDef.MaxLevel or 9
					if level < maxLevel then
						player:SetAttribute("RealmLevel", level + 1)
					else
						local nextRealm = CultivationConfig.getNextRealm(realm)
						if nextRealm then
							player:SetAttribute("Realm", nextRealm)
							player:SetAttribute("RealmLevel", 1)
						else
							player:SetAttribute("RealmLevel", level + 1)
						end
					end

					player:SetAttribute("BreakingThrough", false)
					player:SetAttribute("BreakthroughAvailable", false)
					recalculateStats(player)

					remote:FireAllClients("BreakthroughBurst", player)
					remote:FireClient(player, "BreakthroughSuccess", player:GetAttribute("Realm"), player:GetAttribute("RealmLevel"))

					-- Clean up Tribulation Cloud
					task.delay(1.2, function()
						if cloud and cloud.Parent then
							cloud:Destroy()
						end
					end)
				end)
			end)
		end)

	elseif action == "SpinWheel" then
		local wheelType = args[1]
		if wheelType ~= "Talent" and wheelType ~= "SpiritualRoot" then return end

		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then
			leaderstats = Instance.new("Folder")
			leaderstats.Name = "leaderstats"
			leaderstats.Parent = player
		end
		local goldVal = leaderstats:FindFirstChild("Gold") :: IntValue?
		if not goldVal then
			goldVal = Instance.new("IntValue")
			goldVal.Name = "Gold"
			goldVal.Value = 5000
			goldVal.Parent = leaderstats
		end
		local isTalent = (wheelType == "Talent")
		local spinAttr = isTalent and "TalentSpins" or "RootSpins"
		local spinsDone = player:GetAttribute(spinAttr) or 0
		local cost = (spinsDone == 0) and 0 or DestinyConfig.SPIN_COST

		if cost > 0 and (not goldVal or goldVal.Value < cost) then
			if RunService:IsStudio() or isPlayerAdmin(player) then
				if goldVal then
					goldVal.Value = goldVal.Value + 1000
				end
			else
				remote:FireClient(player, "SpinError", "Not enough Spirit Stones! You need 50 Spirit Stones.")
				return
			end
		end

		if cost > 0 and goldVal then
			goldVal.Value = goldVal.Value - cost
		end

		player:SetAttribute(spinAttr, spinsDone + 1)
		player:SetAttribute("SpinsUsed", (player:GetAttribute("SpinsUsed") or 0) + 1)

		if wheelType == "Talent" then
			local talentEntry, resultIdx = DestinyConfig.RollTalent()
			remote:FireClient(player, "SpinResult", "Talent", resultIdx, talentEntry.Name, talentEntry.Multiplier)
			print(string.format("[DestinyWheel] %s spun Talent: %s (x%.2f)", player.Name, talentEntry.Name, talentEntry.Multiplier))
			task.delay(4.0, function()
				if player.Parent then
					player:SetAttribute("Talent", talentEntry.Name)
					recalculateStats(player)
				end
			end)
		elseif wheelType == "SpiritualRoot" then
			local rootEntry, resultIdx = DestinyConfig.RollSpiritualRoot()
			remote:FireClient(player, "SpinResult", "SpiritualRoot", resultIdx, rootEntry.Name, rootEntry.Multiplier)
			print(string.format("[DestinyWheel] %s spun Spiritual Root: %s (x%.2f)", player.Name, rootEntry.Name, rootEntry.Multiplier))
			task.delay(4.0, function()
				if player.Parent then
					player:SetAttribute("SpiritualRoot", rootEntry.Name)
					recalculateStats(player)
				end
			end)
		end

	elseif action == "BuyItem" then
		local itemName = args[1]
		local item = itemName and ItemConfig.getItem(itemName)
		if item then
			local leaderstats = player:FindFirstChild("leaderstats")
			local goldVal = leaderstats and leaderstats:FindFirstChild("Gold") :: IntValue?
			local inventory = player:FindFirstChild("Inventory")

			if goldVal and inventory and goldVal.Value >= item.Price then
				goldVal.Value = goldVal.Value - item.Price

				local itmVal = inventory:FindFirstChild(itemName) :: IntValue?
				if not itmVal then
					itmVal = Instance.new("IntValue")
					itmVal.Name = itemName
					itmVal.Value = 0
					itmVal.Parent = inventory
				end
				itmVal.Value = itmVal.Value + 1
				print(string.format("[Shop] %s purchased %s for %d Gold", player.Name, itemName, item.Price))
			end
		end

	elseif action == "UseItem" then
		local itemName = args[1]
		local inventory = player:FindFirstChild("Inventory")
		local itmVal = inventory and inventory:FindFirstChild(itemName) :: IntValue?

		if itmVal and itmVal.Value > 0 then
			local item = ItemConfig.getItem(itemName)
			if item and item.Type == "Pill" then
				itmVal.Value = itmVal.Value - 1

				if item.InstantQi then
					local currentQi = player:GetAttribute("Qi") or 0
					local maxQi = player:GetAttribute("MaxQi") or 5000
					local newQi = math.min(maxQi, currentQi + item.InstantQi)
					player:SetAttribute("Qi", newQi)
					local leaderstats = player:FindFirstChild("leaderstats")
					local qiVal = leaderstats and leaderstats:FindFirstChild("Qi") :: IntValue?
					if qiVal then qiVal.Value = newQi end
				end

				if itemName == "Spirit Spring Elixir" then
					local char = player.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.Health = hum.MaxHealth
					end
				end

				if item.QiGatherMultiplier and item.BuffDurationSeconds then
					player:SetAttribute("PillMultiplier", item.QiGatherMultiplier)
					player:SetAttribute("PillBuffExpiry", os.time() + item.BuffDurationSeconds)
					recalculateStats(player)
				end
			end
		end

	elseif action == "EquipItem" then
		local itemName = args[1]
		local item = itemName and ItemConfig.getItem(itemName)
		local inventory = player:FindFirstChild("Inventory")
		local itmVal = inventory and inventory:FindFirstChild(itemName) :: IntValue?

		if item and itmVal and itmVal.Value > 0 then
			if item.Type == "Weapon" then
				player:SetAttribute("EquippedWeapon", item.Name)
			elseif item.Type == "Armor" then
				player:SetAttribute("EquippedArmor", item.Name)
			elseif item.Type == "Manual" then
				player:SetAttribute("EquippedManual", item.Name)
			end
			recalculateStats(player)
		end

	elseif action == "UnequipItem" then
		local itemName = args[1]
		local item = itemName and ItemConfig.getItem(itemName)
		if item then
			if item.Type == "Weapon" and player:GetAttribute("EquippedWeapon") == item.Name then
				player:SetAttribute("EquippedWeapon", "None")
			elseif item.Type == "Armor" and player:GetAttribute("EquippedArmor") == item.Name then
				player:SetAttribute("EquippedArmor", "None")
			elseif item.Type == "Manual" and player:GetAttribute("EquippedManual") == item.Name then
				player:SetAttribute("EquippedManual", "None")
			end
			recalculateStats(player)
		end

	elseif action == "AdminAction" and isPlayerAdmin(player) then
		local subAction = args[1]
		local leaderstats = player:FindFirstChild("leaderstats")
		local inventory = player:FindFirstChild("Inventory")

		if subAction == "AddGold" and leaderstats then
			local g = leaderstats:FindFirstChild("Gold") :: IntValue?
			if g then g.Value = g.Value + (args[2] or 1000) end
		elseif subAction == "AddQi" and leaderstats then
			local q = leaderstats:FindFirstChild("Qi") :: IntValue?
			local add = args[2] or 500
			local cur = player:GetAttribute("Qi") or 0
			player:SetAttribute("Qi", cur + add)
			if q then q.Value = q.Value + add end
			recalculateStats(player)
		elseif subAction == "SetRealmLevel" then
			player:SetAttribute("RealmLevel", args[2] or 1)
			recalculateStats(player)
		elseif subAction == "AddItem" and inventory then
			local itmName = args[2]
			local qty = args[3] or 1
			local itmVal = inventory:FindFirstChild(itmName) :: IntValue?
			if not itmVal then
				itmVal = Instance.new("IntValue")
				itmVal.Name = itmName
				itmVal.Value = 0
				itmVal.Parent = inventory
			end
			itmVal.Value = itmVal.Value + qty
		end
	end
end)

-- Initialize Player
local function setupPlayer(player: Player)
	if not player:GetAttribute("Realm") then player:SetAttribute("Realm", "Qi Condensation") end
	if not player:GetAttribute("RealmLevel") then player:SetAttribute("RealmLevel", 1) end
	if not player:GetAttribute("Qi") then player:SetAttribute("Qi", 0) end
	if not player:GetAttribute("Talent") then player:SetAttribute("Talent", "Mortal") end
	if not player:GetAttribute("SpiritualRoot") then player:SetAttribute("SpiritualRoot", "None") end
	if not player:GetAttribute("EquippedManual") then player:SetAttribute("EquippedManual", "None") end
	if not player:GetAttribute("Cultivating") then player:SetAttribute("Cultivating", false) end
	if not player:GetAttribute("PillMultiplier") then player:SetAttribute("PillMultiplier", 1.0) end

	local inventory = player:FindFirstChild("Inventory")
	if not inventory then
		inventory = Instance.new("Folder")
		inventory.Name = "Inventory"
		inventory.Parent = player
	end

	-- Starter Manual & Pills
	local starterManual = inventory:FindFirstChild("Fire Scripture")
	if not starterManual then
		local itm = Instance.new("IntValue")
		itm.Name = "Fire Scripture"
		itm.Value = 1
		itm.Parent = inventory
	end

	recalculateStats(player)

	player.CharacterAdded:Connect(function(char)
		player:SetAttribute("Cultivating", false)
		player:SetAttribute("BreakingThrough", false)
		local hum = char:WaitForChild("Humanoid", 5) :: Humanoid?
		if hum then
			hum.Died:Connect(function()
				player:SetAttribute("Cultivating", false)
				player:SetAttribute("BreakingThrough", false)
			end)
		end
		recalculateStats(player)
	end)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	setupPlayer(p)
end

-- ============================================================================
-- 2. BACKGROUND MEDITATION & BUFF TICK LOOP (Every 1 Second)
-- ============================================================================
task.spawn(function()
	while true do
		task.wait(1.0)
		local now = os.time()

		for _, p in ipairs(Players:GetPlayers()) do
			local expiry = p:GetAttribute("PillBuffExpiry") or 0
			if expiry > 0 and now >= expiry then
				p:SetAttribute("PillMultiplier", 1.0)
				p:SetAttribute("PillBuffExpiry", 0)
				recalculateStats(p)
			end

			local isCult = p:GetAttribute("Cultivating") == true
			local isBreaking = p:GetAttribute("BreakingThrough") == true

			if isCult and not isBreaking then
				local realm = p:GetAttribute("Realm") or "Qi Condensation"
				local level = p:GetAttribute("RealmLevel") or 1
				local maxCap = CultivationConfig.getRequiredQi(realm, level)

				local leaderstats = p:FindFirstChild("leaderstats")
				local qiVal = leaderstats and leaderstats:FindFirstChild("Qi") :: IntValue?
				local currentQi = p:GetAttribute("Qi") or (qiVal and qiVal.Value or 0)

				if currentQi >= maxCap then
					-- Qi is full! Cap it and flag breakthrough available
					p:SetAttribute("BreakthroughAvailable", true)
					p:SetAttribute("Qi", maxCap)
					if qiVal then qiVal.Value = maxCap end
				else
					p:SetAttribute("BreakthroughAvailable", false)
					local baseQi = CultivationConfig.getBaseQiRate(realm)
					local talentMult = p:GetAttribute("TalentMultiplier") or 1.0
					local rootMult = p:GetAttribute("SpiritualRootMultiplier") or 1.0
					local hasSynergy = p:GetAttribute("ManualSynergy") == true
					local pillMult = p:GetAttribute("PillMultiplier") or 1.0

					local effectiveRoot = hasSynergy and rootMult or 1.0
					local totalRate = CultivationConfig.calculateQiRate(baseQi, talentMult, effectiveRoot, true) * pillMult
					local gain = math.max(1, math.floor(totalRate + 0.5))

					local nextQi = math.min(maxCap, currentQi + gain)
					p:SetAttribute("Qi", nextQi)
					p:SetAttribute("QiRate", totalRate)
					p:SetAttribute("MaxQi", maxCap)
					if qiVal then qiVal.Value = nextQi end

					if nextQi >= maxCap then
						p:SetAttribute("BreakthroughAvailable", true)
					end

					remote:FireClient(p, "QiGainTick", gain, totalRate, nextQi, maxCap)
				end
			end
		end
	end
end)
