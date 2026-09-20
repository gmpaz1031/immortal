--!strict
--[[
    DemonCultAI.luau
    Authoritative server-side AI controller for all Heavenly Demon Cult enemies.

    Architecture mirrors CaveEnemyAI.luau exactly:
      - Target acquisition with LoS and leash range
      - Kinematic Motor6D slash/punch animations
      - Server-side cooldown tracking
      - DamageService integration
      - Clean death handling

    Enemy behaviours:
      DemonCultist          — sword slash
      SeniorDemonCultist    — flaming slash (fire VFX on hit)
      DemonicElder          — near pull palm + far flame projectiles
      FlameDemoness         — flame punch + shockwave + pull
      PoisonDemoness        — claw + poison orb + poison pool
      FistDemon             — heavy punch + ground smash + dash
      SwordDemon            — sword slash + cross slash + sword wave + shadow step
      SupremeDemon          — STANDBY (framework only, skills on standby)
      BloodDemon            — STANDBY (framework only, skills on standby)
]]

local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris    = game:GetService("Debris")

-- Load DamageService (same pattern as CaveEnemyAI)
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
	local dir = targetPos - origin
	local dist = dir.Magnitude
	if dist < 1 then return true end
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = ignoreList
	rp.IgnoreWater = true
	local res = Workspace:Raycast(origin, dir.Unit * dist, rp)
	if res and res.Instance and res.Instance.CanCollide and res.Instance.Transparency < 0.85 then return false end
	return true
end

-- Load DemonCultConfig
local DemonCultConfig = nil
pcall(function()
	local rs = game:GetService("ReplicatedStorage")
	local shared = rs:FindFirstChild("Shared")
	if shared and shared:FindFirstChild("DemonCultConfig") then
		DemonCultConfig = require(shared.DemonCultConfig)
	end
end)

local DemonCultAI = {}

--------------------------------------------------------------------------------
-- VFX Helper
--------------------------------------------------------------------------------
local function spawnVFX(position: Vector3, color1: Color3, color2: Color3, count: number, lifetime: number)
	local p = Instance.new("Part")
	p.Size = Vector3.new(0.5, 0.5, 0.5)
	p.CFrame = CFrame.new(position)
	p.Transparency = 1
	p.CanCollide = false
	p.Anchored = true
	p.Parent = Workspace

	local em = Instance.new("ParticleEmitter")
	em.Color = ColorSequence.new(color1, color2)
	em.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 0) })
	em.Lifetime = NumberRange.new(lifetime * 0.7, lifetime)
	em.Rate = 0
	em.Speed = NumberRange.new(5, 12)
	em.SpreadAngle = Vector2.new(180, 180)
	em.Parent = p
	em:Emit(count)
	Debris:AddItem(p, lifetime + 0.5)
end

--------------------------------------------------------------------------------
-- Shared Weapon Slash Animation (Motor6D)
--------------------------------------------------------------------------------
local function playSlashAnimation(model: Model, isCross: boolean)
	local torso = model:FindFirstChild("Torso") :: BasePart?
	if not torso then return end
	local rShoulder = torso:FindFirstChild("Right Shoulder") :: Motor6D?
	local lShoulder = torso:FindFirstChild("Left Shoulder") :: Motor6D?
	if not rShoulder then return end

	local origR = rShoulder.C0
	local origL = lShoulder and lShoulder.C0

	rShoulder.C0 = origR * CFrame.Angles(math.rad(-80), math.rad(20), math.rad(25))
	if isCross and lShoulder and origL then
		lShoulder.C0 = origL * CFrame.Angles(math.rad(-80), math.rad(-20), math.rad(-25))
	end

	-- VFX at right hand
	local rArm = model:FindFirstChild("Right Arm") :: BasePart?
	if rArm then
		spawnVFX(rArm.Position + rArm.CFrame.LookVector * 1.5, Color3.fromRGB(255, 40, 30), Color3.fromRGB(80, 5, 5), 14, 0.25)
		-- Flash weapon trail
		local blade = model:FindFirstChild("DemonicBlade") :: BasePart?
		if blade then
			local trail = blade:FindFirstChild("WeaponTrail") :: Trail?
			if trail then
				trail.Enabled = true
				task.delay(0.25, function() if trail and trail.Parent then trail.Enabled = false end end)
			end
		end
	end

	task.delay(0.18, function()
		if rShoulder.Parent then rShoulder.C0 = origR * CFrame.Angles(math.rad(15), 0, 0) end
		if isCross and lShoulder and lShoulder.Parent and origL then lShoulder.C0 = origL * CFrame.Angles(math.rad(15), 0, 0) end
	end)
	task.delay(0.32, function()
		if rShoulder.Parent then rShoulder.C0 = origR end
		if lShoulder and lShoulder.Parent and origL then lShoulder.C0 = origL end
	end)
