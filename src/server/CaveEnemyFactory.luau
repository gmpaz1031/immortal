--!strict
--[[
    CaveEnemyFactory.luau
    Constructs procedural rigs and visual models for:
    - Cave Spider & Cave Spider Mother
    - Shadow Assassin & Senior Assassin
    - Four Pillar Assassin & Supreme Assassin (Standby)
    - Fallen Swordsman & Swordmaster (Village Boss, Standby)
]]

local Workspace = game:GetService("Workspace")

local CaveEnemyFactory = {}

local COLORS = {
	SpiderBody = Color3.fromRGB(24, 24, 28),
	SpiderAbdomen = Color3.fromRGB(36, 20, 38),
	SpiderEyes = Color3.fromRGB(255, 30, 40),
	SpiderFangs = Color3.fromRGB(70, 75, 80),
	MotherBody = Color3.fromRGB(18, 16, 22),
	MotherAbdomen = Color3.fromRGB(45, 18, 55),
	MotherPoison = Color3.fromRGB(60, 240, 90),

	AssassinRobes = Color3.fromRGB(20, 20, 24),
	AssassinTrim = Color3.fromRGB(140, 25, 35),
	SeniorRobes = Color3.fromRGB(15, 15, 18),
	SeniorTrim = Color3.fromRGB(210, 165, 45),
	SeniorAura = Color3.fromRGB(80, 20, 120),
	FourPillarSash = Color3.fromRGB(60, 140, 190),
	SupremeRobes = Color3.fromRGB(12, 12, 16),
	SupremeGold = Color3.fromRGB(235, 185, 55),

	SwordsmanRobes = Color3.fromRGB(75, 60, 50),
	SwordsmanArmor = Color3.fromRGB(45, 50, 55),
	SwordmasterRobes = Color3.fromRGB(30, 40, 60),
	SwordmasterGold = Color3.fromRGB(225, 180, 50),
	SwordmasterSteel = Color3.fromRGB(210, 215, 230),
}

