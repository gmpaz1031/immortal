--!strict
--[[
    CaveEnemyAI.luau
    Universal, modular AI controller for Cave Enemies and Swordsmen.
    Controls:
    - Target discovery, chasing, line of sight, and return-to-spawn leash
    - Kinematic Motor6D attack animations (Spider bite, Assassin stab, Behind attack, Senior Multi-slash, Swordsman slash)
    - Hitbox verification & server-side damage validation via DamageService
    - Strict server-side cooldown enforcement:
      * Spider Mother Poison Spit (5.0s)
      * Assassin Behind Attack (3.5s)
      * Senior Assassin Behind Attack (3.5s)
      * Senior Assassin Multi-Slash (10.0s)
    - Standby mode for Swordmaster, Four Pillar Assassin, Supreme Assassin
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local DamageService = nil
pcall(function()
	local sss = game:GetService("ServerScriptService")
	local ds = sss:FindFirstChild("DamageService", true)
	if ds and ds:IsA("ModuleScript") then
		DamageService = require(ds)
	end
end)

local function applyDamage(targetHum: Humanoid, damage: number, skillName: string?)
	if DamageService and DamageService.applyDamage then
		DamageService.applyDamage(targetHum, damage, nil, skillName)
	else
		targetHum:TakeDamage(damage)
	end
end

local function hasLineOfSight(origin: Vector3, targetPos: Vector3, ignoreList: { Instance }): boolean
	if DamageService and DamageService.hasLineOfSight then
		return DamageService.hasLineOfSight(origin, targetPos, ignoreList)
	end
	local direction = targetPos - origin
	local distance = direction.Magnitude
	if distance < 1 then return true end
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = ignoreList
	rayParams.IgnoreWater = true
	local result = Workspace:Raycast(origin, direction.Unit * distance, rayParams)
	if result and result.Instance and result.Instance.CanCollide and result.Instance.Transparency < 0.85 then
		return false
	end
	return true
end

local function findTargetsInRadius(center: Vector3, radius: number): { Humanoid }
	if DamageService and DamageService.findTargetsInRadius then
		return DamageService.findTargetsInRadius(center, radius, nil, false)
	end
	local found = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if hum and root and hum.Health > 0 then
			if (root.Position - center).Magnitude <= radius then
				table.insert(found, hum)
			end
		end
	end
	return found
end

local CaveEnemyConfig = nil
pcall(function()
	local rs = game:GetService("ReplicatedStorage")
	local shared = rs:FindFirstChild("Shared")
	if shared and shared:FindFirstChild("CaveEnemyConfig") then
		CaveEnemyConfig = require(shared.CaveEnemyConfig)
	end
end)
if not CaveEnemyConfig then
	pcall(function()
		local sss = game:GetService("ServerScriptService")
		local cfg = sss:FindFirstChild("CaveEnemyConfig", true)
		if cfg then CaveEnemyConfig = require(cfg) end
	end)
end

local CaveEnemyAI = {}

--------------------------------------------------------------------------------
-- Visual Effects Helpers
--------------------------------------------------------------------------------
local function spawnVFXEmitter(position: Vector3, color1: Color3, color2: Color3, count: number, lifetime: number)
	local p = Instance.new("Part")
	p.Size = Vector3.new(0.5, 0.5, 0.5)
	p.CFrame = CFrame.new(position)
	p.Transparency = 1
	p.CanCollide = false
	p.Anchored = true
	p.Parent = Workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color1, color2)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
	emitter.Lifetime = NumberRange.new(lifetime * 0.7, lifetime)
	emitter.Rate = 0
	emitter.Speed = NumberRange.new(4, 10)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = p
	emitter:Emit(count)

	Debris:AddItem(p, lifetime + 0.5)
end

--------------------------------------------------------------------------------
-- 1. Attack Animations (Kinematic Motor6D Controller)
--------------------------------------------------------------------------------

-- Spider Bite Attack
local function playSpiderBiteAnimation(model: Model, isMother: boolean)
	local thorax = model:FindFirstChild("Thorax") :: BasePart?
	if not thorax then return end

	local leftJoint = thorax:FindFirstChild("LeftFangJoint") :: Motor6D?
	local rightJoint = thorax:FindFirstChild("RightFangJoint") :: Motor6D?
	local hrp = model.PrimaryPart
	if not leftJoint or not rightJoint or not hrp then return end

	local origL = leftJoint.C0
	local origR = rightJoint.C0

	-- 1. Windup: Fangs open wide
	leftJoint.C0 = origL * CFrame.Angles(0, math.rad(-30), 0)
	rightJoint.C0 = origR * CFrame.Angles(0, math.rad(30), 0)

	-- 2. Snap Bite Phase (0.12s later)
	task.delay(0.12, function()
		if leftJoint.Parent and rightJoint.Parent then
			-- Snap fangs inward tightly
			leftJoint.C0 = origL * CFrame.Angles(math.rad(25), math.rad(45), 0)
			rightJoint.C0 = origR * CFrame.Angles(math.rad(25), math.rad(-45), 0)

			-- Venom bite impact spark
			local biteColor = isMother and Color3.fromRGB(60, 255, 90) or Color3.fromRGB(255, 40, 60)
			spawnVFXEmitter(thorax.Position + thorax.CFrame.LookVector * (isMother and 3.5 or 1.6), biteColor, Color3.fromRGB(20, 10, 20), 18, 0.35)
		end
	end)

	-- 3. Return to resting posture
	task.delay(0.35, function()
		if leftJoint.Parent and rightJoint.Parent then
			leftJoint.C0 = origL
			rightJoint.C0 = origR
		end
	end)
end

-- Spider Mother Poison Spit Projectile Attack
local function launchPoisonSpit(model: Model, targetPos: Vector3, damage: number)
	local thorax = model:FindFirstChild("Thorax") :: BasePart?
	if not thorax then return end

	local startPos = thorax.Position + thorax.CFrame.LookVector * 4.0 + Vector3.new(0, 1, 0)
	local direction = (targetPos - startPos)
	local dist = direction.Magnitude
	if dist < 1 then return end
	local unitDir = direction.Unit

	-- Spit Charge VFX at mouth
	spawnVFXEmitter(startPos, Color3.fromRGB(80, 255, 100), Color3.fromRGB(30, 150, 40), 20, 0.4)

	-- Poison Orb Part
	local orb = Instance.new("Part")
	orb.Name = "PoisonSpitOrb"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(2.2, 2.2, 2.2)
	orb.Color = Color3.fromRGB(50, 240, 80)
	orb.Material = Enum.Material.Neon
	orb.CanCollide = false
	orb.Anchored = true
	orb.CFrame = CFrame.new(startPos, startPos + unitDir)
	orb.Parent = Workspace

	local trail = Instance.new("ParticleEmitter")
	trail.Color = ColorSequence.new(Color3.fromRGB(60, 255, 90), Color3.fromRGB(20, 80, 30))
	trail.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.8), NumberSequenceKeypoint.new(1, 0) })
	trail.Lifetime = NumberRange.new(0.25, 0.4)
	trail.Rate = 45
	trail.Speed = NumberRange.new(1, 4)
	trail.Parent = orb

	-- Move projectile with Tween
	local travelTime = math.clamp(dist / 55, 0.2, 1.5)
	local endPos = targetPos + Vector3.new(0, 0.5, 0)

	local tween = TweenService:Create(orb, TweenInfo.new(travelTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = CFrame.new(endPos)
	})
	tween:Play()

	tween.Completed:Connect(function()
		orb:Destroy()

		-- Impact Toxic Pool / Burst (8 stud AoE radius)
		local impactCenter = endPos
		spawnVFXEmitter(impactCenter, Color3.fromRGB(70, 255, 90), Color3.fromRGB(15, 60, 25), 45, 0.8)

		-- Apply AoE damage to living players within 8 studs
		local targets = findTargetsInRadius(impactCenter, 8.5)
		for _, hum in ipairs(targets) do
			if hum.Parent and hum.Parent ~= model then
				local char = hum.Parent
				local player = Players:GetPlayerFromCharacter(char)
				if player then
					applyDamage(hum, damage, "Poison Spit")
				end
			end
		end
	end)
