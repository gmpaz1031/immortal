--!strict
-- src/client/MovementController.client.luau
-- Xianxia Movement Skills Controller (Flash Step & Enhanced Surfing Flying Sword Mount)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GuofengTheme = require(Shared:WaitForChild("GuofengTheme"))

local remotesFolder = ReplicatedStorage:WaitForChild("SkillRemotes") :: Folder

-- Remote Event for Movement Replication
local moveRemote = remotesFolder:FindFirstChild("MovementRemote") :: RemoteEvent?
if not moveRemote then
	moveRemote = Instance.new("RemoteEvent")
	moveRemote.Name = "MovementRemote"
	moveRemote.Parent = remotesFolder
end

-- State variables
local isDashing = false
local lastDashTime = 0
local dashCooldown = 2.0
local dashQiCost = 10

local isMounted = false
local swordMountModel: Instance? = nil
local flightLinearVelocity: LinearVelocity? = nil
local flightAlignOrientation: AlignOrientation? = nil
local flightAttachment: Attachment? = nil
local surfSteppedConn: RBXScriptConnection? = nil

-- Sound & FOV storage
local flightSound: Sound? = nil
local originalFOV = 70.0

-- Prompt notification UI helper
local function showNotification(message: string, color: Color3)
	local pGui = player:FindFirstChildOfClass("PlayerGui")
	if not pGui then return end
	local promptLabel = pGui:FindFirstChild("PromptNotificationLabel", true) :: TextLabel?
	if promptLabel then
		promptLabel.Text = message
		promptLabel.TextColor3 = color
		promptLabel.Visible = true
		task.delay(2.2, function()
			if promptLabel and promptLabel.Text == message then
				promptLabel.Visible = false
			end
		end)
	end
end

-- ============================================================================
-- 1. FLASH STEP (Q KEY / CELESTIAL QI DASH)
-- ============================================================================
local function createAfterimageGhost(char: Model)
	local ghostModel = Instance.new("Model")
	ghostModel.Name = "FlashStepAfterimage"

	for _, part in ipairs(char:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local p = part:Clone()
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = false
			p.Anchored = true
			p.Material = Enum.Material.Neon
			p.Color = Color3.fromRGB(120, 220, 255)
			p.Transparency = 0.3
			p.Parent = ghostModel

			local fadeInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			TweenService:Create(p, fadeInfo, { Transparency = 1.0 }):Play()
		end
	end

	ghostModel.Parent = workspace
	Debris:AddItem(ghostModel, 0.4)
end

local function executeFlashStep()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not char or not root or not hum or hum.Health <= 0 then return end

	local now = os.clock()
	if now - lastDashTime < dashCooldown then
		local remaining = dashCooldown - (now - lastDashTime)
		showNotification(string.format("Flash Step on cooldown (%.1fs)", remaining), GuofengTheme.Colors.GoldAmber)
		return
	end

	-- Check Qi Cost
	local currentQi = player:GetAttribute("Qi") or 0
	if currentQi == 0 then
		local ls = player:FindFirstChild("leaderstats")
		local qiVal = ls and ls:FindFirstChild("Qi") :: IntValue?
		if qiVal then currentQi = qiVal.Value end
	end
	if currentQi < dashQiCost then
		showNotification("Not enough Qi for Flash Step!", Color3.fromRGB(255, 80, 70))
		return
	end

	isDashing = true
	lastDashTime = now

	-- Deduct Qi on client attribute
	player:SetAttribute("Qi", math.max(0, currentQi - dashQiCost))

	-- Determine dash direction vector
	local moveDir = hum.MoveDirection
	local dashVector: Vector3
	if moveDir.Magnitude > 0.1 then
		dashVector = moveDir.Unit
	else
		dashVector = root.CFrame.LookVector
	end

	local dashDistance = 28.0
	local dashDuration = 0.18

	-- Raycast check to prevent wall clipping
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { char }

	local wallRay = workspace:Raycast(root.Position, dashVector * dashDistance, rayParams)
	local targetPos = if wallRay then (wallRay.Position - dashVector * 1.5) else (root.Position + dashVector * dashDistance)

	-- Sound FX
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://9114223170"
	sound.Volume = 0.8
	sound.PlaybackSpeed = 1.3
	sound.Parent = root
	sound:Play()
	Debris:AddItem(sound, 2)

	-- Feet Ground Shockwave Ring
	local ring = Instance.new("Part")
	ring.Name = "FlashStepRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.2, 2, 2)
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(140, 230, 255)
	ring.Transparency = 0.2
	ring.CanCollide = false
	ring.Anchored = true
	ring.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = workspace

	local ringTween = TweenService:Create(ring, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.1, 10, 10),
		Transparency = 1,
	})
	ringTween:Play()
	Debris:AddItem(ring, 0.35)

	-- Spawn Ghost Trail Clones during dash step
	task.spawn(function()
		local stepCount = 5
		for i = 1, stepCount do
			createAfterimageGhost(char)
			task.wait(dashDuration / stepCount)
		end
	end)

	-- Replicate Flash Step to other clients
	if moveRemote then
		moveRemote:FireServer("FlashStep", root.Position, targetPos)
	end

	-- Apply smooth rapid dash translation
	local startPos = root.Position
	local startTime = os.clock()
	while os.clock() - startTime < dashDuration do
		local alpha = (os.clock() - startTime) / dashDuration
		local currentTarget = startPos:Lerp(targetPos, alpha)
		root.CFrame = CFrame.new(currentTarget, currentTarget + dashVector)
		RunService.RenderStepped:Wait()
	end

	root.CFrame = CFrame.new(targetPos, targetPos + dashVector)
	isDashing = false