end

--------------------------------------------------------------------------------
-- Punch Animation (Motor6D)
--------------------------------------------------------------------------------
local function playPunchAnimation(model: Model, armName: string)
	local torso = model:FindFirstChild("Torso") :: BasePart?
	if not torso then return end
	local shoulder = torso:FindFirstChild(armName == "Right Arm" and "Right Shoulder" or "Left Shoulder") :: Motor6D?
	if not shoulder then return end
	local orig = shoulder.C0
	shoulder.C0 = orig * CFrame.Angles(math.rad(-90), 0, 0)
	local arm = model:FindFirstChild(armName) :: BasePart?
	if arm then
		spawnVFX(arm.Position + arm.CFrame.LookVector * 1.2, Color3.fromRGB(255, 100, 10), Color3.fromRGB(60, 10, 5), 12, 0.2)
	end
	task.delay(0.15, function() if shoulder.Parent then shoulder.C0 = orig * CFrame.Angles(math.rad(20), 0, 0) end end)
	task.delay(0.28, function() if shoulder.Parent then shoulder.C0 = orig end end)
end

--------------------------------------------------------------------------------
-- Demonic Elder: Flame Palm Projectile
--------------------------------------------------------------------------------
local function launchFlamePalm(model: Model, targetPos: Vector3, damage: number)
	local torso = model:FindFirstChild("Torso") :: BasePart?
	if not torso then return end

	local startPos = torso.Position + torso.CFrame.LookVector * 2 + Vector3.new(0, 1, 0)
	local dir = (targetPos - startPos)
	local dist = dir.Magnitude
	if dist < 1 then return end

	-- Charge flash
	spawnVFX(startPos, Color3.fromRGB(255, 60, 10), Color3.fromRGB(120, 20, 5), 18, 0.3)

	local orb = Instance.new("Part")
	orb.Name = "FlamePalmOrb"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(2, 2, 2)
	orb.Color = Color3.fromRGB(255, 60, 10)
	orb.Material = Enum.Material.Neon
	orb.CanCollide = false
	orb.Anchored = true
	orb.CFrame = CFrame.new(startPos, startPos + dir.Unit)
	orb.Parent = Workspace

	local trail = Instance.new("ParticleEmitter", orb)
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 80, 10), Color3.fromRGB(60, 10, 5))
	trail.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 0) })
	trail.Lifetime = NumberRange.new(0.2, 0.4)
	trail.Rate = 40
	trail.Speed = NumberRange.new(1, 3)

	local travelTime = math.clamp(dist / 52, 0.2, 1.6)
	local tween = TweenService:Create(orb, TweenInfo.new(travelTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = CFrame.new(targetPos + Vector3.new(0, 0.5, 0))
	})
	tween:Play()
	tween.Completed:Connect(function()
		orb:Destroy()
		spawnVFX(targetPos, Color3.fromRGB(255, 80, 10), Color3.fromRGB(80, 20, 5), 35, 0.6)
		-- AoE hit in 5 stud radius at impact
		if DamageService and DamageService.findTargetsInRadius then
			for _, hum in ipairs(DamageService.findTargetsInRadius(targetPos, 5, nil, false)) do
				applyDamage(hum, damage, "Flame Palm")
			end
		end
	end)
end

