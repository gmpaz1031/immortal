--!strict
--[[
    DemonCultFactory.luau
    Builds procedural R6 enemy rigs for all Heavenly Demon Cult enemies.
    Pattern mirrors CaveEnemyFactory.luau exactly — procedural parts + Motor6D joints +
    WeldConstraint accessories + BillboardGui health bar.

    Enemy types handled:
      DemonCultist, SeniorDemonCultist, DemonicElder,
      FlameDemoness, PoisonDemoness, FistDemon, SwordDemon,
      SupremeDemon, BloodDemon
]]

local DemonCultFactory = {}

--------------------------------------------------------------------------------
-- Color Palette
--------------------------------------------------------------------------------
local COLORS = {
	-- Demon Cultist
	CultistRobe       = Color3.fromRGB(22, 10, 10),
	CultistTrim       = Color3.fromRGB(120, 15, 15),
	CultistSkin       = Color3.fromRGB(180, 130, 110),

	-- Senior Demon Cultist
	SeniorRobe        = Color3.fromRGB(12, 8, 8),
	SeniorTrim        = Color3.fromRGB(200, 40, 20),
	SeniorBlade       = Color3.fromRGB(255, 50, 30),

	-- Demonic Elder
	ElderRobe         = Color3.fromRGB(8, 5, 5),
	ElderGold         = Color3.fromRGB(210, 155, 40),
	ElderSkin         = Color3.fromRGB(155, 100, 85),

	-- Flame Demoness
	FlameSkin         = Color3.fromRGB(240, 120, 60),
	FlameRobe         = Color3.fromRGB(90, 12, 8),
	FlameAura         = Color3.fromRGB(255, 80, 10),

	-- Poison Demoness
	PoisonSkin        = Color3.fromRGB(140, 200, 100),
	PoisonRobe        = Color3.fromRGB(35, 55, 15),
	PoisonAura        = Color3.fromRGB(60, 230, 60),

	-- Fist Demon
	FistSkin          = Color3.fromRGB(90, 20, 20),
	FistArmor         = Color3.fromRGB(55, 10, 10),
	FistFire          = Color3.fromRGB(255, 100, 10),

	-- Sword Demon
	SwordRobe         = Color3.fromRGB(10, 10, 35),
	SwordBlade        = Color3.fromRGB(80, 120, 255),
	SwordSkin         = Color3.fromRGB(160, 140, 180),

	-- Supreme Demon
	SupremeSkin       = Color3.fromRGB(30, 5, 5),
	SupremeArmor      = Color3.fromRGB(8, 8, 8),
	SupremeGold       = Color3.fromRGB(220, 160, 30),
	SupremeAura       = Color3.fromRGB(180, 20, 255),

	-- Blood Demon
	BloodSkin         = Color3.fromRGB(180, 30, 30),
	BloodRobe         = Color3.fromRGB(60, 5, 5),
	BloodAura         = Color3.fromRGB(255, 10, 10),
}

