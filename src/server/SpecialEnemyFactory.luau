--!strict
--[[
    SpecialEnemyFactory.luau
    Phase G — Builds R6 enemy rigs for special wandering enemies:
      IronBodyBandit, ThiefAssassin, WanderingSwordmaster
]]

local SpecialEnemyFactory = {}

local COLORS = {
	BanditSkin   = Color3.fromRGB(175, 140, 110),
	BanditCloth  = Color3.fromRGB(80,  55,  30),
	IronArmor    = Color3.fromRGB(120, 118, 115),
	ThiefSkin    = Color3.fromRGB(140, 115, 90),
	ThiefCloth   = Color3.fromRGB(20,  20,  20),
	ThiefBlade   = Color3.fromRGB(40,  40,  80),
	SwordmasterSkin  = Color3.fromRGB(185, 155, 125),
	SwordmasterRobe  = Color3.fromRGB(35,  25,  15),
	SwordmasterBlade = Color3.fromRGB(200, 210, 230),
}

local function buildSkeleton(name, scale, skin, torsoC, legC)
	local model = Instance.new("Model"); model.Name = name
	local function limb(n, sz, col, mat)
		local part = Instance.new("Part"); part.Name=n; part.Size=sz; part.Color=col
		part.Material=mat or Enum.Material.Fabric; part.CanCollide=false; part.Anchored=false; part.Parent=model; return part
	end
	local hrp = Instance.new("Part"); hrp.Name="HumanoidRootPart"
	hrp.Size=Vector3.new(2*scale,2*scale,scale); hrp.Transparency=1; hrp.CanCollide=false; hrp.Anchored=false; hrp.Parent=model
	model.PrimaryPart = hrp
	local torso = limb("Torso",    Vector3.new(2*scale,2*scale,scale), torsoC)
	local head  = limb("Head",     Vector3.new(1.25*scale,1.25*scale,1.25*scale), skin, Enum.Material.SmoothPlastic)
	local lArm  = limb("Left Arm", Vector3.new(scale,2*scale,scale), torsoC)
	local rArm  = limb("Right Arm",Vector3.new(scale,2*scale,scale), torsoC)
	local lLeg  = limb("Left Leg", Vector3.new(scale,2*scale,scale), legC)
	local rLeg  = limb("Right Leg",Vector3.new(scale,2*scale,scale), legC)
	local function motor(nm, p0, p1, c0, c1)
		local m = Instance.new("Motor6D"); m.Name=nm; m.Part0=p0; m.Part1=p1; m.C0=c0; m.C1=c1; m.Parent=p0
	end
	motor("RootJoint",     hrp,   torso, CFrame.new(), CFrame.new())
	motor("Neck",          torso, head,  CFrame.new(0,scale,0), CFrame.new(0,-0.5*scale,0))
	motor("Right Shoulder",torso, rArm,  CFrame.new(1.5*scale,0.5*scale,0), CFrame.new(0,0.5*scale,0))
	motor("Left Shoulder", torso, lArm,  CFrame.new(-1.5*scale,0.5*scale,0), CFrame.new(0,0.5*scale,0))
	motor("Right Hip",     torso, rLeg,  CFrame.new(0.5*scale,-scale,0), CFrame.new(0,scale,0))
	motor("Left Hip",      torso, lLeg,  CFrame.new(-0.5*scale,-scale,0), CFrame.new(0,scale,0))
	local hum = Instance.new("Humanoid"); hum.AutoJumpEnabled=false; hum.Parent=model
	return model
end

local function weld(p0, p1, offset)
	p1.CanCollide = false
	p1.Massless = true
	p1.CFrame = p0.CFrame * offset
	local w = Instance.new("Weld")
	w.Name = p1.Name .. "Weld"
	w.Part0 = p0
	w.Part1 = p1
	w.C0 = offset
	w.C1 = CFrame.new()
	w.Parent = p1
end

local function addBlade(model, color, size, scale, neon)
	local rArm = model:FindFirstChild("Right Arm"); if not rArm then return end
	local blade = Instance.new("Part"); blade.Name="Blade"; blade.Size=size
	blade.Color=color; blade.Material = neon and Enum.Material.Neon or Enum.Material.Metal
	blade.CanCollide=false; blade.Anchored=false; blade.Parent=model
	weld(rArm,blade,CFrame.new(0,-1.3*scale,-0.7*scale)*CFrame.Angles(math.rad(60),0,0))
	local a0=Instance.new("Attachment",blade); a0.Position=Vector3.new(0,-size.Y/2,0)
	local a1=Instance.new("Attachment",blade); a1.Position=Vector3.new(0,size.Y/2,0)
	local trail=Instance.new("Trail",blade); trail.Attachment0=a0; trail.Attachment1=a1
	trail.Color=ColorSequence.new(color, Color3.fromRGB(200,200,255)); trail.Lifetime=0.18; trail.Enabled=false; trail.Name="WeaponTrail"
end