end

-- Dagger / Sword Slash Animation
local function playWeaponThrustAnimation(model: Model, isCrossSlash: boolean)
	local torso = model:FindFirstChild("Torso") :: BasePart?
	if not torso then return end

	local rShoulder = torso:FindFirstChild("Right Shoulder") :: Motor6D?
	local lShoulder = torso:FindFirstChild("Left Shoulder") :: Motor6D?
	if not rShoulder then return end

	local origR = rShoulder.C0
	local origL = lShoulder and lShoulder.C0

	-- 1. Thrust/Slash Phase
	rShoulder.C0 = origR * CFrame.Angles(math.rad(-85), math.rad(25), math.rad(30))
	if isCrossSlash and lShoulder and origL then
		lShoulder.C0 = origL * CFrame.Angles(math.rad(-85), math.rad(-25), math.rad(-30))
	end

	-- Weapon blade flash VFX
	local hand = model:FindFirstChild("Right Arm") :: BasePart?
	if hand then
		spawnVFXEmitter(hand.Position + hand.CFrame.LookVector * 1.5, Color3.fromRGB(240, 240, 255), Color3.fromRGB(180, 50, 50), 12, 0.25)
	end

	-- 2. Recovery Phase
	task.delay(0.18, function()
		if rShoulder.Parent then
			rShoulder.C0 = origR * CFrame.Angles(math.rad(15), 0, 0)
		end
		if isCrossSlash and lShoulder and lShoulder.Parent and origL then
			lShoulder.C0 = origL * CFrame.Angles(math.rad(15), 0, 0)
		end
	end)

	-- 3. Reset
	task.delay(0.32, function()
		if rShoulder.Parent then
			rShoulder.C0 = origR
		end
		if lShoulder and lShoulder.Parent and origL then
			lShoulder.C0 = origL
		end
	end)
