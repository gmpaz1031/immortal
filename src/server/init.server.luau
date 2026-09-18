local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local DataStoreService = game:GetService("DataStoreService")

local cultivationRemote = ReplicatedStorage:WaitForChild("CultivationRemote")
local punchCooldowns = {}

-- Safe DataStore setup (falls back gracefully if API access is disabled in Studio)
local playerDataStore = nil
pcall(function()
	playerDataStore = DataStoreService:GetDataStore("CultivationData_v1")
end)

--------------------------------------------------------------------------------
-- Item Catalog Definitions
--------------------------------------------------------------------------------
local SHOP_ITEMS = {
	["Qi Condensation Pill"] = {
		Price = 30,
		Rarity = "Rare",
		Description = "Concentrated spiritual essence pill. Amplifies Qi gathering speed by 2x for 5 minutes."
	},
	["Lesser Qi Pill"] = {
		Price = 15,
		Rarity = "Common",
		Description = "Spiritual nourishment. Instantly restores +50 Qi."
	},
	["Spirit Spring Elixir"] = {
		Price = 20,
		Rarity = "Uncommon",
		Description = "Sacred mountain dew. Instantly restores 100% of your Total Health."
	},
	["Helmet"] = {
		Price = 80,
		Rarity = "Uncommon",
		Description = "Sturdy martial helmet. Adds +10 Total Health and +10 Defense."
	},
	["Armor"] = {
		Price = 100,
		Rarity = "Rare",
		Description = "Forged warrior armor. Adds +10 Total Health and +10 Defense."
	}
}

--------------------------------------------------------------------------------
-- Realm Requirements & Calculations
--------------------------------------------------------------------------------
local function requirementFor(player)
	if player:GetAttribute("Realm") ~= "Qi Condensation" then
		return nil
	end

	local level = player:GetAttribute("RealmLevel") or 0
	return math.floor(100 * (2.5 ^ level) + 0.5)
end

local function updatePlayerStats(player)
	local level = player:GetAttribute("RealmLevel") or 0
	local baseDmg = 10 + (level * 5)
	local baseQiMult = 1.0 + (level * 0.25)
	local luckVal = 10 + (level * 2)

	local expiry = player:GetAttribute("PillBuffExpiry") or 0
	local isPillActive = expiry > os.time()
	local pillMult = isPillActive and (player:GetAttribute("PillMultiplier") or 2) or 1
	local effectiveQiMult = baseQiMult * pillMult

	-- Calculate Equipment Bonuses (+10 Health & +10 Defense per equipped piece)
	local hasHelmet = player:GetAttribute("EquippedHelmet") == true
	local hasArmor = player:GetAttribute("EquippedArmor") == true
	local defenseVal = 0
	local bonusMaxHp = 0

	if hasHelmet then
		defenseVal = defenseVal + 10
		bonusMaxHp = bonusMaxHp + 10
	end
	if hasArmor then
		defenseVal = defenseVal + 10
		bonusMaxHp = bonusMaxHp + 10
	end

	player:SetAttribute("Damage", baseDmg)
	player:SetAttribute("BaseQiMultiplier", baseQiMult)
	player:SetAttribute("QiMultiplier", effectiveQiMult)
	player:SetAttribute("Luck", luckVal)
	player:SetAttribute("Defense", defenseVal)

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		local newMaxHp = 100 + bonusMaxHp
		if hum.MaxHealth ~= newMaxHp then
			local diff = newMaxHp - hum.MaxHealth
			hum.MaxHealth = newMaxHp
			hum.Health = math.clamp(hum.Health + diff, 1, newMaxHp)
		end
	end
end

