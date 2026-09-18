--!strict
--[[
    SkillFXHelper.luau
    Client-side visual effects (VFX) and sound helper for all 6 combat skills.
    Called exclusively from SkillClient.client.luau on every client when the
    server fires SkillReplicate.

    All effects are purely cosmetic — no damage is applied here.
]]

local Players     = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace   = game:GetService("Workspace")
local RunService  = game:GetService("RunService")

local localPlayer = Players.LocalPlayer

local SkillFXHelper = {}

--------------------------------------------------------------------------------
-- Utility Helpers
--------------------------------------------------------------------------------

-- Play a short sound at a part's position and auto-destroy
function SkillFXHelper.playSound(parent: Instance, assetId: string, volume: number?, pitch: number?, duration: number?)
	local snd = Instance.new("Sound")
	snd.SoundId = assetId
	snd.Volume  = volume or 0.8
	snd.PlaybackSpeed = pitch or 1.0
	snd.RollOffMaxDistance = 120
	snd.Parent = parent
	snd:Play()
	task.delay(duration or 3, function()
		if snd.Parent then snd:Destroy() end
	end)
end

-- Quick camera shake using CameraOffset on the local camera
function SkillFXHelper.shakeCamera(intensity: number, duration: number)
	local camera = Workspace.CurrentCamera
	if not camera then return end
	local startTime = tick()
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		if elapsed >= duration then
			camera.CFrame = camera.CFrame -- reset
			connection:Disconnect()
			return
		end
		local fade   = 1 - (elapsed / duration)
		local offset = Vector3.new(
			math.sin(elapsed * 55) * intensity * fade,
			math.cos(elapsed * 44) * intensity * fade * 0.6,
			0
		)
		camera.CFrame = camera.CFrame * CFrame.new(offset)
	end)
end

-- Create a neon part at a given CFrame with auto-cleanup
local function makePart(
	size: Vector3,
	cf: CFrame,
	color: Color3,
	transparency: number?,
	anchored: boolean?,
	shape: Enum.PartType?
): Part
	local p = Instance.new("Part")
	p.Size            = size
	p.CFrame          = cf
	p.Color           = color
	p.Material        = Enum.Material.Neon
	p.Transparency    = transparency or 0
	p.Anchored        = anchored ~= false
	p.CanCollide      = false
	p.CastShadow      = false
	p.Shape           = shape or Enum.PartType.Block
	return p
end

-- Fade a part out and destroy
local function fadePart(part: Part, duration: number)
	local tw = TweenService:Create(
		part,
		TweenInfo.new(duration, Enum.EasingStyle.Linear),
		{ Transparency = 1 }
	)
	tw:Play()
	tw.Completed:Connect(function()
		if part.Parent then part:Destroy() end
	end)
end

--------------------------------------------------------------------------------
-- 1. Sword Slash — Forward crescent wind blade projectile
--------------------------------------------------------------------------------
function SkillFXHelper.playSwordSlash(
	_casterChar: Model,
	origin: Vector3,
	direction: Vector3,
	range: number,
	speed: number
)
	SkillFXHelper.playSound(Workspace.Terrain, "rbxassetid://9114813101", 0.75, 1.15, 2.5)

	-- Main crescent blade
	local blade = makePart(
		Vector3.new(0.4, 3.5, 6),
		CFrame.lookAt(origin, origin + direction) * CFrame.new(0, 0, -2),
		Color3.fromRGB(120, 240, 215),
		0.0
	)
	blade.Shape = Enum.PartType.Block
	blade.Parent = Workspace

	-- Trail
	local trail = Instance.new("Trail")
	local att0, att1 = Instance.new("Attachment"), Instance.new("Attachment")
	att0.Position = Vector3.new(0, 1.5, 0)
	att1.Position = Vector3.new(0, -1.5, 0)
	att0.Parent = blade
	att1.Parent = blade
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Color = ColorSequence.new(Color3.fromRGB(120, 240, 215), Color3.fromRGB(200, 255, 255))
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	trail.Lifetime = 0.25
	trail.MinLength = 0
	trail.Parent = blade

	-- Particles
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(Color3.fromRGB(160, 255, 230), Color3.fromRGB(255, 255, 255))
	pe.Size  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	pe.Speed = NumberRange.new(4, 8)
	pe.Rate  = 40
	pe.SpreadAngle = Vector2.new(30, 30)
	pe.Parent = blade

	-- Animate projectile
	local travelTime = range / speed
	local tw = TweenService:Create(blade, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {
		CFrame = CFrame.lookAt(origin + direction * range, origin + direction * (range + 1)),
	})
	tw:Play()
	tw.Completed:Connect(function()
		pe.Rate = 0
		-- Impact flash
		local flash = makePart(Vector3.new(5, 5, 0.1), blade.CFrame, Color3.fromRGB(200, 255, 255), 0.3)
		flash.Parent = Workspace
		fadePart(flash, 0.2)
		task.wait(0.1)
		if blade.Parent then blade:Destroy() end
	end)
