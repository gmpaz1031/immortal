--!strict
-- src/server/MAINSERVER.server.luau
-- CultivationService: Meditation Loop, Breakthroughs, Item Usage & Equipment Stats

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CultivationConfig = require(Shared:WaitForChild("CultivationConfig"))
local ItemConfig = require(Shared:WaitForChild("ItemConfig"))
local DestinyConfig = require(Shared:WaitForChild("DestinyConfig"))

local remote = ReplicatedStorage:WaitForChild("CultivationRemote") :: RemoteEvent

-- Admin User IDs whitelist (Studio testing always allowed)
local ADMIN_USER_IDS = {
	[game.CreatorId] = true,
}

local function isPlayerAdmin(player: Player): boolean
	return RunService:IsStudio() or ADMIN_USER_IDS[player.UserId] == true
end

local function recalculateStats(player: Player)
	local realmName = player:GetAttribute("Realm") or "Qi Condensation"
	local level = player:GetAttribute("RealmLevel") or 0
	local realmDef = CultivationConfig.Realms[realmName]

	local baseDmg = (realmDef and realmDef.BaseDamage or 15) + (level * 3)
	local baseDef = (realmDef and realmDef.BaseDefense or 5) + (level * 2)
	local baseHp  = (realmDef and realmDef.BaseHealth or 100) + (level * 15)

	-- Apply Weapon bonus
	local eqW = player:GetAttribute("EquippedWeapon")
	local wItem = eqW and ItemConfig.getItem(eqW)
	if wItem and wItem.DamageBonus then
		baseDmg = baseDmg + wItem.DamageBonus
	end

	-- Apply Armor bonus
	local eqA = player:GetAttribute("EquippedArmor")
	local aItem = eqA and ItemConfig.getItem(eqA)
	if aItem and aItem.DefenseBonus then
		baseDef = baseDef + aItem.DefenseBonus
	end
	if aItem and aItem.MaxHealthBonus then
		baseHp = baseHp + aItem.MaxHealthBonus
	end

	player:SetAttribute("Damage", baseDmg)
	player:SetAttribute("Defense", baseDef)
	player:SetAttribute("MaxHealth", baseHp)

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.MaxHealth = baseHp
	end
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

		-- Lock/Unlock movement during meditation
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			if newState then
				hum.WalkSpeed = 0
				hum.JumpPower = 0
				remote:FireClient(player, "MeditationStart")
			else
				hum.WalkSpeed = 16
				hum.JumpPower = 50
				remote:FireClient(player, "MeditationStop")
			end
		end

	elseif action == "Breakthrough" then
		local realm = player:GetAttribute("Realm") or "Qi Condensation"
		local level = player:GetAttribute("RealmLevel") or 0
		local leaderstats = player:FindFirstChild("leaderstats")
		local qiVal = leaderstats and leaderstats:FindFirstChild("Qi") :: IntValue?
		local currentQi = qiVal and qiVal.Value or (player:GetAttribute("Qi") or 0)
		local reqQi = CultivationConfig.getRequiredQi(realm, level)

		if currentQi >= reqQi then
			if qiVal then
				qiVal.Value = math.max(0, qiVal.Value - reqQi)
				player:SetAttribute("Qi", qiVal.Value)
			else
				player:SetAttribute("Qi", math.max(0, currentQi - reqQi))
			end

			local realmDef = CultivationConfig.Realms[realm]
			if realmDef and level < realmDef.MaxLevel then
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

			recalculateStats(player)
			remote:FireClient(player, "BreakthroughStart")
			remote:FireAllClients("BreakthroughBurst", player)
			print(string.format("[Breakthrough] %s broke through to %s · Level %d!", player.Name, player:GetAttribute("Realm"), player:GetAttribute("RealmLevel") or 0))
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
					local leaderstats = player:FindFirstChild("leaderstats")
					local qiVal = leaderstats and leaderstats:FindFirstChild("Qi") :: IntValue?
					if qiVal then
						qiVal.Value = qiVal.Value + item.InstantQi
					end
				end

				if itemName == "Spirit Spring Elixir" then
					local char = player.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.Health = hum.MaxHealth
					end
				end

				if item.QiGatherMultiplier and item.BuffDurationSeconds then
					player:SetAttribute("QiMultiplier", item.QiGatherMultiplier)
					player:SetAttribute("PillBuffExpiry", os.time() + item.BuffDurationSeconds)
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
			if q then q.Value = q.Value + (args[2] or 500) end
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

	elseif action == "SpinWheel" then
		local wheelType = args[1] -- "Talent" or "SpiritualRoot"
		if wheelType ~= "Talent" and wheelType ~= "SpiritualRoot" then
			remote:FireClient(player, "SpinError", "Invalid spin category.")
			return
		end

		local leaderstats = player:FindFirstChild("leaderstats")
		local goldVal = leaderstats and leaderstats:FindFirstChild("Gold") :: IntValue?
		local spinsDoneAttr = if wheelType == "Talent" then "TalentSpins" else "RootSpins"
		local spinsDone = player:GetAttribute(spinsDoneAttr) or 0
		local isFree = (spinsDone == 0)

		if not isFree then
			if not goldVal or goldVal.Value < DestinyConfig.SPIN_COST then
				remote:FireClient(player, "SpinError", "Not enough Spirit Stones! Requires 50 Spirit Stones.")
				return
			end
			goldVal.Value = goldVal.Value - DestinyConfig.SPIN_COST
		end

		player:SetAttribute(spinsDoneAttr, spinsDone + 1)

		if wheelType == "Talent" then
			local talent, idx = DestinyConfig.RollTalent()
			player:SetAttribute("Talent", talent.Name)
			recalculateStats(player)
			remote:FireClient(player, "SpinResult", "Talent", idx, talent.Name, talent.Multiplier)
			print(string.format("[Destiny] %s spun Talent: %s (Tier: %s, x%.2f)!", player.Name, talent.Name, talent.TierName, talent.Multiplier))
		else
			local root, idx = DestinyConfig.RollSpiritualRoot()
			player:SetAttribute("SpiritualRoot", root.Name)
			recalculateStats(player)
			remote:FireClient(player, "SpinResult", "SpiritualRoot", idx, root.Name, root.Multiplier)
			print(string.format("[Destiny] %s spun Spiritual Root: %s (Tier: %s, x%.2f)!", player.Name, root.Name, root.TierName, root.Multiplier))
		end
	end