end

-- ============================================================================
-- 2. ENHANCED SURFING FLYING SWORD MOUNT (G KEY / SPIRIT SWORD RIDING)
-- ============================================================================
local function startSurfingPoseLoop(char: Model)
	if surfSteppedConn then
		surfSteppedConn:Disconnect()
		surfSteppedConn = nil
	end

	-- Stop playing default walking tracks so default animations don't fight the surfing pose
	local hum = char:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			track:Stop(0.1)
		end
	end

	local jointsToPose: { [string]: CFrame } = {
		["RootJoint"]      = CFrame.Angles(0, math.rad(55), 0),
		["Neck"]           = CFrame.Angles(0, math.rad(-45), 0),
		["Right Shoulder"] = CFrame.Angles(math.rad(45), math.rad(-20), math.rad(30)),
		["Left Shoulder"]  = CFrame.Angles(math.rad(-30), math.rad(20), math.rad(-20)),
		["Right Hip"]      = CFrame.Angles(math.rad(-15), 0, math.rad(10)),
		["Left Hip"]       = CFrame.Angles(math.rad(-15), 0, math.rad(10)),
	}

	surfSteppedConn = RunService.Stepped:Connect(function()
		if not isMounted or not char or not char.Parent then
			if surfSteppedConn then
				surfSteppedConn:Disconnect()
				surfSteppedConn = nil
			end
			return
		end

		for name, poseTransform in pairs(jointsToPose) do
			local obj = char:FindFirstChild(name, true)
			if obj and obj:IsA("Motor6D") then
				obj.Transform = poseTransform
			end
		end
	end)
end

local function stopSurfingPoseLoop()
	if surfSteppedConn then
		surfSteppedConn:Disconnect()
		surfSteppedConn = nil
	end
end