--------------------------------------------------------------------------------
-- Demonic Elder: Near Pull (Demonic Palm Pull)
--------------------------------------------------------------------------------
local function executePalmPull(model: Model, targetChar: Model, damage: number)
	local hrp = model.PrimaryPart
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
	if not hrp or not targetRoot or not targetHum or targetHum.Health <= 0 then return end

	-- Extend-arm animation
	local torso = model:FindFirstChild("Torso") :: BasePart?
	if torso then
		local rShoulder = torso:FindFirstChild("Right Shoulder") :: Motor6D?
		if rShoulder then
			local orig = rShoulder.C0
			rShoulder.C0 = orig * CFrame.Angles(math.rad(-90), 0, 0)
			-- Giant red hand VFX
			spawnVFX(hrp.Position + hrp.CFrame.LookVector * 3, Color3.fromRGB(255, 20, 20), Color3.fromRGB(80, 5, 5), 30, 0.5)
			task.delay(0.3, function()
				if not rShoulder.Parent then return end
				rShoulder.C0 = orig

				-- Lerp player toward elder
				if targetHum.Health > 0 then
					local pullDir = (hrp.Position - targetRoot.Position)
					local pullDist = pullDir.Magnitude
					if pullDist < 1 then return end
					local pullTarget = hrp.Position + pullDir.Unit * -3.5
					targetRoot.CFrame = CFrame.new(pullTarget, hrp.Position)
					applyDamage(targetHum, damage, "Palm Pull")
				end
			end)
		end
	end
end

--------------------------------------------------------------------------------
-- Fist Demon: Ground Smash Shockwave
--------------------------------------------------------------------------------
local function executeGroundSmash(model: Model, center: Vector3, damage: number)
	local torso = model:FindFirstChild("Torso") :: BasePart?
	-- Windup punch-down
	if torso then
		local rShoulder = torso:FindFirstChild("Right Shoulder") :: Motor6D?
		local lShoulder = torso:FindFirstChild("Left Shoulder") :: Motor6D?
		if rShoulder and lShoulder then
			local origR, origL = rShoulder.C0, lShoulder.C0
			rShoulder.C0 = origR * CFrame.Angles(math.rad(-120), 0, math.rad(-30))
			lShoulder.C0 = origL * CFrame.Angles(math.rad(-120), 0, math.rad(30))
			task.delay(0.25, function()
				if not rShoulder.Parent then return end
				rShoulder.C0 = origR * CFrame.Angles(math.rad(40), 0, math.rad(-10))
				lShoulder.C0 = origL * CFrame.Angles(math.rad(40), 0, math.rad(10))
				-- Ground impact VFX
				spawnVFX(center, Color3.fromRGB(220, 80, 20), Color3.fromRGB(60, 20, 5), 55, 0.7)

				-- Expanding ring visual
				local ring = Instance.new("Part")
				ring.Name = "ShockwaveRing"
				ring.Shape = Enum.PartType.Cylinder
				ring.Size = Vector3.new(0.5, 30, 30)
				ring.Color = Color3.fromRGB(200, 60, 10)
				ring.Material = Enum.Material.Neon
				ring.CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90))
				ring.Anchored = true
				ring.CanCollide = false
				ring.Parent = Workspace
				Debris:AddItem(ring, 0.5)

				-- AoE damage: 15 stud radius
				if DamageService and DamageService.findTargetsInRadius then
					for _, hum in ipairs(DamageService.findTargetsInRadius(center, 15, nil, false)) do
						applyDamage(hum, damage, "Ground Smash")
					end
				end
				task.delay(0.2, function()
					if rShoulder.Parent then rShoulder.C0 = origR end
					if lShoulder.Parent then lShoulder.C0 = origL end
				end)
			end)
		end
	end
end

