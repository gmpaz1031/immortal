--!strict
-- src/server/BanditSpawnerService.server.luau
-- Bandit Village Enemy Spawner, Combat AI, Animations & Boss Stomp System
-- Spawns enemies at exact positions in Workspace.BanditVillage using SAMPLEENEMYMODEL.
-- Features:
-- 1. Velocity-Verified Server Animations:
--    - Smooth Walk animation that scales with physics velocity (eliminating sliding).
--    - Natural Idle when stationary (< 1.2 studs/s) or holding position.
-- 2. Dynamic 3-Hit Combo Attack System:
--    - Combo 1: Horizontal Slash with weapon trail arc.
--    - Combo 2: Heavy Overhead Chop with high-damage vertical power arc.
--    - Combo 3: Piercing Forward Lunge with thrust blur.
--    - Impact hit sparks & flesh impact sounds on player contact.
-- 3. Smart Melee Distancing: Bandits stop walking when in attack range and face the player in combat idle.
-- 4. Smart Jumping: Obstacle raycast clearance and vertical pursuit jumping.
-- 5. Bandit Boss "Earth-Shattering Ground Stomp": Windup telegraph, upward leap, heavy downward slam,
--    expanding shockwave ring, rock debris, blast audio, and ground-clamped knockback.
-- 6. Complete Loot System: Spirit Stones, Qi Pills (2% normal / 10% boss), Equipment drops (10%).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
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

-- Standard R6 Animation Asset IDs
local ANIM_IDS = {
	Idle           = "rbxassetid://180435571",
	Walk           = "rbxassetid://180426354",
	AttackSlash    = "rbxassetid://129967390", -- Horizontal Slash
	AttackOverhead = "rbxassetid://125750867", -- Overhead Chop
	AttackLunge    = "rbxassetid://129967478", -- Forward Piercing Lunge
	Jump           = "rbxassetid://125750702",
}

-- ============================================================================
-- UTILITY FUNCTIONS: Loot, Audio, Ground Clamping & Invariant Welds
-- ============================================================================
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

local function createSound(parent: Instance, soundId: string, volume: number, pitch: number?): Sound
	local s = Instance.new("Sound")
	s.SoundId = soundId
	s.Volume = volume
	s.PlaybackSpeed = pitch or 1.0
	s.Parent = parent
	s:Play()
	Debris:AddItem(s, 3.5)
	return s
end

local function getSurfaceY(pos: Vector3, ignoreList: { Instance }): number?
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = ignoreList
	local res = Workspace:Raycast(pos + Vector3.new(0, 10, 0), Vector3.new(0, -60, 0), rayParams)
	if res then
		return res.Position.Y
	end
	return nil
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

local function spawnWeaponSlashFX(root: BasePart, isBoss: boolean, attackType: string)
	local slash = Instance.new("Part")
	slash.Name = "BanditSlashFX"
	slash.Material = Enum.Material.Neon
	slash.Color = isBoss and Color3.fromRGB(255, 60, 40) or Color3.fromRGB(240, 220, 160)
	slash.Transparency = 0.2
	slash.CanCollide = false
	slash.CanTouch = false
	slash.CanQuery = false
	slash.Anchored = true

	local forwardOffset = root.CFrame.LookVector * (isBoss and 3.2 or 2.2)
	local origin = root.Position + Vector3.new(0, 0.2, 0) + forwardOffset

	if attackType == "Overhead" then
		slash.Size = Vector3.new(isBoss and 0.8 or 0.5, isBoss and 6.5 or 4.5, isBoss and 3.0 or 2.0)
		slash.CFrame = CFrame.lookAt(origin, origin + root.CFrame.LookVector) * CFrame.Angles(math.rad(45), 0, 0)
	elseif attackType == "Lunge" then
		slash.Size = Vector3.new(isBoss and 1.2 or 0.8, isBoss and 1.2 or 0.8, isBoss and 6.0 or 4.2)
		slash.CFrame = CFrame.lookAt(origin, origin + root.CFrame.LookVector)
	else -- Slash
		slash.Size = Vector3.new(isBoss and 6.5 or 4.5, isBoss and 0.5 or 0.3, isBoss and 3.0 or 2.0)
		slash.CFrame = CFrame.lookAt(origin, origin + root.CFrame.LookVector) * CFrame.Angles(0, 0, math.rad(25))
	end

	slash.Parent = Workspace

	local fadeTween = TweenService:Create(slash, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 1.0,
		Size = slash.Size * 1.3,
	})
	fadeTween:Play()
	Debris:AddItem(slash, 0.25)
