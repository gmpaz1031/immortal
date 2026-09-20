--!strict
-- src/shared/SkillFXHelper.luau
-- Visual FX & Sound Replicator for Martial Arts & Spiritual Skills in Immortal

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local SkillFXHelper = {}

local function createSound(parent: Instance, soundId: string, volume: number, pitch: number?)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume
	sound.PlaybackSpeed = pitch or 1.0
	sound.Parent = parent
	sound:Play()
	Debris:AddItem(sound, 3)
	return sound
end

function SkillFXHelper.playSwordSlash(casterChar: Model, origin: Vector3, dir: Vector3, range: number, speed: number)
	local slash = Instance.new("Part")
	slash.Name = "SwordSlashFX"
	slash.Size = Vector3.new(6, 0.4, 1.5)
	slash.Material = Enum.Material.Neon
	slash.Color = Color3.fromRGB(120, 210, 255)
	slash.Transparency = 0.2
	slash.CanCollide = false
	slash.Anchored = true
	slash.CFrame = CFrame.lookAt(origin, origin + dir) * CFrame.Angles(0, 0, math.rad(45))
	slash.Parent = workspace

	createSound(slash, "rbxassetid://9114223170", 0.7, 1.1)

	local targetPos = origin + (dir.Unit * range)
	local duration = range / math.max(1, speed)
	local tween = TweenService:Create(slash, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		CFrame = CFrame.lookAt(targetPos, targetPos + dir) * CFrame.Angles(0, 0, math.rad(45)),
		Transparency = 1,
		Size = Vector3.new(8, 0.1, 2),
	})
	tween:Play()
	Debris:AddItem(slash, duration + 0.1)
end

function SkillFXHelper.playPalmExplosion(hitPos: Vector3, radius: number)
	-- Pure Part-based Sphere Explosion Animation (No Roblox Explosion instance used)

	-- 1. Outer Golden Spherical Blast
	local outerSphere = Instance.new("Part")
	outerSphere.Name = "PalmExplosionOuterSphere"
	outerSphere.Shape = Enum.PartType.Ball
	outerSphere.Size = Vector3.new(0.5, 0.5, 0.5)
	outerSphere.Material = Enum.Material.Neon
	outerSphere.Color = Color3.fromRGB(255, 195, 30) -- Golden Amber
	outerSphere.Transparency = 0.1
	outerSphere.CanCollide = false
	outerSphere.CanTouch = false
	outerSphere.Anchored = true
	outerSphere.CFrame = CFrame.new(hitPos)
	outerSphere.Parent = workspace

	-- 2. Inner White-Hot Core Sphere
	local innerSphere = Instance.new("Part")
	innerSphere.Name = "PalmExplosionInnerCore"
	innerSphere.Shape = Enum.PartType.Ball
	innerSphere.Size = Vector3.new(0.2, 0.2, 0.2)
	innerSphere.Material = Enum.Material.Neon
	innerSphere.Color = Color3.fromRGB(255, 255, 230) -- White-hot core
	innerSphere.Transparency = 0.0
	innerSphere.CanCollide = false
	innerSphere.CanTouch = false
	innerSphere.Anchored = true
	innerSphere.CFrame = CFrame.new(hitPos)
	innerSphere.Parent = workspace

	-- 3. Outer Energy Aura Sphere
	local auraSphere = Instance.new("Part")
	auraSphere.Name = "PalmExplosionAura"
	auraSphere.Shape = Enum.PartType.Ball
	auraSphere.Size = Vector3.new(0.8, 0.8, 0.8)
	auraSphere.Material = Enum.Material.Neon
	auraSphere.Color = Color3.fromRGB(255, 140, 15) -- Fiery golden border
	auraSphere.Transparency = 0.35
	auraSphere.CanCollide = false
	auraSphere.CanTouch = false
	auraSphere.Anchored = true
	auraSphere.CFrame = CFrame.new(hitPos)
	auraSphere.Parent = workspace

	-- 4. Expanding Cylinder Shockwave Ring
	local ring = Instance.new("Part")
	ring.Name = "PalmExplosionShockwaveRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.2, 2, 2)
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 235, 110)
	ring.Transparency = 0.1
	ring.CanCollide = false
	ring.CanTouch = false
	ring.Anchored = true
	ring.CFrame = CFrame.new(hitPos) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = workspace

	-- 5. Point Light Flash
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 215, 60)
	light.Brightness = 8.0
	light.Range = radius * 2.5
	light.Parent = outerSphere

	-- 6. Heavy Blast Sound FX
	createSound(outerSphere, "rbxassetid://9114221976", 0.9, 1.0)

	-- Tween animations for expanding sphere sizes and fading transparency to 1.0
	local duration = 0.35
	local expTweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	TweenService:Create(outerSphere, expTweenInfo, {
		Size = Vector3.new(radius * 2.2, radius * 2.2, radius * 2.2),
		Transparency = 1.0,
	}):Play()

	TweenService:Create(innerSphere, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(radius * 1.3, radius * 1.3, radius * 1.3),
		Transparency = 1.0,
	}):Play()

	TweenService:Create(auraSphere, TweenInfo.new(0.40, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(radius * 2.6, radius * 2.6, radius * 2.6),
		Transparency = 1.0,
	}):Play()

	TweenService:Create(ring, expTweenInfo, {
		Size = Vector3.new(0.05, radius * 2.8, radius * 2.8),
		Transparency = 1.0,
	}):Play()

	TweenService:Create(light, expTweenInfo, {
		Brightness = 0,
		Range = 0,
	}):Play()

	-- Automatic Destruction of Explosion FX Parts
	Debris:AddItem(outerSphere, duration + 0.1)
	Debris:AddItem(innerSphere, duration + 0.1)
	Debris:AddItem(auraSphere, duration + 0.1)
	Debris:AddItem(ring, duration + 0.1)