--------------------------------------------------------------------------------
-- Sword Demon: Sword Wave Projectile
--------------------------------------------------------------------------------
local function launchSwordWave(model: Model, damage: number)
	local hrp = model.PrimaryPart
	if not hrp then return end
	local startPos = hrp.Position + hrp.CFrame.LookVector * 2 + Vector3.new(0, 1, 0)

	local wave = Instance.new("Part")
	wave.Name = "SwordWave"
	wave.Size = Vector3.new(0.5, 3, 6)
	wave.Color = Color3.fromRGB(80, 120, 255)
	wave.Material = Enum.Material.Neon
	wave.CanCollide = false
	wave.Anchored = false
	wave.CFrame = CFrame.new(startPos, startPos + hrp.CFrame.LookVector)
	wave.Parent = Workspace

	local bv = Instance.new("BodyVelocity", wave)
	bv.Velocity = hrp.CFrame.LookVector * 55
	bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	Debris:AddItem(wave, 1.5)

	spawnVFX(startPos, Color3.fromRGB(80, 120, 255), Color3.fromRGB(20, 20, 80), 20, 0.3)

	local hitTracker: { [Model]: boolean } = {}
	wave.Touched:Connect(function(hit)
		local char = hit.Parent
		if not char or not char:IsA("Model") then return end
		if hitTracker[char] then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		local root = char:FindFirstChild("HumanoidRootPart")
		if hum and hum.Health > 0 and root then
			local player = Players:GetPlayerFromCharacter(char)
			if player then
				hitTracker[char] = true
				applyDamage(hum, damage, "Sword Wave")
			end
		end
	end)
end

--------------------------------------------------------------------------------
-- Sword Demon / Assassin-style: Shadow Step (teleport behind)
--------------------------------------------------------------------------------
local function executeShadowStep(model: Model, targetChar: Model, damage: number)
	local hrp = model.PrimaryPart
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
	if not hrp or not targetRoot or not targetHum or targetHum.Health <= 0 then return end

	-- Vanish
	spawnVFX(hrp.Position, Color3.fromRGB(20, 20, 60), Color3.fromRGB(5, 5, 20), 30, 0.4)
	local hiddenParts: { [BasePart]: number } = {}
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p.Transparency < 0.9 then
			hiddenParts[p] = p.Transparency
			p.Transparency = 1
		end
	end

	-- Compute safe behind position
	local targetCF = targetRoot.CFrame
	local desired = targetCF.Position + targetCF.LookVector * -3.5 + Vector3.new(0, 0.2, 0)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { model, targetChar }
	rp.IgnoreWater = true
	local rayRes = Workspace:Raycast(targetCF.Position, desired - targetCF.Position, rp)
	local finalPos = (rayRes and rayRes.Instance and rayRes.Instance.CanCollide)
		and (rayRes.Position + rayRes.Normal * 1.5)
		or desired

	task.delay(0.35, function()
		if not model.Parent or not hrp.Parent then return end
		hrp.CFrame = CFrame.new(finalPos, targetCF.Position)
		for part, orig in pairs(hiddenParts) do
			if part.Parent then part.Transparency = orig end
		end
		spawnVFX(finalPos, Color3.fromRGB(80, 120, 255), Color3.fromRGB(20, 30, 80), 35, 0.4)
		playSlashAnimation(model, false)
		if targetHum.Health > 0 and (targetRoot.Position - finalPos).Magnitude <= 7 then
			applyDamage(targetHum, damage, "Shadow Step Strike")
		end
	end)
end

--------------------------------------------------------------------------------
-- Flame Demoness: Pull Skill
--------------------------------------------------------------------------------
local function executeFlamePull(model: Model, targetChar: Model, damage: number)
	local hrp = model.PrimaryPart
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
	if not hrp or not targetRoot or not targetHum then return end

	spawnVFX(hrp.Position + hrp.CFrame.LookVector * 4, Color3.fromRGB(255, 80, 10), Color3.fromRGB(80, 20, 5), 30, 0.4)
	task.delay(0.25, function()
		if targetHum.Health > 0 then
			local pullPos = hrp.Position + (targetRoot.Position - hrp.Position).Unit * -3
			targetRoot.CFrame = CFrame.new(pullPos, hrp.Position)
			applyDamage(targetHum, damage, "Flame Pull")
		end
	end)
end

