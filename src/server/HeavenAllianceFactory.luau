--!strict
--[[
    HeavenAllianceFactory.luau
    Phase F — Builds procedural R6 enemy rigs for all Heavenly Alliance enemy types.
    Pattern mirrors DemonCultFactory / CaveEnemyFactory exactly.

    Enemy types: HeavenSwordsman, SeniorHeavenSwordsman, HeavenlyElder,
                 HeavenFlamePillar, HeavenThunderPillar, HeavenPalmPillar,
                 HeavenSwordPillar, SupremeHeaven
]]

local HeavenAllianceFactory = {}

local COLORS = {
	-- Shared
	CreamSkin   = Color3.fromRGB(230, 200, 170),
	DarkWood    = Color3.fromRGB(55, 38, 25),
	RedPillar   = Color3.fromRGB(165, 38, 28),

	-- Heaven Swordsman
	SwordsmanRobe  = Color3.fromRGB(220, 215, 200),
	SwordsmanBlade = Color3.fromRGB(200, 220, 255),

	-- Senior Heaven Swordsman
	SeniorRobe   = Color3.fromRGB(200, 180, 150),
	SeniorBlade  = Color3.fromRGB(255, 215, 60),

	-- Heavenly Elder
	ElderRobe    = Color3.fromRGB(245, 240, 225),
	ElderStaff   = Color3.fromRGB(255, 215, 60),

	-- Heaven Flame Pillar
	FlameSkin    = Color3.fromRGB(255, 185, 80),
	FlameRobe    = Color3.fromRGB(200, 120, 20),
	FlameGold    = Color3.fromRGB(255, 215, 60),

	-- Heaven Thunder Pillar
	ThunderSkin  = Color3.fromRGB(170, 140, 220),
	ThunderRobe  = Color3.fromRGB(80, 60, 140),
	ThunderAura  = Color3.fromRGB(180, 120, 255),

	-- Heaven Palm Pillar
	PalmSkin     = Color3.fromRGB(200, 180, 160),
	PalmArmor    = Color3.fromRGB(160, 155, 145),
	PalmGold     = Color3.fromRGB(255, 215, 60),

	-- Heaven Sword Pillar
	SwordPillarRobe  = Color3.fromRGB(210, 215, 230),
	SwordPillarBlade = Color3.fromRGB(200, 220, 255),
	SwordAura        = Color3.fromRGB(140, 180, 255),

	-- Supreme Heaven
	SupremeRobe  = Color3.fromRGB(250, 248, 240),
	SupremeGold  = Color3.fromRGB(255, 215, 60),
	SupremeAura  = Color3.fromRGB(255, 240, 100),
}

-- ============================================================
-- Health Bar (same as DemonCultFactory)
-- ============================================================
local function attachHealthBar(model, adorneePart, title, maxHp, isBoss, scale)
	local bbg = Instance.new("BillboardGui")
	bbg.Name = "EnemyHealthGui"; bbg.AlwaysOnTop = false
	bbg.LightInfluence = 0
	bbg.MaxDistance = 100
	bbg.Size = isBoss and UDim2.new(5.6*scale,0,1.15*scale,0) or UDim2.new(4.2*scale,0,0.88*scale,0)
	bbg.StudsOffset = Vector3.new(0, (2.7+(isBoss and 1.1 or 0))*scale, 0)
	bbg.Adornee = adorneePart; bbg.Parent = model

	local nameLbl = Instance.new("TextLabel"); nameLbl.Name = "NameLabel"
	nameLbl.BackgroundTransparency = 1; nameLbl.Size = UDim2.new(1,0,0.48,0)
	nameLbl.Font = Enum.Font.GothamBold; nameLbl.Text = title
	nameLbl.TextColor3 = isBoss and Color3.fromRGB(255,215,60) or Color3.fromRGB(240,235,210)
	nameLbl.TextScaled = true; nameLbl.Parent = bbg

	local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(30,20,10); stroke.Thickness = 1.2; stroke.Parent = nameLbl

	local hpFrame = Instance.new("Frame"); hpFrame.Name = "HpBar"
	hpFrame.BackgroundColor3 = Color3.fromRGB(20,18,10); hpFrame.BorderSizePixel = 0
	hpFrame.Position = UDim2.new(0,0,0.54,0); hpFrame.Size = UDim2.new(1,0,0.38,0); hpFrame.Parent = bbg
	Instance.new("UICorner", hpFrame).CornerRadius = UDim.new(0.3,0)

	local hpFill = Instance.new("Frame"); hpFill.Name = "Fill"
	hpFill.BackgroundColor3 = isBoss and Color3.fromRGB(60,180,80) or Color3.fromRGB(50,200,80)
	hpFill.BorderSizePixel = 0; hpFill.Size = UDim2.new(1,0,1,0); hpFill.Parent = hpFrame
	Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0.3,0)

	local hpText = Instance.new("TextLabel"); hpText.Name = "Value"
	hpText.BackgroundTransparency = 1; hpText.Size = UDim2.new(1,0,1,0)
	hpText.Font = Enum.Font.GothamBold
	hpText.Text = string.format("%d / %d", maxHp, maxHp)
	hpText.TextColor3 = Color3.fromRGB(255,255,255); hpText.TextScaled = true; hpText.Parent = hpFrame

	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.HealthChanged:Connect(function(health)
			local frac = math.clamp(health / math.max(1, hum.MaxHealth), 0, 1)
			hpFill.Size = UDim2.new(frac, 0, 1, 0)
			hpText.Text = string.format("%d / %d", math.max(0, math.floor(health)), hum.MaxHealth)
		end)
	end