end

function SkillFXHelper.playPalmArt(casterChar: Model?, origin: Vector3?, lookDir: Vector3?, hitPos: Vector3?, speedVal: number?, radiusVal: number?)
	local speed: number = speedVal or 55
	local radius: number = radiusVal or 14

	local startOrigin: Vector3
	local dirUnit: Vector3

	if typeof(casterChar) == "Instance" and casterChar:IsA("Model") and typeof(origin) == "Vector3" and typeof(lookDir) == "Vector3" then
		startOrigin = origin
		dirUnit = if lookDir.Magnitude > 0.01 then lookDir.Unit else Vector3.new(0, 0, -1)
	elseif typeof(casterChar) == "Instance" and casterChar:IsA("Model") then
		local root = casterChar:FindFirstChild("HumanoidRootPart") :: BasePart?
		startOrigin = if root then root.Position else Vector3.zero
		dirUnit = if root then root.CFrame.LookVector else Vector3.new(0, 0, -1)
	elseif typeof(origin) == "Vector3" then
		startOrigin = origin
		dirUnit = if typeof(lookDir) == "Vector3" and lookDir.Magnitude > 0.01 then lookDir.Unit else Vector3.new(0, 0, -1)
	else
		startOrigin = Vector3.zero
		dirUnit = Vector3.new(0, 0, -1)
	end

	-- 1. Locate and clone PalmArtHand template from Workspace or ReplicatedStorage
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local template = workspace:FindFirstChild("PalmArtHand") 
		or ReplicatedStorage:FindFirstChild("PalmArtHand")

	local palm: Instance
	if template then
		palm = template:Clone()
	else
		-- Neon golden fallback hand if template is missing in test environment
		local p = Instance.new("Part")
		p.Name = "PalmArtHand"
		p.Size = Vector3.new(4.5, 1.2, 5.5)
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromRGB(255, 205, 45)
		palm = p
	end

	palm.Name = "PalmArtFX"

	-- Ensure all parts are non-collidable, anchored, and touch-queryable
	local palmParts: { BasePart } = {}
	if palm:IsA("BasePart") then
		palm.CanCollide = false
		palm.CanTouch = true
		palm.CanQuery = true
		palm.Anchored = true
		table.insert(palmParts, palm)
	end
	for _, desc in ipairs(palm:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.CanCollide = false
			desc.CanTouch = true
			desc.CanQuery = true
			desc.Anchored = true
			table.insert(palmParts, desc)
		end
	end

	-- 2. Spawn in front of player on cast, adjusting Y position to ensure ground clearance & no player contact
	local spawnPos = startOrigin + dirUnit * 4 + Vector3.new(0, 1.5, 0)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local filterList: { Instance } = { palm }
	if casterChar then
		table.insert(filterList, casterChar)
	end
	rayParams.FilterDescendantsInstances = filterList

	local groundRay = workspace:Raycast(spawnPos + Vector3.new(0, 5, 0), Vector3.new(0, -20, 0), rayParams)
	if groundRay then
		local minY = groundRay.Position.Y + 3.0
		if spawnPos.Y < minY then
			spawnPos = Vector3.new(spawnPos.X, minY, spawnPos.Z)
		end
	end

	local spawnCFrame = CFrame.lookAt(spawnPos, spawnPos + dirUnit)
	if palm:IsA("Model") then
		palm:PivotTo(spawnCFrame)
	elseif palm:IsA("BasePart") then
		palm.CFrame = spawnCFrame
	end
	palm.Parent = workspace

	local mainPart: BasePart? = if palm:IsA("Model") then (palm.PrimaryPart or palm:FindFirstChildOfClass("BasePart")) else (palm :: BasePart)
	if mainPart then
		createSound(mainPart, "rbxassetid://9114221580", 0.8, 1.0)
	end

	-- 3. Travel towards target for up to 4.0 seconds, exploding on player/ground contact
	local startTime = os.clock()
	local maxDuration = 4.0
	local currentPos = spawnPos
	local hasExploded = false
	local conn: RBXScriptConnection? = nil
	local touchConns: { RBXScriptConnection } = {}

	local function triggerExplosion(impactPos: Vector3)
		if hasExploded then return end
		hasExploded = true

		if conn then conn:Disconnect() conn = nil end
		for _, c in ipairs(touchConns) do c:Disconnect() end
		table.clear(touchConns)

		-- Play part-based sphere explosion animation
		SkillFXHelper.playPalmExplosion(impactPos, radius)

		-- IMMEDIATELY destroy the cloned palm model on contact!
		if palm and palm.Parent then
			palm:Destroy()
		end
	end

	-- Connect instant Touched event on all parts of the palm
	for _, part in ipairs(palmParts) do
		local tConn = part.Touched:Connect(function(otherPart)
			if hasExploded or not otherPart or not otherPart.Parent then return end
			if otherPart:IsDescendantOf(palm) then return end
			if casterChar and otherPart:IsDescendantOf(casterChar) then return end

			-- Ignore non-collidable trigger zones, reticles, or other skill FX
			if otherPart.Name:find("FX") or otherPart.Name:find("Reticle") or otherPart.Name:find("Ring") then return end

			-- Trigger explosion & immediate deletion
			triggerExplosion(otherPart.Position)
		end)
		table.insert(touchConns, tConn)
	end

	conn = game:GetService("RunService").Heartbeat:Connect(function(dt)
		local elapsed = os.clock() - startTime
		if elapsed >= maxDuration or hasExploded or not palm.Parent then
			if conn then conn:Disconnect() conn = nil end
			for _, c in ipairs(touchConns) do c:Disconnect() end
			table.clear(touchConns)

			if not hasExploded and palm.Parent then
				-- 4-second timeout fade out
				hasExploded = true
				local fadeInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				for _, part in ipairs(palmParts) do
					TweenService:Create(part, fadeInfo, { Transparency = 1 }):Play()
				end
				task.delay(0.38, function()
					if palm.Parent then palm:Destroy() end
				end)
			end
			return
		end

		local stepDist = speed * dt
		local nextPos = currentPos + (dirUnit * stepDist)

		-- Contact check via raycast & spatial overlap
		local hitRay = workspace:Raycast(currentPos, dirUnit * (stepDist + 0.8), rayParams)
		local impactPos: Vector3? = if hitRay then hitRay.Position else nil

		if not impactPos then
			local overlapParams = OverlapParams.new()
			overlapParams.FilterType = Enum.RaycastFilterType.Exclude
			overlapParams.FilterDescendantsInstances = filterList

			local parts = workspace:GetPartBoundsInRadius(currentPos, 4.0, overlapParams)
			for _, part in ipairs(parts) do
				if part.Name ~= "Terrain" then
					local model = part:FindFirstAncestorOfClass("Model")
					if model and model:FindFirstChildOfClass("Humanoid") then
						impactPos = part.Position
						break
					end
				end
			end
		end

		if impactPos then
			triggerExplosion(impactPos)
			return
		end

		currentPos = nextPos
		local newCFrame = CFrame.lookAt(currentPos, currentPos + dirUnit)
		if palm:IsA("Model") then
			palm:PivotTo(newCFrame)
		elseif palm:IsA("BasePart") then
			palm.CFrame = newCFrame
		end
	end)

	Debris:AddItem(palm, maxDuration + 1.0)
end

function SkillFXHelper.playFlameBall(casterChar: Model, origin: Vector3, targetPos: Vector3, speed: number, radius: number)
	local ball = Instance.new("Part")
	ball.Name = "FlameBallFX"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(3, 3, 3)
	ball.Material = Enum.Material.Neon
	ball.Color = Color3.fromRGB(255, 100, 20)
	ball.CanCollide = false
	ball.Anchored = true
	ball.CFrame = CFrame.new(origin)
	ball.Parent = workspace

	local fire = Instance.new("Fire")
	fire.Size = 8
	fire.Heat = 15
	fire.Color = Color3.fromRGB(255, 120, 30)
	fire.SecondaryColor = Color3.fromRGB(255, 220, 50)
	fire.Parent = ball

	createSound(ball, "rbxassetid://9114221779", 0.6, 1.0)

	local dist = (targetPos - origin).Magnitude
	local duration = dist / math.max(1, speed)
	local tween = TweenService:Create(ball, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		CFrame = CFrame.new(targetPos),
	})
	tween:Play()

	tween.Completed:Connect(function()
		-- Explosion impact
		local boom = Instance.new("Part")
		boom.Shape = Enum.PartType.Ball
		boom.Size = Vector3.new(1, 1, 1)
		boom.Material = Enum.Material.Neon
		boom.Color = Color3.fromRGB(255, 140, 40)
		boom.CanCollide = false
		boom.Anchored = true
		boom.CFrame = CFrame.new(targetPos)
		boom.Parent = workspace

		createSound(boom, "rbxassetid://9114221976", 0.8, 1.1)

		local expTween = TweenService:Create(boom, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(radius * 2, radius * 2, radius * 2),
			Transparency = 1,
		})
		expTween:Play()
		Debris:AddItem(boom, 0.4)
		ball:Destroy()
	end)
