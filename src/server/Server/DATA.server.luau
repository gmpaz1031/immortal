--!strict
-- src/server/DATA.server.luau
-- PlayerDataService: Leaderstats, Attributes, Inventory & DataStore Persistence

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CultivationConfig = require(Shared:WaitForChild("CultivationConfig"))
local ItemConfig = require(Shared:WaitForChild("ItemConfig"))
local SkillConfig = require(Shared:WaitForChild("SkillConfig"))

local DATA_STORE_NAME = "Immortal_PlayerData_v1"
local playerDataStore = nil

-- Safe DataStore initialization (handles Studio API access disabled)
pcall(function()
	playerDataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)
end)

local loadedProfiles: { [number]: boolean } = {}
local savePlayerData: (player: Player) -> boolean

local function applyCharacterStats(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if humanoid then
		local maxHp = player:GetAttribute("MaxHealth") or 100
		humanoid.MaxHealth = maxHp
		humanoid.Health = maxHp
	end
end

local function setupPlayerOverhead(player: Player, character: Model)
	local head = character:WaitForChild("Head", 5) :: BasePart?
	if not head then return end

	local oldGui = head:FindFirstChild("PlayerOverhead")
	if oldGui then oldGui:Destroy() end

	local bbg = Instance.new("BillboardGui")
	bbg.Name = "PlayerOverhead"
	bbg.Adornee = head
	bbg.Size = UDim2.new(5.2, 0, 1.5, 0) -- 3D PERSPECTIVE SCALE: Preserves proportional size with distance
	bbg.StudsOffset = Vector3.new(0, 2.6, 0)
	bbg.MaxDistance = 80
	bbg.AlwaysOnTop = false
	bbg.LightInfluence = 0
	bbg.Parent = head

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(1, 0, 1, 0)
	container.Parent = bbg

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.new(1, 0, 0.35, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = player.DisplayName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Parent = container

	local nameStroke = Instance.new("UIStroke")
	nameStroke.Thickness = 1.2
	nameStroke.Color = Color3.fromRGB(15, 20, 25)
	nameStroke.Parent = nameLabel

	local realmLabel = Instance.new("TextLabel")
	realmLabel.Name = "RealmLabel"
	realmLabel.BackgroundTransparency = 1
	realmLabel.Size = UDim2.new(1, 0, 0.32, 0)
	realmLabel.Position = UDim2.new(0, 0, 0.35, 0)
	realmLabel.Font = Enum.Font.GothamMedium
	realmLabel.TextColor3 = Color3.fromRGB(140, 225, 255)
	realmLabel.TextScaled = true
	realmLabel.Parent = container

	local realmStroke = Instance.new("UIStroke")
	realmStroke.Thickness = 1.0
	realmStroke.Color = Color3.fromRGB(10, 30, 40)
	realmStroke.Parent = realmLabel

	local rankLabel = Instance.new("TextLabel")
	rankLabel.Name = "RankLabel"
	rankLabel.BackgroundTransparency = 1
	rankLabel.Size = UDim2.new(1, 0, 0.33, 0)
	rankLabel.Position = UDim2.new(0, 0, 0.67, 0)
	rankLabel.Font = Enum.Font.GothamBlack
	rankLabel.TextColor3 = Color3.fromRGB(255, 215, 100) -- Imperial Gold
	rankLabel.TextScaled = true
	rankLabel.Parent = container

	local rankStroke = Instance.new("UIStroke")
	rankStroke.Thickness = 1.2
	rankStroke.Color = Color3.fromRGB(60, 40, 5)
	rankStroke.Parent = rankLabel

	local function refreshOverhead()
		local realm = player:GetAttribute("Realm") or "Qi Condensation"
		local level = player:GetAttribute("RealmLevel") or 0
		local realmDef = CultivationConfig.Realms[realm]
		local rankTitle = realmDef and realmDef.RankTitle or "Mortal Disciple"

		realmLabel.Text = string.format("[%s · Lv %d]", realm, level)
		rankLabel.Text = string.format("« %s »", rankTitle)
	end

	refreshOverhead()

	player:GetAttributeChangedSignal("Realm"):Connect(refreshOverhead)
	player:GetAttributeChangedSignal("RealmLevel"):Connect(refreshOverhead)
end

local function onPlayerAdded(player: Player)
	-- 1. Create Leaderstats Folder
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local goldVal = Instance.new("IntValue")
	goldVal.Name = "Gold"
	goldVal.Value = 50 -- Starting 50 Gold as confirmed by user
	goldVal.Parent = leaderstats

	local qiVal = Instance.new("IntValue")
	qiVal.Name = "Qi"
	qiVal.Value = 0 -- Starting at 0 Qi as requested
	qiVal.Parent = leaderstats

	-- 2. Create Inventory Folder
	local inventory = Instance.new("Folder")
	inventory.Name = "Inventory"
	inventory.Parent = player

	-- 3. Default Attributes (Qi Condensation Level 0)
	player:SetAttribute("Realm", "Qi Condensation")
	player:SetAttribute("RealmLevel", 0)
	player:SetAttribute("Qi", 0)
	player:SetAttribute("Cultivating", false)
	player:SetAttribute("Damage", 15)
	player:SetAttribute("Defense", 5)
	player:SetAttribute("MaxHealth", 100)
	player:SetAttribute("EquippedWeapon", "None")
	player:SetAttribute("EquippedArmor", "None")
	player:SetAttribute("Talent", "Mortal")
	player:SetAttribute("SpiritualRoot", "None")
	player:SetAttribute("TalentSpins", 0)
	player:SetAttribute("RootSpins", 0)
	player:SetAttribute("QiMultiplier", 1.0)
	player:SetAttribute("PillBuffExpiry", 0)

	-- Default skill hotbar slots
	for slotIdx = 1, 4 do
		local defaultSkill = SkillConfig.DefaultSlots[slotIdx] or "Sword Slash"
		player:SetAttribute("SkillSlot" .. slotIdx, defaultSkill)
	end

	-- Sync leaderstats.Qi with attribute Qi
	qiVal.Changed:Connect(function(newVal)
		player:SetAttribute("Qi", newVal)
	end)

	-- 4. Load from DataStore
	local userId = player.UserId
	local savedData = nil
	local fetchSuccess = false

	if playerDataStore then
		for attempt = 1, 3 do
			local success, result = pcall(function()
				return playerDataStore:GetAsync("User_" .. userId)
			end)
			if success then
				fetchSuccess = true
				savedData = result
				break
			else
				warn(string.format("[PlayerData] GetAsync attempt %d failed for %s (%d): %s", attempt, player.Name, userId, tostring(result)))
				task.wait(0.5 * attempt)
			end
		end
	else
		fetchSuccess = false
	end

	-- If DataStore call failed even after retries, do NOT allow saving this session to prevent wiping data
	if not fetchSuccess and playerDataStore then
		warn(string.format("[PlayerData] Could not safely load profile for %s (%d). Saving is disabled for this session.", player.Name, userId))
		return
	end

	loadedProfiles[userId] = true

	if savedData and typeof(savedData) == "table" then
		goldVal.Value = savedData.Gold or 50
		qiVal.Value = savedData.Qi or 0
		player:SetAttribute("Realm", savedData.Realm or "Qi Condensation")
		player:SetAttribute("RealmLevel", savedData.RealmLevel or 0)
		player:SetAttribute("EquippedWeapon", savedData.EquippedWeapon or "None")
		player:SetAttribute("EquippedArmor", savedData.EquippedArmor or "None")
		player:SetAttribute("Talent", savedData.Talent or "Mortal")
		player:SetAttribute("SpiritualRoot", savedData.SpiritualRoot or "None")
		player:SetAttribute("TalentSpins", savedData.TalentSpins or 0)
		player:SetAttribute("RootSpins", savedData.RootSpins or 0)

		if savedData.SkillSlots and typeof(savedData.SkillSlots) == "table" then
			for slotIdx = 1, 4 do
				local sName = savedData.SkillSlots[slotIdx] or savedData.SkillSlots[tostring(slotIdx)]
				if typeof(sName) == "string" and SkillConfig.Skills[sName] then
					player:SetAttribute("SkillSlot" .. slotIdx, sName)
				end
			end
		end

		if savedData.Inventory and typeof(savedData.Inventory) == "table" then
			for itemName, qty in pairs(savedData.Inventory) do
				if typeof(qty) == "number" and qty > 0 then
					local itmVal = Instance.new("IntValue")
					itmVal.Name = tostring(itemName)
					itmVal.Value = qty
					itmVal.Parent = inventory
				end
			end
		end
	else
		-- New player starter gift: 2 Lesser Qi Pills
		local starterPill = Instance.new("IntValue")
		starterPill.Name = "Lesser Qi Pill"
		starterPill.Value = 2
		starterPill.Parent = inventory
	end

	-- Recalculate stats based on realm and equipped gear
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

	player:SetAttribute("Damage", baseDmg)
	player:SetAttribute("Defense", baseDef)
	player:SetAttribute("MaxHealth", baseHp)

	if player.Character then
		applyCharacterStats(player, player.Character)
		setupPlayerOverhead(player, player.Character)
	end
	player.CharacterAdded:Connect(function(char)
		applyCharacterStats(player, char)
		setupPlayerOverhead(player, char)
	end)

	-- Debounced auto-save on major progression milestones (Breakthrough to new Realm / RealmLevel)
	local milestoneDebounce = false
	local function triggerMilestoneSave()
		if milestoneDebounce or not loadedProfiles[userId] then return end
		milestoneDebounce = true
		task.delay(1.5, function()
			milestoneDebounce = false
			if player and player.Parent and loadedProfiles[userId] then
				savePlayerData(player)
			end
		end)
	end
	player:GetAttributeChangedSignal("Realm"):Connect(triggerMilestoneSave)
	player:GetAttributeChangedSignal("RealmLevel"):Connect(triggerMilestoneSave)

	print(string.format("[PlayerData] Initialized profile for %s (Realm: %s · %d, Gold: %d)", player.Name, realmName, player:GetAttribute("RealmLevel") or 0, goldVal.Value))
end

function savePlayerData(player: Player): boolean
	local userId = player.UserId
	if not loadedProfiles[userId] or not playerDataStore then return false end

	local leaderstats = player:FindFirstChild("leaderstats")
	local goldVal = leaderstats and leaderstats:FindFirstChild("Gold") and (leaderstats:FindFirstChild("Gold") :: IntValue).Value or 0
	local qiVal = leaderstats and leaderstats:FindFirstChild("Qi") and (leaderstats:FindFirstChild("Qi") :: IntValue).Value or 0

	local invTable = {}
	local inventory = player:FindFirstChild("Inventory")
	if inventory then
		for _, child in ipairs(inventory:GetChildren()) do
			if child:IsA("IntValue") and child.Value > 0 then
				invTable[child.Name] = child.Value
			end
		end
	end

	local skillSlotsTable = {}
	for slotIdx = 1, 4 do
		skillSlotsTable[slotIdx] = player:GetAttribute("SkillSlot" .. slotIdx) or SkillConfig.DefaultSlots[slotIdx] or "Sword Slash"
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
		TalentSpins = player:GetAttribute("TalentSpins") or 0,
		RootSpins = player:GetAttribute("RootSpins") or 0,
		Inventory = invTable,
		SkillSlots = skillSlotsTable,
	}

	local saveSuccess = false
	for attempt = 1, 3 do
		local success, err = pcall(function()
			playerDataStore:SetAsync("User_" .. userId, dataToSave)
		end)
		if success then
			saveSuccess = true
			break
		else
			warn(string.format("[PlayerData] SetAsync attempt %d failed for %s (%d): %s", attempt, player.Name, userId, tostring(err)))
			task.wait(0.3 * attempt)
		end
	end

	return saveSuccess
end

local function onPlayerRemoving(player: Player)
	savePlayerData(player)
	loadedProfiles[player.UserId] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, p)
end

-- Auto-save loop every 3 minutes
task.spawn(function()
	while true do
		task.wait(180)
		for _, p in ipairs(Players:GetPlayers()) do
			savePlayerData(p)
		end
	end
end)

game:BindToClose(function()
	local players = Players:GetPlayers()
	local total = #players
	if total == 0 then return end

	local completed = 0
	for _, p in ipairs(players) do
		task.spawn(function()
			savePlayerData(p)
			completed += 1
		end)
	end

	local timeout = os.clock() + 4.0
	while completed < total and os.clock() < timeout do
		task.wait(0.1)
	end
	print(string.format("[PlayerData] BindToClose finished saving %d/%d players.", completed, total))
end)