local function addAura(part, c1, c2, rate, size)
	local em=Instance.new("ParticleEmitter"); em.Color=ColorSequence.new(c1,c2)
	em.Size=NumberSequence.new({ NumberSequenceKeypoint.new(0,size), NumberSequenceKeypoint.new(1,0) })
	em.Transparency=NumberSequence.new({ NumberSequenceKeypoint.new(0,0.35), NumberSequenceKeypoint.new(1,1) })
	em.Lifetime=NumberRange.new(0.5,0.9); em.Rate=rate; em.Speed=NumberRange.new(1,2.5); em.SpreadAngle=Vector2.new(180,180); em.Parent=part
end

local function attachHealthBar(model, adorneePart, title, maxHp, isBoss, scale)
	local bbg = Instance.new("BillboardGui"); bbg.Name="EnemyHealthGui"; bbg.AlwaysOnTop=false
	bbg.LightInfluence = 0
	bbg.MaxDistance = 100
	bbg.Size = isBoss and UDim2.new(5.6*scale,0,1.15*scale,0) or UDim2.new(4.2*scale,0,0.88*scale,0)
	bbg.StudsOffset=Vector3.new(0,(2.7+(isBoss and 1.1 or 0))*scale,0); bbg.Adornee=adorneePart; bbg.Parent=model

	local nameLbl=Instance.new("TextLabel"); nameLbl.Name="NameLabel"; nameLbl.BackgroundTransparency=1
	nameLbl.Size=UDim2.new(1,0,0.48,0); nameLbl.Font=Enum.Font.GothamBold; nameLbl.Text=title
	nameLbl.TextColor3=isBoss and Color3.fromRGB(255,215,60) or Color3.fromRGB(240,220,200)
	nameLbl.TextScaled=true; nameLbl.Parent=bbg
	Instance.new("UIStroke",nameLbl).Thickness=1.2

	local hpFrame=Instance.new("Frame"); hpFrame.Name="HpBar"; hpFrame.BackgroundColor3=Color3.fromRGB(20,15,10)
	hpFrame.BorderSizePixel=0; hpFrame.Position=UDim2.new(0,0,0.54,0); hpFrame.Size=UDim2.new(1,0,0.38,0); hpFrame.Parent=bbg
	Instance.new("UICorner",hpFrame).CornerRadius=UDim.new(0.3,0)
	local hpFill=Instance.new("Frame"); hpFill.Name="Fill"
	hpFill.BackgroundColor3=isBoss and Color3.fromRGB(240,160,20) or Color3.fromRGB(220,140,20)
	hpFill.BorderSizePixel=0; hpFill.Size=UDim2.new(1,0,1,0); hpFill.Parent=hpFrame
	Instance.new("UICorner",hpFill).CornerRadius=UDim.new(0.3,0)
	local hpText=Instance.new("TextLabel"); hpText.Name="Value"; hpText.BackgroundTransparency=1
	hpText.Size=UDim2.new(1,0,1,0); hpText.Font=Enum.Font.GothamBold
	hpText.Text=string.format("%d / %d",maxHp,maxHp); hpText.TextColor3=Color3.fromRGB(255,255,255); hpText.TextScaled=true; hpText.Parent=hpFrame

	local hum=model:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.HealthChanged:Connect(function(hp)
			local frac=math.clamp(hp/math.max(1,hum.MaxHealth),0,1)
			hpFill.Size=UDim2.new(frac,0,1,0); hpText.Text=string.format("%d / %d",math.max(0,math.floor(hp)),hum.MaxHealth)
		end)
	end
end