--------------------------------------------------------------------------------
-- Cosmetic Equipment Attachment (Helmet & Armor 3D Visual Models)
--------------------------------------------------------------------------------
local function updateEquippedCosmetics(player)
	local character = player.Character
	if not character then return end
	local head = character:FindFirstChild("Head")
	local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
	if not head or not torso then return end

	-- 1. Helmet Cosmetic
	local existingHelm = character:FindFirstChild("EquippedHelmetModel")
	if player:GetAttribute("EquippedHelmet") then
		if not existingHelm then
			local helmModel = Instance.new("Model")
			helmModel.Name = "EquippedHelmetModel"

			local helmPart = Instance.new("Part")
			helmPart.Name = "HelmetPart"
			helmPart.Size = Vector3.new(1.35, 0.6, 1.35)
			helmPart.Color = Color3.fromRGB(65, 70, 80)
			helmPart.Material = Enum.Material.Metal
			helmPart.CanCollide = false
			helmPart.Anchored = false
			helmPart.CFrame = head.CFrame * CFrame.new(0, 0.45, 0)
			helmPart.Parent = helmModel

			-- Golden Forehead Crest
			local crest = Instance.new("Part")
			crest.Name = "HelmetCrest"
			crest.Size = Vector3.new(0.5, 0.4, 0.2)
			crest.Color = Color3.fromRGB(230, 185, 45)
			crest.Material = Enum.Material.Neon
			crest.CanCollide = false
			crest.Anchored = false
			crest.CFrame = head.CFrame * CFrame.new(0, 0.5, -0.68)
			crest.Parent = helmModel

			local weld1 = Instance.new("WeldConstraint")
			weld1.Part0 = head
			weld1.Part1 = helmPart
			weld1.Parent = helmPart

			local weld2 = Instance.new("WeldConstraint")
			weld2.Part0 = head
			weld2.Part1 = crest
			weld2.Parent = crest

			helmModel.Parent = character
		end
	else
		if existingHelm then
			existingHelm:Destroy()
		end
	end

	-- 2. Armor Cosmetic (Chestplate + Pauldrons)
	local existingArmor = character:FindFirstChild("EquippedArmorModel")
	if player:GetAttribute("EquippedArmor") then
		if not existingArmor then
			local armorModel = Instance.new("Model")
			armorModel.Name = "EquippedArmorModel"

			-- Chestplate
			local chest = Instance.new("Part")
			chest.Name = "Chestplate"
			chest.Size = Vector3.new(2.1, 1.8, 1.15)
			chest.Color = Color3.fromRGB(50, 55, 65)
			chest.Material = Enum.Material.Metal
			chest.CanCollide = false
			chest.Anchored = false
			chest.CFrame = torso.CFrame
			chest.Parent = armorModel

			local chestWeld = Instance.new("WeldConstraint")
			chestWeld.Part0 = torso
			chestWeld.Part1 = chest
			chestWeld.Parent = chest

			-- Pauldrons (Left & Right Shoulders)
			for _, xOff in ipairs({ -1.3, 1.3 }) do
				local pauldron = Instance.new("Part")
				pauldron.Name = "Pauldron"
				pauldron.Size = Vector3.new(0.9, 0.5, 1.2)
				pauldron.Color = Color3.fromRGB(210, 160, 40)
				pauldron.Material = Enum.Material.Metal
				pauldron.CanCollide = false
				pauldron.Anchored = false
				pauldron.CFrame = torso.CFrame * CFrame.new(xOff, 0.8, 0)
				pauldron.Parent = armorModel

				local pWeld = Instance.new("WeldConstraint")
				pWeld.Part0 = torso
				pWeld.Part1 = pauldron
				pWeld.Parent = pauldron
			end

			armorModel.Parent = character
		end
	else
		if existingArmor then
			existingArmor:Destroy()
		end
	end
end

--------------------------------------------------------------------------------
-- Dynamic Combat Tool Creation
--------------------------------------------------------------------------------
local function createCombatTool()
	local tool = Instance.new("Tool")
	tool.Name = "Combat"
	tool.CanBeDropped = false
	tool.RequiresHandle = false
	tool.ToolTip = "Click to punch enemies · 10 damage"

	local clientScript = Instance.new("LocalScript")
	clientScript.Name = "CombatClient"
	clientScript.Source = [[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local tool = script.Parent
local remote = ReplicatedStorage:WaitForChild("CultivationRemote")
local cooldown = false

local function playPunchAnimation()
	local character = player.Character
	local shoulder = character and character:FindFirstChild("RightShoulder", true)
	if not shoulder or not shoulder:IsA("Motor6D") then
		return
	end

	local original = shoulder.Transform
	shoulder.Transform = CFrame.Angles(math.rad(-75), 0, math.rad(20))
	task.delay(0.1, function()
		if shoulder.Parent then
			shoulder.Transform = CFrame.Angles(math.rad(20), 0, math.rad(-8))
		end
	end)
	task.delay(0.2, function()
		if shoulder.Parent then
			shoulder.Transform = original
		end
	end)
end

tool.Activated:Connect(function()
	if cooldown or tool.Parent ~= player.Character or player:GetAttribute("Cultivating") then
		return
	end

	cooldown = true
	playPunchAnimation()
	remote:FireServer("Punch")
	task.delay(0.45, function()
		cooldown = false
	end)
end)
]]
	clientScript.Parent = tool
	return tool