end)

-- ============================================================================
-- 2. QI CULTIVATION AREAS SPATIAL DETECTION & REQUIREMENT GATING
-- ============================================================================
local function getActiveCultivationArea(char: Model): (Model?, number, string, boolean, string)
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return nil, 1.0, "None", false, "" end

	local areasFolder = workspace:FindFirstChild("QiCultivationAreas")
	if not areasFolder then return nil, 1.0, "None", false, "" end

	local rootPos = root.Position
	for _, area in ipairs(areasFolder:GetChildren()) do
		if area:IsA("Model") then
			local cf, size
			local primary = area.PrimaryPart or area:FindFirstChild("CULTIVATION AREA") or area:FindFirstChildWhichIsA("BasePart")
			if primary then
				cf = primary.CFrame
				size = primary.Size + Vector3.new(4, 10, 4)
			else
				cf, size = area:GetBoundingBox()
				size = size + Vector3.new(4, 10, 4)
			end

			local localPos = cf:PointToObjectSpace(rootPos)
			local halfX = size.X * 0.5
			local halfY = size.Y * 0.5
			local halfZ = size.Z * 0.5

			if math.abs(localPos.X) <= halfX and math.abs(localPos.Z) <= halfZ and math.abs(localPos.Y) <= halfY then
				local mult = area:GetAttribute("Multiplier") or 1.5
				local areaType = area:GetAttribute("Type") or "Qi"
				local req = area:GetAttribute("Requirement") or "Qi Condensation"

				return area, tonumber(mult) or 1.0, tostring(areaType), true, tostring(req)
			end
		end
	end

	return nil, 1.0, "None", false, ""
