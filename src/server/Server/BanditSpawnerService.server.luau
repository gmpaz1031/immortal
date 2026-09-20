--!strict
-- src/server/BanditSpawnerService.server.luau
-- Bandit Village Enemy Spawner & Loot System
-- Spawns enemies at exact positions in Workspace.BanditVillage using SAMPLEENEMYMODEL.
-- 1 Boss at Chieftain Dais + 5 Bandits across the village outpost.
-- Drop rates: Normal = 2% Qi Pill, 10% Weapon/Armor; Boss = 10% Qi Pill, 10% Weapon/Armor.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemConfig = require(Shared:WaitForChild("ItemConfig"))

local villageFolder = Workspace:FindFirstChild("BanditVillage")
local enemiesFolder = villageFolder or Workspace:FindFirstChild("Enemies")
if not enemiesFolder then
	enemiesFolder = Instance.new("Folder")
	enemiesFolder.Name = "Enemies"
	enemiesFolder.Parent = Workspace
end

-- Exact positions extracted from Workspace.BanditVillage
local BOSS_SPAWN = {
	pos = Vector3.new(-477.61, 11.70, -294.91),
	rotY = 180,
}

local BANDIT_SPAWNS = {
	{ name = "Bandit Scout - Lv 2",    pos = Vector3.new(-495.61, 9.20, -241.91), rotY = 0 },
	{ name = "Bandit Raider - Lv 3",   pos = Vector3.new(-459.61, 9.20, -241.91), rotY = 0 },
	{ name = "Bandit Marauder - Lv 2", pos = Vector3.new(-499.61, 9.20, -268.91), rotY = 0 },
	{ name = "Bandit Enforcer - Lv 3", pos = Vector3.new(-455.61, 9.20, -268.91), rotY = 0 },
	{ name = "Bandit Guard - Lv 2",    pos = Vector3.new(-477.61, 9.20, -222.91), rotY = 0 },
}

local function awardItemToPlayer(player: Player, itemName: string, qty: number)
	local inventory = player:FindFirstChild("Inventory")
	if not inventory then return end

	local itmVal = inventory:FindFirstChild(itemName) :: IntValue?
	if not itmVal then
		itmVal = Instance.new("IntValue")
		itmVal.Name = itemName
		itmVal.Value = 0
		itmVal.Parent = inventory
	end
	itmVal.Value = itmVal.Value + qty
end

local function showFloatingRewardText(position: Vector3, text: string, textColor: Color3)
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.5, 0.5, 0.5)
	part.Transparency = 1
	part.CanCollide = false
	part.Anchored = true
	part.Position = position + Vector3.new(0, 3, 0)
	part.Parent = Workspace

	local bbg = Instance.new("BillboardGui")
	bbg.Size = UDim2.new(0, 220, 0, 50)
	bbg.StudsOffset = Vector3.new(0, 2, 0)
	bbg.AlwaysOnTop = true
	bbg.Parent = part

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Font = Enum.Font.GothamBlack
	label.Text = text
	label.TextColor3 = textColor
	label.TextSize = 14
	label.Parent = bbg

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(15, 20, 20)
	stroke.Thickness = 1.5
	stroke.Parent = label

	task.spawn(function()
		for i = 1, 30 do
			part.Position = part.Position + Vector3.new(0, 0.1, 0)
			label.TextTransparency = i / 30
			stroke.Transparency = i / 30
			task.wait(0.04)
		end
		part:Destroy()
	end)
end

local function attachAccessory(model: Model, bodyPart: BasePart, accessory: BasePart, localOffset: CFrame)
	accessory.CanCollide = false
	accessory.Massless = true
	accessory.CFrame = bodyPart.CFrame * localOffset
	accessory.Parent = model

	local weld = Instance.new("Weld")
	weld.Name = accessory.Name .. "Weld"
	weld.Part0 = bodyPart
	weld.Part1 = accessory
	weld.C0 = localOffset
	weld.C1 = CFrame.new()
	weld.Parent = accessory
end