--------------------------------------------------------------------------------
-- Shared: Health Bar BillboardGui
-- Matches CaveEnemyFactory.attachHealthBar exactly
--------------------------------------------------------------------------------
local function attachHealthBar(model: Model, adorneePart: BasePart, title: string, maxHp: number, isBoss: boolean, scale: number)
	local bbg = Instance.new("BillboardGui")
	bbg.Name = "EnemyHealthGui"
	bbg.AlwaysOnTop = false
	bbg.LightInfluence = 0
	bbg.MaxDistance = 100
	bbg.Size = isBoss
		and UDim2.new(5.6 * scale, 0, 1.15 * scale, 0)
		or  UDim2.new(4.2 * scale, 0, 0.88 * scale, 0)
	bbg.StudsOffset = Vector3.new(0, (2.7 + (isBoss and 1.1 or 0)) * scale, 0)
	bbg.Adornee = adorneePart
	bbg.Parent = model

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Name = "NameLabel"
	nameLbl.BackgroundTransparency = 1
	nameLbl.Size = UDim2.new(1, 0, 0.48, 0)
	nameLbl.Position = UDim2.new(0, 0, 0, 0)
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.Text = title
	nameLbl.TextColor3 = isBoss and Color3.fromRGB(255, 140, 60) or Color3.fromRGB(255, 200, 160)
	nameLbl.TextScaled = true
	nameLbl.Parent = bbg

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(10, 5, 5)
	stroke.Thickness = 1.2
	stroke.Parent = nameLbl

	local hpFrame = Instance.new("Frame")
	hpFrame.Name = "HpBar"
	hpFrame.BackgroundColor3 = Color3.fromRGB(25, 12, 12)
	hpFrame.BorderSizePixel = 0
	hpFrame.Position = UDim2.new(0, 0, 0.54, 0)
	hpFrame.Size = UDim2.new(1, 0, 0.38, 0)
	hpFrame.Parent = bbg

	local hpCorner = Instance.new("UICorner")
	hpCorner.CornerRadius = UDim.new(0.3, 0)
	hpCorner.Parent = hpFrame

	local hpFill = Instance.new("Frame")
	hpFill.Name = "Fill"
	hpFill.BackgroundColor3 = isBoss and Color3.fromRGB(235, 35, 35) or Color3.fromRGB(220, 55, 40)
	hpFill.BorderSizePixel = 0
	hpFill.Size = UDim2.new(1, 0, 1, 0)
	hpFill.Parent = hpFrame

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0.3, 0)
	fillCorner.Parent = hpFill

	local hpText = Instance.new("TextLabel")
	hpText.Name = "Value"
	hpText.BackgroundTransparency = 1
	hpText.Size = UDim2.new(1, 0, 1, 0)
	hpText.Font = Enum.Font.GothamBold
	hpText.Text = string.format("%d / %d", maxHp, maxHp)
	hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
	hpText.TextScaled = true
	hpText.Parent = hpFrame

	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.HealthChanged:Connect(function(health)
			local frac = math.clamp(health / math.max(1, hum.MaxHealth), 0, 1)
			hpFill.Size = UDim2.new(frac, 0, 1, 0)
			hpText.Text = string.format("%d / %d", math.max(0, math.floor(health)), hum.MaxHealth)
		end)
	end
end

--------------------------------------------------------------------------------
-- Shared: Build a standard R6 humanoid skeleton with Motor6D joints
--------------------------------------------------------------------------------
local function buildR6Skeleton(name: string, scale: number, skinColor: Color3, torsoColor: Color3, legColor: Color3): Model
	local model = Instance.new("Model")
	model.Name = name

	-- HumanoidRootPart
	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2 * scale, 2 * scale, 1 * scale)
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.Anchored = false
	hrp.Parent = model
	model.PrimaryPart = hrp

	-- Torso
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2 * scale, 2 * scale, 1 * scale)
	torso.Color = torsoColor
	torso.Material = Enum.Material.Fabric
	torso.CanCollide = false
	torso.Anchored = false
	torso.Parent = model

	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.25 * scale, 1.25 * scale, 1.25 * scale)
	head.Color = skinColor
	head.CanCollide = false
	head.Anchored = false
	head.Parent = model

	-- Arms
	local leftArm = Instance.new("Part")
	leftArm.Name = "Left Arm"
	leftArm.Size = Vector3.new(1 * scale, 2 * scale, 1 * scale)
	leftArm.Color = torsoColor
	leftArm.Material = Enum.Material.Fabric
	leftArm.CanCollide = false
	leftArm.Anchored = false
	leftArm.Parent = model

	local rightArm = Instance.new("Part")
	rightArm.Name = "Right Arm"
	rightArm.Size = Vector3.new(1 * scale, 2 * scale, 1 * scale)
	rightArm.Color = torsoColor
	rightArm.Material = Enum.Material.Fabric
	rightArm.CanCollide = false
	rightArm.Anchored = false
	rightArm.Parent = model

	-- Legs
	local leftLeg = Instance.new("Part")
	leftLeg.Name = "Left Leg"
	leftLeg.Size = Vector3.new(1 * scale, 2 * scale, 1 * scale)
	leftLeg.Color = legColor
	leftLeg.Material = Enum.Material.Fabric
	leftLeg.CanCollide = false
	leftLeg.Anchored = false
	leftLeg.Parent = model

	local rightLeg = Instance.new("Part")
	rightLeg.Name = "Right Leg"
	rightLeg.Size = Vector3.new(1 * scale, 2 * scale, 1 * scale)
	rightLeg.Color = legColor
	rightLeg.Material = Enum.Material.Fabric
	rightLeg.CanCollide = false
	rightLeg.Anchored = false
	rightLeg.Parent = model

	-- Motor6D Joints
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
	rightShoulder.C0 = CFrame.new(1.5 * scale, 0.5 * scale, 0)
	rightShoulder.C1 = CFrame.new(0, 0.5 * scale, 0)
	rightShoulder.Parent = torso

	local leftShoulder = Instance.new("Motor6D")
	leftShoulder.Name = "Left Shoulder"
	leftShoulder.Part0 = torso
	leftShoulder.Part1 = leftArm
	leftShoulder.C0 = CFrame.new(-1.5 * scale, 0.5 * scale, 0)
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

	-- Humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.AutoJumpEnabled = false
	humanoid.Parent = model

	return model