local function toggleFlyingSwordMount()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local camera = workspace.CurrentCamera
	if not char or not root or not hum or hum.Health <= 0 then return end

	if isMounted then
		-- Dismount
		isMounted = false

		stopSurfingPoseLoop()

		if flightLinearVelocity then flightLinearVelocity:Destroy() flightLinearVelocity = nil end
		if flightAlignOrientation then flightAlignOrientation:Destroy() flightAlignOrientation = nil end
		if flightAttachment then flightAttachment:Destroy() flightAttachment = nil end
		if swordMountModel then swordMountModel:Destroy() swordMountModel = nil end
		if flightSound then flightSound:Destroy() flightSound = nil end

		if camera then
			TweenService:Create(camera, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = originalFOV }):Play()
		end

		hum.PlatformStand = false
		hum:ChangeState(Enum.HumanoidStateType.Freefall)

		showNotification("Dismounted Flying Sword", GuofengTheme.Colors.TextMuted)

		if moveRemote then
			moveRemote:FireServer("DismountSword")
		end
	else
		-- Mount Flying Sword
		isMounted = true

		if camera then
			originalFOV = camera.FieldOfView
		end

		-- Elevate character off the ground instantly on mount
		root.CFrame = root.CFrame + Vector3.new(0, 8, 0)
		hum.PlatformStand = true
		hum:ChangeState(Enum.HumanoidStateType.Flying)

		-- Start Procedural Surfing Stance Loop
		startSurfingPoseLoop(char)

		-- Setup Flight Physics Constraints (LinearVelocity & AlignOrientation)
		flightAttachment = Instance.new("Attachment")
		flightAttachment.Name = "FlightAttachment"
		flightAttachment.Parent = root

		flightLinearVelocity = Instance.new("LinearVelocity")
		flightLinearVelocity.Name = "FlightLinearVelocity"
		flightLinearVelocity.MaxForce = math.huge
		flightLinearVelocity.VectorVelocity = Vector3.zero
		flightLinearVelocity.Attachment0 = flightAttachment
		flightLinearVelocity.Parent = root

		flightAlignOrientation = Instance.new("AlignOrientation")
		flightAlignOrientation.Name = "FlightAlignOrientation"
		flightAlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
		flightAlignOrientation.RigidityEnabled = true
		flightAlignOrientation.Attachment0 = flightAttachment
		flightAlignOrientation.CFrame = root.CFrame
		flightAlignOrientation.Parent = root

		-- 1. Locate and Clone SwordFlightPart template from Workspace or ReplicatedStorage
		local template = workspace:FindFirstChild("SwordFlightPart") 
			or ReplicatedStorage:FindFirstChild("SwordFlightPart")

		local swordInstance: Instance
		if template then
			swordInstance = template:Clone()
		else
			-- Fallback Neon Spiritual Sword Mesh Part if template is missing in test environment
			local p = Instance.new("Part")
			p.Name = "SwordFlightPart"
			p.Size = Vector3.new(1.4, 8.0, 0.35) -- X: width, Y: length, Z: thickness
			p.Material = Enum.Material.Neon
			p.Color = Color3.fromRGB(130, 225, 255)
			swordInstance = p
		end

		swordInstance.Name = "ActiveSwordMount"

		-- Ensure ALL parts in sword hierarchy are non-collidable, massless, and unanchored
		for _, desc in ipairs(swordInstance:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.CanCollide = false
				desc.Massless = true
				desc.Anchored = false
			end
		end
		if swordInstance:IsA("BasePart") then
			swordInstance.CanCollide = false
			swordInstance.Massless = true
			swordInstance.Anchored = false
		end

		local mainSwordPart: BasePart
		if swordInstance:IsA("Model") then
			mainSwordPart = swordInstance.PrimaryPart or swordInstance:FindFirstChildOfClass("BasePart") or Instance.new("Part", swordInstance)
		else
			mainSwordPart = swordInstance :: BasePart
		end

		-- Clean existing WeldConstraints and reinforce invariant local welds for all child parts
		for _, desc in ipairs(swordInstance:GetDescendants()) do
			if desc:IsA("WeldConstraint") then
				desc:Destroy()
			end
		end
		for _, child in ipairs(swordInstance:GetChildren()) do
			if child:IsA("BasePart") and child ~= mainSwordPart then
				local w = Instance.new("Weld")
				w.Name = child.Name .. "Weld"
				w.Part0 = mainSwordPart
				w.Part1 = child
				w.C0 = CFrame.Angles(0, 0, math.rad(180))
				w.C1 = CFrame.new()
				w.Parent = child
			end
		end

		-- Calculate Mount CFrame: Laid completely flat directly beneath the player's feet (Y = -3.15)
		-- with the sword tip (+Y) facing Forward (-Z in character space)
		local mountOffset = CFrame.new(0, -3.15, -0.5) * CFrame.Angles(math.rad(-90), 0, 0)
		mainSwordPart.CFrame = root.CFrame * mountOffset

		-- Weld main sword part to HumanoidRootPart
		local weld = Instance.new("Weld")
		weld.Name = "SwordMountWeld"
		weld.Part0 = root
		weld.Part1 = mainSwordPart
		weld.C0 = mountOffset
		weld.C1 = CFrame.new()
		weld.Parent = mainSwordPart

		-- 2. Glowing Energy Ribbon Trail Behind Sword (trailing from pommel/hilt at -Y)
		local trailAtt0 = Instance.new("Attachment")
		trailAtt0.Position = Vector3.new(-0.8, -4.2, 0)
		trailAtt0.Parent = mainSwordPart

		local trailAtt1 = Instance.new("Attachment")
		trailAtt1.Position = Vector3.new(0.8, -4.2, 0)
		trailAtt1.Parent = mainSwordPart

		local swordTrail = Instance.new("Trail")
		swordTrail.Name = "SwordEnergyTrail"
		swordTrail.Attachment0 = trailAtt0
		swordTrail.Attachment1 = trailAtt1
		swordTrail.Color = ColorSequence.new(Color3.fromRGB(130, 230, 255), Color3.fromRGB(255, 220, 100))
		swordTrail.Lifetime = 0.55
		swordTrail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1.0) })
		swordTrail.Parent = mainSwordPart

		-- 3. Speed Lines Wind Particle Emitter (emitting backward from tail of sword)
		local windAttachment = Instance.new("Attachment")
		windAttachment.Position = Vector3.new(0, -4.2, 0)
		windAttachment.Parent = mainSwordPart

		local windEmitter = Instance.new("ParticleEmitter")
		windEmitter.Name = "WindSpeedEmitter"
		windEmitter.Texture = "rbxassetid://242200388"
		windEmitter.Color = ColorSequence.new(Color3.fromRGB(220, 245, 255), Color3.fromRGB(140, 210, 255))
		windEmitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.8), NumberSequenceKeypoint.new(1, 0.1) })
		windEmitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1.0) })
		windEmitter.Lifetime = NumberRange.new(0.25, 0.5)
		windEmitter.Rate = 0 -- Dynamically scales with flight speed
		windEmitter.Speed = NumberRange.new(12, 35)
		windEmitter.EmissionDirection = Enum.NormalId.Bottom -- In mainSwordPart space, -Y points backward
		windEmitter.Parent = windAttachment

		swordInstance.Parent = char
		swordMountModel = swordInstance

		-- 4. Flight Wind Audio Loop
		flightSound = Instance.new("Sound")
		flightSound.SoundId = "rbxassetid://9114223170"
		flightSound.Volume = 0.2
		flightSound.Looped = true
		flightSound.PlaybackSpeed = 0.9
		flightSound.Parent = mainSwordPart
		flightSound:Play()

		showNotification("Mounted Sword! Hold W to accelerate, S to slow/reverse, A/D to lean, Space to ascend.", GuofengTheme.Colors.CyanGlow)

		-- Flight Momentum Physics & Dynamic FOV/Particle Loop
		task.spawn(function()
			local currentForwardSpeed = 0.0
			local maxForwardSpeed = 85.0
			local maxReverseSpeed = -30.0
			local accelRate = 65.0
			local decelRate = 50.0
			local frictionRate = 35.0
			local strafeSpeed = 32.0

			while isMounted and char.Parent and hum.Health > 0 do
				local dt = RunService.RenderStepped:Wait()
				local camCF = camera.CFrame

				-- Accelerate / Decelerate Forward Momentum
				if UserInputService:IsKeyDown(Enum.KeyCode.W) then
					currentForwardSpeed = math.min(maxForwardSpeed, currentForwardSpeed + accelRate * dt)
				elseif UserInputService:IsKeyDown(Enum.KeyCode.S) then
					currentForwardSpeed = math.max(maxReverseSpeed, currentForwardSpeed - decelRate * dt)
				else
					-- Decay back to 0 when W/S are released
					if currentForwardSpeed > 0 then
						currentForwardSpeed = math.max(0, currentForwardSpeed - frictionRate * dt)
					elseif currentForwardSpeed < 0 then
						currentForwardSpeed = math.min(0, currentForwardSpeed + frictionRate * dt)
					end
				end

				-- Strafe & Vertical Movement Inputs
				local strafeDir = 0
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then strafeDir = strafeDir + 1 end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then strafeDir = strafeDir - 1 end

				local vertDir = 0
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vertDir = vertDir + 1 end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.C) then vertDir = vertDir - 1 end

				-- Calculate 3D Velocity Vector
				local fwdVector = camCF.LookVector * currentForwardSpeed
				local strafeVector = camCF.RightVector * (strafeDir * strafeSpeed)
				local vertVector = Vector3.new(0, vertDir * 28.0, 0)
				local totalVelocity = fwdVector + strafeVector + vertVector

				if flightLinearVelocity and flightAlignOrientation then
					flightLinearVelocity.VectorVelocity = totalVelocity

					-- Roll/Tilt into turns
					local rollAngle = math.rad(-strafeDir * 14.0)
					flightAlignOrientation.CFrame = CFrame.lookAt(root.Position, root.Position + camCF.LookVector) * CFrame.Angles(0, 0, rollAngle)
				end

				-- Dynamic FOV Speed Zoom (70 -> 92)
				local speedRatio = math.clamp(currentForwardSpeed / maxForwardSpeed, 0, 1)
				local targetFOV = 70.0 + (speedRatio * 22.0)
				camera.FieldOfView = camera.FieldOfView + (targetFOV - camera.FieldOfView) * 0.1

				-- Wind Particle Rate & Sound Pitching with Speed
				if windEmitter then
					windEmitter.Rate = math.floor(speedRatio * 110)
				end
				if flightSound then
					flightSound.PlaybackSpeed = 0.85 + (speedRatio * 0.75)
					flightSound.Volume = 0.25 + (speedRatio * 0.55)
				end
			end
		end)

		if moveRemote then
			moveRemote:FireServer("MountSword")
		end
	end
end

-- ============================================================================
-- KEYBOARD BINDINGS (Q = Flash Step, G = Flying Sword Mount)
-- ============================================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or UserInputService:GetFocusedTextBox() ~= nil then return end

	if input.KeyCode == Enum.KeyCode.Q then
		executeFlashStep()
	elseif input.KeyCode == Enum.KeyCode.G then
		toggleFlyingSwordMount()
	end
end)

print("[MovementController] Enhanced Xianxia Surfing Movement Controller with Stepped Transform & Wind Trails initialized cleanly.")