end

function SkillFXHelper.playThunderStrike(targetPos: Vector3, radius: number, warningDuration: number)
	-- Ground warning circle (celestial hexagram)
	local mark = Instance.new("Part")
	mark.Name = "ThunderWarningFX"
	mark.Shape = Enum.PartType.Cylinder
	mark.Size = Vector3.new(0.2, radius * 2, radius * 2)
	mark.Material = Enum.Material.Neon
	mark.Color = Color3.fromRGB(150, 80, 255)
	mark.Transparency = 0.5
	mark.CanCollide = false
	mark.Anchored = true
	mark.CFrame = CFrame.new(targetPos) * CFrame.Angles(0, 0, math.rad(90))
	mark.Parent = workspace

	createSound(mark, "rbxassetid://9114222144", 0.5, 1.4)
	Debris:AddItem(mark, warningDuration + 0.3)

	task.delay(warningDuration, function()
		if mark.Parent then
			mark:Destroy()
		end

		-- Lightning Bolt Strike
		local bolt = Instance.new("Part")
		bolt.Name = "LightningBoltFX"
		bolt.Size = Vector3.new(2.8, 160, 2.8)
		bolt.Material = Enum.Material.Neon
		bolt.Color = Color3.fromRGB(225, 195, 255)
		bolt.CanCollide = false
		bolt.Anchored = true
		bolt.CFrame = CFrame.new(targetPos + Vector3.new(0, 80, 0))
		bolt.Parent = workspace

		createSound(bolt, "rbxassetid://9114222328", 1.0, 0.9)

		local fade = TweenService:Create(bolt, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.2, 160, 0.2),
			Transparency = 1,
		})
		fade:Play()
		fade.Completed:Connect(function()
			if bolt.Parent then bolt:Destroy() end
		end)
		task.delay(0.35, function()
			if bolt.Parent then bolt:Destroy() end
		end)
		Debris:AddItem(bolt, 0.4)

		-- Ground Shockwave Ring
		local shock = Instance.new("Part")
		shock.Name = "ThunderShockwaveFX"
		shock.Shape = Enum.PartType.Cylinder
		shock.Size = Vector3.new(0.2, 2, 2)
		shock.Material = Enum.Material.Neon
		shock.Color = Color3.fromRGB(180, 120, 255)
		shock.CanCollide = false
		shock.Anchored = true
		shock.CFrame = CFrame.new(targetPos) * CFrame.Angles(0, 0, math.rad(90))
		shock.Parent = workspace

		local stw = TweenService:Create(shock, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.1, radius * 2.2, radius * 2.2),
			Transparency = 1,
		})
		stw:Play()
		stw.Completed:Connect(function()
			if shock.Parent then shock:Destroy() end
		end)
		task.delay(0.38, function()
			if shock.Parent then shock:Destroy() end
		end)
		Debris:AddItem(shock, 0.4)

		-- Ground Debris Effect (Rock fragments flying outward and fading)
		for i = 1, 8 do
			local rock = Instance.new("Part")
			rock.Name = "ThunderDebrisRock"
			local s = math.random(6, 12) / 10
			rock.Size = Vector3.new(s, s * 0.8, s)
			rock.Material = Enum.Material.Slate
			rock.Color = Color3.fromRGB(75, 75, 80)
			rock.CanCollide = false
			rock.Anchored = false
			local offset = Vector3.new(math.random(-3, 3), 0.5, math.random(-3, 3))
			rock.CFrame = CFrame.new(targetPos + offset) * CFrame.Angles(math.random(), math.random(), math.random())
			rock.AssemblyLinearVelocity = Vector3.new(math.random(-25, 25), math.random(25, 45), math.random(-25, 25))
			rock.AssemblyAngularVelocity = Vector3.new(math.random(-15, 15), math.random(-15, 15), math.random(-15, 15))
			rock.Parent = workspace

			task.delay(0.7, function()
				if rock.Parent then
					local rtw = TweenService:Create(rock, TweenInfo.new(0.4), { Transparency = 1 })
					rtw:Play()
					rtw.Completed:Connect(function()
						if rock.Parent then rock:Destroy() end
					end)
				end
			end)
			task.delay(1.2, function()
				if rock.Parent then rock:Destroy() end
			end)
			Debris:AddItem(rock, 1.4)
		end
	end)