end

local function weld(parent: BasePart, child: BasePart, offset: CFrame)
	child.CanCollide = false
	child.Massless = true
	child.CFrame = parent.CFrame * offset
	local w = Instance.new("Weld")
	w.Name = child.Name .. "Weld"
	w.Part0 = parent
	w.Part1 = child
	w.C0 = offset
	w.C1 = CFrame.new()
	w.Parent = child
end

--------------------------------------------------------------------------------
-- Shared: Add a glowing blade weapon to right arm
--------------------------------------------------------------------------------
local function addBlade(model: Model, bladeColor: Color3, bladeSize: Vector3, neon: boolean, scale: number)
	local rArm = model:FindFirstChild("Right Arm") :: BasePart
	if not rArm then return end
	local blade = Instance.new("Part")
	blade.Name = "DemonicBlade"
	blade.Size = bladeSize
	blade.Color = bladeColor
	blade.Material = neon and Enum.Material.Neon or Enum.Material.Metal
	blade.CanCollide = false
	blade.Anchored = false
	blade.Parent = model
	weld(rArm, blade, CFrame.new(0, -1.3 * scale, -0.7 * scale) * CFrame.Angles(math.rad(60), 0, 0))

	-- Trail attachment
	local att0 = Instance.new("Attachment", blade)
	att0.Position = Vector3.new(0, -bladeSize.Y / 2, 0)
	local att1 = Instance.new("Attachment", blade)
	att1.Position = Vector3.new(0, bladeSize.Y / 2, 0)

	local trail = Instance.new("Trail", blade)
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Color = ColorSequence.new(bladeColor, Color3.fromRGB(10, 5, 5))
	trail.Lifetime = 0.2
	trail.Enabled = false
	trail.Name = "WeaponTrail"
end

--------------------------------------------------------------------------------
-- Shared: Add a particle aura emitter
--------------------------------------------------------------------------------
local function addAura(part: BasePart, color1: Color3, color2: Color3, rate: number, size: number)
	local em = Instance.new("ParticleEmitter")
	em.Name = "AuraEmitter"
	em.Color = ColorSequence.new(color1, color2)
	em.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size),
		NumberSequenceKeypoint.new(0.5, size * 0.6),
		NumberSequenceKeypoint.new(1, 0),
	})
	em.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
	em.Lifetime = NumberRange.new(0.5, 0.9)
	em.Rate = rate
	em.Speed = NumberRange.new(1, 2.5)
	em.SpreadAngle = Vector2.new(180, 180)
	em.Parent = part
end