end

--------------------------------------------------------------------------------
-- 2. Palm Art — Golden shockwave AoE expanding ring
--------------------------------------------------------------------------------
function SkillFXHelper.playPalmArt(
	casterChar: Model,
	origin: Vector3,
	_lookDir: Vector3,
	radius: number
)
	SkillFXHelper.playSound(Workspace.Terrain, "rbxassetid://9114206424", 0.9, 0.95, 3.0)

	-- Golden palm energy ring that expands outward
	local ring = makePart(
		Vector3.new(2, 0.5, 2),
		CFrame.new(origin),
		Color3.fromRGB(255, 210, 40),
		0.15,
		true,
		Enum.PartType.Cylinder
	)
	ring.Size = Vector3.new(0.5, radius * 2, radius * 2)
	ring.CFrame = CFrame.new(origin) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Parent = Workspace

	local tw = TweenService:Create(ring, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.5, radius * 2.5, radius * 2.5),
		Transparency = 1,
	})
	tw:Play()
	tw.Completed:Connect(function()
		if ring.Parent then ring:Destroy() end
	end)

	-- Central burst particles
	local burstPart = makePart(Vector3.new(1, 1, 1), CFrame.new(origin), Color3.fromRGB(255, 220, 80), 1)
	burstPart.Parent = Workspace

	local burst = Instance.new("ParticleEmitter")
	burst.Color = ColorSequence.new(Color3.fromRGB(255, 210, 40), Color3.fromRGB(255, 255, 200))
	burst.Size  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.5), NumberSequenceKeypoint.new(1, 0) })
	burst.Speed = NumberRange.new(18, 35)
	burst.SpreadAngle = Vector2.new(180, 180)
	burst.Lifetime = NumberRange.new(0.4, 0.8)
	burst.Parent = burstPart
	burst:Emit(55)

	-- Camera shake for nearby caster
	if localPlayer.Character then
		local dist = (localPlayer.Character:GetPivot().Position - origin).Magnitude
		if dist < radius + 8 then
			SkillFXHelper.shakeCamera(0.6, 0.4)
		end
	end

	task.delay(1.0, function()
		if burstPart.Parent then burstPart:Destroy() end
	end)
end

--------------------------------------------------------------------------------
-- 3. Flame Ball — Phoenix fire orb projectile with impact explosion
--------------------------------------------------------------------------------
function SkillFXHelper.playFlameBall(
	_casterChar: Model,
	origin: Vector3,
	targetPos: Vector3,
	speed: number,
	radius: number
)
	SkillFXHelper.playSound(Workspace.Terrain, "rbxassetid://9114204072", 0.8, 1.05, 3.0)

	local dir        = (targetPos - origin).Unit
	local travelTime = (targetPos - origin).Magnitude / speed

	-- Orb
	local orb = makePart(
		Vector3.new(2.2, 2.2, 2.2),
		CFrame.new(origin),
		Color3.fromRGB(255, 90, 10),
		0.0,
		false,
		Enum.PartType.Ball
	)
	orb.Anchored = true
	orb.Parent   = Workspace

	local flame = Instance.new("ParticleEmitter")
	flame.Color = ColorSequence.new(Color3.fromRGB(255, 60, 0), Color3.fromRGB(255, 200, 40))
	flame.Size  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.4), NumberSequenceKeypoint.new(1, 0) })
	flame.Speed = NumberRange.new(5, 12)
	flame.Rate  = 70
	flame.SpreadAngle = Vector2.new(180, 180)
	flame.Lifetime = NumberRange.new(0.2, 0.5)
	flame.Parent = orb

	-- Tween the orb to target
	local tw = TweenService:Create(orb, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {
		CFrame = CFrame.new(targetPos),
	})
	tw:Play()
	tw.Completed:Connect(function()
		flame.Rate = 0
		SkillFXHelper.playSound(Workspace.Terrain, "rbxassetid://9114224027", 1.0, 0.9, 2.5)

		-- Impact explosion ring
		local explosion = makePart(
			Vector3.new(0.5, radius * 2, radius * 2),
			CFrame.new(targetPos) * CFrame.Angles(0, 0, math.pi / 2),
			Color3.fromRGB(255, 120, 20),
			0.2,
			true,
			Enum.PartType.Cylinder
		)
		explosion.Parent = Workspace
		TweenService:Create(explosion, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.5, radius * 3, radius * 3),
			Transparency = 1,
		}):Play()

		-- Burst particles
		local imp = Instance.new("ParticleEmitter")
		imp.Color = ColorSequence.new(Color3.fromRGB(255, 200, 50), Color3.fromRGB(255, 50, 0))
		imp.Size  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 0) })
		imp.Speed = NumberRange.new(25, 50)
		imp.SpreadAngle = Vector2.new(180, 180)
		imp.Lifetime = NumberRange.new(0.3, 0.7)
		imp.Parent = orb
		imp:Emit(60)

		if localPlayer.Character then
			local dist = (localPlayer.Character:GetPivot().Position - targetPos).Magnitude
			if dist < radius + 10 then
				SkillFXHelper.shakeCamera(0.8, 0.35)
			end
		end

		task.wait(0.4)
		if orb.Parent then orb:Destroy() end
		task.delay(0.5, function()
			if explosion.Parent then explosion:Destroy() end
		end)
	end)