--- Styles an enemy model that has ALREADY been positioned at its actual spawn location
local function designEnemyModel(model: Model, isBoss: boolean, variantIndex: number)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = Instance.new("Humanoid")
		humanoid.Parent = model
	end
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.MaxHealth = isBoss and 600 or 120
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = isBoss and 14 or 16

	local head = model:FindFirstChild("Head") :: BasePart?
	local torso = model:FindFirstChild("Torso") :: BasePart?
	local leftArm = model:FindFirstChild("Left Arm") :: BasePart?
	local rightArm = model:FindFirstChild("Right Arm") :: BasePart?
	local leftLeg = model:FindFirstChild("Left Leg") :: BasePart?
	local rightLeg = model:FindFirstChild("Right Leg") :: BasePart?
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart? or torso
	model.PrimaryPart = root

	-- Clean old accessories/hats
	for _, ch in ipairs(model:GetChildren()) do
		if ch:IsA("Accessory") or ch:IsA("Shirt") or ch:IsA("Pants") or ch:IsA("ShirtGraphic") then
			ch:Destroy()
		end
	end

	local bodyColors = model:FindFirstChildOfClass("BodyColors")
	if not bodyColors then
		bodyColors = Instance.new("BodyColors")
		bodyColors.Parent = model
	end

	if isBoss then
		model.Name = "Bandit Boss - Iron Fiend"

		bodyColors.HeadColor3 = Color3.fromRGB(190, 145, 115)
		bodyColors.TorsoColor3 = Color3.fromRGB(35, 38, 48)
		bodyColors.LeftArmColor3 = Color3.fromRGB(125, 28, 32)
		bodyColors.RightArmColor3 = Color3.fromRGB(125, 28, 32)
		bodyColors.LeftLegColor3 = Color3.fromRGB(28, 30, 38)
		bodyColors.RightLegColor3 = Color3.fromRGB(28, 30, 38)

		if torso then
			torso.Material = Enum.Material.Metal
			-- Add heavy spiked pauldrons
			for _, side in ipairs({ -1.3, 1.3 }) do
				local pauldron = Instance.new("Part")
				pauldron.Name = "IronPauldron"
				pauldron.Size = Vector3.new(1.1, 0.6, 1.1)
				pauldron.Color = Color3.fromRGB(48, 52, 64)
				pauldron.Material = Enum.Material.Metal
				attachAccessory(model, torso, pauldron, CFrame.new(side, 0.8, 0))
			end
		end

		if head then
			local helm = Instance.new("Part")
			helm.Name = "BossHelm"
			helm.Size = Vector3.new(1.3, 0.5, 1.3)
			helm.Color = Color3.fromRGB(25, 26, 32)
			helm.Material = Enum.Material.Metal
			attachAccessory(model, head, helm, CFrame.new(0, 0.45, 0))

			local eyeLight = Instance.new("PointLight")
			eyeLight.Color = Color3.fromRGB(255, 40, 40)
			eyeLight.Range = 6
			eyeLight.Brightness = 2
			eyeLight.Parent = head
		end

		if rightArm then
			local blade = Instance.new("Part")
			blade.Name = "BossCleaver"
			blade.Size = Vector3.new(0.4, 4.2, 1.0)
			blade.Color = Color3.fromRGB(180, 185, 195)
			blade.Material = Enum.Material.DiamondPlate
			local bladeOffset = CFrame.new(0, -1.8, -0.4) * CFrame.Angles(math.rad(45), 0, 0)
			attachAccessory(model, rightArm, blade, bladeOffset)
		end
	else
		local banditDef = BANDIT_SPAWNS[variantIndex]
		model.Name = banditDef and banditDef.name or "Bandit Scout"

		local palette = {
			{ torso = Color3.fromRGB(58, 48, 38), arm = Color3.fromRGB(145, 120, 95), leg = Color3.fromRGB(42, 35, 30) },
			{ torso = Color3.fromRGB(38, 45, 42), arm = Color3.fromRGB(120, 110, 95), leg = Color3.fromRGB(32, 38, 35) },
			{ torso = Color3.fromRGB(48, 36, 42), arm = Color3.fromRGB(135, 115, 100), leg = Color3.fromRGB(38, 30, 35) },
			{ torso = Color3.fromRGB(62, 42, 35), arm = Color3.fromRGB(150, 125, 90), leg = Color3.fromRGB(45, 32, 28) },
			{ torso = Color3.fromRGB(40, 40, 48), arm = Color3.fromRGB(130, 130, 140), leg = Color3.fromRGB(35, 35, 42) },
		}
		local pal = palette[variantIndex] or palette[1]
		bodyColors.HeadColor3 = Color3.fromRGB(205, 160, 130)
		bodyColors.TorsoColor3 = pal.torso
		bodyColors.LeftArmColor3 = pal.arm
		bodyColors.RightArmColor3 = pal.arm
		bodyColors.LeftLegColor3 = pal.leg
		bodyColors.RightLegColor3 = pal.leg

		if head then
			local mask = Instance.new("Part")
			mask.Name = "BanditMask"
			mask.Size = Vector3.new(1.15, 0.45, 1.15)
			mask.Color = Color3.fromRGB(28, 26, 24)
			mask.Material = Enum.Material.Fabric
			attachAccessory(model, head, mask, CFrame.new(0, -0.2, 0))
		end

		if rightArm then
			local wep = Instance.new("Part")
			wep.Name = "BanditWeapon"
			wep.Size = Vector3.new(0.3, 2.4, 0.5)
			wep.Color = Color3.fromRGB(140, 145, 155)
			wep.Material = Enum.Material.Metal
			local wepOffset = CFrame.new(0, -1.2, -0.3) * CFrame.Angles(math.rad(30), 0, 0)
			attachAccessory(model, rightArm, wep, wepOffset)
		end
	end

	local targetHead = head or torso
	if targetHead then
		local bbg = Instance.new("BillboardGui")
		bbg.Name = "OverheadHUD"
		bbg.Size = UDim2.new(0, isBoss and 160 or 120, 0, 36)
		bbg.StudsOffset = Vector3.new(0, isBoss and 3.8 or 2.8, 0)
		bbg.AlwaysOnTop = false
		bbg.LightInfluence = 0
		bbg.MaxDistance = 100
		bbg.Parent = targetHead

		local nameLabel = Instance.new("TextLabel")
		nameLabel.BackgroundTransparency = 1
		nameLabel.Size = UDim2.new(1, 0, 0, 16)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.Text = model.Name
		nameLabel.TextColor3 = isBoss and Color3.fromRGB(255, 75, 75) or Color3.fromRGB(250, 220, 160)
		nameLabel.TextSize = isBoss and 13 or 11
		nameLabel.Parent = bbg

		local nStroke = Instance.new("UIStroke")
		nStroke.Color = Color3.fromRGB(10, 15, 15)
		nStroke.Thickness = 1.2
		nStroke.Parent = nameLabel

		local barBg = Instance.new("Frame")
		barBg.BackgroundColor3 = Color3.fromRGB(15, 20, 20)
		barBg.Size = UDim2.new(1, 0, 0, 6)
		barBg.Position = UDim2.new(0, 0, 0, 20)
		barBg.BorderSizePixel = 0
		barBg.Parent = bbg

		local barFill = Instance.new("Frame")
		barFill.Name = "Fill"
		barFill.BackgroundColor3 = isBoss and Color3.fromRGB(230, 45, 45) or Color3.fromRGB(215, 75, 75)
		barFill.Size = UDim2.new(1, 0, 1, 0)
		barFill.BorderSizePixel = 0
		barFill.Parent = barBg

		humanoid.HealthChanged:Connect(function(newHp)
			barFill.Size = UDim2.new(math.clamp(newHp / humanoid.MaxHealth, 0, 1), 0, 1, 0)
		end)
	end