end

function SkillFXHelper.playZapEffect(victimModel: Model, duration: number?)
	local dur = duration or 6.5
	local root = victimModel:FindFirstChild("HumanoidRootPart") :: BasePart?
		or victimModel:FindFirstChild("Torso") :: BasePart?
		or victimModel.PrimaryPart
	if not root then return end

	-- Clean existing aura
	local oldAura = victimModel:FindFirstChild("ZapAuraFolder")
	if oldAura then oldAura:Destroy() end

	local folder = Instance.new("Folder")
	folder.Name = "ZapAuraFolder"
	folder.Parent = victimModel

	local att = Instance.new("Attachment")
	att.Name = "ZapAtt"
	att.Parent = root

	local p = Instance.new("ParticleEmitter")
	p.Name = "ZapSparks"
	p.Texture = "rbxassetid://258129524"
	p.Color = ColorSequence.new(Color3.fromRGB(160, 210, 255), Color3.fromRGB(210, 130, 255))
	p.LightEmission = 1
	p.Size = NumberSequence.new(0.5, 0.15)
	p.Lifetime = NumberRange.new(0.15, 0.3)
	p.Rate = 25
	p.Speed = NumberRange.new(3, 8)
	p.SpreadAngle = Vector2.new(180, 180)
	p.Parent = att

	local light = Instance.new("PointLight")
	light.Name = "ZapLight"
	light.Color = Color3.fromRGB(170, 190, 255)
	light.Brightness = 2
	light.Range = 10
	light.Parent = root

	task.delay(dur, function()
		if p.Parent then p:Destroy() end
		if att.Parent then att:Destroy() end
		if light.Parent then light:Destroy() end
		if folder.Parent then folder:Destroy() end
	end)
	Debris:AddItem(folder, dur + 0.5)
	Debris:AddItem(att, dur + 0.5)
	Debris:AddItem(light, dur + 0.5)