end

--------------------------------------------------------------------------------
-- 4. Thunder Strike — Sky lightning bolt with warning ring
--------------------------------------------------------------------------------
function SkillFXHelper.playThunderStrike(
	targetPos: Vector3,
	radius: number,
	warningDuration: number
)
	SkillFXHelper.playSound(Workspace.Terrain, "rbxassetid://9114180476", 0.85, 0.9, 3.5)

	-- Warning ring on the ground
	local warnRing = makePart(
		Vector3.new(0.3, radius * 2, radius * 2),
		CFrame.new(targetPos) * CFrame.Angles(0, 0, math.pi / 2),
		Color3.fromRGB(180, 80, 255),
		0.3,
		true,
		Enum.PartType.Cylinder
	)
	warnRing.Parent = Workspace

	-- Pulse the warning ring
	task.spawn(function()
		local pulseCount = math.floor(warningDuration / 0.3)
		for _ = 1, pulseCount do
			TweenService:Create(warnRing, TweenInfo.new(0.15), { Transparency = 0.1 }):Play()
			task.wait(0.15)
			TweenService:Create(warnRing, TweenInfo.new(0.15), { Transparency = 0.6 }):Play()
			task.wait(0.15)
		end
	end)

	task.wait(warningDuration)

	-- Strike bolt from sky
	local skyPos = targetPos + Vector3.new(0, 80, 0)
	local bolt = makePart(
		Vector3.new(1.5, 80, 1.5),
		CFrame.new((skyPos + targetPos) / 2),
		Color3.fromRGB(200, 120, 255),
		0.0,
		true
	)
	bolt.Parent = Workspace

	SkillFXHelper.playSound(Workspace.Terrain, "rbxassetid://9114206424", 1.1, 1.3, 3.0)

	-- Burst at impact
	local impPart = makePart(Vector3.new(1, 1, 1), CFrame.new(targetPos), Color3.fromRGB(200, 100, 255), 1)
	impPart.Parent = Workspace

	local impBurst = Instance.new("ParticleEmitter")
	impBurst.Color = ColorSequence.new(Color3.fromRGB(200, 80, 255), Color3.fromRGB(255, 200, 255))
	impBurst.Size  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3.5), NumberSequenceKeypoint.new(1, 0) })
	impBurst.Speed = NumberRange.new(20, 45)
	impBurst.SpreadAngle = Vector2.new(180, 180)
	impBurst.Lifetime = NumberRange.new(0.3, 0.8)
	impBurst.Parent = impPart
	impBurst:Emit(70)

	if localPlayer.Character then
		local dist = (localPlayer.Character:GetPivot().Position - targetPos).Magnitude
		if dist < radius + 12 then
			SkillFXHelper.shakeCamera(1.2, 0.5)
		end
	end

	fadePart(bolt, 0.18)
	task.delay(0.18, function()
		if warnRing.Parent then warnRing:Destroy() end
		if impPart.Parent then impPart:Destroy() end
	end)
end