--------------------------------------------------------------------------------
-- PUBLIC: Create any Demon Cult enemy model by type name
--------------------------------------------------------------------------------
function DemonCultFactory.createEnemy(enemyType: string): Model
	local scale = 1.0
	if enemyType == "SeniorDemonCultist" then scale = 1.1
	elseif enemyType == "DemonicElder"     then scale = 1.2
	elseif enemyType == "FlameDemoness"    then scale = 1.15
	elseif enemyType == "PoisonDemoness"   then scale = 1.15
	elseif enemyType == "FistDemon"        then scale = 1.3
	elseif enemyType == "SwordDemon"       then scale = 1.2
	elseif enemyType == "SupremeDemon"     then scale = 1.45
	elseif enemyType == "BloodDemon"       then scale = 1.35
	end

	local isBoss = (
		enemyType == "DemonicElder"  or enemyType == "FlameDemoness"  or
		enemyType == "PoisonDemoness" or enemyType == "FistDemon"      or
		enemyType == "SwordDemon"    or enemyType == "SupremeDemon"    or
		enemyType == "BloodDemon"
	)

	local model: Model
	local torso: BasePart
	local head: BasePart

	-- -------------------------------------------------------
	if enemyType == "DemonCultist" then
		model = buildR6Skeleton("DemonCultist", scale, COLORS.CultistSkin, COLORS.CultistRobe, Color3.fromRGB(18, 8, 8))
		torso = model:FindFirstChild("Torso") :: BasePart
		head  = model:FindFirstChild("Head")  :: BasePart

		-- Red cloth mask over lower face
		local mask = Instance.new("Part")
		mask.Name = "CultMask"
		mask.Size = Vector3.new(1.3 * scale, 0.55 * scale, 0.2 * scale)
		mask.Color = COLORS.CultistTrim
		mask.Material = Enum.Material.Fabric
		mask.CanCollide = false; mask.Anchored = false
		mask.Parent = model
		weld(head, mask, CFrame.new(0, -0.25 * scale, -0.65 * scale))

		-- Red glowing sword
		addBlade(model, COLORS.CultistTrim, Vector3.new(0.2 * scale, 3.5 * scale, 0.45 * scale), true, scale)

		-- Dim red aura on torso
		addAura(torso, Color3.fromRGB(120, 10, 10), Color3.fromRGB(40, 5, 5), 6, 0.5 * scale)

	-- -------------------------------------------------------
	elseif enemyType == "SeniorDemonCultist" then
		model = buildR6Skeleton("SeniorDemonCultist", scale, COLORS.CultistSkin, COLORS.SeniorRobe, Color3.fromRGB(10, 5, 5))
		torso = model:FindFirstChild("Torso") :: BasePart
		head  = model:FindFirstChild("Head")  :: BasePart

		-- Horned helmet
		local helm = Instance.new("Part")
		helm.Name = "DemonHelm"
		helm.Size = Vector3.new(1.4 * scale, 0.6 * scale, 1.4 * scale)
		helm.Color = Color3.fromRGB(30, 10, 10)
		helm.Material = Enum.Material.Metal
		helm.CanCollide = false; helm.Anchored = false
		helm.Parent = model
		weld(head, helm, CFrame.new(0, 0.45 * scale, 0))

		for _, side in ipairs({ -1, 1 }) do
			local horn = Instance.new("Part")
			horn.Name = "Horn"
			horn.Size = Vector3.new(0.3 * scale, 1.0 * scale, 0.3 * scale)
			horn.Color = Color3.fromRGB(60, 15, 15)
			horn.Material = Enum.Material.Metal
			horn.CanCollide = false; horn.Anchored = false
			horn.Parent = model
			weld(head, horn, CFrame.new(side * 0.55 * scale, 1.0 * scale, 0) * CFrame.Angles(0, 0, math.rad(side * -15)))
		end

		-- Flaming red sword (glowing red + fire VFX)
		addBlade(model, COLORS.SeniorBlade, Vector3.new(0.22 * scale, 4.0 * scale, 0.48 * scale), true, scale)
		local rArm = model:FindFirstChild("Right Arm") :: BasePart
		if rArm then addAura(rArm, COLORS.FlameAura, Color3.fromRGB(80, 20, 5), 14, 0.7 * scale) end

		-- Shoulder pauldrons
		for _, side in ipairs({ -1, 1 }) do
			local pauldron = Instance.new("Part")
			pauldron.Name = "Pauldron"
			pauldron.Size = Vector3.new(1.1 * scale, 0.55 * scale, 1.1 * scale)
			pauldron.Color = Color3.fromRGB(50, 10, 10)
			pauldron.Material = Enum.Material.Metal
			pauldron.CanCollide = false; pauldron.Anchored = false
			pauldron.Parent = model
			weld(torso, pauldron, CFrame.new(side * 1.3 * scale, 0.85 * scale, 0))
		end

	-- -------------------------------------------------------
	elseif enemyType == "DemonicElder" then
		model = buildR6Skeleton("DemonicElder", scale, COLORS.ElderSkin, COLORS.ElderRobe, Color3.fromRGB(6, 4, 4))
		torso = model:FindFirstChild("Torso") :: BasePart
		head  = model:FindFirstChild("Head")  :: BasePart

		-- Tall ceremonial crown
		local crown = Instance.new("Part")
		crown.Name = "ElderCrown"
		crown.Size = Vector3.new(1.5 * scale, 1.0 * scale, 1.5 * scale)
		crown.Color = COLORS.ElderGold
		crown.Material = Enum.Material.Metal
		crown.CanCollide = false; crown.Anchored = false
		crown.Parent = model
		weld(head, crown, CFrame.new(0, 0.8 * scale, 0))

		-- Ornate red gems on crown
		for _, pos in ipairs({ Vector3.new(0, 0.5 * scale, -0.8 * scale), Vector3.new(-0.5 * scale, 0.5 * scale, 0), Vector3.new(0.5 * scale, 0.5 * scale, 0) }) do
			local gem = Instance.new("Part")
			gem.Name = "CrownGem"
			gem.Size = Vector3.new(0.3 * scale, 0.35 * scale, 0.3 * scale)
			gem.Color = Color3.fromRGB(255, 30, 30)
			gem.Material = Enum.Material.Neon
			gem.CanCollide = false; gem.Anchored = false
			gem.Parent = model
			weld(crown, gem, CFrame.new(pos))
		end

		-- Flowing long robes (sash behind torso)
		local sash = Instance.new("Part")
		sash.Name = "ElderSash"
		sash.Size = Vector3.new(2.0 * scale, 3.5 * scale, 0.2 * scale)
		sash.Color = Color3.fromRGB(55, 8, 8)
		sash.Material = Enum.Material.Fabric
		sash.CanCollide = false; sash.Anchored = false
		sash.Parent = model
		weld(torso, sash, CFrame.new(0, -1.4 * scale, 0.55 * scale) * CFrame.Angles(math.rad(12), 0, 0))

		-- Dark red aura + point light
		addAura(torso, Color3.fromRGB(180, 10, 10), Color3.fromRGB(60, 5, 5), 20, 1.0 * scale)
		local light = Instance.new("PointLight", torso)
		light.Color = Color3.fromRGB(255, 20, 20)
		light.Brightness = 1.5
		light.Range = 20

	-- -------------------------------------------------------
	elseif enemyType == "FlameDemoness" then
		model = buildR6Skeleton("FlameDemoness", scale, COLORS.FlameSkin, COLORS.FlameRobe, Color3.fromRGB(50, 8, 5))
		torso = model:FindFirstChild("Torso") :: BasePart
		head  = model:FindFirstChild("Head")  :: BasePart

		-- Flame crown (horns)
		for _, data in ipairs({ { -0.6, 1.4 }, { 0.6, 1.4 }, { 0, 1.8 } }) do
			local horn = Instance.new("Part")
			horn.Name = "FlameHorn"
			horn.Size = Vector3.new(0.35 * scale, 0.9 * scale, 0.35 * scale)
			horn.Color = COLORS.FlameAura
			horn.Material = Enum.Material.Neon
			horn.CanCollide = false; horn.Anchored = false
			horn.Parent = model
			weld(head, horn, CFrame.new(data[1] * scale, data[2] * scale, 0))
		end

		-- Flaming fists
		for _, armName in ipairs({ "Left Arm", "Right Arm" }) do
			local arm = model:FindFirstChild(armName) :: BasePart
			if arm then
				addAura(arm, COLORS.FlameAura, Color3.fromRGB(80, 20, 5), 20, 1.0 * scale)
				local light = Instance.new("PointLight", arm)
				light.Color = COLORS.FlameAura
				light.Brightness = 2
				light.Range = 14
			end
		end
		addAura(torso, Color3.fromRGB(200, 60, 10), Color3.fromRGB(60, 15, 5), 12, 0.8 * scale)

	-- -------------------------------------------------------
	elseif enemyType == "PoisonDemoness" then
		model = buildR6Skeleton("PoisonDemoness", scale, COLORS.PoisonSkin, COLORS.PoisonRobe, Color3.fromRGB(20, 35, 8))
		torso = model:FindFirstChild("Torso") :: BasePart
		head  = model:FindFirstChild("Head")  :: BasePart

		-- Venom-dripping claws on both hands
		for _, armName in ipairs({ "Left Arm", "Right Arm" }) do
			local arm = model:FindFirstChild(armName) :: BasePart
			if arm then
				for i = 1, 3 do
					local claw = Instance.new("Part")
					claw.Name = "Claw" .. i
					claw.Size = Vector3.new(0.2 * scale, 0.6 * scale, 0.2 * scale)
					claw.Color = COLORS.PoisonAura
					claw.Material = Enum.Material.Neon
					claw.CanCollide = false; claw.Anchored = false
					claw.Parent = model
					weld(arm, claw, CFrame.new((i - 2) * 0.3 * scale, -1.1 * scale, -0.45 * scale) * CFrame.Angles(math.rad(-30), 0, 0))
				end
				addAura(arm, COLORS.PoisonAura, Color3.fromRGB(20, 80, 20), 10, 0.5 * scale)
			end
		end

		-- Poison mist
		addAura(torso, COLORS.PoisonAura, Color3.fromRGB(15, 50, 15), 16, 1.0 * scale)
		local light = Instance.new("PointLight", torso)
		light.Color = COLORS.PoisonAura
		light.Brightness = 1.5
		light.Range = 18

	-- -------------------------------------------------------
	elseif enemyType == "FistDemon" then
		model = buildR6Skeleton("FistDemon", scale, COLORS.FistSkin, COLORS.FistArmor, Color3.fromRGB(40, 8, 8))
		torso = model:FindFirstChild("Torso") :: BasePart
		head  = model:FindFirstChild("Head")  :: BasePart

		-- Spiked shoulder armor
		for _, side in ipairs({ -1, 1 }) do
			local pauldron = Instance.new("Part")
			pauldron.Name = "SpikePauldron"
			pauldron.Size = Vector3.new(1.3 * scale, 0.7 * scale, 1.3 * scale)
			pauldron.Color = Color3.fromRGB(35, 8, 8)
			pauldron.Material = Enum.Material.Metal
			pauldron.CanCollide = false; pauldron.Anchored = false
			pauldron.Parent = model
			weld(torso, pauldron, CFrame.new(side * 1.4 * scale, 0.8 * scale, 0))

			-- Spikes on pauldrons
			for i = 1, 3 do
				local spike = Instance.new("Part")
				spike.Name = "PauldronSpike"
				spike.Size = Vector3.new(0.25 * scale, 0.7 * scale, 0.25 * scale)
				spike.Color = Color3.fromRGB(60, 15, 15)
				spike.Material = Enum.Material.Metal
				spike.CanCollide = false; spike.Anchored = false
				spike.Parent = model
				weld(pauldron, spike, CFrame.new((i - 2) * 0.4 * scale, 0.6 * scale, 0))
			end
		end

		-- Flame-engulfed fists
		for _, armName in ipairs({ "Left Arm", "Right Arm" }) do
			local arm = model:FindFirstChild(armName) :: BasePart
			if arm then
				addAura(arm, COLORS.FistFire, Color3.fromRGB(60, 20, 5), 22, 1.1 * scale)
				local fistLight = Instance.new("PointLight", arm)
				fistLight.Color = COLORS.FistFire
				fistLight.Brightness = 2.5
				fistLight.Range = 12
			end
		end

	-- -------------------------------------------------------
	elseif enemyType == "SwordDemon" then
		model = buildR6Skeleton("SwordDemon", scale, COLORS.SwordSkin, COLORS.SwordRobe, Color3.fromRGB(8, 8, 25))
		torso = model:FindFirstChild("Torso") :: BasePart
		head  = model:FindFirstChild("Head")  :: BasePart

		-- Dark ninja mask
		local mask = Instance.new("Part")
		mask.Name = "ShadowMask"
		mask.Size = Vector3.new(1.3 * scale, 0.65 * scale, 0.18 * scale)
		mask.Color = Color3.fromRGB(8, 8, 20)
		mask.Material = Enum.Material.Fabric
		mask.CanCollide = false; mask.Anchored = false
		mask.Parent = model
		weld(head, mask, CFrame.new(0, -0.2 * scale, -0.65 * scale))

		-- Blue spectral sword
		addBlade(model, COLORS.SwordBlade, Vector3.new(0.22 * scale, 4.5 * scale, 0.45 * scale), true, scale)

		-- Orbiting spectral blades (2 small ones)
		for i, angle in ipairs({ 0, math.pi }) do
			local orbBlade = Instance.new("Part")
			orbBlade.Name = "SpectralBlade" .. i
			orbBlade.Size = Vector3.new(0.15 * scale, 2.5 * scale, 0.3 * scale)
			orbBlade.Color = COLORS.SwordBlade
			orbBlade.Material = Enum.Material.Neon
			orbBlade.CanCollide = false; orbBlade.Anchored = false
			orbBlade.Parent = model
			weld(torso, orbBlade, CFrame.new(math.cos(angle) * 2.5 * scale, 0, math.sin(angle) * 2.5 * scale) * CFrame.Angles(0, angle, math.rad(30)))
		end

		addAura(torso, COLORS.SwordBlade, Color3.fromRGB(20, 20, 80), 10, 0.8 * scale)

	-- -------------------------------------------------------
	elseif enemyType == "SupremeDemon" then
		model = buildR6Skeleton("SupremeDemon", scale, COLORS.SupremeSkin, COLORS.SupremeArmor, Color3.fromRGB(5, 5, 5))
		torso = model:FindFirstChild("Torso") :: BasePart
		head  = model:FindFirstChild("Head")  :: BasePart

		-- Full plate armor overlay
		local chest = Instance.new("Part")
		chest.Name = "SupremeChest"
		chest.Size = Vector3.new(2.3 * scale, 2.2 * scale, 1.2 * scale)
		chest.Color = COLORS.SupremeArmor
		chest.Material = Enum.Material.Metal
		chest.CanCollide = false; chest.Anchored = false
		chest.Parent = model
		weld(torso, chest, CFrame.new())

		-- Gold trim lines on chest
		local trim = Instance.new("Part")
		trim.Name = "GoldTrim"
		trim.Size = Vector3.new(2.25 * scale, 0.2 * scale, 1.25 * scale)
		trim.Color = COLORS.SupremeGold
		trim.Material = Enum.Material.Neon
		trim.CanCollide = false; trim.Anchored = false
		trim.Parent = model
		weld(chest, trim, CFrame.new(0, 0.8 * scale, 0))

		-- Crown of shadow energy
		local crown = Instance.new("Part")
		crown.Name = "SupremeCrown"
		crown.Size = Vector3.new(1.6 * scale, 0.5 * scale, 1.6 * scale)
		crown.Color = COLORS.SupremeGold
		crown.Material = Enum.Material.Metal
		crown.CanCollide = false; crown.Anchored = false
		crown.Parent = model
		weld(head, crown, CFrame.new(0, 0.7 * scale, 0))

		-- Huge horns
		for _, side in ipairs({ -1, 1 }) do
			local horn = Instance.new("Part")
			horn.Name = "SupremeHorn"
			horn.Size = Vector3.new(0.45 * scale, 2.0 * scale, 0.45 * scale)
			horn.Color = Color3.fromRGB(15, 5, 5)
			horn.Material = Enum.Material.Metal
			horn.CanCollide = false; horn.Anchored = false
			horn.Parent = model
			weld(head, horn, CFrame.new(side * 0.8 * scale, 1.5 * scale, 0) * CFrame.Angles(0, 0, math.rad(side * -20)))
		end

		-- Immense dark purple aura
		addAura(torso, COLORS.SupremeAura, Color3.fromRGB(40, 5, 80), 35, 1.4 * scale)
		local light = Instance.new("PointLight", torso)
		light.Color = COLORS.SupremeAura
		light.Brightness = 3
		light.Range = 30

		-- Long flowing war cape
		local cape = Instance.new("Part")
		cape.Name = "SupremeCape"
		cape.Size = Vector3.new(2.4 * scale, 4.5 * scale, 0.2 * scale)
		cape.Color = Color3.fromRGB(10, 5, 5)
		cape.Material = Enum.Material.Fabric
		cape.CanCollide = false; cape.Anchored = false
		cape.Parent = model
		weld(torso, cape, CFrame.new(0, -1.5 * scale, 0.65 * scale) * CFrame.Angles(math.rad(10), 0, 0))

	-- -------------------------------------------------------
	elseif enemyType == "BloodDemon" then
		model = buildR6Skeleton("BloodDemon", scale, COLORS.BloodSkin, COLORS.BloodRobe, Color3.fromRGB(30, 5, 5))
		torso = model:FindFirstChild("Torso") :: BasePart
		head  = model:FindFirstChild("Head")  :: BasePart

		-- Blood drip VFX from both hands
		for _, armName in ipairs({ "Left Arm", "Right Arm" }) do
			local arm = model:FindFirstChild(armName) :: BasePart
			if arm then
				addAura(arm, COLORS.BloodAura, Color3.fromRGB(60, 5, 5), 18, 0.5 * scale)
				local bLight = Instance.new("PointLight", arm)
				bLight.Color = COLORS.BloodAura
				bLight.Brightness = 2
				bLight.Range = 10
			end
		end

		-- Blood-infused curved blade
		addBlade(model, COLORS.BloodAura, Vector3.new(0.25 * scale, 4.2 * scale, 0.5 * scale), true, scale)

		-- Tattered crimson cape
		local cape = Instance.new("Part")
		cape.Name = "BloodCape"
		cape.Size = Vector3.new(2.2 * scale, 3.8 * scale, 0.2 * scale)
		cape.Color = Color3.fromRGB(70, 8, 8)
		cape.Material = Enum.Material.Fabric
		cape.CanCollide = false; cape.Anchored = false
		cape.Parent = model
		weld(torso, cape, CFrame.new(0, -1.2 * scale, 0.6 * scale) * CFrame.Angles(math.rad(8), 0, 0))

		-- Strong crimson aura
		addAura(torso, COLORS.BloodAura, Color3.fromRGB(50, 5, 5), 25, 1.1 * scale)
		local light = Instance.new("PointLight", torso)
		light.Color = COLORS.BloodAura
		light.Brightness = 2.5
		light.Range = 22
	end

	-- Humanoid stat setup
	local DemonCultConfig = nil
	pcall(function()
		local rs = game:GetService("ReplicatedStorage")
		local shared = rs:FindFirstChild("Shared")
		if shared then
			DemonCultConfig = require(shared:FindFirstChild("DemonCultConfig"))
		end
	end)

	local stats = DemonCultConfig and DemonCultConfig[enemyType]
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum and stats then
		hum.MaxHealth  = stats.MaxHealth
		hum.Health     = stats.MaxHealth
		hum.WalkSpeed  = stats.WalkSpeed
		hum.DisplayName = stats.Title or enemyType
	end

	local headPart = model:FindFirstChild("Head") :: BasePart
	if headPart and hum and stats then
		attachHealthBar(model, headPart, stats.Title or enemyType, hum.MaxHealth, isBoss, scale)
	end

	return model
end

return DemonCultFactory