--------------------------------------------------------------------------------
-- Helper: Health Bar Billboard UI
--------------------------------------------------------------------------------
local function attachHealthBar(model: Model, adorneePart: BasePart, title: string, maxHp: number, isBoss: boolean, scale: number)
	local bbg = Instance.new("BillboardGui")
	bbg.Name = "EnemyHealthGui"
	bbg.AlwaysOnTop = false
	bbg.MaxDistance = isBoss and 58 or 44
	bbg.Size = isBoss and UDim2.new(5.6 * scale, 0, 1.15 * scale, 0) or UDim2.new(4.2 * scale, 0, 0.88 * scale, 0)
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
	nameLbl.TextColor3 = isBoss and Color3.fromRGB(255, 215, 90) or Color3.fromRGB(255, 230, 160)
	nameLbl.TextScaled = true
	nameLbl.Parent = bbg

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(15, 10, 10)
	stroke.Thickness = 1.2
	stroke.Parent = nameLbl

	local hpFrame = Instance.new("Frame")
	hpFrame.Name = "HpBar"
	hpFrame.BackgroundColor3 = Color3.fromRGB(25, 18, 22)
	hpFrame.BorderSizePixel = 0
	hpFrame.Position = UDim2.new(0, 0, 0.54, 0)
	hpFrame.Size = UDim2.new(1, 0, 0.38, 0)
	hpFrame.Parent = bbg

	local hpCorner = Instance.new("UICorner")
	hpCorner.CornerRadius = UDim.new(0.3, 0)
	hpCorner.Parent = hpFrame

	local hpFill = Instance.new("Frame")
	hpFill.Name = "Fill"
	hpFill.BackgroundColor3 = isBoss and Color3.fromRGB(235, 45, 55) or Color3.fromRGB(220, 70, 50)
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
	hpText.Position = UDim2.new(0, 0, 0, 0)
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
-- 1. Cave Spider & Spider Mother Procedural Rig
--------------------------------------------------------------------------------
function CaveEnemyFactory.createSpider(isMother: boolean): Model
	local scale = isMother and 2.2 or 1.0
	local name = isMother and "CaveSpiderMother" or "CaveSpider"

	local model = Instance.new("Model")
	model.Name = name

	-- 1. HumanoidRootPart
	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2.5 * scale, 1.2 * scale, 3 * scale)
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.Anchored = false
	hrp.Parent = model
	model.PrimaryPart = hrp

	-- 2. Cephalothorax (Head & Thorax)
	local thorax = Instance.new("Part")
	thorax.Name = "Thorax"
	thorax.Size = Vector3.new(2.2 * scale, 1.4 * scale, 2.2 * scale)
	thorax.Color = isMother and COLORS.MotherBody or COLORS.SpiderBody
	thorax.Material = Enum.Material.Slate
	thorax.CanCollide = false
	thorax.Anchored = false
	thorax.Parent = model

	local rootJoint = Instance.new("Motor6D")
	rootJoint.Name = "RootJoint"
	rootJoint.Part0 = hrp
	rootJoint.Part1 = thorax
	rootJoint.C0 = CFrame.new(0, 0, 0)
	rootJoint.C1 = CFrame.new(0, 0, 0)
	rootJoint.Parent = hrp

	-- 3. Abdomen (Bulbous rear body)
	local abdomen = Instance.new("Part")
	abdomen.Name = "Abdomen"
	abdomen.Size = Vector3.new(3.2 * scale, 2.5 * scale, 4.0 * scale)
	abdomen.Color = isMother and COLORS.MotherAbdomen or COLORS.SpiderAbdomen
	abdomen.Material = Enum.Material.Slate
	abdomen.CanCollide = false
	abdomen.Anchored = false
	abdomen.Parent = model

	local abdMesh = Instance.new("SpecialMesh")
	abdMesh.MeshType = Enum.MeshType.Sphere
	abdMesh.Parent = abdomen

	local abdJoint = Instance.new("Motor6D")
	abdJoint.Name = "AbdomenJoint"
	abdJoint.Part0 = thorax
	abdJoint.Part1 = abdomen
	abdJoint.C0 = CFrame.new(0, 0.4 * scale, 2.6 * scale)
	abdJoint.C1 = CFrame.new(0, 0, 0)
	abdJoint.Parent = thorax

	-- Poison veins for Spider Mother
	if isMother then
		local pGlow = Instance.new("PointLight")
		pGlow.Color = COLORS.MotherPoison
		pGlow.Brightness = 2.5
		pGlow.Range = 14 * scale
		pGlow.Parent = abdomen
	end

	-- 4. Multiple Glowing Eyes
	for _, eyePos in ipairs({
		Vector3.new(-0.4 * scale, 0.3 * scale, -1.15 * scale),
		Vector3.new(0.4 * scale, 0.3 * scale, -1.15 * scale),
		Vector3.new(-0.2 * scale, 0.5 * scale, -1.12 * scale),
		Vector3.new(0.2 * scale, 0.5 * scale, -1.12 * scale),
	}) do
		local eye = Instance.new("Part")
		eye.Name = "SpiderEye"
		eye.Size = Vector3.new(0.2 * scale, 0.2 * scale, 0.2 * scale)
		eye.Color = isMother and COLORS.MotherPoison or COLORS.SpiderEyes
		eye.Material = Enum.Material.Neon
		eye.CanCollide = false
		eye.Anchored = false

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = thorax
		weld.Part1 = eye
		weld.Parent = eye

		eye.CFrame = thorax.CFrame * CFrame.new(eyePos)
		eye.Parent = model
	end

	-- 5. Animated Mandibles / Fangs (Equipped with Motor6Ds for Bite Animation)
	local leftFang = Instance.new("Part")
	leftFang.Name = "LeftFang"
	leftFang.Size = Vector3.new(0.35 * scale, 0.7 * scale, 0.5 * scale)
	leftFang.Color = COLORS.SpiderFangs
	leftFang.Material = Enum.Material.Metal
	leftFang.CanCollide = false
	leftFang.Anchored = false
	leftFang.Parent = model

	local leftFangJoint = Instance.new("Motor6D")
	leftFangJoint.Name = "LeftFangJoint"
	leftFangJoint.Part0 = thorax
	leftFangJoint.Part1 = leftFang
	leftFangJoint.C0 = CFrame.new(-0.5 * scale, -0.4 * scale, -1.2 * scale) * CFrame.Angles(math.rad(20), math.rad(-15), 0)
	leftFangJoint.C1 = CFrame.new(0, 0.3 * scale, 0)
	leftFangJoint.Parent = thorax

	local rightFang = Instance.new("Part")
	rightFang.Name = "RightFang"
	rightFang.Size = Vector3.new(0.35 * scale, 0.7 * scale, 0.5 * scale)
	rightFang.Color = COLORS.SpiderFangs
	rightFang.Material = Enum.Material.Metal
	rightFang.CanCollide = false
	rightFang.Anchored = false
	rightFang.Parent = model

	local rightFangJoint = Instance.new("Motor6D")
	rightFangJoint.Name = "RightFangJoint"
	rightFangJoint.Part0 = thorax
	rightFangJoint.Part1 = rightFang
	rightFangJoint.C0 = CFrame.new(0.5 * scale, -0.4 * scale, -1.2 * scale) * CFrame.Angles(math.rad(20), math.rad(15), 0)
	rightFangJoint.C1 = CFrame.new(0, 0.3 * scale, 0)
	rightFangJoint.Parent = thorax

	-- 6. 8 Articulated Legs (4 per side)
	for i = 1, 4 do
		local zOffset = (i - 2.5) * 0.55 * scale
		for _, side in ipairs({ -1, 1 }) do
			local sideStr = side == -1 and "Left" or "Right"
			local legName = string.format("%sLeg%d", sideStr, i)

			-- Upper Leg (Femur)
			local femur = Instance.new("Part")
			femur.Name = legName .. "_Femur"
			femur.Size = Vector3.new(0.35 * scale, 2.2 * scale, 0.35 * scale)
			femur.Color = isMother and COLORS.MotherBody or COLORS.SpiderBody
			femur.Material = Enum.Material.Slate
			femur.CanCollide = false
			femur.Anchored = false
			femur.Parent = model

			local hip = Instance.new("Motor6D")
			hip.Name = legName .. "_Hip"
			hip.Part0 = thorax
			hip.Part1 = femur
			local yaw = math.rad(side * (40 + (i * 15)))
			hip.C0 = CFrame.new(side * 1.1 * scale, 0, zOffset) * CFrame.Angles(0, yaw, math.rad(side * 35))
			hip.C1 = CFrame.new(0, 1.0 * scale, 0)
			hip.Parent = thorax

			-- Lower Leg (Tibia)
			local tibia = Instance.new("Part")
			tibia.Name = legName .. "_Tibia"
			tibia.Size = Vector3.new(0.28 * scale, 2.6 * scale, 0.28 * scale)
			tibia.Color = isMother and COLORS.MotherAbdomen or COLORS.SpiderBody
			tibia.Material = Enum.Material.Slate
			tibia.CanCollide = false
			tibia.Anchored = false
			tibia.Parent = model

			local knee = Instance.new("Motor6D")
			knee.Name = legName .. "_Knee"
			knee.Part0 = femur
			knee.Part1 = tibia
			knee.C0 = CFrame.new(0, -1.0 * scale, 0) * CFrame.Angles(0, 0, math.rad(side * -75))
			knee.C1 = CFrame.new(0, 1.2 * scale, 0)
			knee.Parent = femur
		end
	end

	-- 7. Humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.DisplayName = isMother and "Cave Spider Mother" or "Cave Spider"
	humanoid.MaxHealth = isMother and 650 or 85
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = isMother and 13 or 15
	humanoid.HipHeight = 1.8 * scale
	humanoid.Parent = model

	attachHealthBar(model, thorax, humanoid.DisplayName, humanoid.MaxHealth, isMother, scale)

	return model
