local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local BanditManager = {}

local cultivationRemote = ReplicatedStorage:WaitForChild("CultivationRemote")

--------------------------------------------------------------------------------
-- Color & Visual Constants
--------------------------------------------------------------------------------
local BANDIT_COLORS = {
	Skin = Color3.fromRGB(225, 185, 145),
	Torso = Color3.fromRGB(65, 42, 32), -- Dark leather vest
	Legs = Color3.fromRGB(38, 38, 42),  -- Charcoal pants
	Bandana = Color3.fromRGB(155, 30, 30), -- Crimson headband/mask
	BossSkin = Color3.fromRGB(210, 170, 135),
	BossTorso = Color3.fromRGB(90, 20, 20), -- Heavy spiked crimson breastplate
	BossArmorTrim = Color3.fromRGB(220, 170, 45), -- Gold trim
	BossLegs = Color3.fromRGB(25, 25, 30),
	BossHorns = Color3.fromRGB(40, 40, 45),
}

--------------------------------------------------------------------------------
-- Helper: Build a Standard R6 Humanoid Rig
--------------------------------------------------------------------------------
local function buildR6Rig(name, scale, isBoss)
	scale = scale or 1.0

	local model = Instance.new("Model")
	model.Name = name

	-- 1. HumanoidRootPart
	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2 * scale, 2 * scale, 1 * scale)
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.Anchored = false
	hrp.Parent = model
	model.PrimaryPart = hrp

	-- 2. Torso
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2 * scale, 2 * scale, 1 * scale)
	torso.Color = isBoss and BANDIT_COLORS.BossTorso or BANDIT_COLORS.Torso
	torso.Material = Enum.Material.Fabric
	torso.CanCollide = false
	torso.Anchored = false
	torso.Parent = model

	-- 3. Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.25 * scale, 1.25 * scale, 1.25 * scale)
	head.Color = isBoss and BANDIT_COLORS.BossSkin or BANDIT_COLORS.Skin
	head.CanCollide = false
	head.Anchored = false
	head.Parent = model

	-- 4. Left & Right Arms
	local leftArm = Instance.new("Part")
	leftArm.Name = "Left Arm"
	leftArm.Size = Vector3.new(1 * scale, 2 * scale, 1 * scale)
	leftArm.Color = isBoss and BANDIT_COLORS.BossTorso or BANDIT_COLORS.Skin
	leftArm.Material = Enum.Material.SmoothPlastic
	leftArm.CanCollide = false
	leftArm.Anchored = false
	leftArm.Parent = model

	local rightArm = Instance.new("Part")
	rightArm.Name = "Right Arm"
	rightArm.Size = Vector3.new(1 * scale, 2 * scale, 1 * scale)
	rightArm.Color = isBoss and BANDIT_COLORS.BossTorso or BANDIT_COLORS.Skin
	rightArm.Material = Enum.Material.SmoothPlastic
	rightArm.CanCollide = false
	rightArm.Anchored = false
	rightArm.Parent = model

	-- 5. Left & Right Legs
	local leftLeg = Instance.new("Part")
	leftLeg.Name = "Left Leg"
	leftLeg.Size = Vector3.new(1 * scale, 2 * scale, 1 * scale)
	leftLeg.Color = isBoss and BANDIT_COLORS.BossLegs or BANDIT_COLORS.Legs
	leftLeg.Material = Enum.Material.Fabric
	leftLeg.CanCollide = false
	leftLeg.Anchored = false
	leftLeg.Parent = model

	local rightLeg = Instance.new("Part")
	rightLeg.Name = "Right Leg"
	rightLeg.Size = Vector3.new(1 * scale, 2 * scale, 1 * scale)
	rightLeg.Color = isBoss and BANDIT_COLORS.BossLegs or BANDIT_COLORS.Legs
	rightLeg.Material = Enum.Material.Fabric
	rightLeg.CanCollide = false
	rightLeg.Anchored = false
	rightLeg.Parent = model

	-- 6. Motor6D Joints
	local rootJoint = Instance.new("Motor6D")
	rootJoint.Name = "RootJoint"
	rootJoint.Part0 = hrp
	rootJoint.Part1 = torso
	rootJoint.C0 = CFrame.new()
	rootJoint.C1 = CFrame.new()
	rootJoint.Parent = hrp

	local neck = Instance.new("Motor6D")
	neck.Name = "Neck"
	neck.Part0 = torso
	neck.Part1 = head
	neck.C0 = CFrame.new(0, 1 * scale, 0)
	neck.C1 = CFrame.new(0, -0.5 * scale, 0)
	neck.Parent = torso

	local rightShoulder = Instance.new("Motor6D")
	rightShoulder.Name = "Right Shoulder"
	rightShoulder.Part0 = torso
	rightShoulder.Part1 = rightArm
	rightShoulder.C0 = CFrame.new(1 * scale + (0.5 * scale), 0.5 * scale, 0)
	rightShoulder.C1 = CFrame.new(0, 0.5 * scale, 0)
	rightShoulder.Parent = torso

	local leftShoulder = Instance.new("Motor6D")
	leftShoulder.Name = "Left Shoulder"
	leftShoulder.Part0 = torso
	leftShoulder.Part1 = leftArm
	leftShoulder.C0 = CFrame.new(-1 * scale - (0.5 * scale), 0.5 * scale, 0)
	leftShoulder.C1 = CFrame.new(0, 0.5 * scale, 0)
	leftShoulder.Parent = torso

	local rightHip = Instance.new("Motor6D")
	rightHip.Name = "Right Hip"
	rightHip.Part0 = torso
	rightHip.Part1 = rightLeg
	rightHip.C0 = CFrame.new(0.5 * scale, -1 * scale, 0)
	rightHip.C1 = CFrame.new(0, 1 * scale, 0)
	rightHip.Parent = torso

	local leftHip = Instance.new("Motor6D")
	leftHip.Name = "Left Hip"
	leftHip.Part0 = torso
	leftHip.Part1 = leftLeg
	leftHip.C0 = CFrame.new(-0.5 * scale, -1 * scale, 0)
	leftHip.C1 = CFrame.new(0, 1 * scale, 0)
	leftHip.Parent = torso

	-- 7. Humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.DisplayName = name
	humanoid.MaxHealth = isBoss and 280 or 60
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = isBoss and 13 or 11
	humanoid.HipHeight = 2 * scale
	humanoid.Parent = model

	-- Visual accessories: Bandana / Pauldrons / Helm
	if isBoss then
		-- Spiked Pauldrons (Shoulder armor)
		for _, xOff in ipairs({ -1.5 * scale, 1.5 * scale }) do
			local pauldron = Instance.new("Part")
			pauldron.Name = "BossPauldron"
			pauldron.Size = Vector3.new(1.3 * scale, 0.7 * scale, 1.3 * scale)
			pauldron.Color = BANDIT_COLORS.BossArmorTrim
			pauldron.Material = Enum.Material.Metal
			pauldron.CanCollide = false
			pauldron.Anchored = false

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = torso
			weld.Part1 = pauldron
			weld.Parent = pauldron

			pauldron.CFrame = torso.CFrame * CFrame.new(xOff, 0.8 * scale, 0)
			pauldron.Parent = model
		end

		-- Horned Boss Crown on Head
		local crown = Instance.new("Part")
		crown.Name = "BossCrown"
		crown.Size = Vector3.new(1.3 * scale, 0.4 * scale, 1.3 * scale)
		crown.Color = BANDIT_COLORS.BossArmorTrim
		crown.Material = Enum.Material.Metal
		crown.CanCollide = false
		crown.Anchored = false

		local cWeld = Instance.new("WeldConstraint")
		cWeld.Part0 = head
		cWeld.Part1 = crown
		cWeld.Parent = crown

		crown.CFrame = head.CFrame * CFrame.new(0, 0.7 * scale, 0)
		crown.Parent = model
	else
		-- Crimson Bandit Headband
		local bandana = Instance.new("Part")
		bandana.Name = "Bandana"
		bandana.Size = Vector3.new(1.3 * scale, 0.35 * scale, 1.3 * scale)
		bandana.Color = BANDIT_COLORS.Bandana
		bandana.Material = Enum.Material.Fabric
		bandana.CanCollide = false
		bandana.Anchored = false

		local bWeld = Instance.new("WeldConstraint")
		bWeld.Part0 = head
		bWeld.Part1 = bandana
		bWeld.Parent = bandana

		bandana.CFrame = head.CFrame * CFrame.new(0, 0.3 * scale, 0)
		bandana.Parent = model
	end

	-- 8. Overhead Health Bar Billboard (compact: small name + health bar)
	local bbg = Instance.new("BillboardGui")
	bbg.Name = "EnemyHealthGui"
	bbg.AlwaysOnTop = true
	bbg.Size = isBoss and UDim2.new(0, 120, 0, 28) or UDim2.new(0, 100, 0, 24)
	bbg.StudsOffset = Vector3.new(0, (2.6 + (isBoss and 1.0 or 0)) * scale, 0)
	bbg.Adornee = head
	bbg.Parent = model

	-- Small name label above the health bar
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Name = "NameLabel"
	nameLbl.BackgroundTransparency = 1
	nameLbl.Size = UDim2.new(1, 0, 0, 12)
	nameLbl.Position = UDim2.new(0, 0, 0, 0)
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.Text = isBoss and "Bandit Boss" or "Bandit"
	nameLbl.TextColor3 = isBoss and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 220, 100)
	nameLbl.TextSize = isBoss and 11 or 10
	nameLbl.Parent = bbg

	local nameStroke = Instance.new("UIStroke")
	nameStroke.Color = Color3.fromRGB(20, 10, 10)
	nameStroke.Thickness = 1
	nameStroke.Parent = nameLbl

	-- Health bar frame sits below the name
	local hpFrame = Instance.new("Frame")
	hpFrame.Name = "HpBar"
	hpFrame.BackgroundColor3 = Color3.fromRGB(35, 20, 20)
	hpFrame.BorderSizePixel = 0
	hpFrame.Position = UDim2.new(0, 0, 0, 14)
	hpFrame.Size = isBoss and UDim2.new(1, 0, 0, 12) or UDim2.new(1, 0, 0, 10)
	hpFrame.Parent = bbg

	local hpCorner = Instance.new("UICorner")
	hpCorner.CornerRadius = UDim.new(0, 3)
	hpCorner.Parent = hpFrame

	local hpFill = Instance.new("Frame")
	hpFill.Name = "Fill"
	hpFill.BackgroundColor3 = isBoss and Color3.fromRGB(230, 35, 45) or Color3.fromRGB(210, 60, 40)
	hpFill.BorderSizePixel = 0
	hpFill.Size = UDim2.new(1, 0, 1, 0)
	hpFill.Parent = hpFrame

	local hpFillCorner = Instance.new("UICorner")
	hpFillCorner.CornerRadius = UDim.new(0, 3)
	hpFillCorner.Parent = hpFill

	local hpText = Instance.new("TextLabel")
	hpText.Name = "Value"
	hpText.BackgroundTransparency = 1
	hpText.Size = UDim2.new(1, 0, 1, 0)
	hpText.Font = Enum.Font.GothamBold
	hpText.Text = string.format("%d / %d", humanoid.Health, humanoid.MaxHealth)
	hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
	hpText.TextSize = isBoss and 10 or 8
	hpText.Parent = hpFrame

	humanoid.HealthChanged:Connect(function(health)
		local frac = math.clamp(health / math.max(1, humanoid.MaxHealth), 0, 1)
		hpFill.Size = UDim2.new(frac, 0, 1, 0)
		hpText.Text = string.format("%d / %d", math.max(0, math.floor(health)), humanoid.MaxHealth)
	end)

	return model