end

--------------------------------------------------------------------------------
-- 2. Assassin Disappear and Behind Attack with Raycast Obstacle Safety
--------------------------------------------------------------------------------
local function executeBehindAttack(model: Model, targetChar: Model, damage: number)
	local hrp = model.PrimaryPart
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
	if not hrp or not targetRoot or not targetHum or targetHum.Health <= 0 then return end

	-- 1. Disappear: Trigger smoke puff & set model transparent
	spawnVFXEmitter(hrp.Position, Color3.fromRGB(20, 15, 25), Color3.fromRGB(5, 5, 8), 35, 0.5)

	local hiddenParts = {}
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p.Transparency < 0.9 then
			hiddenParts[p] = p.Transparency
			p.Transparency = 1
		end
	end

	-- 2. Compute Safe Position Behind Player (3.5 studs behind target)
	local targetCF = targetRoot.CFrame
	local desiredPos = targetCF.Position + (targetCF.LookVector * -3.5) + Vector3.new(0, 0.2, 0)

	-- Raycast safety validation: check line between target and desired spot
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { model, targetChar }
	rayParams.IgnoreWater = true

	local rayResult = Workspace:Raycast(targetCF.Position, (desiredPos - targetCF.Position), rayParams)
	local finalPos = desiredPos
	if rayResult and rayResult.Instance and rayResult.Instance.CanCollide then
		-- Obstacle in the way: position 1.5 studs from wall to prevent clipping inside
		finalPos = rayResult.Position + rayResult.Normal * 1.5
	end

	-- Face directly towards the player's back
	local finalCF = CFrame.new(finalPos, targetCF.Position)

	-- 3. Reappear behind player (after 0.35s vanish duration)
	task.delay(0.35, function()
		if not model.Parent or not hrp.Parent then return end

		hrp.CFrame = finalCF

		-- Restore visibility
		for part, origTransp in pairs(hiddenParts) do
			if part.Parent then
				part.Transparency = origTransp
			end
		end

		-- Shadow Burst on Reappearance
		spawnVFXEmitter(finalPos, Color3.fromRGB(180, 20, 30), Color3.fromRGB(30, 10, 20), 40, 0.4)

		-- Execute surprise dagger backstab
		playWeaponThrustAnimation(model, true)

		-- Hitbox check: if still in melee range, deal backstab damage
		if targetHum.Health > 0 and (targetRoot.Position - finalPos).Magnitude <= 7.0 then
			applyDamage(targetHum, damage, "Surprise Backstab")
		end
	end)
end

--------------------------------------------------------------------------------
-- 3. Senior Assassin Multiple Rapid Slash Skill (10s Cooldown)
--------------------------------------------------------------------------------
local function executeMultipleSlashSkill(model: Model, targetChar: Model, slashDmg: number)
	local hrp = model.PrimaryPart
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
	if not hrp or not targetRoot or not targetHum or targetHum.Health <= 0 then return end

	-- 1. Anticipation Flash
	spawnVFXEmitter(hrp.Position, Color3.fromRGB(255, 60, 40), Color3.fromRGB(150, 10, 10), 20, 0.3)

	-- 3 Rapid Slashes with individual timing and hit-registration safeguards
	local slashTimes = { 0.12, 0.32, 0.55 }
	local hitTracker = {} -- Prevents duplicate damage during each slash window

	for i, delayTime in ipairs(slashTimes) do
		task.delay(delayTime, function()
			if not model.Parent or targetHum.Health <= 0 then return end

			local isLastSlash = (i == 3)
			playWeaponThrustAnimation(model, isLastSlash)

			-- Check melee range for this specific slash
			if (targetRoot.Position - hrp.Position).Magnitude <= 7.5 then
				if not hitTracker[i] then
					hitTracker[i] = true
					applyDamage(targetHum, slashDmg, string.format("Multi-Slash #%d", i))
				end
			end
		end)
	end
end

--------------------------------------------------------------------------------
-- 4. Target Acquisition Helper
--------------------------------------------------------------------------------
local function findNearestLivingPlayer(rootPart: BasePart, maxDist: number): (Humanoid?, BasePart?, number)
	local nearestHum, nearestRoot, minDist = nil, nil, maxDist

	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local pRoot = char and char:FindFirstChild("HumanoidRootPart")

		if hum and pRoot and hum.Health > 0 then
			local dist = (pRoot.Position - rootPart.Position).Magnitude
			if dist <= minDist then
				if hasLineOfSight(rootPart.Position, pRoot.Position, { rootPart.Parent, char }) then
					nearestHum = hum
					nearestRoot = pRoot
					minDist = dist
				end
			end
		end
	end

	return nearestHum, nearestRoot, minDist