end

-- ============================================================
-- Build R6 Skeleton
-- ============================================================
local function buildSkeleton(name, scale, skinColor, torsoColor, legColor)
	local model = Instance.new("Model"); model.Name = name
	local function limb(n, sz, col)
		local part = Instance.new("Part"); part.Name = n; part.Size = sz
		part.Color = col; part.Material = Enum.Material.Fabric
		part.CanCollide = false; part.Anchored = false; part.Parent = model; return part
	end
	local hrp = Instance.new("Part"); hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2*scale,2*scale,1*scale); hrp.Transparency = 1
	hrp.CanCollide = false; hrp.Anchored = false; hrp.Parent = model
	model.PrimaryPart = hrp

	local torso = limb("Torso", Vector3.new(2*scale,2*scale,1*scale), torsoColor)
	local head  = limb("Head",  Vector3.new(1.25*scale,1.25*scale,1.25*scale), skinColor)
	head.Material = Enum.Material.SmoothPlastic
	local lArm  = limb("Left Arm",  Vector3.new(scale,2*scale,scale), torsoColor)
	local rArm  = limb("Right Arm", Vector3.new(scale,2*scale,scale), torsoColor)
	local lLeg  = limb("Left Leg",  Vector3.new(scale,2*scale,scale), legColor)
	local rLeg  = limb("Right Leg", Vector3.new(scale,2*scale,scale), legColor)

	local function motor(name2, p0, p1, c0, c1)
		local m = Instance.new("Motor6D"); m.Name = name2; m.Part0 = p0; m.Part1 = p1
		m.C0 = c0; m.C1 = c1; m.Parent = p0
	end
	motor("RootJoint",     hrp,   torso, CFrame.new(), CFrame.new())
	motor("Neck",          torso, head,  CFrame.new(0,scale,0), CFrame.new(0,-0.5*scale,0))
	motor("Right Shoulder",torso, rArm,  CFrame.new(1.5*scale,0.5*scale,0), CFrame.new(0,0.5*scale,0))
	motor("Left Shoulder", torso, lArm,  CFrame.new(-1.5*scale,0.5*scale,0), CFrame.new(0,0.5*scale,0))
	motor("Right Hip",     torso, rLeg,  CFrame.new(0.5*scale,-scale,0), CFrame.new(0,scale,0))
	motor("Left Hip",      torso, lLeg,  CFrame.new(-0.5*scale,-scale,0), CFrame.new(0,scale,0))

	local hum = Instance.new("Humanoid"); hum.AutoJumpEnabled = false; hum.Parent = model
	return model
end

local function weld(parent, child, offset)
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

