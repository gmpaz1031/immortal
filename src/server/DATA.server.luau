--!strict
-- src/server/DATA.server.luau
-- PlayerDataService: Leaderstats, Attributes, Inventory, Destiny & DataStore Persistence

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CultivationConfig = require(Shared:WaitForChild("CultivationConfig"))
local ItemConfig = require(Shared:WaitForChild("ItemConfig"))
local DestinyConfig = require(Shared:WaitForChild("DestinyConfig"))

local DATA_STORE_NAME = "Immortal_PlayerData_v1"
local playerDataStore = nil

pcall(function()
	playerDataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)
end)

local sessionData: { [number]: any } = {}

local function applyCharacterStats(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if humanoid then
		local maxHp = player:GetAttribute("MaxHealth") or 100
		humanoid.MaxHealth = maxHp
		humanoid.Health = maxHp
	end
end

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local goldVal = Instance.new("IntValue")
	goldVal.Name = "Gold"
	goldVal.Value = 50 -- Starting 50 Gold
	goldVal.Parent = leaderstats

	local qiVal = Instance.new("IntValue")
	qiVal.Name = "Qi"
	qiVal.Value = 100 -- Starting Qi
	qiVal.Parent = leaderstats

	local inventory = Instance.new("Folder")
	inventory.Name = "Inventory"
	inventory.Parent = player

	local miscs = Instance.new("Folder")
	miscs.Name = "Miscs"
	miscs.Parent = inventory

	-- Default Attributes
	player:SetAttribute("Realm", "Qi Condensation")
	player:SetAttribute("RealmLevel", 0)
	player:SetAttribute("Qi", 100)
	player:SetAttribute("Cultivating", false)
	player:SetAttribute("Damage", 15)
	player:SetAttribute("Defense", 5)
	player:SetAttribute("MaxHealth", 100)
	player:SetAttribute("EquippedWeapon", "None")
	player:SetAttribute("EquippedArmor", "None")
	player:SetAttribute("QiMultiplier", 1.0)
	player:SetAttribute("PillBuffExpiry", 0)
	player:SetAttribute("Talent", "Mortal")
	player:SetAttribute("TalentMultiplier", 1.0)
	player:SetAttribute("SpiritualRoot", "None")
	player:SetAttribute("SpiritualRootMultiplier", 1.0)
	player:SetAttribute("SpinsUsed", 0)

	qiVal.Changed:Connect(function(newVal)
		player:SetAttribute("Qi", newVal)
	end)

	local userId = player.UserId
	local savedData = nil

	if playerDataStore and not RunService:IsStudio() then
		local success, result = pcall(function()
			return playerDataStore:GetAsync("User_" .. userId)
		end)
		if success and result then
			savedData = result
		end
	end

	if savedData and typeof(savedData) == "table" then
		goldVal.Value = savedData.Gold or 50
		qiVal.Value = savedData.Qi or 0
		player:SetAttribute("Realm", savedData.Realm or "Qi Condensation")
		player:SetAttribute("RealmLevel", savedData.RealmLevel or 0)
		player:SetAttribute("EquippedWeapon", savedData.EquippedWeapon or "None")
		player:SetAttribute("EquippedArmor", savedData.EquippedArmor or "None")
		player:SetAttribute("Talent", savedData.Talent or "Mortal")
		player:SetAttribute("SpiritualRoot", savedData.SpiritualRoot or "None")
		player:SetAttribute("SpinsUsed", savedData.SpinsUsed or 0)
		player:SetAttribute("TalentSpins", savedData.TalentSpins or 0)
		player:SetAttribute("RootSpins", savedData.RootSpins or 0)

		if savedData.Inventory and typeof(savedData.Inventory) == "table" then
			for itemName, qty in pairs(savedData.Inventory) do
				if qty > 0 then
					local itmDef = ItemConfig.getItem(itemName)
					local parentFolder = (itmDef and (itmDef.Type == "Miscs" or itmDef.Category == "Miscs")) and miscs or inventory
					local itmVal = Instance.new("IntValue")
					itmVal.Name = itemName
					itmVal.Value = qty
					itmVal.Parent = parentFolder
				end
			end
		end
	else
		local starterPill = Instance.new("IntValue")
		starterPill.Name = "Lesser Qi Pill"
		starterPill.Value = 2
		starterPill.Parent = inventory
	end

	local realmName = player:GetAttribute("Realm") or "Qi Condensation"
	local realmDef = CultivationConfig.Realms[realmName]
	local baseDmg = realmDef and realmDef.BaseDamage or 15
	local baseDef = realmDef and realmDef.BaseDefense or 5
	local baseHp = realmDef and realmDef.BaseHealth or 100

	local eqW = player:GetAttribute("EquippedWeapon")
	local wItem = eqW and ItemConfig.getItem(eqW)
	if wItem and wItem.DamageBonus then
		baseDmg = baseDmg + wItem.DamageBonus
	end

	local eqA = player:GetAttribute("EquippedArmor")
	local aItem = eqA and ItemConfig.getItem(eqA)
	if aItem and aItem.DefenseBonus then
		baseDef = baseDef + aItem.DefenseBonus
	end
	if aItem and aItem.MaxHealthBonus then
		baseHp = baseHp + aItem.MaxHealthBonus
	end

	local talent = player:GetAttribute("Talent") or "Mortal"
	local root = player:GetAttribute("SpiritualRoot") or "None"
	local talentMult = DestinyConfig.GetTalentMultiplier(talent)
	local rootMult = DestinyConfig.GetRootMultiplier(root)

	player:SetAttribute("Damage", baseDmg)
	player:SetAttribute("Defense", baseDef)
	player:SetAttribute("MaxHealth", baseHp)
	player:SetAttribute("TalentMultiplier", talentMult)
	player:SetAttribute("SpiritualRootMultiplier", rootMult)

	if player.Character then
		applyCharacterStats(player, player.Character)
	end
	player.CharacterAdded:Connect(function(char)
		applyCharacterStats(player, char)
	end)

	sessionData[userId] = true
	print(string.format("[PlayerData] Initialized profile for %s (Talent: %s, Root: %s)", player.Name, talent, root))
end

local function savePlayerData(player: Player)
	local userId = player.UserId
	if not sessionData[userId] or not playerDataStore then return end

	local leaderstats = player:FindFirstChild("leaderstats")
	local goldVal = leaderstats and leaderstats:FindFirstChild("Gold") and (leaderstats:FindFirstChild("Gold") :: IntValue).Value or 0
	local qiVal = leaderstats and leaderstats:FindFirstChild("Qi") and (leaderstats:FindFirstChild("Qi") :: IntValue).Value or 0

	local invTable = {}
	local inventory = player:FindFirstChild("Inventory")
	if inventory then
		for _, child in ipairs(inventory:GetChildren()) do
			if child:IsA("IntValue") and child.Value > 0 then
				invTable[child.Name] = child.Value
			elseif child:IsA("Folder") then
				for _, subChild in ipairs(child:GetChildren()) do
					if subChild:IsA("IntValue") and subChild.Value > 0 then
						invTable[subChild.Name] = subChild.Value
					end
				end
			end
		end
	end

	local dataToSave = {
		Gold = goldVal,
		Qi = qiVal,
		Realm = player:GetAttribute("Realm") or "Qi Condensation",
		RealmLevel = player:GetAttribute("RealmLevel") or 0,
		EquippedWeapon = player:GetAttribute("EquippedWeapon") or "None",
		EquippedArmor = player:GetAttribute("EquippedArmor") or "None",
		Talent = player:GetAttribute("Talent") or "Mortal",
		SpiritualRoot = player:GetAttribute("SpiritualRoot") or "None",
		SpinsUsed = player:GetAttribute("SpinsUsed") or 0,
		TalentSpins = player:GetAttribute("TalentSpins") or 0,
		RootSpins = player:GetAttribute("RootSpins") or 0,
		Inventory = invTable,
	}

	pcall(function()
		playerDataStore:SetAsync("User_" .. userId, dataToSave)
	end)
end

local function onPlayerRemoving(player: Player)
	savePlayerData(player)
	sessionData[player.UserId] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, p)
end

task.spawn(function()
	while true do
		task.wait(180)
		for _, p in ipairs(Players:GetPlayers()) do
			savePlayerData(p)
		end
	end
end)

game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do
		savePlayerData(p)
	end
end)