end

-- Active area tracking loop (Every 0.5 Seconds)
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, p in ipairs(Players:GetPlayers()) do
			local char = p.Character
			if char then
				local areaModel, mult, areaType, isInside, req = getActiveCultivationArea(char)
				local prevArea = p:GetAttribute("CurrentCultivationArea") or "None"

				if isInside and areaModel then
					local currentRealm = p:GetAttribute("Realm") or "Qi Condensation"
					local meetsReq = CultivationConfig.meetsRequirement(currentRealm, req)

					if meetsReq then
						p:SetAttribute("AreaQiMultiplier", mult)
						p:SetAttribute("AreaType", areaType)
						p:SetAttribute("CurrentCultivationArea", areaModel.Name)

						if prevArea ~= areaModel.Name then
							remote:FireClient(p, "FloatingNotice", string.format("Entered Spiritual Vein: %s (x%.1f %s Boost)", areaModel.Name, mult, areaType))
						end
					else
						p:SetAttribute("AreaQiMultiplier", 1.0)
						p:SetAttribute("AreaType", "None")
						p:SetAttribute("CurrentCultivationArea", "None")

						if prevArea ~= (areaModel.Name .. "_Unqualified") then
							p:SetAttribute("CurrentCultivationArea", areaModel.Name .. "_Unqualified")
							remote:FireClient(p, "FloatingNotice", string.format("Spiritual density too intense! Requires %s+ to absorb energy here.", req))
						end
					end
				else
					if prevArea ~= "None" then
						p:SetAttribute("AreaQiMultiplier", 1.0)
						p:SetAttribute("AreaType", "None")
						p:SetAttribute("CurrentCultivationArea", "None")
					end
				end
			end
		end
	end
end)

-- ============================================================================
-- 3. BACKGROUND MEDITATION & BUFF TICK LOOP (Every 1 Second)
-- ============================================================================
task.spawn(function()
	while true do
		task.wait(1.0)
		local now = os.time()

		for _, p in ipairs(Players:GetPlayers()) do
			-- Check Pill Buff Expiry
			local expiry = p:GetAttribute("PillBuffExpiry") or 0
			if expiry > 0 and now >= expiry then
				p:SetAttribute("QiMultiplier", 1.0)
				p:SetAttribute("PillBuffExpiry", 0)
			end

			-- Meditation Spiritual Qi Gathering (Strictly active only, zero passive regen)
			local isCult = p:GetAttribute("Cultivating") == true
			local realm = p:GetAttribute("Realm") or "Qi Condensation"
			local level = p:GetAttribute("RealmLevel") or 0
			local realmDef = CultivationConfig.Realms[realm]
			local baseSpeed = realmDef and realmDef.BaseQiPerSecond or 5
			local mult = p:GetAttribute("QiMultiplier") or 1.0
			local areaMult = p:GetAttribute("AreaQiMultiplier") or 1.0

			local talent = p:GetAttribute("Talent")
			local root = p:GetAttribute("SpiritualRoot")
			local talentMult = DestinyConfig.GetTalentMultiplier(talent)
			local rootMult = DestinyConfig.GetRootMultiplier(root)
			local destinyMult = talentMult * rootMult

			local reqQi = CultivationConfig.getRequiredQi(realm, level)
			local limit = reqQi

			local leaderstats = p:FindFirstChild("leaderstats")
			local qiVal = leaderstats and leaderstats:FindFirstChild("Qi") :: IntValue?
			if qiVal then
				if isCult then
					if qiVal.Value < limit then
						local gain = math.max(1, math.floor(baseSpeed * mult * areaMult * destinyMult * 2))
						qiVal.Value = math.clamp(qiVal.Value + gain, 0, limit)
						p:SetAttribute("Qi", qiVal.Value)
						remote:FireClient(p, "QiGainTick", gain)
					else
						p:SetAttribute("Qi", qiVal.Value)
					end
				else
					p:SetAttribute("Qi", qiVal.Value)
				end
			end
		end
	end
end)