local function addBlade(model, color, size, scale)
	local rArm = model:FindFirstChild("Right Arm"); if not rArm then return end
	local blade = Instance.new("Part"); blade.Name = "HeavenBlade"; blade.Size = size
	blade.Color = color; blade.Material = Enum.Material.Neon; blade.CanCollide = false; blade.Anchored = false; blade.Parent = model
	weld(rArm, blade, CFrame.new(0,-1.3*scale,-0.7*scale)*CFrame.Angles(math.rad(60),0,0))
	local a0 = Instance.new("Attachment",blade); a0.Position = Vector3.new(0,-size.Y/2,0)
	local a1 = Instance.new("Attachment",blade); a1.Position = Vector3.new(0,size.Y/2,0)
	local trail = Instance.new("Trail",blade); trail.Attachment0=a0; trail.Attachment1=a1
	trail.Color = ColorSequence.new(color, Color3.fromRGB(255,255,200)); trail.Lifetime=0.2; trail.Enabled=false; trail.Name="WeaponTrail"
end

local function addAura(part, c1, c2, rate, size)
	local em = Instance.new("ParticleEmitter")
	em.Color = ColorSequence.new(c1,c2)
	em.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0,size), NumberSequenceKeypoint.new(0.5,size*0.6), NumberSequenceKeypoint.new(1,0) })
	em.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0,0.35), NumberSequenceKeypoint.new(1,1) })
	em.Lifetime = NumberRange.new(0.5,0.9); em.Rate = rate
	em.Speed = NumberRange.new(1,2.5); em.SpreadAngle = Vector2.new(180,180); em.Parent = part
end