end

local function spawnBandit(spawnCFrame: CFrame, isBoss: boolean, variantIndex: number)
	local sample = Workspace:FindFirstChild("SAMPLEENEMYMODEL")
	local model: Model
	if sample and sample:IsA("Model") then
		sample.Archivable = true
		model = sample:Clone()
	else
		model = Instance.new("Model")
		local hum = Instance.new("Humanoid")
		hum.Parent = model
		local root = Instance.new("Part")
		root.Name = "HumanoidRootPart"
		root.Size = Vector3.new(2, 2, 1)
		root.Transparency = 1
		root.Parent = model
		model.PrimaryPart = root
		local torso = Instance.new("Part")
		torso.Name = "Torso"
		torso.Size = Vector3.new(2, 2, 1)
		torso.Parent = model
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Size = Vector3.new(1.2, 1.2, 1.2)
		head.Parent = model
	end

	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart? or model:FindFirstChild("Torso") :: BasePart?
	model.PrimaryPart = root

	-- CRITICAL RULE: First pivot the model to its target spawn CFrame and parent it to the village container!
	-- NEVER attach or weld accessories while the model is at SAMPLEENEMYMODEL's position.
	model:PivotTo(spawnCFrame)
	model.Parent = enemiesFolder

	-- Apply custom design, armor, helmet, weapons directly to the positioned enemy
	designEnemyModel(model, isBoss, variantIndex)

	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local chaseDist = isBoss and 90 or 60
	local attackDist = 5
	local baseDmg = isBoss and 40 or 16
	local attackCd = isBoss and 1.2 or 1.5
	local nextAttack = 0
	local isDead = false

	humanoid.Died:Connect(function()
		if isDead then return end
		isDead = true

		local killerPlayer: Player? = nil
		local closestDist = 60
		for _, p in ipairs(Players:GetPlayers()) do
			local char = p.Character
			local pRoot = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if pRoot and root then
				local d = (pRoot.Position - root.Position).Magnitude
				if d < closestDist then
					closestDist = d
					killerPlayer = p
				end
			end
		end

		if killerPlayer then
			local leaderstats = killerPlayer:FindFirstChild("leaderstats")
			local goldVal = leaderstats and leaderstats:FindFirstChild("Gold") :: IntValue?
			local earnedGold = isBoss and math.random(100, 250) or math.random(15, 30)

			if goldVal then
				goldVal.Value = goldVal.Value + earnedGold
			end

			local rewardMessages = { string.format("+%d Spirit Stones", earnedGold) }

			-- 1. QI PILL DROP CHECK (2% normal, 10% boss)
			local pillRoll = math.random()
			local pillChance = isBoss and 0.10 or 0.02
			if pillRoll <= pillChance then
				local pillType = math.random() <= 0.5 and "Qi Condensation Pill" or "Lesser Qi Pill"
				awardItemToPlayer(killerPlayer, pillType, 1)
				table.insert(rewardMessages, "Dropped Pill: " .. pillType)
			end

			-- 2. EQUIPMENT DROP CHECK (10% normal, 10% boss)
			local equipRoll = math.random()
			if equipRoll <= 0.10 then
				local pool = ItemConfig.EquipmentDrops
				local dropItem = pool[math.random(1, #pool)]
				awardItemToPlayer(killerPlayer, dropItem, 1)
				table.insert(rewardMessages, "Dropped Equipment: " .. dropItem)
			end

			if root then
				showFloatingRewardText(root.Position, table.concat(rewardMessages, "\n"), isBoss and Color3.fromRGB(255, 215, 70) or Color3.fromRGB(255, 235, 180))
			end
			print(string.format("[Loot] %s defeated %s and received: %s", killerPlayer.Name, model.Name, table.concat(rewardMessages, ", ")))
		end

		Debris:AddItem(model, 2.5)

		task.delay(isBoss and 45 or 15, function()
			spawnBandit(spawnCFrame, isBoss, variantIndex)
		end)
	end)

	-- AI Movement, Leash & Return Teleport System
	-- Rule: Enemies will not go too far from home. If an enemy is returning and has not detected an enemy
	-- for more than 15 seconds without reaching home, they teleport back.
	local homePos = spawnCFrame.Position
	local MAX_LEASH_DIST = isBoss and 65 or 40 -- Max distance allowed from home position
	local AGGRO_RANGE = isBoss and 50 or 30    -- Detection radius around enemy
	local returningStartTime: number? = nil

	task.spawn(function()
		while model and model.Parent and not isDead do
			if humanoid.Health > 0 and root then
				local currentPos = root.Position
				local distFromHome = (currentPos - homePos).Magnitude

				local targetPlayer: Player? = nil
				local targetHum: Humanoid? = nil
				local targetRoot: BasePart? = nil
				local closestDist = AGGRO_RANGE

				-- Only search for targets if enemy itself is within leash bounds
				if distFromHome <= MAX_LEASH_DIST then
					for _, p in ipairs(Players:GetPlayers()) do
						local char = p.Character
						local pHum = char and char:FindFirstChildOfClass("Humanoid")
						local pRoot = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?

						if pHum and pHum.Health > 0 and pRoot then
							local distToEnemy = (pRoot.Position - currentPos).Magnitude
							local playerDistFromHome = (pRoot.Position - homePos).Magnitude

							-- Target must be within detection range AND within village leash boundary
							if distToEnemy < closestDist and playerDistFromHome <= MAX_LEASH_DIST then
								closestDist = distToEnemy
								targetPlayer = p
								targetHum = pHum
								targetRoot = pRoot
							end
						end
					end
				end

				-- State 1: Active Combat Chase
				if targetRoot and targetHum then
					-- Player detected! Reset return timer
					returningStartTime = nil

					humanoid:MoveTo(targetRoot.Position)

					if closestDist <= attackDist and os.clock() >= nextAttack then
						nextAttack = os.clock() + attackCd
						local def = (targetPlayer and targetPlayer:GetAttribute("Defense")) or 5
						local finalDmg = math.max(1, baseDmg - def)
						targetHum:TakeDamage(finalDmg)
					end
				else
					-- State 2: Returning home (No enemy detected)
					if distFromHome > 4 then
						-- Mark when the enemy started returning
						if not returningStartTime then
							returningStartTime = os.clock()
						end

						local timeReturning = os.clock() - returningStartTime
						if timeReturning >= 15 then
							-- Teleport back if taking > 15s to return to home
							model:PivotTo(spawnCFrame)
							returningStartTime = nil
							humanoid:MoveTo(homePos)
						else
							-- Walk back towards original position
							humanoid:MoveTo(homePos)
						end
					else
						-- Safely back at original position
						returningStartTime = nil
					end
				end
			end
			task.wait(0.5)
		end
	end)
end

-- ============================================================================
-- INITIALIZE BANDIT OUTPOST AT BanditVillage POSITIONS
-- ============================================================================
local function initBanditVillage()
	-- Clear old humanoid enemies in enemiesFolder
	for _, old in ipairs(enemiesFolder:GetChildren()) do
		if old:FindFirstChildOfClass("Humanoid") then
			old:Destroy()
		end
	end

	-- Delete legacy static bandit models inside Workspace.BanditVillage if still present
	local bv = Workspace:FindFirstChild("BanditVillage")
	if bv then
		for _, ch in ipairs(bv:GetChildren()) do
			if string.find(ch.Name, "Bandit") and not string.find(ch.Name, "Tent") and not string.find(ch.Name, "Gate") and not string.find(ch.Name, "Camp") then
				if not ch:FindFirstChildOfClass("Humanoid") then
					ch:Destroy()
				end
			end
		end
	end

	-- 1. Spawn Bandit Boss at Chieftain Dais throne
	local bossCF = CFrame.new(BOSS_SPAWN.pos) * CFrame.Angles(0, math.rad(BOSS_SPAWN.rotY), 0)
	spawnBandit(bossCF, true, 1)

	-- 2. Spawn 5 Bandits at their respective village positions
	for i, bDef in ipairs(BANDIT_SPAWNS) do
		local bCF = CFrame.new(bDef.pos) * CFrame.Angles(0, math.rad(bDef.rotY), 0)
		spawnBandit(bCF, false, i)
	end

	print(string.format("[BanditSpawnerService] Initialized 1 Boss + %d Bandits at exact BanditVillage positions.", #BANDIT_SPAWNS))
end

task.spawn(initBanditVillage)