--------------------------------------------------------------------------------
-- Poison Demoness: Poison Orb Projectile
--------------------------------------------------------------------------------
local function launchPoisonOrb(model: Model, targetPos: Vector3, damage: number)
	local torso = model:FindFirstChild("Torso") :: BasePart?
	if not torso then return end
	local startPos = torso.Position + torso.CFrame.LookVector * 2 + Vector3.new(0, 1, 0)
	local dir = (targetPos - startPos)
	local dist = dir.Magnitude
	if dist < 1 then return end

	spawnVFX(startPos, Color3.fromRGB(60, 230, 60), Color3.fromRGB(15, 80, 15), 15, 0.3)

	local orb = Instance.new("Part")
	orb.Name = "PoisonOrb"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(2, 2, 2)
	orb.Color = Color3.fromRGB(60, 220, 60)
	orb.Material = Enum.Material.Neon
	orb.CanCollide = false
	orb.Anchored = true
	orb.CFrame = CFrame.new(startPos, startPos + dir.Unit)
	orb.Parent = Workspace

	local em = Instance.new("ParticleEmitter", orb)
	em.Color = ColorSequence.new(Color3.fromRGB(60, 230, 60), Color3.fromRGB(15, 60, 15))
	em.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
	em.Lifetime = NumberRange.new(0.2, 0.35)
	em.Rate = 35
	em.Speed = NumberRange.new(1, 3)

	local travelTime = math.clamp(dist / 48, 0.2, 1.8)
	local tween = TweenService:Create(orb, TweenInfo.new(travelTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = CFrame.new(targetPos + Vector3.new(0, 0.5, 0))
	})
	tween:Play()
	tween.Completed:Connect(function()
		orb:Destroy()
		spawnVFX(targetPos, Color3.fromRGB(60, 230, 60), Color3.fromRGB(15, 80, 15), 40, 0.8)
		if DamageService and DamageService.findTargetsInRadius then
			for _, hum in ipairs(DamageService.findTargetsInRadius(targetPos, 6, nil, false)) do
				applyDamage(hum, damage, "Poison Orb")
			end
		end
	end)
end

--------------------------------------------------------------------------------
-- Poison Demoness: Poison Pool (AoE damage zone)
--------------------------------------------------------------------------------
local function spawnPoisonPool(center: Vector3, damage: number, duration: number)
	local pool = Instance.new("Part")
	pool.Name = "PoisonPool"
	pool.Shape = Enum.PartType.Cylinder
	pool.Size = Vector3.new(1, 18, 18)
	pool.Color = Color3.fromRGB(40, 180, 40)
	pool.Material = Enum.Material.Neon
	pool.CFrame = CFrame.new(center - Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90))
	pool.Anchored = true
	pool.CanCollide = false
	pool.Parent = Workspace
	pool.Transparency = 0.5
	Debris:AddItem(pool, duration)

	local light = Instance.new("PointLight", pool)
	light.Color = Color3.fromRGB(60, 230, 60)
	light.Brightness = 1.5
	light.Range = 22

	-- Tick damage every second for duration
	task.spawn(function()
		for _ = 1, math.floor(duration) do
			task.wait(1)
			if not pool.Parent then break end
			if DamageService and DamageService.findTargetsInRadius then
				for _, hum in ipairs(DamageService.findTargetsInRadius(center, 9, nil, false)) do
					applyDamage(hum, damage, "Poison Pool Tick")
				end
			end
		end
	end)
end