end

local function ensureCombatTool(player)
	local backpack = player:WaitForChild("Backpack", 5)
	if not backpack then return end
	local character = player.Character

	local hasInBackpack = backpack:FindFirstChild("Combat")
	local hasInChar = character and character:FindFirstChild("Combat")

	if not hasInBackpack and not hasInChar then
		local newTool = createCombatTool()
		newTool.Parent = backpack
	end

	local starterPack = game:GetService("StarterPack")
	if not starterPack:FindFirstChild("Combat") then
		local spTool = createCombatTool()
		spTool.Parent = starterPack
	end
end

--------------------------------------------------------------------------------
-- Character Status & Cultivation Anchoring
--------------------------------------------------------------------------------
local function updateCharacterStatus(player, isCultivating)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	local head = character:FindFirstChild("Head")
	local status = character:FindFirstChild("CultivatingStatus")
	if status and head then
		status.Adornee = head
		status.Enabled = isCultivating
	end

	if root then
		root.Anchored = isCultivating
	end

	if humanoid then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, not isCultivating)

		if isCultivating then
			if humanoid.WalkSpeed > 0 then
				player:SetAttribute("CultivationWalkSpeed", humanoid.WalkSpeed)
			end
			if humanoid.UseJumpPower then
				if humanoid.JumpPower > 0 then
					player:SetAttribute("CultivationJumpPower", humanoid.JumpPower)
				end
			else
				if humanoid.JumpHeight > 0 then
					player:SetAttribute("CultivationJumpHeight", humanoid.JumpHeight)
				end
			end

			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
			humanoid.JumpHeight = 0
		else
			local savedSpeed = player:GetAttribute("CultivationWalkSpeed")
			if not savedSpeed or savedSpeed <= 0 then
				savedSpeed = 16
			end
			humanoid.WalkSpeed = savedSpeed

			local savedJump = player:GetAttribute("CultivationJumpPower")
			if not savedJump or savedJump <= 0 then
				savedJump = 50
			end
			humanoid.JumpPower = savedJump

			local savedHeight = player:GetAttribute("CultivationJumpHeight")
			if not savedHeight or savedHeight <= 0 then
				savedHeight = 7.2
			end
			humanoid.JumpHeight = savedHeight

			humanoid.Sit = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end
end

local function setCultivating(player, isCultivating)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if isCultivating then
		if not humanoid or humanoid.Health <= 0 then
			return
		end
		if humanoid.FloorMaterial == Enum.Material.Air then
			return
		end
	end

	player:SetAttribute("Cultivating", isCultivating)
	updateCharacterStatus(player, isCultivating)
end

--------------------------------------------------------------------------------
-- Enemy Configuration & Combat
--------------------------------------------------------------------------------
local function isEnemyHumanoid(humanoid)
	local model = humanoid.Parent
	return model and model:IsA("Model") and not Players:GetPlayerFromCharacter(model)
end

local function configureEnemy(humanoid)
	if isEnemyHumanoid(humanoid) then
		humanoid.MaxHealth = 50
		humanoid.Health = 50
	end
end

for _, instance in Workspace:GetDescendants() do
	if instance:IsA("Humanoid") then
		configureEnemy(instance)
	end
end

Workspace.DescendantAdded:Connect(function(instance)
	if instance:IsA("Humanoid") then
		configureEnemy(instance)
	end
end)

local function punchNearbyEnemies(player)
	if player:GetAttribute("Cultivating") then
		return
	end

	local now = time()
	if punchCooldowns[player] and now - punchCooldowns[player] < 0.45 then
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	punchCooldowns[player] = now
	local baseDamage = player:GetAttribute("Damage") or 10
	for _, instance in Workspace:GetDescendants() do
		if instance:IsA("Humanoid") and instance.Health > 0 and isEnemyHumanoid(instance) then
			local enemyRoot = instance.Parent:FindFirstChild("HumanoidRootPart")
			if enemyRoot and (enemyRoot.Position - root.Position).Magnitude <= 8 then
				instance:TakeDamage(baseDamage)
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Inventory Helpers
--------------------------------------------------------------------------------
local function getInventoryFolder(player)
	local inv = player:FindFirstChild("Inventory")
	if not inv then
		inv = Instance.new("Folder")
		inv.Name = "Inventory"
		inv.Parent = player
	end
	return inv
end