end

local function spawnHitSpark(hitPos: Vector3, isBoss: boolean)
	local spark = Instance.new("Part")
	spark.Name = "HitSparkFX"
	spark.Shape = Enum.PartType.Ball
	spark.Size = Vector3.new(isBoss and 2.5 or 1.6, isBoss and 2.5 or 1.6, isBoss and 2.5 or 1.6)
	spark.Material = Enum.Material.Neon
	spark.Color = isBoss and Color3.fromRGB(255, 80, 50) or Color3.fromRGB(255, 230, 140)
	spark.Transparency = 0.1
	spark.CanCollide = false
	spark.CanTouch = false
	spark.CanQuery = false
	spark.Anchored = true
	spark.CFrame = CFrame.new(hitPos)
	spark.Parent = Workspace

	TweenService:Create(spark, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = spark.Size * 1.8,
		Transparency = 1.0,
	}):Play()
	Debris:AddItem(spark, 0.22)
end

-- ============================================================================
-- ANIMATION CONTROLLER (Velocity-Verified Server R6 Animation Manager)
-- ============================================================================
export type BanditAnimController = {
	playAttack: (isBoss: boolean, onStrike: (attackType: string) -> ()) -> (),
	triggerJump: () -> (),
	stopAll: () -> (),
}

local function setupBanditAnimations(model: Model, humanoid: Humanoid, rootPart: BasePart): BanditAnimController
	-- 1. Clean inert client Animate scripts that cannot run on NPCs in Workspace
	for _, child in ipairs(model:GetChildren()) do
		if child.Name == "Animate" and (child:IsA("LocalScript") or child:IsA("Script")) then
			child:Destroy()
		end
	end

	-- 2. Ensure Animator exists under Humanoid on the server
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	-- 3. Create Animation instances
	local function createAnim(id: string, name: string): Animation
		local a = Instance.new("Animation")
		a.Name = name
		a.AnimationId = id
		return a
	end

	local idleAnim = createAnim(ANIM_IDS.Idle, "BanditIdle")
	local walkAnim = createAnim(ANIM_IDS.Walk, "BanditWalk")
	local slashAnim = createAnim(ANIM_IDS.AttackSlash, "BanditAttackSlash")
	local overheadAnim = createAnim(ANIM_IDS.AttackOverhead, "BanditAttackOverhead")
	local lungeAnim = createAnim(ANIM_IDS.AttackLunge, "BanditAttackLunge")
	local jumpAnim = createAnim(ANIM_IDS.Jump, "BanditJump")

	local idleTrack = animator:LoadAnimation(idleAnim)
	idleTrack.Priority = Enum.AnimationPriority.Idle
	idleTrack.Looped = true

	local walkTrack = animator:LoadAnimation(walkAnim)
	walkTrack.Priority = Enum.AnimationPriority.Movement
	walkTrack.Looped = true

	local slashTrack = animator:LoadAnimation(slashAnim)
	slashTrack.Priority = Enum.AnimationPriority.Action
	slashTrack.Looped = false

	local overheadTrack = animator:LoadAnimation(overheadAnim)
	overheadTrack.Priority = Enum.AnimationPriority.Action
	overheadTrack.Looped = false

	local lungeTrack = animator:LoadAnimation(lungeAnim)
	lungeTrack.Priority = Enum.AnimationPriority.Action
	lungeTrack.Looped = false

	local jumpTrack = animator:LoadAnimation(jumpAnim)
	jumpTrack.Priority = Enum.AnimationPriority.Action
	jumpTrack.Looped = false

	-- State variables
	local isAttacking = false
	local isJumping = false
	local isDestroyed = false
	local comboStep = 0

	-- Start initial idle animation
	idleTrack:Play(0.2)

	-- Update Movement State based on ACTUAL Physical Motion
	local function updateMovementState()
		if isDestroyed or isAttacking or not model.Parent or humanoid.Health <= 0 then return end

		-- Horizontal physics velocity strictly detects if the NPC is in motion across the ground
		local horizVel = (rootPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude
		local isActuallyMoving = horizVel > 1.2

		if isActuallyMoving then
			if not walkTrack.IsPlaying then
				walkTrack:Play(0.15)
				idleTrack:Stop(0.15)
			end
			-- Synchronize leg swing speed to actual ground velocity to eliminate foot sliding
			local baseSpeed = humanoid.WalkSpeed > 0 and humanoid.WalkSpeed or 16
			walkTrack:AdjustSpeed(math.clamp(horizVel / baseSpeed, 0.7, 1.4))
		else
			if not idleTrack.IsPlaying then
				idleTrack:Play(0.15)
				walkTrack:Stop(0.15)
			end
		end
	end

	-- Listen for Humanoid running speed changes
	local runningConn = humanoid.Running:Connect(function()
		updateMovementState()
	end)

	-- Listen for continuous physical velocity updates via Heartbeat
	local heartbeatConn = RunService.Heartbeat:Connect(function()
		updateMovementState()
	end)

	local controller: BanditAnimController = {
		playAttack = function(isBoss: boolean, onStrike: (attackType: string) -> ())
			if isAttacking or isDestroyed then return end
			isAttacking = true

			-- Immediately stop walking when launching attack
			walkTrack:Stop(0.08)

			-- Advance 3-hit combo sequence
			comboStep = (comboStep % 3) + 1
			local currentTrack: AnimationTrack
			local attackType = "Slash"
			local strikeDelay = 0.22
			local totalDuration = 0.60

			if comboStep == 1 then
				currentTrack = slashTrack
				attackType = "Slash"
				strikeDelay = 0.22
				totalDuration = 0.58
				createSound(rootPart, "rbxassetid://9114223170", isBoss and 0.9 or 0.7, 1.15)
			elseif comboStep == 2 then
				currentTrack = overheadTrack
				attackType = "Overhead"
				strikeDelay = 0.28
				totalDuration = 0.68
				createSound(rootPart, "rbxassetid://9114223170", isBoss and 1.0 or 0.75, 0.92)
			else
				currentTrack = lungeTrack
				attackType = "Lunge"
				strikeDelay = 0.20
				totalDuration = 0.55
				createSound(rootPart, "rbxassetid://9114223170", isBoss and 0.9 or 0.7, 1.30)
			end

			currentTrack:Play(0.06)
			spawnWeaponSlashFX(rootPart, isBoss, attackType)

			-- Apply damage & impact VFX at strike window
			task.delay(strikeDelay, function()
				if not isDestroyed and model.Parent and humanoid.Health > 0 then
					onStrike(attackType)
				end
			end)

			-- Reset attack state after animation completes
			task.delay(totalDuration, function()
				isAttacking = false
				updateMovementState()
			end)
		end,

		triggerJump = function()
			if isJumping or isDestroyed then return end
			isJumping = true
			jumpTrack:Play(0.05)
			humanoid.Jump = true

			task.delay(0.6, function()
				isJumping = false
			end)
		end,

		stopAll = function()
			isDestroyed = true
			if runningConn then runningConn:Disconnect() end
			if heartbeatConn then heartbeatConn:Disconnect() end
			idleTrack:Stop(0.1)
			walkTrack:Stop(0.1)
			slashTrack:Stop(0.1)
			overheadTrack:Stop(0.1)
			lungeTrack:Stop(0.1)
			jumpTrack:Stop(0.1)
			idleTrack:Destroy()
			walkTrack:Destroy()
			slashTrack:Destroy()
			overheadTrack:Destroy()
			lungeTrack:Destroy()
			jumpTrack:Destroy()
		end,
	}

	return controller
end

-- ============================================================================
-- ENEMY DESIGN & RIGGING
-- ============================================================================
local function designEnemyModel(model: Model, isBoss: boolean, variantIndex: number)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = Instance.new("Humanoid")
		humanoid.Parent = model
	end
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.MaxHealth = isBoss and 650 or 120
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = isBoss and 15 or 16
	humanoid.JumpPower = 50

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
		bbg.Size = UDim2.new(0, isBoss and 180 or 120, 0, 42)
		bbg.StudsOffset = Vector3.new(0, isBoss and 4.0 or 2.8, 0)
		bbg.AlwaysOnTop = false
		bbg.LightInfluence = 0
		bbg.MaxDistance = 100
		bbg.Parent = targetHead

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "EnemyNameLabel"
		nameLabel.BackgroundTransparency = 1
		nameLabel.Size = UDim2.new(1, 0, 0, 18)
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
		barBg.Position = UDim2.new(0, 0, 0, 22)
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

-- ============================================================================
-- BANDIT BOSS GROUND STOMP SKILL IMPLEMENTATION
-- ============================================================================
local function executeBossGroundStomp(bossModel: Model, bossRoot: BasePart, bossHum: Humanoid, targetChar: Model?)
	-- 1. Telegraph & Overhead Warning
	local overheadHUD = bossModel:FindFirstChild("OverheadHUD", true) :: BillboardGui?
	local nameLabel = overheadHUD and overheadHUD:FindFirstChild("EnemyNameLabel") :: TextLabel?
	local origText = nameLabel and nameLabel.Text or bossModel.Name
	local origColor = nameLabel and nameLabel.TextColor3 or Color3.fromRGB(255, 75, 75)

	if nameLabel then
		nameLabel.Text = "! CRITICAL: EARTH STOMP !"
		nameLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
	end

	-- Crimson charge aura at feet
	local chargeMark = Instance.new("Part")
	chargeMark.Name = "BossStompChargeMark"
	chargeMark.Shape = Enum.PartType.Cylinder
	chargeMark.Size = Vector3.new(0.2, 6, 6)
	chargeMark.Material = Enum.Material.Neon
	chargeMark.Color = Color3.fromRGB(255, 50, 30)
	chargeMark.Transparency = 0.4
	chargeMark.CanCollide = false
	chargeMark.Anchored = true
	chargeMark.CFrame = CFrame.new(bossRoot.Position - Vector3.new(0, 2.7, 0)) * CFrame.Angles(0, 0, math.rad(90))
	chargeMark.Parent = Workspace
	Debris:AddItem(chargeMark, 1.2)

	createSound(bossRoot, "rbxassetid://9114222144", 0.7, 0.8)

	-- 2. Upward Leap (Ascend into the air)
	task.wait(0.35)
	if not bossModel.Parent or bossHum.Health <= 0 then
		if chargeMark.Parent then chargeMark:Destroy() end
		return
	end

	bossRoot.AssemblyLinearVelocity = Vector3.new(0, 40, 0)

	-- 3. Downward Slam (Plunge towards ground)
	task.wait(0.4)
	if not bossModel.Parent or bossHum.Health <= 0 then
		if chargeMark.Parent then chargeMark:Destroy() end
		return
	end

	bossRoot.AssemblyLinearVelocity = Vector3.new(0, -65, 0)

	-- Wait until impact
	task.wait(0.25)
	if chargeMark.Parent then chargeMark:Destroy() end
	if not bossModel.Parent or bossHum.Health <= 0 then return end

	local impactPos = bossRoot.Position - Vector3.new(0, 2.5, 0)

	-- 4. Impact Blast Audio
	createSound(bossRoot, "rbxassetid://9114221976", 1.0, 0.85)

	-- 5. Expanding Shockwave Ring (Cylinder Tween)
	local shockwave = Instance.new("Part")
	shockwave.Name = "BossGroundStompShockwave"
	shockwave.Shape = Enum.PartType.Cylinder
	shockwave.Size = Vector3.new(0.3, 2, 2)
	shockwave.Material = Enum.Material.Neon
	shockwave.Color = Color3.fromRGB(255, 120, 40)
	shockwave.Transparency = 0.15
	shockwave.CanCollide = false
	shockwave.Anchored = true
	shockwave.CFrame = CFrame.new(impactPos) * CFrame.Angles(0, 0, math.rad(90))
	shockwave.Parent = Workspace

	local shockTween = TweenService:Create(shockwave, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.05, 34, 34),
		Transparency = 1.0,
	})
	shockTween:Play()
	Debris:AddItem(shockwave, 0.5)

	-- 6. Radial Slate Rock Debris Particles
	for i = 1, 10 do
		local rock = Instance.new("Part")
		rock.Name = "StompDebrisRock"
		local s = math.random(8, 16) / 10
		rock.Size = Vector3.new(s, s * 0.7, s)
		rock.Material = Enum.Material.Slate
		rock.Color = Color3.fromRGB(65, 60, 55)
		rock.CanCollide = false
		rock.Anchored = false
		local angle = (i / 10) * math.pi * 2
		local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
		rock.CFrame = CFrame.new(impactPos + dir * 1.5 + Vector3.new(0, 0.5, 0))
		rock.AssemblyLinearVelocity = dir * math.random(25, 45) + Vector3.new(0, math.random(15, 30), 0)
		rock.AssemblyAngularVelocity = Vector3.new(math.random(-15, 15), math.random(-15, 15), math.random(-15, 15))
		rock.Parent = Workspace

		task.delay(0.6, function()
			if rock.Parent then
				local rTw = TweenService:Create(rock, TweenInfo.new(0.3), { Transparency = 1.0 })
				rTw:Play()
			end
		end)
		Debris:AddItem(rock, 1.0)
	end

	-- 7. Hitbox, Damage & Ground-Clamped Knockback
	local stompRadius = 24.0
	local stompBaseDamage = 50

	for _, p in ipairs(Players:GetPlayers()) do
		local pChar = p.Character
		local pHum = pChar and pChar:FindFirstChildOfClass("Humanoid")
		local pRoot = pChar and pChar:FindFirstChild("HumanoidRootPart") :: BasePart?

		if pHum and pHum.Health > 0 and pRoot then
			local dist = (pRoot.Position - impactPos).Magnitude
			if dist <= stompRadius then
				local def = p:GetAttribute("Defense") or 5
				local finalDmg = math.max(12, stompBaseDamage - def)
				pHum:TakeDamage(finalDmg)

				local pushDir = (pRoot.Position - impactPos) * Vector3.new(1, 0, 1)
				local pushUnit = if pushDir.Magnitude > 0.1 then pushDir.Unit else pRoot.CFrame.LookVector
				pRoot.AssemblyLinearVelocity = pushUnit * 42 + Vector3.new(0, 8, 0)

				task.delay(0.3, function()
					if pRoot and pRoot.Parent then
						local groundY = getSurfaceY(pRoot.Position, { pChar })
						if groundY and pRoot.Position.Y > groundY + 8 then
							pRoot.CFrame = CFrame.new(pRoot.Position.X, groundY + 3, pRoot.Position.Z)
							pRoot.AssemblyLinearVelocity = Vector3.zero
						end
					end
				end)
			end
		end
	end

	task.delay(0.8, function()
		if nameLabel and nameLabel.Parent then
			nameLabel.Text = origText
			nameLabel.TextColor3 = origColor
		end
	end)