end

--------------------------------------------------------------------------------
-- Punch Combat Animation Function
--------------------------------------------------------------------------------
local function executePunchAnimation(model, isRightArm)
	local torso = model:FindFirstChild("Torso")
	if not torso then return end

	local shoulderName = isRightArm and "Right Shoulder" or "Left Shoulder"
	local shoulder = torso:FindFirstChild(shoulderName)
	if not shoulder or not shoulder:IsA("Motor6D") then return end

	local origC0 = shoulder.C0
	local sign = isRightArm and 1 or -1

	-- 1. Punch Strike Phase: Thrust arm forward and twist
	shoulder.C0 = origC0 * CFrame.Angles(math.rad(-85), math.rad(sign * 15), math.rad(sign * 10))

	-- Punch Impact VFX at hand
	local hand = model:FindFirstChild(isRightArm and "Right Arm" or "Left Arm")
	if hand then
		local pPart = Instance.new("Part")
		pPart.Size = Vector3.new(0.6, 0.6, 0.6)
		pPart.CFrame = hand.CFrame * CFrame.new(0, -1, 0)
		pPart.Transparency = 1
		pPart.CanCollide = false
		pPart.Anchored = true
		pPart.Parent = Workspace

		local punchEmitter = Instance.new("ParticleEmitter")
		punchEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 220, 120), Color3.fromRGB(255, 80, 20))
		punchEmitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
		punchEmitter.Lifetime = NumberRange.new(0.2, 0.35)
		punchEmitter.Rate = 0
		punchEmitter.Speed = NumberRange.new(5, 12)
		punchEmitter.SpreadAngle = Vector2.new(180, 180)
		punchEmitter.Parent = pPart
		punchEmitter:Emit(15)

		Debris:AddItem(pPart, 0.4)
	end

	-- 2. Recoil Phase
	task.delay(0.12, function()
		if shoulder and shoulder.Parent then
			shoulder.C0 = origC0 * CFrame.Angles(math.rad(15), 0, math.rad(-sign * 5))
		end
	end)

	-- 3. Return to Idle
	task.delay(0.25, function()
		if shoulder and shoulder.Parent then
			shoulder.C0 = origC0
		end
	end)
