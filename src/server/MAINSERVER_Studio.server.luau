--!strict
-- src/server/MAINSERVER.server.luau
-- CultivationService: Meditation Loop, Breakthroughs, Item Usage & Equipment Stats

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CultivationConfig = require(Shared:WaitForChild("CultivationConfig"))
local ItemConfig = require(Shared:WaitForChild("ItemConfig"))

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
		local currentQi = player:GetAttribute("Qi") or 0
		local reqQi = CultivationConfig.getRequiredQi(realm, level)

		if currentQi >= reqQi then
			local leaderstats = player:FindFirstChild("leaderstats")
			local qiVal = leaderstats and leaderstats:FindFirstChild("Qi") :: IntValue?
			if qiVal then
				qiVal.Value = math.max(0, qiVal.Value - reqQi)
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
	end
end)

-- ============================================================================
-- 2. BACKGROUND MEDITATION & BUFF TICK LOOP (Every 1 Second)
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

			-- Meditation & Passive Spiritual Qi Gathering
			local isCult = p:GetAttribute("Cultivating") == true
			local realm = p:GetAttribute("Realm") or "Qi Condensation"
			local realmDef = CultivationConfig.Realms[realm]
			local baseSpeed = realmDef and realmDef.BaseQiPerSecond or 5
			local mult = p:GetAttribute("QiMultiplier") or 1.0

			local leaderstats = p:FindFirstChild("leaderstats")
			local qiVal = leaderstats and leaderstats:FindFirstChild("Qi") :: IntValue?
			local maxCap = (realmDef and realmDef.BreakthroughRequirement or 100) * 2
			if qiVal then
				local gain = isCult and math.floor(baseSpeed * mult * 2) or math.max(1, math.floor(baseSpeed * 0.4))
				if qiVal.Value < maxCap or isCult then
					qiVal.Value = qiVal.Value + gain
					-- Fire Qi gain tick to client for floating popup
					if isCult then
						remote:FireClient(p, "QiGainTick", gain)
					end
				end
			end
		end
	end
end)