local function addInventoryItem(player, itemName, count)
	local inv = getInventoryFolder(player)
	local itemVal = inv:FindFirstChild(itemName)
	if not itemVal then
		itemVal = Instance.new("IntValue")
		itemVal.Name = itemName
		itemVal.Value = 0
		itemVal.Parent = inv
	end
	itemVal.Value = itemVal.Value + (count or 1)
end

local function setInventoryItem(player, itemName, count)
	local inv = getInventoryFolder(player)
	local itemVal = inv:FindFirstChild(itemName)
	if not itemVal then
		itemVal = Instance.new("IntValue")
		itemVal.Name = itemName
		itemVal.Value = 0
		itemVal.Parent = inv
	end
	itemVal.Value = math.max(0, count or 0)
end

local function getInventoryItemCount(player, itemName)
	local inv = getInventoryFolder(player)
	local itemVal = inv:FindFirstChild(itemName)
	return itemVal and itemVal.Value or 0
end

local function consumeInventoryItem(player, itemName)
	local inv = getInventoryFolder(player)
	local itemVal = inv:FindFirstChild(itemName)
	if itemVal and itemVal.Value > 0 then
		itemVal.Value = itemVal.Value - 1
		return true
	end
	return false
end

--------------------------------------------------------------------------------
-- Auto-Save & Data Persistence System
--------------------------------------------------------------------------------
local function serializePlayerData(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local goldVal = leaderstats and leaderstats:FindFirstChild("Gold") and leaderstats.Gold.Value or 0

	local invFolder = player:FindFirstChild("Inventory")
	local invTable = {}
	if invFolder then
		for _, child in ipairs(invFolder:GetChildren()) do
			if child:IsA("IntValue") and child.Value > 0 then
				invTable[child.Name] = child.Value
			end
		end
	end

	local data = {
		Gold = goldVal,
		Qi = player:GetAttribute("Qi") or 0,
		Realm = player:GetAttribute("Realm") or "Qi Condensation",
		RealmLevel = player:GetAttribute("RealmLevel") or 0,
		PillBuffExpiry = player:GetAttribute("PillBuffExpiry") or 0,
		EquippedHelmet = player:GetAttribute("EquippedHelmet") or false,
		EquippedArmor = player:GetAttribute("EquippedArmor") or false,
		Inventory = invTable,
		SavedAt = os.time()
	}
	return data
end

local function savePlayerData(player)
	if not playerDataStore then return end
	local key = "Player_" .. tostring(player.UserId)
	local data = serializePlayerData(player)
	local success, err = pcall(function()
		playerDataStore:SetAsync(key, data)
	end)
	if success then
		print(string.format("💾 [AutoSave] Successfully saved data for %s (Gold: %d, Qi: %d, Level: %d)", player.Name, data.Gold, data.Qi, data.RealmLevel))
	else
		warn(string.format("⚠️ [AutoSave] Failed to save data for %s: %s", player.Name, tostring(err)))
	end
end

local function loadPlayerData(player)
	if not playerDataStore then return false end
	local key = "Player_" .. tostring(player.UserId)
	local success, savedData = pcall(function()
		return playerDataStore:GetAsync(key)
	end)

	if success and savedData and type(savedData) == "table" then
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats and leaderstats:FindFirstChild("Gold") and savedData.Gold then
			leaderstats.Gold.Value = savedData.Gold
		end

		if savedData.Qi then player:SetAttribute("Qi", savedData.Qi) end
		if savedData.Realm then player:SetAttribute("Realm", savedData.Realm) end
		if savedData.RealmLevel then player:SetAttribute("RealmLevel", savedData.RealmLevel) end
		if savedData.PillBuffExpiry then player:SetAttribute("PillBuffExpiry", savedData.PillBuffExpiry) end
		if savedData.EquippedHelmet ~= nil then player:SetAttribute("EquippedHelmet", savedData.EquippedHelmet) end
		if savedData.EquippedArmor ~= nil then player:SetAttribute("EquippedArmor", savedData.EquippedArmor) end

		if savedData.Inventory and type(savedData.Inventory) == "table" then
			for itemName, count in pairs(savedData.Inventory) do
				setInventoryItem(player, itemName, count)
			end
		end

		print(string.format("📂 [AutoSave] Successfully loaded profile for %s (Gold: %d, Qi: %d, Level: %d)", player.Name, savedData.Gold or 0, savedData.Qi or 0, savedData.RealmLevel or 0))
		return true
	end
	return false
end

--------------------------------------------------------------------------------
-- Player Setup & Lifecycle
--------------------------------------------------------------------------------
local function setupPlayer(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local gold = Instance.new("IntValue")
	gold.Name = "Gold"
	gold.Value = 50 -- Starting gold for new players
	gold.Parent = leaderstats

	player:SetAttribute("Qi", 0)
	player:SetAttribute("Realm", "Qi Condensation")
	player:SetAttribute("RealmLevel", 0)
	player:SetAttribute("Cultivating", false)
	player:SetAttribute("CultivationWalkSpeed", 16)
	player:SetAttribute("CultivationJumpPower", 50)
	player:SetAttribute("CultivationJumpHeight", 7.2)
	player:SetAttribute("BreakingThrough", false)
	player:SetAttribute("PillBuffExpiry", 0)
	player:SetAttribute("PillMultiplier", 2)
	player:SetAttribute("Defense", 0)
	player:SetAttribute("EquippedHelmet", false)
	player:SetAttribute("EquippedArmor", false)

	-- Default starter inventory
	addInventoryItem(player, "Qi Condensation Pill", 1)

	-- Load saved data if available
	local loaded = loadPlayerData(player)
	if not loaded then
		print(string.format("✨ [AutoSave] Initialized new profile for %s", player.Name))
	end

	updatePlayerStats(player)

	local function onCharacter(character)
		player:SetAttribute("Cultivating", false)
		player:SetAttribute("BreakingThrough", false)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if humanoid then
			humanoid.Died:Connect(function()
				if player:GetAttribute("Cultivating") then
					setCultivating(player, false)
				end
			end)
		end
		updateCharacterStatus(player, false)
		ensureCombatTool(player)
		updatePlayerStats(player)
		updateEquippedCosmetics(player)
	end

	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
	ensureCombatTool(player)

	-- 1-second Qi gathering loop with active Pill Multiplier support
	task.spawn(function()
		while player.Parent do
			task.wait(1)
			updatePlayerStats(player)

			if player:GetAttribute("Cultivating") then
				local character = player.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					local mult = player:GetAttribute("QiMultiplier") or 1
					local gained = math.floor(5 * mult + 0.5)
					player:SetAttribute("Qi", (player:GetAttribute("Qi") or 0) + gained)
				else
					setCultivating(player, false)
				end
			end
		end
	end)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do
	setupPlayer(player)
end

-- Save on Player Leave
Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
end)

-- Auto-Save Loop every 60 seconds
task.spawn(function()
	while true do
		task.wait(60)
		for _, player in ipairs(Players:GetPlayers()) do
			savePlayerData(player)
		end
	end
end)

-- Save on Server Shutdown / BindToClose
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayerData(player)
	end
	task.wait(1.5)
end)