end

--------------------------------------------------------------------------------
-- Drop Rolling Logic (Exact user specified percentages)
--------------------------------------------------------------------------------
local function rollBanditDrops(isBoss)
	local roll = math.random() * 100
	local droppedItem = nil

	if isBoss then
		-- Bandit Boss Drop:
		-- Lesser Qi Pill: 12%
		-- Helmet: 25%
		-- Armor: 25%
		-- No Item: 38%
		if roll <= 12 then
			droppedItem = "Lesser Qi Pill"
		elseif roll <= (12 + 25) then -- 37%
			droppedItem = "Helmet"
		elseif roll <= (12 + 25 + 25) then -- 62%
			droppedItem = "Armor"
		else
			droppedItem = nil -- 38% No Item
		end
		return 500, droppedItem
	else
		-- Regular Bandit Drop:
		-- 100 Gold guaranteed
		-- Lesser Qi Pill: 3%
		-- Helmet: 15%
		-- Armor: 12%
		-- No Item: 70%
		if roll <= 3 then
			droppedItem = "Lesser Qi Pill"
		elseif roll <= (3 + 15) then -- 18%
			droppedItem = "Helmet"
		elseif roll <= (3 + 15 + 12) then -- 30%
			droppedItem = "Armor"
		else
			droppedItem = nil -- 70% No Item
		end
		return 100, droppedItem
	end