--------------------------------------------------------------------------------
-- Target Acquisition (same as CaveEnemyAI)
--------------------------------------------------------------------------------
local function findNearestPlayer(rootPart: BasePart, maxDist: number): (Humanoid?, BasePart?, number)
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
-- PUBLIC: Attach AI to an enemy model
--------------------------------------------------------------------------------
function DemonCultAI.attach(model: Model, enemyTypeName: string, customSpawnCF: CFrame?)
	local stats = DemonCultConfig and DemonCultConfig[enemyTypeName]
	if not stats then
		warn("[DemonCultAI] Unknown enemy type:", enemyTypeName)
		return
	end

	local hrp = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then
		warn("[DemonCultAI] Model missing RootPart or Humanoid:", model.Name)
		return
	end

	local spawnCF = customSpawnCF or hrp.CFrame
	local isDead = false

	-- STANDBY CHECK: SupremeDemon and BloodDemon
	if stats.IsStandby then
		print(string.format("[DemonCultAI] %s is on STANDBY (skills pending).", stats.Title or model.Name))
		return
	end

	-- Cooldown Tracking
	local nextMeleeAttack = 0
	local nextSkillTime: { [string]: number } = {}
	if stats.SpecialCooldowns then
		for skillName, _ in pairs(stats.SpecialCooldowns) do
			nextSkillTime[skillName] = tick() + math.random(1, 4)
		end
	end

	-- Death Handler
	humanoid.Died:Connect(function()
		if isDead then return end
		isDead = true
		task.delay(2.5, function()
			if model and model.Parent then model:Destroy() end
		end)
	end)

	-- AI Loop
	task.spawn(function()
		while not isDead and model.Parent and humanoid.Health > 0 do
			local targetHum, targetRoot, dist = findNearestPlayer(hrp, stats.ChaseRange)

			if targetHum and targetRoot then
				local targetChar = targetHum.Parent :: Model
				local usedSkill = false

				-- ================================================
				-- DEMONIC ELDER SKILLS
				-- ================================================
				if enemyTypeName == "DemonicElder" then
					-- Near Pull
					if not usedSkill and nextSkillTime["NearPull"] and tick() >= nextSkillTime["NearPull"] then
						if dist <= 10 then
							nextSkillTime["NearPull"] = tick() + (stats.SpecialCooldowns and stats.SpecialCooldowns["NearPull"] or 4)
							usedSkill = true
							executePalmPull(model, targetChar, 30)
						end
					end
					-- Far Flame Barrage (3 rapid orbs)
					if not usedSkill and nextSkillTime["FarFlame"] and tick() >= nextSkillTime["FarFlame"] then
						if dist > 10 and dist <= stats.ChaseRange then
							nextSkillTime["FarFlame"] = tick() + (stats.SpecialCooldowns and stats.SpecialCooldowns["FarFlame"] or 3)
							usedSkill = true
							for i = 0, 2 do
								task.delay(i * 0.3, function()
									if model.Parent and targetRoot.Parent then
										launchFlamePalm(model, targetRoot.Position, 22)
									end
								end)
							end
						end
					end

				-- ================================================
				-- FLAME DEMONESS SKILLS
				-- ================================================
				elseif enemyTypeName == "FlameDemoness" then
					-- Flame Pull (if player close)
					if not usedSkill and nextSkillTime["FlamePull"] and tick() >= nextSkillTime["FlamePull"] then
						if dist <= 10 then
							nextSkillTime["FlamePull"] = tick() + (stats.SpecialCooldowns and stats.SpecialCooldowns["FlamePull"] or 4)
							usedSkill = true
							executeFlamePull(model, targetChar, 28)
						end
					end
					-- Flame Shockwave (AoE around self)
					if not usedSkill and nextSkillTime["FlameShockwave"] and tick() >= nextSkillTime["FlameShockwave"] then
						if dist <= 12 then
							nextSkillTime["FlameShockwave"] = tick() + (stats.SpecialCooldowns and stats.SpecialCooldowns["FlameShockwave"] or 6)
							usedSkill = true
							spawnVFX(hrp.Position, Color3.fromRGB(255, 80, 10), Color3.fromRGB(120, 20, 5), 60, 0.8)
							if DamageService and DamageService.findTargetsInRadius then
								for _, hum in ipairs(DamageService.findTargetsInRadius(hrp.Position, 10, nil, false)) do
									applyDamage(hum, 30, "Flame Shockwave")
								end
							end
						end
					end

				-- ================================================
				-- POISON DEMONESS SKILLS
				-- ================================================
				elseif enemyTypeName == "PoisonDemoness" then
					-- Poison Orb (ranged)
					if not usedSkill and nextSkillTime["PoisonOrb"] and tick() >= nextSkillTime["PoisonOrb"] then
						if dist > 8 and dist <= stats.ChaseRange then
							nextSkillTime["PoisonOrb"] = tick() + (stats.SpecialCooldowns and stats.SpecialCooldowns["PoisonOrb"] or 5)
							usedSkill = true
							launchPoisonOrb(model, targetRoot.Position, 24)
						end
					end
					-- Poison Pool (place under target)
					if not usedSkill and nextSkillTime["PoisonPool"] and tick() >= nextSkillTime["PoisonPool"] then
						if dist <= 18 then
							nextSkillTime["PoisonPool"] = tick() + (stats.SpecialCooldowns and stats.SpecialCooldowns["PoisonPool"] or 8)
							usedSkill = true
							spawnPoisonPool(targetRoot.Position, 8, 6)
						end
					end

				-- ================================================
				-- FIST DEMON SKILLS
				-- ================================================
				elseif enemyTypeName == "FistDemon" then
					-- Ground Smash
					if not usedSkill and nextSkillTime["GroundSmash"] and tick() >= nextSkillTime["GroundSmash"] then
						if dist <= 15 then
							nextSkillTime["GroundSmash"] = tick() + (stats.SpecialCooldowns and stats.SpecialCooldowns["GroundSmash"] or 7)
							usedSkill = true
							executeGroundSmash(model, hrp.Position, 38)
						end
					end
					-- Demonic Dash (charge at player)
					if not usedSkill and nextSkillTime["DemonicDash"] and tick() >= nextSkillTime["DemonicDash"] then
						if dist > 8 and dist <= 30 then
							nextSkillTime["DemonicDash"] = tick() + (stats.SpecialCooldowns and stats.SpecialCooldowns["DemonicDash"] or 5)
							usedSkill = true
							spawnVFX(hrp.Position, Color3.fromRGB(220, 60, 10), Color3.fromRGB(60, 10, 5), 25, 0.3)
							local bv = Instance.new("BodyVelocity", hrp)
							bv.Velocity = hrp.CFrame.LookVector * 60
							bv.MaxForce = Vector3.new(1e5, 0, 1e5)
							Debris:AddItem(bv, 0.35)
							task.delay(0.35, function()
								if targetHum.Health > 0 and (targetRoot.Position - hrp.Position).Magnitude <= 8 then
									applyDamage(targetHum, 35, "Demonic Dash")
								end
							end)
						end
					end

				-- ================================================
				-- SWORD DEMON SKILLS
				-- ================================================
				elseif enemyTypeName == "SwordDemon" then
					-- Shadow Step (teleport behind player)
					if not usedSkill and nextSkillTime["ShadowStep"] and tick() >= nextSkillTime["ShadowStep"] then
						if dist > 12 then
							nextSkillTime["ShadowStep"] = tick() + (stats.SpecialCooldowns and stats.SpecialCooldowns["ShadowStep"] or 5)
							usedSkill = true
							executeShadowStep(model, targetChar, 40)
						end
					end
					-- Sword Wave (forward projectile)
					if not usedSkill and nextSkillTime["SwordWave"] and tick() >= nextSkillTime["SwordWave"] then
						if dist > 6 and dist <= 30 then
							nextSkillTime["SwordWave"] = tick() + (stats.SpecialCooldowns and stats.SpecialCooldowns["SwordWave"] or 4)
							usedSkill = true
							hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetRoot.Position.X, hrp.Position.Y, targetRoot.Position.Z))
							playSlashAnimation(model, false)
							launchSwordWave(model, 32)
						end
					end
					-- Cross Slash (dual arm + larger VFX)
					if not usedSkill and nextSkillTime["CrossSlash"] and tick() >= nextSkillTime["CrossSlash"] then
						if dist <= stats.AttackRange + 2 then
							nextSkillTime["CrossSlash"] = tick() + (stats.SpecialCooldowns and stats.SpecialCooldowns["CrossSlash"] or 6)
							usedSkill = true
							playSlashAnimation(model, true)
							spawnVFX(hrp.Position + hrp.CFrame.LookVector * 3, Color3.fromRGB(80, 120, 255), Color3.fromRGB(20, 20, 80), 50, 0.5)
							if targetHum.Health > 0 and dist <= stats.AttackRange + 3 then
								applyDamage(targetHum, 45, "Cross Slash")
							end
						end
					end
				end

				-- ================================================
				-- BASIC MELEE ATTACK (all non-standby types)
				-- ================================================
				if not usedSkill and dist <= stats.AttackRange and tick() >= nextMeleeAttack then
					nextMeleeAttack = tick() + stats.AttackCooldown

					if enemyTypeName == "DemonCultist" then
						playSlashAnimation(model, false)
						task.delay(0.15, function()
							if targetHum.Health > 0 and (targetRoot.Position - hrp.Position).Magnitude <= stats.AttackRange + 1 then
								applyDamage(targetHum, stats.BaseDamage, "Demon Slash")
							end
						end)

					elseif enemyTypeName == "SeniorDemonCultist" then
						-- Flaming single slash
						playSlashAnimation(model, false)
						local rArm = model:FindFirstChild("Right Arm") :: BasePart?
						if rArm then spawnVFX(rArm.Position + rArm.CFrame.LookVector * 1.5, Color3.fromRGB(255, 80, 10), Color3.fromRGB(80, 20, 5), 20, 0.3) end
						task.delay(0.15, function()
							if targetHum.Health > 0 and (targetRoot.Position - hrp.Position).Magnitude <= stats.AttackRange + 1 then
								applyDamage(targetHum, stats.BaseDamage, "Flaming Slash")
							end
						end)

					elseif enemyTypeName == "DemonicElder" then
						playSlashAnimation(model, false)
						task.delay(0.15, function()
							if targetHum.Health > 0 and (targetRoot.Position - hrp.Position).Magnitude <= stats.AttackRange + 1 then
								applyDamage(targetHum, stats.BaseDamage, "Elder Slash")
							end
						end)

					elseif enemyTypeName == "FlameDemoness" then
						-- Flaming punches (3-hit combo)
						for i = 0, 2 do
							task.delay(i * 0.22, function()
								if isDead or not model.Parent then return end
								local arm = i % 2 == 0 and "Right Arm" or "Left Arm"
								playPunchAnimation(model, arm)
								task.delay(0.08, function()
									if targetHum.Health > 0 and (targetRoot.Position - hrp.Position).Magnitude <= stats.AttackRange + 1 then
										applyDamage(targetHum, stats.BaseDamage * 0.5, "Flame Punch")
									end
								end)
							end)
						end

					elseif enemyTypeName == "PoisonDemoness" then
						-- Poison claw swipe
						playSlashAnimation(model, false)
						task.delay(0.15, function()
							if targetHum.Health > 0 and (targetRoot.Position - hrp.Position).Magnitude <= stats.AttackRange + 1 then
								applyDamage(targetHum, stats.BaseDamage, "Poison Claw")
								-- Small poison VFX on target
								local targetTorso = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
								if targetTorso then
									spawnVFX(targetTorso.Position, Color3.fromRGB(60, 230, 60), Color3.fromRGB(15, 60, 15), 12, 0.4)
								end
							end
						end)

					elseif enemyTypeName == "FistDemon" then
						-- Heavy punch (alternating fists)
						local arm = (math.random(1,2) == 1) and "Right Arm" or "Left Arm"
						playPunchAnimation(model, arm)
						task.delay(0.12, function()
							if targetHum.Health > 0 and (targetRoot.Position - hrp.Position).Magnitude <= stats.AttackRange + 1 then
								applyDamage(targetHum, stats.BaseDamage, "Heavy Punch")
							end
						end)

					elseif enemyTypeName == "SwordDemon" then
						-- Rapid sword slash
						playSlashAnimation(model, false)
						task.delay(0.12, function()
							if targetHum.Health > 0 and (targetRoot.Position - hrp.Position).Magnitude <= stats.AttackRange + 1 then
								applyDamage(targetHum, stats.BaseDamage, "Demon Blade Slash")
							end
						end)
					end
				end

				-- Face and chase target
				hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetRoot.Position.X, hrp.Position.Y, targetRoot.Position.Z))
				humanoid:MoveTo(targetRoot.Position)
			else
				-- Leash: return to spawn if wandered
				if (hrp.Position - spawnCF.Position).Magnitude > 30 then
					humanoid:MoveTo(spawnCF.Position)
				end
			end

			task.wait(0.25)
		end
	end)
end

return DemonCultAI