--------------------------------------------------------------------------------
-- In-World Shop Merchant NPC & Neon Circle
--------------------------------------------------------------------------------
local function spawnShopMerchant()
	local existing = Workspace:FindFirstChild("ShopMerchant")
	if existing then return existing end

	local merchantPos = Vector3.new(20, 0, -10)

	-- 1. Neon Circle on the ground
	local circle = Instance.new("Part")
	circle.Name = "ShopCircle"
	circle.Shape = Enum.PartType.Cylinder
	circle.Size = Vector3.new(0.3, 16, 16)
	circle.CFrame = CFrame.new(merchantPos + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
	circle.Material = Enum.Material.Neon
	circle.Color = Color3.fromRGB(0, 230, 255)
	circle.Anchored = true
	circle.CanCollide = false
	circle.CastShadow = false
	circle.Parent = Workspace

	-- 2. Merchant Model
	local model = Instance.new("Model")
	model.Name = "ShopMerchant"

	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.CFrame = CFrame.new(merchantPos + Vector3.new(0, 3, 0))
	hrp.Transparency = 1
	hrp.Anchored = true
	hrp.CanCollide = false
	hrp.Parent = model
	model.PrimaryPart = hrp

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.CFrame = hrp.CFrame
	torso.Color = Color3.fromRGB(45, 25, 65)
	torso.Anchored = true
	torso.CanCollide = true
	torso.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.CFrame = hrp.CFrame + Vector3.new(0, 1.6, 0)
	head.Color = Color3.fromRGB(245, 215, 175)
	head.Anchored = true
	head.CanCollide = true
	head.Parent = model

	local leftArm = Instance.new("Part")
	leftArm.Name = "Left Arm"
	leftArm.Size = Vector3.new(1, 2, 1)
	leftArm.CFrame = hrp.CFrame + Vector3.new(-1.5, 0, 0)
	leftArm.Color = Color3.fromRGB(255, 215, 80)
	leftArm.Anchored = true
	leftArm.CanCollide = true
	leftArm.Parent = model

	local rightArm = Instance.new("Part")
	rightArm.Name = "Right Arm"
	rightArm.Size = Vector3.new(1, 2, 1)
	rightArm.CFrame = hrp.CFrame + Vector3.new(1.5, 0, 0)
	rightArm.Color = Color3.fromRGB(255, 215, 80)
	rightArm.Anchored = true
	rightArm.CanCollide = true
	rightArm.Parent = model

	local leftLeg = Instance.new("Part")
	leftLeg.Name = "Left Leg"
	leftLeg.Size = Vector3.new(1, 2, 1)
	leftLeg.CFrame = hrp.CFrame + Vector3.new(-0.5, -2, 0)
	leftLeg.Color = Color3.fromRGB(30, 18, 45)
	leftLeg.Anchored = true
	leftLeg.CanCollide = true
	leftLeg.Parent = model

	local rightLeg = Instance.new("Part")
	rightLeg.Name = "Right Leg"
	rightLeg.Size = Vector3.new(1, 2, 1)
	rightLeg.CFrame = hrp.CFrame + Vector3.new(0.5, -2, 0)
	rightLeg.Color = Color3.fromRGB(30, 18, 45)
	rightLeg.Anchored = true
	rightLeg.CanCollide = true
	rightLeg.Parent = model

	-- Floating BillboardGui
	local bbg = Instance.new("BillboardGui")
	bbg.Name = "ShopLabel"
	bbg.AlwaysOnTop = true
	bbg.Size = UDim2.new(0, 240, 0, 60)
	bbg.StudsOffset = Vector3.new(0, 3.8, 0)
	bbg.Adornee = head
	bbg.Parent = model

	local titleLbl = Instance.new("TextLabel")
	titleLbl.BackgroundTransparency = 1
	titleLbl.Size = UDim2.new(1, 0, 0.55, 0)
	titleLbl.Font = Enum.Font.GothamBlack
	titleLbl.Text = "🛒 PILL SHOP"
	titleLbl.TextColor3 = Color3.fromRGB(255, 215, 80)
	titleLbl.TextScaled = true
	titleLbl.Parent = bbg

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(40, 20, 10)
	titleStroke.Thickness = 1.8
	titleStroke.Parent = titleLbl

	local subLbl = Instance.new("TextLabel")
	subLbl.BackgroundTransparency = 1
	subLbl.Position = UDim2.new(0, 0, 0.55, 0)
	subLbl.Size = UDim2.new(1, 0, 0.45, 0)
	subLbl.Font = Enum.Font.GothamBold
	subLbl.Text = "[E] Click or Walk Close"
	subLbl.TextColor3 = Color3.fromRGB(0, 235, 255)
	subLbl.TextScaled = true
	subLbl.Parent = bbg

	-- ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Pill Pavilion"
	prompt.ActionText = "Browse Shop"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = hrp

	prompt.Triggered:Connect(function(player)
		cultivationRemote:FireClient(player, "OpenShop")
	end)

	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 18
	clickDetector.Parent = model

	clickDetector.MouseClick:Connect(function(player)
		cultivationRemote:FireClient(player, "OpenShop")
	end)

	-- Stepping on circle opens shop
	local touchDebounce = {}
	circle.Touched:Connect(function(hit)
		local char = hit.Parent
		local player = Players:GetPlayerFromCharacter(char)
		if player and (not touchDebounce[player] or tick() - touchDebounce[player] > 3) then
			touchDebounce[player] = tick()
			cultivationRemote:FireClient(player, "OpenShop")
		end
	end)

	model.Parent = Workspace
end

task.spawn(spawnShopMerchant)

task.spawn(function()
	task.wait(1)
	local vg = script:WaitForChild("VillageGenerator", 5)
	if vg then
		local ok, mod = pcall(require, vg)
		if ok and mod and mod.generate then
			mod.generate()
		end
	end

	-- Initialize Bandit Stronghold Village
	local bv = script:WaitForChild("BanditVillage", 5)
	if bv then
		local ok, mod = pcall(require, bv)
		if ok and mod and mod.generate then
			mod.generate()
		end
	end

	-- Initialize Bandit Enemies & Boss AI
	local bm = script:WaitForChild("BanditManager", 5)
	if bm then
		local ok, mod = pcall(require, bm)
		if ok and mod and mod.init then
			mod.init()
		end
	end

	-- Initialize Combat Skill System Service
	local ss = script:WaitForChild("SkillService", 5)
	if ss then
		local ok, err = pcall(function()
			local mod = require(ss)
			if mod and mod.init then
				mod.init()
			end
		end)
		if not ok then
			warn("❌ [SkillService] Failed to initialize:", err)
		end
	else
		warn("⚠️ [SkillService] SkillService ModuleScript not found in Server!")
	end
end)

--------------------------------------------------------------------------------
-- Remote Event Router & Admin Commands
--------------------------------------------------------------------------------
cultivationRemote.OnServerEvent:Connect(function(player, action, ...)
	local args = { ... }

	if action == "Cultivate" then
		setCultivating(player, not player:GetAttribute("Cultivating"))
		return
	end

	if action == "Punch" then
		punchNearbyEnemies(player)
		return
	end

	if action == "Breakthrough" then
		if player:GetAttribute("BreakingThrough") then
			return
		end

		local required = requirementFor(player)
		local qi = player:GetAttribute("Qi") or 0
		if not required or qi < required then
			return
		end

		if player:GetAttribute("Cultivating") then
			setCultivating(player, false)
		end

		player:SetAttribute("BreakingThrough", true)
		cultivationRemote:FireAllClients("BreakthroughStart", player)

		task.delay(2.6, function()
			if not player.Parent then return end

			local reqNow = requirementFor(player)
			local qiNow = player:GetAttribute("Qi") or 0
			if not reqNow or qiNow < reqNow then
				player:SetAttribute("BreakingThrough", false)
				return
			end

			player:SetAttribute("Qi", qiNow - reqNow)
			local level = player:GetAttribute("RealmLevel") or 0
			if level < 10 then
				player:SetAttribute("RealmLevel", level + 1)
			else
				player:SetAttribute("Realm", "Bone Forging Realm")
				player:SetAttribute("RealmLevel", 1)
			end
			updatePlayerStats(player)
			savePlayerData(player)

			cultivationRemote:FireAllClients("BreakthroughBurst", player)

			task.delay(1.2, function()
				if player.Parent then
					player:SetAttribute("BreakingThrough", false)
				end
			end)
		end)
		return
	end

	-- Shop Buy Action
	if action == "BuyItem" then
		local itemName = args[1]
		local itemData = SHOP_ITEMS[itemName]
		if not itemData then return end

		local leaderstats = player:FindFirstChild("leaderstats")
		local gold = leaderstats and leaderstats:FindFirstChild("Gold")
		if not gold or gold.Value < itemData.Price then
			cultivationRemote:FireClient(player, "Notification", "Not enough Gold!")
			return
		end

		gold.Value = gold.Value - itemData.Price
		addInventoryItem(player, itemName, 1)
		savePlayerData(player)
		cultivationRemote:FireClient(player, "Notification", "Purchased " .. itemName .. "!")
		return
	end

	-- Inventory Use Action
	if action == "UseItem" then
		local itemName = args[1]
		if not itemName then return end

		local count = getInventoryItemCount(player, itemName)
		if count <= 0 then
			cultivationRemote:FireClient(player, "Notification", "You do not have any " .. itemName .. "!")
			return
		end

		if itemName == "Qi Condensation Pill" then
			if consumeInventoryItem(player, itemName) then
				local currentExpiry = player:GetAttribute("PillBuffExpiry") or 0
				local now = os.time()
				local newExpiry = math.max(now, currentExpiry) + 300 -- 5 minutes (300s)
				player:SetAttribute("PillBuffExpiry", newExpiry)
				player:SetAttribute("PillMultiplier", 2)
				updatePlayerStats(player)
				savePlayerData(player)
				cultivationRemote:FireClient(player, "Notification", "Consumed Qi Condensation Pill! 2x Qi for 5 minutes!")
			end
		elseif itemName == "Lesser Qi Pill" then
			if consumeInventoryItem(player, itemName) then
				player:SetAttribute("Qi", (player:GetAttribute("Qi") or 0) + 50)
				savePlayerData(player)
				cultivationRemote:FireClient(player, "Notification", "Consumed Lesser Qi Pill! +50 Qi gained!")
			end
		elseif itemName == "Spirit Spring Elixir" then
			if consumeInventoryItem(player, itemName) then
				local char = player.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.Health = hum.MaxHealth
				end
				savePlayerData(player)
				cultivationRemote:FireClient(player, "Notification", "Drank Spirit Spring Elixir! Health fully restored!")
			end
		end
		return
	end

	-- Equip Item Action
	if action == "EquipItem" then
		local itemName = args[1]
		local count = getInventoryItemCount(player, itemName)
		if count <= 0 then
			cultivationRemote:FireClient(player, "Notification", "You do not own a " .. tostring(itemName) .. "!")
			return
		end

		if itemName == "Helmet" then
			player:SetAttribute("EquippedHelmet", true)
			updatePlayerStats(player)
			updateEquippedCosmetics(player)
			savePlayerData(player)
			cultivationRemote:FireClient(player, "Notification", "🛡️ Equipped Helmet! (+10 Max Health, +10 Defense)")
		elseif itemName == "Armor" then
			player:SetAttribute("EquippedArmor", true)
			updatePlayerStats(player)
			updateEquippedCosmetics(player)
			savePlayerData(player)
			cultivationRemote:FireClient(player, "Notification", "🛡️ Equipped Armor! (+10 Max Health, +10 Defense)")
		end
		return
	end

	-- Unequip Item Action
	if action == "UnequipItem" then
		local itemName = args[1]
		if itemName == "Helmet" then
			player:SetAttribute("EquippedHelmet", false)
			updatePlayerStats(player)
			updateEquippedCosmetics(player)
			savePlayerData(player)
			cultivationRemote:FireClient(player, "Notification", "Unequipped Helmet.")
		elseif itemName == "Armor" then
			player:SetAttribute("EquippedArmor", false)
			updatePlayerStats(player)
			updateEquippedCosmetics(player)
			savePlayerData(player)
			cultivationRemote:FireClient(player, "Notification", "Unequipped Armor.")
		end
		return
	end

	----------------------------------------------------------------------------
	-- Admin Panel Server Actions (Adds currency, qi, items, levels, save, etc.)
	----------------------------------------------------------------------------
	if action == "AdminAction" then
		local subAction = args[1]
		local param = args[2]

		if subAction == "AddGold" then
			local amount = tonumber(param) or 1000
			local leaderstats = player:FindFirstChild("leaderstats")
			local gold = leaderstats and leaderstats:FindFirstChild("Gold")
			if gold then
				gold.Value = math.max(0, gold.Value + amount)
				cultivationRemote:FireClient(player, "Notification", string.format("⚡ Admin: Added %d Gold!", amount))
			end
		elseif subAction == "AddQi" then
			local amount = tonumber(param) or 500
			local currentQi = player:GetAttribute("Qi") or 0
			player:SetAttribute("Qi", math.max(0, currentQi + amount))
			cultivationRemote:FireClient(player, "Notification", string.format("⚡ Admin: Added %d Qi!", amount))
		elseif subAction == "SetRealmLevel" then
			local newLevel = math.clamp(tonumber(param) or 0, 10)
			player:SetAttribute("RealmLevel", newLevel)
			updatePlayerStats(player)
			cultivationRemote:FireClient(player, "Notification", string.format("⚡ Admin: Set Realm Level to %d!", newLevel))
		elseif subAction == "AddItem" then
			local itemName = tostring(param)
			if SHOP_ITEMS[itemName] or itemName == "Qi Condensation Pill" or itemName == "Lesser Qi Pill" or itemName == "Spirit Spring Elixir" or itemName == "Helmet" or itemName == "Armor" then
				local qty = tonumber(args[3]) or 5
				addInventoryItem(player, itemName, qty)
				cultivationRemote:FireClient(player, "Notification", string.format("⚡ Admin: Added %dx %s!", qty, itemName))
			end
		elseif subAction == "HealFull" then
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.Health = hum.MaxHealth
				cultivationRemote:FireClient(player, "Notification", "⚡ Admin: Fully Healed Character!")
			end
		elseif subAction == "MaxBuff" then
			local now = os.time()
			player:SetAttribute("PillBuffExpiry", now + 3600) -- 1 hour buff
			player:SetAttribute("PillMultiplier", 5) -- 5x multiplier!
			updatePlayerStats(player)
			cultivationRemote:FireClient(player, "Notification", "⚡ Admin: Applied 5x Qi Mega-Buff (1 hour)!")
		elseif subAction == "SaveNow" then
			savePlayerData(player)
			cultivationRemote:FireClient(player, "Notification", "⚡ Admin: Force Saved Data to DataStore!")
		end

		savePlayerData(player)
		return
	end
end)