end

--------------------------------------------------------------------------------
-- Floating 3D Loot Effect
--------------------------------------------------------------------------------
local function spawnLootPickup(position, goldAmount, itemName)
	local lootModel = Instance.new("Model")
	lootModel.Name = "LootDrop"

	-- Floating glowing coin / gem
	local core = Instance.new("Part")
	core.Name = "Core"
	core.Shape = Enum.PartType.Cylinder
	core.Size = Vector3.new(0.4, 2, 2)
	core.CFrame = CFrame.new(position + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	core.Color = itemName and Color3.fromRGB(120, 200, 255) or Color3.fromRGB(255, 215, 60)
	core.Material = Enum.Material.Neon
	core.Anchored = true
	core.CanCollide = false
	core.Parent = lootModel

	local bbg = Instance.new("BillboardGui")
	bbg.AlwaysOnTop = true
	bbg.Size = UDim2.new(0, 160, 0, 40)
	bbg.StudsOffset = Vector3.new(0, 1.8, 0)
	bbg.Adornee = core
	bbg.Parent = core

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Font = Enum.Font.GothamBlack
	if itemName then
		label.Text = string.format("🪙 +%d Gold\n🎁 %s!", goldAmount, itemName)
		label.TextColor3 = Color3.fromRGB(255, 230, 80)
	else
		label.Text = string.format("🪙 +%d Gold", goldAmount)
		label.TextColor3 = Color3.fromRGB(255, 215, 50)
	end
	label.TextScaled = true
	label.Parent = bbg

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(20, 20, 20)
	stroke.Thickness = 1.5
	stroke.Parent = label

	lootModel.Parent = Workspace

	-- Animate floating up and spinning
	task.spawn(function()
		local t0 = tick()
		while tick() - t0 < 3.5 and core.Parent do
			task.wait(0.03)
			local elapsed = tick() - t0
			core.CFrame = CFrame.new(position + Vector3.new(0, 1.5 + (elapsed * 0.6), 0)) * CFrame.Angles(0, elapsed * 3, math.rad(90))
		end
		lootModel:Destroy()
	end)
end

--------------------------------------------------------------------------------
-- Inventory Addition & Auto-Save Helper
--------------------------------------------------------------------------------
local function givePlayerDrop(player, goldAmount, itemName)
	local leaderstats = player:FindFirstChild("leaderstats")
	local gold = leaderstats and leaderstats:FindFirstChild("Gold")
	if gold then
		gold.Value = gold.Value + goldAmount
	end

	if itemName then
		local inv = player:FindFirstChild("Inventory")
		if not inv then
			inv = Instance.new("Folder")
			inv.Name = "Inventory"
			inv.Parent = player
		end

		local itemVal = inv:FindFirstChild(itemName)
		if not itemVal then
			itemVal = Instance.new("IntValue")
			itemVal.Name = itemName
			itemVal.Value = 0
			itemVal.Parent = inv
		end
		itemVal.Value = itemVal.Value + 1

		local notifMsg = string.format("🎁 LOOT DROP: Obtained %s! (+%d Gold)", itemName, goldAmount)
		cultivationRemote:FireClient(player, "Notification", notifMsg)
	else
		cultivationRemote:FireClient(player, "Notification", string.format("🪙 +%d Gold looted!", goldAmount))
	end
end

--------------------------------------------------------------------------------
-- Find Nearest Living Player
--------------------------------------------------------------------------------
local function findNearestLivingPlayer(rootPart, maxDist)
	local nearestHum, nearestRoot, minDist = nil, nil, maxDist or 60

	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local pRoot = char and char:FindFirstChild("HumanoidRootPart")

		if hum and pRoot and hum.Health > 0 then
			local dist = (pRoot.Position - rootPart.Position).Magnitude
			if dist <= minDist then
				nearestHum = hum
				nearestRoot = pRoot
				minDist = dist
			end
		end
	end

	return nearestHum, nearestRoot, minDist
end

--------------------------------------------------------------------------------
-- Spawn and Run an Enemy Unit (Bandit or Boss)
--------------------------------------------------------------------------------
local function spawnEnemy(name, spawnCF, isBoss)
	local scale = isBoss and 1.35 or 1.0
	local enemyModel = buildR6Rig(name, scale, isBoss)
	local hrp = enemyModel.PrimaryPart
	local humanoid = enemyModel:FindFirstChildOfClass("Humanoid")

	hrp.CFrame = spawnCF
	enemyModel.Parent = Workspace

	local baseDamage = isBoss and 24 or 12
	local attackCooldown = isBoss and 1.2 or 1.0
	local attackRange = 5 * scale
	local chaseRange = isBoss and 80 or 55
	local respawnDelay = isBoss and 60 or 10 -- 1 minute for boss, 10s for bandits

	local nextAttackTime = 0
	local punchSide = true
	local isDead = false

	-- Death Handler
	humanoid.Died:Connect(function()
		if isDead then return end
		isDead = true

		local deathPos = hrp.Position
		local gold, item = rollBanditDrops(isBoss)

		-- Find players who are close by to reward
		local rewardedPlayers = {}
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local pRoot = char and char:FindFirstChild("HumanoidRootPart")
			if pRoot and (pRoot.Position - deathPos).Magnitude <= (isBoss and 80 or 45) then
				table.insert(rewardedPlayers, player)
			end
		end

		if #rewardedPlayers > 0 then
			for _, p in ipairs(rewardedPlayers) do
				givePlayerDrop(p, gold, item)
			end
		else
			-- Fallback: give to first active player if in server
			local first = Players:GetPlayers()[1]
			if first then
				givePlayerDrop(first, gold, item)
			end
		end

		-- Spawn 3D Floating Loot
		spawnLootPickup(deathPos, gold, item)

		if isBoss then
			for _, p in ipairs(Players:GetPlayers()) do
				cultivationRemote:FireClient(p, "Notification", "👑 Bandit Chieftain has fallen! Respawning in 1 minute...")
			end
		end

		-- Clean up dead model after 2 seconds
		task.delay(2, function()
			enemyModel:Destroy()
		end)

		-- Schedule Respawn
		task.delay(respawnDelay, function()
			spawnEnemy(name, spawnCF, isBoss)
		end)
	end)

	-- AI Combat & Punch Loop
	task.spawn(function()
		while not isDead and enemyModel.Parent and humanoid.Health > 0 do
			local targetHum, targetRoot, dist = findNearestLivingPlayer(hrp, chaseRange)

			if targetHum and targetRoot then
				humanoid:MoveTo(targetRoot.Position)

				-- Punch Attack Condition
				if dist <= attackRange and tick() >= nextAttackTime then
					nextAttackTime = tick() + attackCooldown
					punchSide = not punchSide
					executePunchAnimation(enemyModel, punchSide)

					-- Calculate Player Defense Reduction
					local targetChar = targetHum.Parent
					local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
					local playerDefense = targetPlayer and (targetPlayer:GetAttribute("Defense") or 0) or 0

					-- Defense absorbs damage! Minimum 1 damage
					local finalDamage = math.max(1, baseDamage - playerDefense)
					targetHum:TakeDamage(finalDamage)
				end
			else
				-- Return towards spawn if too far
				if (hrp.Position - spawnCF.Position).Magnitude > 35 then
					humanoid:MoveTo(spawnCF.Position)
				end
			end

			task.wait(0.25)
		end
	end)
end

--------------------------------------------------------------------------------
-- Initialization: Spawn Bandits & Boss across the Bandit Village
--------------------------------------------------------------------------------
function BanditManager.init()
	-- Bandit Village center is around CFrame.new(160, 0, -20)
	local centerPos = Vector3.new(160, 0, -20)

	-- 1. Spawn 4-5 Regular Bandits stationed in the camp
	local banditSpawnPositions = {
		centerPos + Vector3.new(-18, 3, 15),   -- Near Campfire West
		centerPos + Vector3.new(18, 3, 15),    -- Near Campfire East
		centerPos + Vector3.new(-22, 3, -12),  -- Near Western Tent
		centerPos + Vector3.new(22, 3, -12),   -- Near Eastern Tent
		centerPos + Vector3.new(0, 3, 34),     -- Guarding Front Gate
	}

	for i, pos in ipairs(banditSpawnPositions) do
		local spawnCF = CFrame.new(pos) * CFrame.Angles(0, math.rad(math.random(-180, 180)), 0)
		spawnEnemy("Bandit_" .. i, spawnCF, false)
	end

	-- 2. Spawn 1 Bandit Boss on the Chieftain Dais
	local bossSpawnCF = CFrame.new(centerPos + Vector3.new(0, 5.5, -38)) * CFrame.Angles(0, math.rad(180), 0)
	spawnEnemy("Bandit Chieftain", bossSpawnCF, true)

	print("⚔️ [BanditManager] Spawned 5 Bandits (10s respawn) and 1 Bandit Boss (1m respawn)!")
end

return BanditManager