end

--------------------------------------------------------------------------------
-- 2. Humanoid Rig Builder (Assassins & Swordsmen)
--------------------------------------------------------------------------------
function CaveEnemyFactory.createHumanoidEnemy(enemyType: string): Model
	local isBoss = (enemyType == "SpiderMother" or enemyType == "FourPillarAssassin" or enemyType == "SupremeAssassin" or enemyType == "Swordmaster")
	local scale = 1.0

	if enemyType == "SeniorAssassin" then
		scale = 1.15
	elseif enemyType == "FourPillarAssassin" then
		scale = 1.25
	elseif enemyType == "SupremeAssassin" then
		scale = 1.4
	elseif enemyType == "Swordmaster" then
		scale = 1.35
	end

	local model = Instance.new("Model")
	model.Name = enemyType

	-- 1. HumanoidRootPart
	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2 * scale, 2 * scale, 1 * scale)
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.Anchored = false
	hrp.Parent = model
	model.PrimaryPart = hrp

	-- Colors based on enemy type
	local torsoColor = COLORS.AssassinRobes
	local trimColor = COLORS.AssassinTrim

	if enemyType == "SeniorAssassin" then
		torsoColor = COLORS.SeniorRobes
		trimColor = COLORS.SeniorTrim
	elseif enemyType == "FourPillarAssassin" then
		torsoColor = COLORS.SupremeRobes
		trimColor = COLORS.FourPillarSash
	elseif enemyType == "SupremeAssassin" then
		torsoColor = COLORS.SupremeRobes
		trimColor = COLORS.SupremeGold
	elseif enemyType == "Swordsman" then
		torsoColor = COLORS.SwordsmanRobes
		trimColor = COLORS.SwordsmanArmor
	elseif enemyType == "Swordmaster" then
		torsoColor = COLORS.SwordmasterRobes
		trimColor = COLORS.SwordmasterGold
	end

	-- 2. Torso
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2 * scale, 2 * scale, 1 * scale)
	torso.Color = torsoColor
	torso.Material = Enum.Material.Fabric
	torso.CanCollide = false
	torso.Anchored = false
	torso.Parent = model

	-- 3. Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.25 * scale, 1.25 * scale, 1.25 * scale)
	head.Color = Color3.fromRGB(215, 180, 145)
	head.CanCollide = false
	head.Anchored = false
	head.Parent = model

	-- 4. Left & Right Arms
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

	-- 5. Left & Right Legs
	local leftLeg = Instance.new("Part")
	leftLeg.Name = "Left Leg"
	leftLeg.Size = Vector3.new(1 * scale, 2 * scale, 1 * scale)
	leftLeg.Color = Color3.fromRGB(25, 25, 28)
	leftLeg.Material = Enum.Material.Fabric
	leftLeg.CanCollide = false
	leftLeg.Anchored = false
	leftLeg.Parent = model

	local rightLeg = Instance.new("Part")
	rightLeg.Name = "Right Leg"
	rightLeg.Size = Vector3.new(1 * scale, 2 * scale, 1 * scale)
	rightLeg.Color = Color3.fromRGB(25, 25, 28)
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

	-- 7. Visual Accoutrements by Type
	if enemyType:find("Assassin") then
		-- Shinobi Cloth Mask
		local mask = Instance.new("Part")
		mask.Name = "ShinobiMask"
		mask.Size = Vector3.new(1.3 * scale, 0.6 * scale, 1.3 * scale)
		mask.Color = torsoColor
		mask.Material = Enum.Material.Fabric
		mask.CanCollide = false
		mask.Anchored = false

		local mWeld = Instance.new("WeldConstraint")
		mWeld.Part0 = head
		mWeld.Part1 = mask
		mWeld.Parent = mask
		mask.CFrame = head.CFrame * CFrame.new(0, -0.2 * scale, 0.05 * scale)
		mask.Parent = model

		-- Dual Daggers (Right & Left Hands)
		for _, armName in ipairs({ "Right Arm", "Left Arm" }) do
			local arm = model:FindFirstChild(armName) :: BasePart
			if arm then
				local dagger = Instance.new("Part")
				dagger.Name = armName == "Right Arm" and "MainDagger" or "OffDagger"
				dagger.Size = Vector3.new(0.25 * scale, 1.8 * scale, 0.4 * scale)
				dagger.Color = trimColor
				dagger.Material = Enum.Material.Metal
				dagger.CanCollide = false
				dagger.Anchored = false

				local dWeld = Instance.new("WeldConstraint")
				dWeld.Part0 = arm
				dWeld.Part1 = dagger
				dWeld.Parent = dagger

				-- Reverse grip pointing downwards
				dagger.CFrame = arm.CFrame * CFrame.new(0, -1.0 * scale, -0.3 * scale) * CFrame.Angles(math.rad(180), 0, 0)
				dagger.Parent = model
			end
		end

		if enemyType == "SeniorAssassin" or enemyType == "SupremeAssassin" then
			-- Shadow mist emitter on torso
			local mist = Instance.new("ParticleEmitter")
			mist.Name = "ShadowMist"
			mist.Color = ColorSequence.new(Color3.fromRGB(30, 10, 40), Color3.fromRGB(10, 5, 15))
			mist.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8 * scale), NumberSequenceKeypoint.new(1, 1.8 * scale) })
			mist.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
			mist.Lifetime = NumberRange.new(0.6, 1.0)
			mist.Rate = 12
			mist.Speed = NumberRange.new(1, 3)
			mist.Parent = torso
		end

		if enemyType == "SupremeAssassin" then
			-- Flowing Shadow Cape on back
			local cape = Instance.new("Part")
			cape.Name = "ShadowCape"
			cape.Size = Vector3.new(2.2 * scale, 3.5 * scale, 0.2 * scale)
			cape.Color = Color3.fromRGB(15, 12, 18)
			cape.Material = Enum.Material.Fabric
			cape.CanCollide = false
			cape.Anchored = false

			local cWeld = Instance.new("WeldConstraint")
			cWeld.Part0 = torso
			cWeld.Part1 = cape
			cWeld.Parent = cape
			cape.CFrame = torso.CFrame * CFrame.new(0, -0.6 * scale, 0.6 * scale) * CFrame.Angles(math.rad(10), 0, 0)
			cape.Parent = model
		end

	elseif enemyType == "Swordsman" or enemyType == "Swordmaster" then
		-- Straw Kasa Hat / Crested Helm
		local hat = Instance.new("Part")
		hat.Name = "CultivatorHat"
		hat.Size = Vector3.new(2.6 * scale, 0.4 * scale, 2.6 * scale)
		hat.Color = enemyType == "Swordmaster" and COLORS.SwordmasterGold or Color3.fromRGB(120, 95, 60)
		hat.Material = enemyType == "Swordmaster" and Enum.Material.Metal or Enum.Material.Wood
		hat.CanCollide = false
		hat.Anchored = false

		local hWeld = Instance.new("WeldConstraint")
		hWeld.Part0 = head
		hWeld.Part1 = hat
		hWeld.Parent = hat
		hat.CFrame = head.CFrame * CFrame.new(0, 0.7 * scale, 0)
		hat.Parent = model

		-- Sword in Right Hand
		local rArm = model:FindFirstChild("Right Arm") :: BasePart
		if rArm then
			local blade = Instance.new("Part")
			blade.Name = enemyType == "Swordmaster" and "MasterOdachi" or "SteelDao"
			blade.Size = enemyType == "Swordmaster" and Vector3.new(0.3 * scale, 5.0 * scale, 0.6 * scale) or Vector3.new(0.2 * scale, 3.4 * scale, 0.5 * scale)
			blade.Color = enemyType == "Swordmaster" and COLORS.SwordmasterGold or Color3.fromRGB(220, 225, 230)
			blade.Material = Enum.Material.Metal
			blade.CanCollide = false
			blade.Anchored = false

			local sWeld = Instance.new("WeldConstraint")
			sWeld.Part0 = rArm
			sWeld.Part1 = blade
			sWeld.Parent = blade

			blade.CFrame = rArm.CFrame * CFrame.new(0, -1.4 * scale, -0.8 * scale) * CFrame.Angles(math.rad(65), 0, 0)
			blade.Parent = model
		end
	end

	-- 8. Humanoid & Overhead Health Bar
	local hpMap = {
		Assassin = 100,
		SeniorAssassin = 220,
		FourPillarAssassin = 480,
		SupremeAssassin = 1100,
		Swordsman = 95,
		Swordmaster = 880,
	}
	local speedMap = {
		Assassin = 16,
		SeniorAssassin = 17,
		FourPillarAssassin = 14,
		SupremeAssassin = 14,
		Swordsman = 13,
		Swordmaster = 14,
	}

	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.DisplayName = enemyType
	humanoid.MaxHealth = hpMap[enemyType] or 100
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = speedMap[enemyType] or 14
	humanoid.HipHeight = 2.0 * scale
	humanoid.Parent = model

	attachHealthBar(model, head, enemyType, humanoid.MaxHealth, isBoss, scale)

	return model
end

return CaveEnemyFactory