function SpecialEnemyFactory.createEnemy(enemyType)
	local scale = (enemyType == "WanderingSwordmaster") and 1.3 or (enemyType == "IronBodyBandit" and 1.15 or 1.0)
	local isBoss = (enemyType == "WanderingSwordmaster")
	local model

	if enemyType == "IronBodyBandit" then
		model = buildSkeleton("IronBodyBandit", scale, COLORS.BanditSkin, COLORS.BanditCloth, Color3.fromRGB(50,35,20))
		-- Leather bandana over head
		local head = model:FindFirstChild("Head")
		if head then
			local band = Instance.new("Part"); band.Name="Bandana"; band.Size=Vector3.new(1.35*scale,0.5*scale,0.2*scale)
			band.Color=Color3.fromRGB(60,15,15); band.Material=Enum.Material.Fabric; band.CanCollide=false; band.Anchored=false; band.Parent=model
			weld(head,band,CFrame.new(0,0.2*scale,-0.68*scale))
		end
		-- Heavy axe
		local rArm = model:FindFirstChild("Right Arm")
		if rArm then
			local haft = Instance.new("Part"); haft.Name="AxeHaft"; haft.Size=Vector3.new(0.5*scale,4*scale,0.5*scale)
			haft.Color=Color3.fromRGB(70,45,25); haft.Material=Enum.Material.Wood; haft.CanCollide=false; haft.Anchored=false; haft.Parent=model
			weld(rArm,haft,CFrame.new(0,-1.5*scale,-0.3*scale))
			local head2 = Instance.new("Part"); head2.Name="AxeHead"; head2.Size=Vector3.new(0.5*scale,1.5*scale,2.5*scale)
			head2.Color=Color3.fromRGB(120,118,115); head2.Material=Enum.Material.Metal; head2.CanCollide=false; head2.Anchored=false; head2.Parent=model
			weld(haft,head2,CFrame.new(0,-2.3*scale,0)*CFrame.Angles(0,math.rad(90),0))
		end
		-- Iron Body mode: stored attribute to track
		model:SetAttribute("IronBodyActive", false)

	elseif enemyType == "ThiefAssassin" then
		model = buildSkeleton("ThiefAssassin", scale, COLORS.ThiefSkin, COLORS.ThiefCloth, Color3.fromRGB(15,15,15))
		-- Shadow mask
		local head = model:FindFirstChild("Head")
		if head then
			local mask = Instance.new("Part"); mask.Name="ShadowMask"; mask.Size=Vector3.new(1.3*scale,0.7*scale,0.18*scale)
			mask.Color=Color3.fromRGB(10,10,10); mask.Material=Enum.Material.Fabric; mask.CanCollide=false; mask.Anchored=false; mask.Parent=model
			weld(head,mask,CFrame.new(0,-0.15*scale,-0.65*scale))
			-- Glowing eyes
			for _, xOff in ipairs({-0.3, 0.3}) do
				local eye = Instance.new("Part"); eye.Name="Eye"; eye.Size=Vector3.new(0.25*scale,0.2*scale,0.1*scale)
				eye.Color=Color3.fromRGB(200,0,0); eye.Material=Enum.Material.Neon; eye.CanCollide=false; eye.Anchored=false; eye.Parent=model
				weld(mask,eye,CFrame.new(xOff*scale,0.05*scale,-0.15*scale))
			end
		end
		-- Dual short blades
		addBlade(model, Color3.fromRGB(30,30,60), Vector3.new(0.15*scale,2.5*scale,0.35*scale), scale, false)
		local lArm = model:FindFirstChild("Left Arm")
		if lArm then
			local lblade = Instance.new("Part"); lblade.Name="LeftBlade"; lblade.Size=Vector3.new(0.15*scale,2.5*scale,0.35*scale)
			lblade.Color=Color3.fromRGB(30,30,60); lblade.Material=Enum.Material.Metal; lblade.CanCollide=false; lblade.Anchored=false; lblade.Parent=model
			weld(lArm,lblade,CFrame.new(0,-1.3*scale,-0.7*scale)*CFrame.Angles(math.rad(60),0,0))
		end
		local torso = model:FindFirstChild("Torso"); if torso then addAura(torso, Color3.fromRGB(20,20,40), Color3.fromRGB(5,5,15), 8, 0.5*scale) end

	elseif enemyType == "WanderingSwordmaster" then
		model = buildSkeleton("WanderingSwordmaster", scale, COLORS.SwordmasterSkin, COLORS.SwordmasterRobe, Color3.fromRGB(20,15,10))
		-- Long robe sash
		local torso = model:FindFirstChild("Torso")
		if torso then
			local sash = Instance.new("Part"); sash.Name="Sash"; sash.Size=Vector3.new(2.2*scale,4*scale,0.2*scale)
			sash.Color=Color3.fromRGB(25,18,10); sash.Material=Enum.Material.Fabric; sash.CanCollide=false; sash.Anchored=false; sash.Parent=model
			weld(torso,sash,CFrame.new(0,-1.5*scale,0.6*scale)*CFrame.Angles(math.rad(8),0,0))
			addAura(torso, Color3.fromRGB(200,210,230), Color3.fromRGB(100,120,180), 15, 0.9*scale)
			local l=Instance.new("PointLight",torso); l.Color=Color3.fromRGB(200,210,240); l.Brightness=1.5; l.Range=22
		end
		-- Long katana
		addBlade(model, COLORS.SwordmasterBlade, Vector3.new(0.2*scale,5.5*scale,0.45*scale), scale, true)
		-- Hair bun / topknot
		local head = model:FindFirstChild("Head")
		if head then
			local bun = Instance.new("Part"); bun.Name="Topknot"; bun.Size=Vector3.new(0.7*scale,1.0*scale,0.7*scale)
			bun.Color=Color3.fromRGB(15,10,8); bun.Material=Enum.Material.SmoothPlastic; bun.CanCollide=false; bun.Anchored=false; bun.Parent=model
			weld(head,bun,CFrame.new(0,0.75*scale,0))
		end
	end

	-- Apply config stats
	local cfg = nil
	pcall(function()
		local rs = game:GetService("ReplicatedStorage")
		local shared = rs:FindFirstChild("Shared")
		if shared then cfg = require(shared:FindFirstChild("SpecialEnemyConfig")) end
	end)
	local stats = cfg and cfg[enemyType]
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum and stats then hum.MaxHealth=stats.MaxHealth; hum.Health=stats.MaxHealth; hum.WalkSpeed=stats.WalkSpeed; hum.DisplayName=stats.Title or enemyType end
	local headPart = model:FindFirstChild("Head")
	if headPart and stats then attachHealthBar(model, headPart, stats.Title or enemyType, stats.MaxHealth, isBoss, scale) end

	return model
end

return SpecialEnemyFactory