--------------------------------------------------------------------------------
-- 5. Multiple Swords — Spectral blue sword volley
--------------------------------------------------------------------------------
function SkillFXHelper.playMultipleSwords(
	_casterChar: Model,
	origin: Vector3,
	targetPos: Vector3,
	count: number,
	speed: number
)
	SkillFXHelper.playSound(Workspace.Terrain, "rbxassetid://9114813101", 0.7, 1.3, 3.0)

	local dir        = (targetPos - origin)
	local travelTime = dir.Magnitude / speed

	for i = 1, count do
		task.delay(i * 0.08, function()
			-- Spiral offset around origin
			local angle  = (i / count) * math.pi * 2
			local offset = Vector3.new(math.cos(angle) * 3, math.sin(angle) * 2, math.sin(angle) * 3)
			local startPos = origin + offset

			local sword = makePart(
				Vector3.new(0.3, 0.3, 5),
				CFrame.lookAt(startPos, startPos + dir.Unit),
				Color3.fromRGB(80, 160, 255),
				0.0
			)
			sword.Parent = Workspace

			-- Glow trail
			local trail = Instance.new("Trail")
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			a0.Position = Vector3.new(0, 0, 2.5)
			a1.Position = Vector3.new(0, 0, -2.5)
			a0.Parent = sword; a1.Parent = sword
			trail.Attachment0 = a0; trail.Attachment1 = a1
			trail.Color = ColorSequence.new(Color3.fromRGB(80, 160, 255), Color3.fromRGB(200, 230, 255))
			trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
			trail.Lifetime = 0.2
			trail.MinLength = 0
			trail.Parent = sword

			local jitter = Vector3.new(math.random(-2, 2), math.random(-1, 1), math.random(-2, 2))
			local dest   = targetPos + jitter

			TweenService:Create(sword, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {
				CFrame = CFrame.lookAt(dest, dest + dir.Unit),
			}):Play()

			task.delay(travelTime + 0.05, function()
				-- Small impact flash
				local flash = makePart(Vector3.new(3, 3, 0.1), sword.CFrame, Color3.fromRGB(160, 220, 255), 0.4)
				flash.Parent = Workspace
				fadePart(flash, 0.2)
				if sword.Parent then sword:Destroy() end
			end)
		end)
	end
end

--------------------------------------------------------------------------------
-- 6. Flame Spear — Solar homing spear
--------------------------------------------------------------------------------
function SkillFXHelper.playFlameSpear(
	_casterChar: Model,
	origin: Vector3,
	targetModel: Model?,
	targetStaticPos: Vector3,
	speed: number
)
	SkillFXHelper.playSound(Workspace.Terrain, "rbxassetid://9114204072", 0.9, 1.2, 3.0)

	-- Spear body
	local spear = makePart(
		Vector3.new(0.45, 0.45, 7),
		CFrame.lookAt(origin, targetStaticPos),
		Color3.fromRGB(255, 160, 20),
		0.0
	)
	spear.Parent = Workspace

	-- Flame trail
	local trail = Instance.new("Trail")
	local t0, t1 = Instance.new("Attachment"), Instance.new("Attachment")
	t0.Position = Vector3.new(0, 0, 3.5)
	t1.Position = Vector3.new(0, 0, -3.5)
	t0.Parent = spear; t1.Parent = spear
	trail.Attachment0 = t0; trail.Attachment1 = t1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 160, 20), Color3.fromRGB(255, 240, 80))
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	trail.Lifetime = 0.3
	trail.MinLength = 0
	trail.Parent = spear

	-- Solar Flare Particles
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 80, 10))
	pe.Size  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.8), NumberSequenceKeypoint.new(1, 0) })
	pe.Speed = NumberRange.new(8, 15)
	pe.Rate  = 60
	pe.SpreadAngle = Vector2.new(30, 30)
	pe.Parent = spear

	-- Guided Homing Simulation
	task.spawn(function()
		local curPos     = origin
		local maxSteps   = 45
		local stepDuration = 0.03
		local step       = 0

		while step < maxSteps and spear.Parent do
			step = step + 1
			task.wait(stepDuration)

			-- Recalculate target position if target is a live enemy
			local dest = targetStaticPos
			if targetModel and targetModel.Parent then
				local tRoot = targetModel:FindFirstChild("HumanoidRootPart") or targetModel:FindFirstChild("Torso")
				if tRoot and tRoot:IsA("BasePart") then
					dest = tRoot.Position
				end
			end

			local toDest  = dest - curPos
			local dist    = toDest.Magnitude
			local moveStep = math.min((speed or 80) * stepDuration, dist)
			local nextPos = curPos + toDest.Unit * moveStep

			spear.CFrame = CFrame.lookAt(nextPos, dest)
			curPos = nextPos

			if dist <= 2.5 then
				break
			end
		end

		-- Explosion on contact
		if spear.Parent then
			SkillFXHelper.playSound(spear, "rbxassetid://9114224027", 1.1, 1.2, 2.0)
			pe.Rate = 0

			local impactBurst = Instance.new("ParticleEmitter")
			impactBurst.Color = ColorSequence.new(Color3.fromRGB(255, 240, 100), Color3.fromRGB(255, 40, 10))
			impactBurst.Size  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3.5), NumberSequenceKeypoint.new(1, 0) })
			impactBurst.Speed = NumberRange.new(20, 40)
			impactBurst.SpreadAngle = Vector2.new(180, 180)
			impactBurst.Lifetime = NumberRange.new(0.3, 0.6)
			impactBurst.Parent = spear
			impactBurst:Emit(45)

			spear.Transparency = 1
			if localPlayer.Character and (localPlayer.Character:GetPivot().Position - curPos).Magnitude < 40 then
				SkillFXHelper.shakeCamera(1.2, 0.3)
			end

			task.wait(0.35)
			spear:Destroy()
		end
	end)
end

return SkillFXHelper