end

--------------------------------------------------------------------------------
-- 5. Attach & Run Autonomous AI on an Enemy Model
--------------------------------------------------------------------------------
function CaveEnemyAI.attach(model: Model, enemyTypeName: string, customSpawnCF: CFrame?)
	local stats = CaveEnemyConfig[enemyTypeName]
	if not stats then
		warn("[CaveEnemyAI] Unknown enemy type:", enemyTypeName)
		return
	end

	local hrp = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then
		warn("[CaveEnemyAI] Model missing RootPart or Humanoid:", model.Name)
		return
	end

	local spawnCF = customSpawnCF or hrp.CFrame
	local isDead = false

	-- STANDBY CHECK: Bosses/semi-bosses on standby do not engage in combat loops yet
	if stats.IsStandby then
		print(string.format("🛡️ [CaveEnemyAI] %s is currently on STANDBY (awaiting future skills).", stats.Title or model.Name))
		return
	end

	-- Cooldown Tracker
	local nextMeleeAttack = 0
	local nextSkillTime: { [string]: number } = {}
	if stats.SpecialCooldowns then
		for skillName, cd in pairs(stats.SpecialCooldowns) do
			-- Stagger initial cooldowns slightly so skills don't all fire on first frame
			nextSkillTime[skillName] = tick() + math.random(1, 3)
		end
	end

	-- Death Handler
	humanoid.Died:Connect(function()
		if isDead then return end
		isDead = true

		-- Clean up after 2.5s
		task.delay(2.5, function()
			if model and model.Parent then
				model:Destroy()
			end
		end)
	end)

	-- Active AI & Combat Loop
	task.spawn(function()
		while not isDead and model.Parent and humanoid.Health > 0 do
			local targetHum, targetRoot, dist = findNearestLivingPlayer(hrp, stats.ChaseRange)

			if targetHum and targetRoot then
				local targetChar = targetHum.Parent :: Model

				-- 1. Check Special Skills (if any are off cooldown)
				local usedSkill = false

				-- Spider Mother: Poison Spit (5.0s cooldown)
				if enemyTypeName == "SpiderMother" and nextSkillTime["PoisonSpit"] and tick() >= nextSkillTime["PoisonSpit"] then
					if dist > 8 and dist <= stats.ChaseRange then
						nextSkillTime["PoisonSpit"] = tick() + 5.0
						usedSkill = true
						launchPoisonSpit(model, targetRoot.Position, 32)
					end
				end

				-- Senior Assassin: Multiple Slash (10.0s cooldown)
				if not usedSkill and enemyTypeName == "SeniorAssassin" and nextSkillTime["MultipleSlash"] and tick() >= nextSkillTime["MultipleSlash"] then
					if dist <= stats.AttackRange + 2 then
						nextSkillTime["MultipleSlash"] = tick() + 10.0
						usedSkill = true
						executeMultipleSlashSkill(model, targetChar, 12)
					end
				end

				-- Assassin & Senior Assassin: Disappear and Behind Attack (3.5s cooldown)
				if not usedSkill and (enemyTypeName == "Assassin" or enemyTypeName == "SeniorAssassin") then
					if nextSkillTime["BehindAttack"] and tick() >= nextSkillTime["BehindAttack"] then
						nextSkillTime["BehindAttack"] = tick() + 3.5
						usedSkill = true
						local behindDmg = enemyTypeName == "SeniorAssassin" and 25 or 22
						executeBehindAttack(model, targetChar, behindDmg)
					end
				end

				-- 2. Basic Melee Attack (Spider Bite, Assassin Stab, Swordsman Slash)
				if not usedSkill and dist <= stats.AttackRange and tick() >= nextMeleeAttack then
					nextMeleeAttack = tick() + stats.AttackCooldown

					if enemyTypeName:find("Spider") then
						playSpiderBiteAnimation(model, enemyTypeName == "SpiderMother")
					else
						playWeaponThrustAnimation(model, false)
					end

					applyDamage(targetHum, stats.BaseDamage, stats.Title or "Melee Strike")
				end

				-- 3. Navigation Chasing
				humanoid:MoveTo(targetRoot.Position)
			else
				-- Leash return towards spawn point if wandering too far
				if (hrp.Position - spawnCF.Position).Magnitude > 25 then
					humanoid:MoveTo(spawnCF.Position)
				end
			end

			task.wait(0.25)
		end
	end)
end

return CaveEnemyAI