-- ============================================================
-- PUBLIC: createEnemy
-- ============================================================
function HeavenAllianceFactory.createEnemy(enemyType)
	local scaleMap = {
		SeniorHeavenSwordsman=1.1, HeavenlyElder=1.2,
		HeavenFlamePillar=1.2, HeavenThunderPillar=1.2,
		HeavenPalmPillar=1.3, HeavenSwordPillar=1.2, SupremeHeaven=1.5,
	}
	local scale = scaleMap[enemyType] or 1.0
	local isBoss = (enemyType ~= "HeavenSwordsman" and enemyType ~= "SeniorHeavenSwordsman")
	local model

	if enemyType == "HeavenSwordsman" then
		model = buildSkeleton("HeavenSwordsman", scale, COLORS.CreamSkin, COLORS.SwordsmanRobe, Color3.fromRGB(180,175,160))
		addBlade(model, COLORS.SwordsmanBlade, Vector3.new(0.18*scale,3.5*scale,0.4*scale), scale)
		local torso = model:FindFirstChild("Torso"); if torso then addAura(torso, Color3.fromRGB(200,220,255), Color3.fromRGB(150,180,255), 5, 0.4*scale) end

	elseif enemyType == "SeniorHeavenSwordsman" then
		model = buildSkeleton("SeniorHeavenSwordsman", scale, COLORS.CreamSkin, COLORS.SeniorRobe, Color3.fromRGB(160,145,120))
		addBlade(model, COLORS.SeniorBlade, Vector3.new(0.2*scale,4.0*scale,0.45*scale), scale)
		-- Gold pauldrons
		local torso = model:FindFirstChild("Torso")
		if torso then
			for _, side in ipairs({-1,1}) do
				local pd = Instance.new("Part"); pd.Name="Pauldron"; pd.Size=Vector3.new(1.1*scale,0.55*scale,1.1*scale)
				pd.Color=Color3.fromRGB(200,155,30); pd.Material=Enum.Material.Metal; pd.CanCollide=false; pd.Anchored=false; pd.Parent=model
				weld(torso,pd,CFrame.new(side*1.3*scale,0.85*scale,0))
			end
			addAura(torso, COLORS.SeniorBlade, Color3.fromRGB(200,150,20), 10, 0.6*scale)
		end

	elseif enemyType == "HeavenlyElder" then
		model = buildSkeleton("HeavenlyElder", scale, COLORS.CreamSkin, COLORS.ElderRobe, Color3.fromRGB(200,195,180))
		-- White beard overlay
		local head = model:FindFirstChild("Head")
		if head then
			local beard = Instance.new("Part"); beard.Name="Beard"; beard.Size=Vector3.new(0.8*scale,0.8*scale,0.2*scale)
			beard.Color=Color3.fromRGB(245,245,245); beard.Material=Enum.Material.Fabric; beard.CanCollide=false; beard.Anchored=false; beard.Parent=model
			weld(head,beard,CFrame.new(0,-0.55*scale,-0.65*scale))
		end
		-- Elder Staff
		local rArm = model:FindFirstChild("Right Arm")
		if rArm then
			local staff = Instance.new("Part"); staff.Name="ElderStaff"; staff.Size=Vector3.new(0.4*scale,5*scale,0.4*scale)
			staff.Color=COLORS.ElderStaff; staff.Material=Enum.Material.Metal; staff.CanCollide=false; staff.Anchored=false; staff.Parent=model
			weld(rArm,staff,CFrame.new(0,-1.8*scale,-0.3*scale))
			local tip = Instance.new("Part"); tip.Name="StaffTip"; tip.Size=Vector3.new(0.8*scale,0.8*scale,0.8*scale)
			tip.Color=Color3.fromRGB(255,215,60); tip.Material=Enum.Material.Neon; tip.CanCollide=false; tip.Anchored=false; tip.Parent=model
			weld(staff,tip,CFrame.new(0,-2.6*scale,0))
			local tipLight = Instance.new("PointLight",tip); tipLight.Color=Color3.fromRGB(255,215,60); tipLight.Brightness=2; tipLight.Range=18
		end
		local torso = model:FindFirstChild("Torso"); if torso then addAura(torso, Color3.fromRGB(255,240,150), Color3.fromRGB(200,180,80), 12, 0.8*scale) end

	elseif enemyType == "HeavenFlamePillar" then
		model = buildSkeleton("HeavenFlamePillar", scale, COLORS.FlameSkin, COLORS.FlameRobe, Color3.fromRGB(140,80,15))
		-- Solar crown
		local head = model:FindFirstChild("Head")
		if head then
			for _, pos in ipairs({ Vector3.new(0,1.8,0), Vector3.new(-0.6,1.4,0), Vector3.new(0.6,1.4,0) }) do
				local ray = Instance.new("Part"); ray.Name="SolarRay"; ray.Size=Vector3.new(0.35*scale,0.9*scale,0.35*scale)
				ray.Color=COLORS.FlameGold; ray.Material=Enum.Material.Neon; ray.CanCollide=false; ray.Anchored=false; ray.Parent=model
				weld(head,ray,CFrame.new(pos*scale))
			end
		end
		for _, armName in ipairs({"Left Arm","Right Arm"}) do
			local arm = model:FindFirstChild(armName)
			if arm then
				addAura(arm, Color3.fromRGB(255,200,50), Color3.fromRGB(200,120,10), 20, 0.9*scale)
				local l = Instance.new("PointLight",arm); l.Color=COLORS.FlameGold; l.Brightness=2.5; l.Range=14
			end
		end

	elseif enemyType == "HeavenThunderPillar" then
		model = buildSkeleton("HeavenThunderPillar", scale, COLORS.ThunderSkin, COLORS.ThunderRobe, Color3.fromRGB(50,40,100))
		addBlade(model, COLORS.ThunderAura, Vector3.new(0.2*scale,4.5*scale,0.45*scale), scale)
		local torso = model:FindFirstChild("Torso")
		if torso then addAura(torso, COLORS.ThunderAura, Color3.fromRGB(80,50,160), 15, 0.9*scale)
			local l = Instance.new("PointLight",torso); l.Color=COLORS.ThunderAura; l.Brightness=2; l.Range=20
		end

	elseif enemyType == "HeavenPalmPillar" then
		model = buildSkeleton("HeavenPalmPillar", scale, COLORS.PalmSkin, COLORS.PalmArmor, Color3.fromRGB(130,125,115))
		-- Heavy plate armor
		local torso = model:FindFirstChild("Torso")
		if torso then
			local chest = Instance.new("Part"); chest.Name="ChestPlate"; chest.Size=Vector3.new(2.3*scale,2.2*scale,1.2*scale)
			chest.Color=COLORS.PalmArmor; chest.Material=Enum.Material.Metal; chest.CanCollide=false; chest.Anchored=false; chest.Parent=model
			weld(torso,chest,CFrame.new())
			local trim = Instance.new("Part"); trim.Name="GoldTrim"; trim.Size=Vector3.new(2.25*scale,0.2*scale,1.25*scale)
			trim.Color=COLORS.PalmGold; trim.Material=Enum.Material.Neon; trim.CanCollide=false; trim.Anchored=false; trim.Parent=model
			weld(chest,trim,CFrame.new(0,0.8*scale,0))
			addAura(torso, COLORS.PalmGold, Color3.fromRGB(200,150,20), 12, 0.9*scale)
		end

	elseif enemyType == "HeavenSwordPillar" then
		model = buildSkeleton("HeavenSwordPillar", scale, COLORS.CreamSkin, COLORS.SwordPillarRobe, Color3.fromRGB(180,185,200))
		addBlade(model, COLORS.SwordPillarBlade, Vector3.new(0.22*scale,4.5*scale,0.45*scale), scale)
		-- Orbiting spectral blades
		local torso = model:FindFirstChild("Torso")
		if torso then
			for i, angle in ipairs({0, math.pi*0.66, math.pi*1.33}) do
				local orb = Instance.new("Part"); orb.Name="OrbBlade"..i; orb.Size=Vector3.new(0.15*scale,2.5*scale,0.3*scale)
				orb.Color=COLORS.SwordAura; orb.Material=Enum.Material.Neon; orb.CanCollide=false; orb.Anchored=false; orb.Parent=model
				weld(torso,orb,CFrame.new(math.cos(angle)*2.5*scale,0,math.sin(angle)*2.5*scale)*CFrame.Angles(0,angle,math.rad(25)))
			end
			addAura(torso, COLORS.SwordAura, Color3.fromRGB(100,130,220), 10, 0.8*scale)
		end

	elseif enemyType == "SupremeHeaven" then
		model = buildSkeleton("SupremeHeaven", scale, COLORS.CreamSkin, COLORS.SupremeRobe, Color3.fromRGB(230,228,215))
		-- Full golden armor
		local torso = model:FindFirstChild("Torso")
		if torso then
			local chest = Instance.new("Part"); chest.Name="SupremeChest"; chest.Size=Vector3.new(2.5*scale,2.3*scale,1.3*scale)
			chest.Color=COLORS.SupremeGold; chest.Material=Enum.Material.Metal; chest.CanCollide=false; chest.Anchored=false; chest.Parent=model
			weld(torso,chest,CFrame.new())
			addAura(torso, COLORS.SupremeAura, Color3.fromRGB(220,180,40), 30, 1.4*scale)
			local l = Instance.new("PointLight",torso); l.Color=COLORS.SupremeAura; l.Brightness=4; l.Range=35
		end
		local head = model:FindFirstChild("Head")
		if head then
			local crown = Instance.new("Part"); crown.Name="SupremeCrown"; crown.Size=Vector3.new(1.7*scale,0.6*scale,1.7*scale)
			crown.Color=COLORS.SupremeGold; crown.Material=Enum.Material.Metal; crown.CanCollide=false; crown.Anchored=false; crown.Parent=model
			weld(head,crown,CFrame.new(0,0.8*scale,0))
		end
		-- Golden cape
		local cape = Instance.new("Part"); cape.Name="GoldenCape"; cape.Size=Vector3.new(2.6*scale,5*scale,0.2*scale)
		cape.Color=COLORS.SupremeGold; cape.Material=Enum.Material.Fabric; cape.CanCollide=false; cape.Anchored=false; cape.Parent=model
		local torso2 = model:FindFirstChild("Torso")
		if torso2 then weld(torso2,cape,CFrame.new(0,-1.8*scale,0.65*scale)*CFrame.Angles(math.rad(10),0,0)) end
	end

	-- Apply stats from config
	local cfg = nil
	pcall(function()
		local rs = game:GetService("ReplicatedStorage")
		local shared = rs:FindFirstChild("Shared")
		if shared then cfg = require(shared:FindFirstChild("HeavenAllianceConfig")) end
	end)
	local stats = cfg and cfg[enemyType]
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum and stats then hum.MaxHealth=stats.MaxHealth; hum.Health=stats.MaxHealth; hum.WalkSpeed=stats.WalkSpeed; hum.DisplayName=stats.Title or enemyType end
	local headPart = model:FindFirstChild("Head")
	if headPart and stats then attachHealthBar(model, headPart, stats.Title or enemyType, stats.MaxHealth, isBoss, scale) end

	return model
end

return HeavenAllianceFactory