end

-- ============================================================================
-- BANDIT SPAWN & AI LOOP
-- ============================================================================
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
	model:PivotTo(spawnCFrame)
	model.Parent = enemiesFolder

	-- Ensure server has authoritative network ownership over NPC movement
	if root:CanSetNetworkOwnership() then
		root:SetNetworkOwner(nil)
	end

	-- Apply custom design, armor, helmet, weapons directly to the positioned enemy
	designEnemyModel(model, isBoss, variantIndex)

	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local chaseDist = isBoss and 90 or 60
	local attackDist = 5.2
	local baseDmg = isBoss and 40 or 16
	local attackCd = isBoss and 1.2 or 1.4
	local nextAttack = 0
	local isDead = false

	-- Setup velocity-verified animations
	local anim = setupBanditAnimations(model, humanoid, root)

	-- Boss ground stomp timer
	local nextBossStomp = os.clock() + math.random(5, 9)
	local isBossStomping = false

	humanoid.Died:Connect(function()
		if isDead then return end
		isDead = true

		anim.stopAll()

		local killerPlayer: Player? = nil
		local closestDist = 70
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

	-- AI Movement, Jumping, Combat & Boss Skill Loop
	local homePos = spawnCFrame.Position
	local MAX_LEASH_DIST = isBoss and 70 or 42
	local AGGRO_RANGE = isBoss and 55 or 32
	local returningStartTime: number? = nil
	local lastJumpCheck = 0

	task.spawn(function()
		while model and model.Parent and not isDead do
			if humanoid.Health > 0 and root and not isBossStomping then
				local currentPos = root.Position
				local distFromHome = (currentPos - homePos).Magnitude

				local targetPlayer: Player? = nil
				local targetHum: Humanoid? = nil
				local targetRoot: BasePart? = nil
				local closestDist = AGGRO_RANGE

				-- Search for targets within leash bounds
				if distFromHome <= MAX_LEASH_DIST then
					for _, p in ipairs(Players:GetPlayers()) do
						local char = p.Character
						local pHum = char and char:FindFirstChildOfClass("Humanoid")
						local pRoot = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?

						if pHum and pHum.Health > 0 and pRoot then
							local distToEnemy = (pRoot.Position - currentPos).Magnitude
							local playerDistFromHome = (pRoot.Position - homePos).Magnitude

							if distToEnemy < closestDist and playerDistFromHome <= MAX_LEASH_DIST then
								closestDist = distToEnemy
								targetPlayer = p
								targetHum = pHum
								targetRoot = pRoot
							end
						end
					end
				end

				-- State 1: Active Combat Chase & Attack
				if targetRoot and targetHum then
					returningStartTime = nil

					-- Check Boss Ground Stomp Skill Trigger
					if isBoss and closestDist <= 28 and os.clock() >= nextBossStomp then
						isBossStomping = true
						humanoid:MoveTo(root.Position) -- Halt movement during stomp
						executeBossGroundStomp(model, root, humanoid, targetPlayer and targetPlayer.Character)
						isBossStomping = false
						nextBossStomp = os.clock() + math.random(11, 14)
					elseif closestDist <= attackDist then
						-- In melee range: Stop moving and face the player in battle stance
						humanoid:MoveTo(root.Position)
						local lookDir = (targetRoot.Position - currentPos) * Vector3.new(1, 0, 1)
						if lookDir.Magnitude > 0.1 then
							root.CFrame = CFrame.lookAt(currentPos, currentPos + lookDir.Unit)
						end

						-- Execute combo attack if cooldown is ready
						if os.clock() >= nextAttack then
							nextAttack = os.clock() + attackCd

							anim.playAttack(isBoss, function(attackType: string)
								if root and root.Parent and targetHum and targetHum.Health > 0 and targetRoot then
									local strikeDist = (targetRoot.Position - root.Position).Magnitude
									if strikeDist <= attackDist + 2.5 then
										-- Hit spark flash
										spawnHitSpark(targetRoot.Position, isBoss)

										-- Flesh / armor impact audio
										createSound(targetRoot, "rbxassetid://9114221779", isBoss and 0.9 or 0.6, 1.25)

										local def = (targetPlayer and targetPlayer:GetAttribute("Defense")) or 5
										local multiplier = (attackType == "Overhead" and 1.25) or (attackType == "Lunge" and 1.1) or 1.0
										local finalDmg = math.max(1, math.floor((baseDmg * multiplier) - def))
										targetHum:TakeDamage(finalDmg)
									end
								end
							end)
						end
					else
						-- Outside melee range: Pursue target!
						humanoid:MoveTo(targetRoot.Position)

						-- Obstacle / Elevation Jump Checks
						local now = os.clock()
						if now - lastJumpCheck >= 0.8 and humanoid.FloorMaterial ~= Enum.Material.Air then
							lastJumpCheck = now

							-- 1. Elevation pursuit: jump if target is on a higher ledge or jumping
							local heightDiff = targetRoot.Position.Y - currentPos.Y
							if heightDiff > 2.2 and closestDist <= 18 then
								anim.triggerJump()
							else
								-- 2. Obstacle in front check via raycast
								local rayParams = RaycastParams.new()
								rayParams.FilterType = Enum.RaycastFilterType.Exclude
								rayParams.FilterDescendantsInstances = { model, targetPlayer and targetPlayer.Character or model }
								local forwardRay = Workspace:Raycast(currentPos - Vector3.new(0, 1.2, 0), root.CFrame.LookVector * 5.0, rayParams)
								if forwardRay and forwardRay.Instance and forwardRay.Instance.CanCollide then
									anim.triggerJump()
								end
							end
						end
					end

				else
					-- State 2: Returning Home or Idling
					if distFromHome > 5 then
						if not returningStartTime then
							returningStartTime = os.clock()
						end

						local timeReturning = os.clock() - returningStartTime
						if timeReturning >= 15 then
							-- Teleport back if stuck for > 15 seconds
							model:PivotTo(spawnCFrame)
							returningStartTime = nil
							humanoid:MoveTo(homePos)
						else
							humanoid:MoveTo(homePos)

							-- Check forward obstacle on return path
							local now = os.clock()
							if now - lastJumpCheck >= 1.0 and humanoid.FloorMaterial ~= Enum.Material.Air then
								lastJumpCheck = now
								local rayParams = RaycastParams.new()
								rayParams.FilterType = Enum.RaycastFilterType.Exclude
								rayParams.FilterDescendantsInstances = { model }
								local returnRay = Workspace:Raycast(currentPos - Vector3.new(0, 1.2, 0), root.CFrame.LookVector * 4.5, rayParams)
								if returnRay and returnRay.Instance and returnRay.Instance.CanCollide then
									anim.triggerJump()
								end
							end
						end
					else
						-- At home position: Stop walking and idle cleanly
						returningStartTime = nil
						humanoid:MoveTo(root.Position)
					end
				end
			end
			task.wait(0.2)
		end
	end)
end

-- ============================================================================
-- INITIALIZE BANDIT OUTPOST AT BanditVillage POSITIONS
-- ============================================================================
local function initBanditVillage()
	-- Delete all legacy bandit models inside Workspace.BanditVillage to prevent old scripts from running
	local bv = Workspace:FindFirstChild("BanditVillage")
	if bv then
		for _, ch in ipairs(bv:GetChildren()) do
			if string.find(ch.Name, "Bandit") and not string.find(ch.Name, "Tent") and not string.find(ch.Name, "Gate") and not string.find(ch.Name, "Camp") then
				ch:Destroy()
			end
		end
	end

	-- Also clear enemiesFolder
	for _, old in ipairs(enemiesFolder:GetChildren()) do
		if old:FindFirstChildOfClass("Humanoid") then
			old:Destroy()
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

	print(string.format("[BanditSpawnerService] Initialized 1 Boss + %d Bandits with velocity-synchronized walking and 3-hit combo attacks.", #BANDIT_SPAWNS))
end

task.spawn(initBanditVillage)