end

function SkillFXHelper.playZapPulse(victimModel: Model)
	local root = victimModel:FindFirstChild("HumanoidRootPart") :: BasePart?
		or victimModel:FindFirstChild("Torso") :: BasePart?
		or victimModel.PrimaryPart
	if not root then return end

	local flash = Instance.new("Part")
	flash.Name = "ZapPulseFlash"
	flash.Shape = Enum.PartType.Ball
	flash.Size = Vector3.new(3, 3, 3)
	flash.Material = Enum.Material.Neon
	flash.Color = Color3.fromRGB(190, 220, 255)
	flash.CanCollide = false
	flash.Anchored = true
	flash.CFrame = root.CFrame
	flash.Parent = workspace

	createSound(flash, "rbxassetid://9114222144", 0.7, 1.6)

	local tw = TweenService:Create(flash, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(5.5, 5.5, 5.5),
		Transparency = 1,
	})
	tw:Play()
	tw.Completed:Connect(function()
		if flash.Parent then flash:Destroy() end
	end)
	task.delay(0.22, function()
		if flash.Parent then flash:Destroy() end
	end)
	Debris:AddItem(flash, 0.3)
end

function SkillFXHelper.playMultipleSwords(casterChar: Model, origin: Vector3, targetPos: Vector3, count: number, speed: number)
	for i = 1, count do
		task.delay((i - 1) * 0.12, function()
			local sword = Instance.new("Part")
			sword.Name = "SpiritFlyingSword"
			sword.Size = Vector3.new(0.6, 0.3, 4.5)
			sword.Material = Enum.Material.Neon
			sword.Color = Color3.fromRGB(140, 220, 255)
			sword.CanCollide = false
			sword.Anchored = true

			local offset = Vector3.new(math.cos(i * 1.2) * 3, 2 + math.sin(i * 1.2) * 2, 0)
			local startPos = origin + offset
			sword.CFrame = CFrame.lookAt(startPos, targetPos)
			sword.Parent = workspace

			createSound(sword, "rbxassetid://9114222513", 0.4, 1.2 + (i * 0.05))

			local dist = (targetPos - startPos).Magnitude
			local duration = dist / math.max(1, speed)
			local tween = TweenService:Create(sword, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				CFrame = CFrame.lookAt(targetPos, targetPos + (targetPos - startPos).Unit),
			})
			tween:Play()

			tween.Completed:Connect(function()
				sword:Destroy()
			end)
		end)
	end
end

function SkillFXHelper.playFlameSpear(casterChar: Model, origin: Vector3, targetModel: Model?, targetPos: Vector3, speed: number)
	local spear = Instance.new("Part")
	spear.Name = "FlameSpearFX"
	spear.Size = Vector3.new(0.8, 0.8, 9)
	spear.Material = Enum.Material.Neon
	spear.Color = Color3.fromRGB(255, 60, 20)
	spear.CanCollide = false
	spear.Anchored = true
	spear.CFrame = CFrame.lookAt(origin, targetPos)
	spear.Parent = workspace

	createSound(spear, "rbxassetid://9114222687", 0.8, 1.0)

	local dist = (targetPos - origin).Magnitude
	local duration = dist / math.max(1, speed)
	local tween = TweenService:Create(spear, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		CFrame = CFrame.lookAt(targetPos, targetPos + (targetPos - origin).Unit),
		Size = Vector3.new(1.2, 1.2, 12),
	})
	tween:Play()

	tween.Completed:Connect(function()
		spear:Destroy()
	end)
end

function SkillFXHelper.playSkillFX(action: string, ...)
	if action == "SwordSlash" or action == "Sword Slash" then
		SkillFXHelper.playSwordSlash(...)
	elseif action == "FlameBall" or action == "Flame Ball" then
		SkillFXHelper.playFlameBall(...)
	elseif action == "PalmArt" or action == "Palm Art" then
		SkillFXHelper.playPalmArt(...)
	elseif action == "PalmExplosion" then
		SkillFXHelper.playPalmExplosion(...)
	elseif action == "ThunderStrike" or action == "Thunder Strike" then
		SkillFXHelper.playThunderStrike(...)
	elseif action == "ZapEffect" then
		SkillFXHelper.playZapEffect(...)
	elseif action == "ZapPulse" then
		SkillFXHelper.playZapPulse(...)
	elseif action == "MultipleSwords" or action == "Multiple Swords" then
		SkillFXHelper.playMultipleSwords(...)
	elseif action == "FlameSpear" or action == "Flame Spear" then
		SkillFXHelper.playFlameSpear(...)
	end
end

return SkillFXHelper
