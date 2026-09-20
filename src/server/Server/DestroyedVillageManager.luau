--!strict
-- src/server/DestroyedVillageManager.luau
-- Authoritative Combat AI, Custom Martial Arts Animations & Xianxia Weapons
-- Controls all enemies in Workspace.DestroyedVillage_Enemies:
-- 5 Pillar Swordsmen + 1 Grandmaster Swordmaster Boss at exact edit-mode coordinates.
-- Zero Unicode emojis, zero conflicting scripts, zero goofy lunge animations.

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local DamageService = nil
pcall(function()
	local sss = game:GetService("ServerScriptService")
	local ds = sss:FindFirstChild("DamageService", true)
	if ds and ds:IsA("ModuleScript") then
		DamageService = require(ds) :: any
	end
end)

local function dealDamage(hum: Humanoid, amount: number, skillName: string?)
	if DamageService and DamageService.applyDamage then
		DamageService.applyDamage(hum, amount, nil, skillName)
	else
		hum:TakeDamage(amount)
	end
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

local function showFloatingText(position: Vector3, text: string, textColor: Color3)
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

local function awardKillRewards(killerPlayer: Player?, isBoss: boolean)
	if not killerPlayer then end
	if not killerPlayer then return end
	local leaderstats = killerPlayer:FindFirstChild("leaderstats")
	local goldVal = leaderstats and leaderstats:FindFirstChild("Gold") :: IntValue?
	local qiVal = leaderstats and leaderstats:FindFirstChild("Qi") :: IntValue?
	local inventory = killerPlayer:FindFirstChild("Inventory")

	local goldReward = isBoss and 250 or math.random(30, 55)
	local qiReward = isBoss and 600 or math.random(80, 150)

	if goldVal then goldVal.Value = goldVal.Value + goldReward end
	if qiVal then qiVal.Value = qiVal.Value + qiReward end

	local killerChar = killerPlayer.Character
	local killerRoot = killerChar and killerChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if killerRoot then
		showFloatingText(killerRoot.Position, string.format("+%d Gold  +%d Qi", goldReward, qiReward), Color3.fromRGB(255, 215, 80))
	end

	if inventory and isBoss then
		local dropName = if math.random() > 0.5 then "Spirit Stone" else "Qi Condensation Pill"
		local itm = inventory:FindFirstChild(dropName) :: IntValue?
		if not itm then
			itm = Instance.new("IntValue")
			itm.Name = dropName
			itm.Value = 0
			itm.Parent = inventory
		end
		itm.Value = itm.Value + 1
	end
end

-- ============================================================================
-- R6 MARTIAL ARTS ANIMATION CONFIGURATION
-- ============================================================================
local ANIM_IDS = {
	Idle       = "rbxassetid://180435571", -- Official R6 Idle (smooth breathing, upright stance)
	Walk       = "rbxassetid://180426354", -- Official R6 Walk (velocity-blended natural leg stride)
	Slash      = "rbxassetid://129967390", -- Horizontal Crescent Slash
	Overhead   = "rbxassetid://125750867", -- Sky-Cleaving Overhead Chop
	CrossSlash = "rbxassetid://243827693", -- Martial Arts Spin Cross-Slash (Fast, dynamic, zero goofy lunge)
	Jump       = "rbxassetid://125750702", -- Classic R6 Jump
}

-- ============================================================================
-- AUTHORITATIVE XIANXIA WEAPON BUILDER & HAND GRIP ALIGNMENT
-- ============================================================================
local function makePartWeld(part0: BasePart, part1: BasePart, c0: CFrame?, c1: CFrame?)
	local w = Instance.new("Weld")
	w.Part0 = part0
	w.Part1 = part1
	w.C0 = c0 or CFrame.new()
	w.C1 = c1 or CFrame.new()
	w.Parent = part0
	return w
end

local function cleanOldWeapons(model: Model)
	for _, child in ipairs(model:GetChildren()) do
		local n = child.Name:lower()
		if child:IsA("BasePart") and (n:find("hilt") or n:find("tsuba") or n:find("blade") or n:find("guard") or n:find("weapon") or n:find("katana") or n:find("dao") or n:find("cleaver") or n:find("jian")) then
			child:Destroy()
		end
	end
	local oldModel = model:FindFirstChild("EquippedWeapon")
	if oldModel then oldModel:Destroy() end

	local rightArm = model:FindFirstChild("Right Arm")
	if rightArm then
		for _, child in ipairs(rightArm:GetChildren()) do
			if child:IsA("Weld") or child:IsA("WeldConstraint") then
				child:Destroy()
			end
		end
	end
end

-- Exact forward-pointing sword grip matrix from Azure Wind Swordsman (Swordsman_4)
local FORWARD_GRIP_ROT = CFrame.fromMatrix(
	Vector3.new(),
	Vector3.new(-1, 0, 0),
	Vector3.new(0, 0, -1),
	Vector3.new(0, -1, 0)
)

-- 1. SHADOW KATANA (Swordsman_1)
local function buildShadowKatana(model: Model)
	cleanOldWeapons(model)
	local rightArm = model:FindFirstChild("Right Arm") :: BasePart?
	if not rightArm then return end

	local weaponModel = Instance.new("Model")
	weaponModel.Name = "EquippedWeapon"
	weaponModel.Parent = model

	local tsuba = Instance.new("Part")
	tsuba.Name = "KatanaTsuba"
	tsuba.Size = Vector3.new(0.72, 0.1, 0.72)
	tsuba.Color = Color3.fromRGB(150, 120, 65)
	tsuba.Material = Enum.Material.Metal
	tsuba.CanCollide = false
	tsuba.Parent = weaponModel
	local tm = Instance.new("SpecialMesh", tsuba)
	tm.MeshType = Enum.MeshType.Cylinder
	makePartWeld(rightArm, tsuba, CFrame.new(0, -0.93, -0.48) * FORWARD_GRIP_ROT)

	local grip = Instance.new("Part")
	grip.Name = "KatanaHilt"
	grip.Size = Vector3.new(0.24, 0.95, 0.24)
	grip.Color = Color3.fromRGB(30, 30, 36)
	grip.Material = Enum.Material.SmoothPlastic
	grip.CanCollide = false
	grip.Parent = weaponModel
	local gm = Instance.new("SpecialMesh", grip)
	gm.MeshType = Enum.MeshType.Cylinder
	makePartWeld(tsuba, grip, CFrame.new(0, -0.5, 0))

	local pommel = Instance.new("Part")
	pommel.Name = "KatanaPommel"
	pommel.Size = Vector3.new(0.32, 0.15, 0.32)
	pommel.Color = Color3.fromRGB(180, 145, 75)
	pommel.Material = Enum.Material.Metal
	pommel.CanCollide = false
	pommel.Parent = weaponModel
	local pm = Instance.new("SpecialMesh", pommel)
	pm.MeshType = Enum.MeshType.Cylinder
	makePartWeld(grip, pommel, CFrame.new(0, -0.5, 0))

	local habaki = Instance.new("Part")
	habaki.Name = "KatanaHabaki"
	habaki.Size = Vector3.new(0.2, 0.22, 0.3)
	habaki.Color = Color3.fromRGB(210, 175, 85)
	habaki.Material = Enum.Material.Metal
	habaki.CanCollide = false
	habaki.Parent = weaponModel
	makePartWeld(tsuba, habaki, CFrame.new(0, 0.14, 0))

	local blade = Instance.new("Part")
	blade.Name = "WeaponBlade"
	blade.Size = Vector3.new(0.12, 3.2, 0.36)
	blade.Color = Color3.fromRGB(38, 40, 48)
	blade.Material = Enum.Material.Metal
	blade.CanCollide = false
	blade.CastShadow = true
	blade.Parent = weaponModel
	makePartWeld(habaki, blade, CFrame.new(0, 1.7, 0))

	local tip = Instance.new("WedgePart")
	tip.Name = "BladeTip"
	tip.Size = Vector3.new(0.12, 0.55, 0.36)
	tip.Color = Color3.fromRGB(55, 58, 68)
	tip.Material = Enum.Material.Metal
	tip.CanCollide = false
	tip.Parent = weaponModel
	makePartWeld(blade, tip, CFrame.new(0, 1.85, 0) * CFrame.Angles(math.rad(180), 0, 0))

	local fx = Instance.new("ParticleEmitter")
	fx.Name = "ShadowMist"
	fx.Color = ColorSequence.new(Color3.fromRGB(60, 25, 85), Color3.fromRGB(20, 15, 30))
	fx.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.5) })
	fx.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
	fx.Lifetime = NumberRange.new(0.4, 0.8)
	fx.Rate = 12
	fx.Speed = NumberRange.new(0.4, 1.2)
	fx.LightEmission = 0.2
	fx.Parent = blade
end

-- 2. CRIMSON FLAME DAO (Swordsman_2)
local function buildCrimsonDao(model: Model)
	cleanOldWeapons(model)
	local rightArm = model:FindFirstChild("Right Arm") :: BasePart?
	if not rightArm then return end

	local weaponModel = Instance.new("Model")
	weaponModel.Name = "EquippedWeapon"
	weaponModel.Parent = model

	local guard = Instance.new("Part")
	guard.Name = "DaoGuard"
	guard.Size = Vector3.new(0.85, 0.12, 0.85)
	guard.Color = Color3.fromRGB(215, 175, 55)
	guard.Material = Enum.Material.Metal
	guard.CanCollide = false
	guard.Parent = weaponModel
	local gdm = Instance.new("SpecialMesh", guard)
	gdm.MeshType = Enum.MeshType.Cylinder
	makePartWeld(rightArm, guard, CFrame.new(0, -0.93, -0.48) * FORWARD_GRIP_ROT)

	local grip = Instance.new("Part")
	grip.Name = "DaoHilt"
	grip.Size = Vector3.new(0.24, 0.95, 0.24)
	grip.Color = Color3.fromRGB(150, 30, 35)
	grip.Material = Enum.Material.Fabric
	grip.CanCollide = false
	grip.Parent = weaponModel
	local gm = Instance.new("SpecialMesh", grip)
	gm.MeshType = Enum.MeshType.Cylinder
	makePartWeld(guard, grip, CFrame.new(0, -0.5, 0))

	local pommel = Instance.new("Part")
	pommel.Name = "DaoPommel"
	pommel.Size = Vector3.new(0.36, 0.15, 0.36)
	pommel.Color = Color3.fromRGB(215, 175, 55)
	pommel.Material = Enum.Material.Metal
	pommel.CanCollide = false
	pommel.Parent = weaponModel
	local pm = Instance.new("SpecialMesh", pommel)
	pm.MeshType = Enum.MeshType.Cylinder
	makePartWeld(grip, pommel, CFrame.new(0, -0.52, 0))

	local tassel = Instance.new("Part")
	tassel.Name = "RedTassel"
	tassel.Size = Vector3.new(0.18, 0.65, 0.18)
	tassel.Color = Color3.fromRGB(200, 25, 30)
	tassel.Material = Enum.Material.Fabric
	tassel.CanCollide = false
	tassel.Parent = weaponModel
	local tm = Instance.new("SpecialMesh", tassel)
	tm.MeshType = Enum.MeshType.Cylinder
	makePartWeld(pommel, tassel, CFrame.new(0, -0.4, 0))

	local blade = Instance.new("Part")
	blade.Name = "WeaponBlade"
	blade.Size = Vector3.new(0.14, 3.4, 0.52)
	blade.Color = Color3.fromRGB(180, 45, 45)
	blade.Material = Enum.Material.Metal
	blade.CanCollide = false
	blade.CastShadow = true
	blade.Parent = weaponModel
	makePartWeld(guard, blade, CFrame.new(0, 1.75, 0))

	local fuller = Instance.new("Part")
	fuller.Name = "BladeFuller"
	fuller.Size = Vector3.new(0.16, 2.8, 0.1)
	fuller.Color = Color3.fromRGB(255, 75, 45)
	fuller.Material = Enum.Material.Neon
	fuller.CanCollide = false
	fuller.Parent = weaponModel
	makePartWeld(blade, fuller, CFrame.new(0, -0.1, 0))

	local tip = Instance.new("WedgePart")
	tip.Name = "BladeTip"
	tip.Size = Vector3.new(0.14, 0.65, 0.52)
	tip.Color = Color3.fromRGB(215, 55, 55)
	tip.Material = Enum.Material.Metal
	tip.CanCollide = false
	tip.Parent = weaponModel
	makePartWeld(blade, tip, CFrame.new(0, 2.0, 0) * CFrame.Angles(math.rad(180), 0, 0))

	local fx = Instance.new("ParticleEmitter")
	fx.Name = "FlameEmbers"
	fx.Color = ColorSequence.new(Color3.fromRGB(255, 120, 30), Color3.fromRGB(255, 30, 10))
	fx.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0.05) })
	fx.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	fx.Lifetime = NumberRange.new(0.3, 0.7)
	fx.Rate = 14
	fx.Speed = NumberRange.new(1, 2.5)
	fx.LightEmission = 0.8
	fx.Parent = blade
end

-- 3. IRON MOUNTAIN CLEAVER (Swordsman_3)
local function buildIronCleaver(model: Model)
	cleanOldWeapons(model)
	local rightArm = model:FindFirstChild("Right Arm") :: BasePart?
	if not rightArm then return end

	local weaponModel = Instance.new("Model")
	weaponModel.Name = "EquippedWeapon"
	weaponModel.Parent = model

	local guard = Instance.new("Part")
	guard.Name = "CleaverGuard"
	guard.Size = Vector3.new(0.9, 0.2, 0.5)
	guard.Color = Color3.fromRGB(80, 85, 95)
	guard.Material = Enum.Material.DiamondPlate
	guard.CanCollide = false
	guard.Parent = weaponModel
	makePartWeld(rightArm, guard, CFrame.new(0, -0.93, -0.48) * FORWARD_GRIP_ROT)

	local grip = Instance.new("Part")
	grip.Name = "CleaverHilt"
	grip.Size = Vector3.new(0.28, 1.1, 0.28)
	grip.Color = Color3.fromRGB(45, 50, 55)
	grip.Material = Enum.Material.Metal
	grip.CanCollide = false
	grip.Parent = weaponModel
	local gm = Instance.new("SpecialMesh", grip)
	gm.MeshType = Enum.MeshType.Cylinder
	makePartWeld(guard, grip, CFrame.new(0, -0.6, 0))

	local pommel = Instance.new("Part")
	pommel.Name = "CleaverPommel"
	pommel.Size = Vector3.new(0.45, 0.25, 0.45)
	pommel.Color = Color3.fromRGB(30, 33, 38)
	pommel.Material = Enum.Material.Metal
	pommel.CanCollide = false
	pommel.Parent = weaponModel
	local pm = Instance.new("SpecialMesh", pommel)
	pm.MeshType = Enum.MeshType.Cylinder
	makePartWeld(grip, pommel, CFrame.new(0, -0.65, 0))

	local blade = Instance.new("Part")
	blade.Name = "WeaponBlade"
	blade.Size = Vector3.new(0.2, 3.8, 0.85)
	blade.Color = Color3.fromRGB(130, 135, 145)
	blade.Material = Enum.Material.Metal
	blade.CanCollide = false
	blade.CastShadow = true
	blade.Parent = weaponModel
	makePartWeld(guard, blade, CFrame.new(0, 2.0, 0))

	local edge = Instance.new("Part")
	edge.Name = "CleaverEdge"
	edge.Size = Vector3.new(0.22, 3.7, 0.15)
	edge.Color = Color3.fromRGB(190, 195, 205)
	edge.Material = Enum.Material.Metal
	edge.CanCollide = false
	edge.Parent = weaponModel
	makePartWeld(blade, edge, CFrame.new(0, 0, 0.45))

	local tip = Instance.new("WedgePart")
	tip.Name = "BladeTip"
	tip.Size = Vector3.new(0.2, 0.7, 0.85)
	tip.Color = Color3.fromRGB(160, 165, 175)
	tip.Material = Enum.Material.Metal
	tip.CanCollide = false
	tip.Parent = weaponModel
	makePartWeld(blade, tip, CFrame.new(0, 2.25, 0) * CFrame.Angles(math.rad(180), 0, 0))

	local fx = Instance.new("ParticleEmitter")
	fx.Name = "IronGlint"
	fx.Color = ColorSequence.new(Color3.fromRGB(220, 230, 245), Color3.fromRGB(150, 160, 175))
	fx.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.05) })
	fx.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	fx.Lifetime = NumberRange.new(0.3, 0.6)
	fx.Rate = 8
	fx.Speed = NumberRange.new(0.5, 2.0)
	fx.LightEmission = 0.4
	fx.Parent = blade
end

-- 4. AZURE WIND JIAN (Swordsman_4 - Authoritative Forward Grip Reference)
local function buildAzureJian(model: Model)
	cleanOldWeapons(model)
	local rightArm = model:FindFirstChild("Right Arm") :: BasePart?
	if not rightArm then return end

	local weaponModel = Instance.new("Model")
	weaponModel.Name = "EquippedWeapon"
	weaponModel.Parent = model

	local guard = Instance.new("Part")
	guard.Name = "JianGuard"
	guard.Size = Vector3.new(0.8, 0.15, 0.32)
	guard.Color = Color3.fromRGB(60, 175, 170)
	guard.Material = Enum.Material.Metal
	guard.CanCollide = false
	guard.Parent = weaponModel
	makePartWeld(rightArm, guard, CFrame.new(0, -0.93, -0.48) * FORWARD_GRIP_ROT)

	local grip = Instance.new("Part")
	grip.Name = "JianHilt"
	grip.Size = Vector3.new(0.22, 0.95, 0.22)
	grip.Color = Color3.fromRGB(240, 245, 250)
	grip.Material = Enum.Material.SmoothPlastic
	grip.CanCollide = false
	grip.Parent = weaponModel
	local gm = Instance.new("SpecialMesh", grip)
	gm.MeshType = Enum.MeshType.Cylinder
	makePartWeld(guard, grip, CFrame.new(0, -0.52, 0))

	local pommel = Instance.new("Part")
	pommel.Name = "JianPommel"
	pommel.Size = Vector3.new(0.35, 0.18, 0.35)
	pommel.Color = Color3.fromRGB(80, 220, 180)
	pommel.Material = Enum.Material.Neon
	pommel.CanCollide = false
	pommel.Parent = weaponModel
	local pm = Instance.new("SpecialMesh", pommel)
	pm.MeshType = Enum.MeshType.Sphere
	makePartWeld(grip, pommel, CFrame.new(0, -0.55, 0))

	local blade = Instance.new("Part")
	blade.Name = "WeaponBlade"
	blade.Size = Vector3.new(0.12, 3.4, 0.36)
	blade.Color = Color3.fromRGB(200, 230, 240)
	blade.Material = Enum.Material.Metal
	blade.CanCollide = false
	blade.CastShadow = true
	blade.Parent = weaponModel
	makePartWeld(guard, blade, CFrame.new(0, 1.75, 0))

	local core = Instance.new("Part")
	core.Name = "SpiritualCore"
	core.Size = Vector3.new(0.14, 3.1, 0.08)
	core.Color = Color3.fromRGB(110, 240, 255)
	core.Material = Enum.Material.Neon
	core.CanCollide = false
	core.Parent = weaponModel
	makePartWeld(blade, core, CFrame.new(0, 0, 0))

	local tip = Instance.new("WedgePart")
	tip.Name = "BladeTip"
	tip.Size = Vector3.new(0.12, 0.6, 0.36)
	tip.Color = Color3.fromRGB(220, 240, 250)
	tip.Material = Enum.Material.Metal
	tip.CanCollide = false
	tip.Parent = weaponModel
	makePartWeld(blade, tip, CFrame.new(0, 1.95, 0) * CFrame.Angles(math.rad(180), 0, 0))

	local fx = Instance.new("ParticleEmitter")
	fx.Name = "WindRipples"
	fx.Color = ColorSequence.new(Color3.fromRGB(150, 245, 255), Color3.fromRGB(90, 200, 230))
	fx.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.45) })
	fx.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	fx.Lifetime = NumberRange.new(0.3, 0.6)
	fx.Rate = 10
	fx.Speed = NumberRange.new(1, 3)
	fx.LightEmission = 0.5
	fx.Parent = blade
end

-- 5. PHANTOM SOUL BLADE (Swordsman_5)
local function buildGhostBlade(model: Model)
	cleanOldWeapons(model)
	local rightArm = model:FindFirstChild("Right Arm") :: BasePart?
	if not rightArm then return end

	local weaponModel = Instance.new("Model")
	weaponModel.Name = "EquippedWeapon"
	weaponModel.Parent = model

	local guard = Instance.new("Part")
	guard.Name = "GhostGuard"
	guard.Size = Vector3.new(0.85, 0.15, 0.45)
	guard.Color = Color3.fromRGB(90, 55, 125)
	guard.Material = Enum.Material.Metal
	guard.CanCollide = false
	guard.Parent = weaponModel
	makePartWeld(rightArm, guard, CFrame.new(0, -0.93, -0.48) * FORWARD_GRIP_ROT)

	local grip = Instance.new("Part")
	grip.Name = "GhostHilt"
	grip.Size = Vector3.new(0.24, 0.95, 0.24)
	grip.Color = Color3.fromRGB(55, 45, 65)
	grip.Material = Enum.Material.SmoothPlastic
	grip.CanCollide = false
	grip.Parent = weaponModel
	local gm = Instance.new("SpecialMesh", grip)
	gm.MeshType = Enum.MeshType.Cylinder
	makePartWeld(guard, grip, CFrame.new(0, -0.52, 0))

	local pommel = Instance.new("Part")
	pommel.Name = "SkullPommel"
	pommel.Size = Vector3.new(0.38, 0.3, 0.38)
	pommel.Color = Color3.fromRGB(175, 165, 185)
	pommel.Material = Enum.Material.SmoothPlastic
	pommel.CanCollide = false
	pommel.Parent = weaponModel
	local pm = Instance.new("SpecialMesh", pommel)
	pm.MeshType = Enum.MeshType.Sphere
	makePartWeld(grip, pommel, CFrame.new(0, -0.58, 0))

	local blade = Instance.new("Part")
	blade.Name = "WeaponBlade"
	blade.Size = Vector3.new(0.14, 3.4, 0.44)
	blade.Color = Color3.fromRGB(130, 65, 200)
	blade.Material = Enum.Material.Neon
	blade.CanCollide = false
	blade.CastShadow = true
	blade.Parent = weaponModel
	makePartWeld(guard, blade, CFrame.new(0, 1.75, 0))

	local tip = Instance.new("WedgePart")
	tip.Name = "BladeTip"
	tip.Size = Vector3.new(0.14, 0.6, 0.44)
	tip.Color = Color3.fromRGB(160, 90, 235)
	tip.Material = Enum.Material.Neon
	tip.CanCollide = false
	tip.Parent = weaponModel
	makePartWeld(blade, tip, CFrame.new(0, 1.95, 0) * CFrame.Angles(math.rad(180), 0, 0))

	local fx = Instance.new("ParticleEmitter")
	fx.Name = "SoulFlames"
	fx.Color = ColorSequence.new(Color3.fromRGB(180, 80, 255), Color3.fromRGB(70, 235, 205))
	fx.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.4) })
	fx.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1) })
	fx.Lifetime = NumberRange.new(0.4, 0.8)
	fx.Rate = 12
	fx.Speed = NumberRange.new(0.8, 2.0)
	fx.LightEmission = 0.9
	fx.Parent = blade
end

-- 6. HEAVENLY DRAGON MASTER BLADE (Swordmaster_Boss)
local function buildMasterBlade(model: Model)
	cleanOldWeapons(model)
	local rightArm = model:FindFirstChild("Right Arm") :: BasePart?
	if not rightArm then return end

	local weaponModel = Instance.new("Model")
	weaponModel.Name = "EquippedWeapon"
	weaponModel.Parent = model

	local guard = Instance.new("Part")
	guard.Name = "MasterGuard"
	guard.Size = Vector3.new(1.3, 0.25, 0.65)
	guard.Color = Color3.fromRGB(245, 205, 60)
	guard.Material = Enum.Material.Metal
	guard.CanCollide = false
	guard.Parent = weaponModel
	makePartWeld(rightArm, guard, CFrame.new(0, -1.25, -0.65) * FORWARD_GRIP_ROT)

	local grip = Instance.new("Part")
	grip.Name = "MasterHilt"
	grip.Size = Vector3.new(0.35, 1.5, 0.35)
	grip.Color = Color3.fromRGB(45, 32, 20)
	grip.Material = Enum.Material.SmoothPlastic
	grip.CanCollide = false
	grip.Parent = weaponModel
	local gm = Instance.new("SpecialMesh", grip)
	gm.MeshType = Enum.MeshType.Cylinder
	makePartWeld(guard, grip, CFrame.new(0, -0.85, 0))

	local pommel = Instance.new("Part")
	pommel.Name = "DragonPommel"
	pommel.Size = Vector3.new(0.55, 0.4, 0.55)
	pommel.Color = Color3.fromRGB(245, 205, 60)
	pommel.Material = Enum.Material.Metal
	pommel.CanCollide = false
	pommel.Parent = weaponModel
	local pm = Instance.new("SpecialMesh", pommel)
	pm.MeshType = Enum.MeshType.Sphere
	makePartWeld(grip, pommel, CFrame.new(0, -0.9, 0))

	local jewel = Instance.new("Part")
	jewel.Name = "DragonPearl"
	jewel.Size = Vector3.new(0.35, 0.35, 0.35)
	jewel.Color = Color3.fromRGB(255, 50, 40)
	jewel.Material = Enum.Material.Neon
	jewel.CanCollide = false
	jewel.Parent = weaponModel
	local jm = Instance.new("SpecialMesh", jewel)
	jm.MeshType = Enum.MeshType.Sphere
	makePartWeld(guard, jewel, CFrame.new(0, 0, 0.32))

	local blade = Instance.new("Part")
	blade.Name = "WeaponBlade"
	blade.Size = Vector3.new(0.22, 5.0, 0.75)
	blade.Color = Color3.fromRGB(235, 240, 250)
	blade.Material = Enum.Material.Metal
	blade.CanCollide = false
	blade.CastShadow = true
	blade.Parent = weaponModel
	makePartWeld(guard, blade, CFrame.new(0, 2.6, 0))

	local runes = Instance.new("Part")
	runes.Name = "CelestialRunes"
	runes.Size = Vector3.new(0.26, 4.2, 0.16)
	runes.Color = Color3.fromRGB(255, 215, 70)
	runes.Material = Enum.Material.Neon
	runes.CanCollide = false
	runes.Parent = weaponModel
	makePartWeld(blade, runes, CFrame.new(0, -0.2, 0))

	local tip = Instance.new("WedgePart")
	tip.Name = "BladeTip"
	tip.Size = Vector3.new(0.22, 0.9, 0.75)
	tip.Color = Color3.fromRGB(250, 250, 255)
	tip.Material = Enum.Material.Metal
	tip.CanCollide = false
	tip.Parent = weaponModel
	makePartWeld(blade, tip, CFrame.new(0, 2.9, 0) * CFrame.Angles(math.rad(180), 0, 0))

	local fx = Instance.new("ParticleEmitter")
	fx.Name = "GoldenDragonAura"
	fx.Color = ColorSequence.new(Color3.fromRGB(255, 225, 90), Color3.fromRGB(255, 140, 20))
	fx.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0.8) })
	fx.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	fx.Lifetime = NumberRange.new(0.5, 1.0)
	fx.Rate = 18
	fx.Speed = NumberRange.new(1.2, 3.0)
	fx.LightEmission = 1.0
	fx.Parent = blade
end

local function attachCustomSword(model: Model, variantName: string)
	local isBoss = string.find(variantName:lower(), "boss") ~= nil 
		or string.find(model.Name:lower(), "boss") ~= nil 
		or string.find(variantName:lower(), "swordmaster") ~= nil

	if isBoss then
		buildMasterBlade(model)
	elseif string.find(variantName, "Crimson") or string.find(model.Name, "Swordsman_2") then
		buildCrimsonDao(model)
	elseif string.find(variantName, "Iron") or string.find(model.Name, "Swordsman_3") then
		buildIronCleaver(model)
	elseif string.find(variantName, "Azure") or string.find(model.Name, "Swordsman_4") then
		buildAzureJian(model)
	elseif string.find(variantName, "Ghost") or string.find(model.Name, "Swordsman_5") then
		buildGhostBlade(model)
	else
		buildShadowKatana(model)
	end
end

-- ============================================================================
-- ENEMY ANIMATION CONTROLLER
-- ============================================================================
export type EnemyAnimController = {
	playAttack: (comboIndex: number, onStrike: (attackType: string) -> ()) -> (),
	triggerJump: () -> (),
	stopAll: () -> (),
	setAttacking: (val: boolean) -> (),
	isAttacking: () -> boolean,
}

local function setupEnemyAnimations(model: Model, humanoid: Humanoid, rootPart: BasePart): EnemyAnimController
	-- 1. Purge legacy or inert scripts
	for _, child in ipairs(model:GetChildren()) do
		if (child.Name == "EnemyController" or child.Name == "Animate") and child:IsA("LuaSourceContainer") then
			child:Destroy()
		end
	end

	-- 2. Setup Server Animator
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local function loadAnim(id: string, priority: Enum.AnimationPriority, looped: boolean): AnimationTrack
		local a = Instance.new("Animation")
		a.AnimationId = id
		local track = animator:LoadAnimation(a)
		track.Priority = priority
		track.Looped = looped
		return track
	end

	local idleTrack = loadAnim(ANIM_IDS.Idle, Enum.AnimationPriority.Idle, true)
	local walkTrack = loadAnim(ANIM_IDS.Walk, Enum.AnimationPriority.Movement, true)
	local slashTrack = loadAnim(ANIM_IDS.Slash, Enum.AnimationPriority.Action, false)
	local overheadTrack = loadAnim(ANIM_IDS.Overhead, Enum.AnimationPriority.Action, false)
	local crossSlashTrack = loadAnim(ANIM_IDS.CrossSlash, Enum.AnimationPriority.Action, false)
	local jumpTrack = loadAnim(ANIM_IDS.Jump, Enum.AnimationPriority.Action, false)

	local isAttacking = false
	local isDestroyed = false

	idleTrack:Play(0.2)

	local function updateMovement()
		if isDestroyed or isAttacking or not model.Parent or humanoid.Health <= 0 then return end
		local horizVel = (rootPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude
		local isMoving = horizVel > 1.2

		if isMoving then
			if not walkTrack.IsPlaying then
				walkTrack:Play(0.15)
				idleTrack:Stop(0.15)
			end
			local baseSpeed = humanoid.WalkSpeed > 0 and humanoid.WalkSpeed or 16
			walkTrack:AdjustSpeed(math.clamp(horizVel / baseSpeed, 0.7, 1.4))
		else
			if not idleTrack.IsPlaying then
				idleTrack:Play(0.15)
				walkTrack:Stop(0.15)
			end
		end
	end

	local conn1 = humanoid.Running:Connect(updateMovement)
	local conn2 = RunService.Heartbeat:Connect(updateMovement)

	humanoid.Died:Connect(function()
		isDestroyed = true
		conn1:Disconnect()
		conn2:Disconnect()
		pcall(function()
			idleTrack:Stop(0.1)
			walkTrack:Stop(0.1)
			slashTrack:Stop(0.1)
			overheadTrack:Stop(0.1)
			crossSlashTrack:Stop(0.1)
			jumpTrack:Stop(0.1)
		end)
	end)

	local controller: EnemyAnimController = {
		playAttack = function(comboIndex: number, onStrike: (attackType: string) -> ())
			if isAttacking or isDestroyed then return end
			isAttacking = true
			walkTrack:Stop(0.08)

			if comboIndex == 1 then
				-- Combo 1: Horizontal Crescent Slash
				slashTrack:Play(0.06, 1, 1.25)
				createSound(rootPart, "rbxassetid://9114223170", 0.8, 1.15)

				task.delay(0.20, function()
					if not isDestroyed and humanoid.Health > 0 then
						onStrike("Slash")
					end
				end)

				task.delay(0.48, function()
					isAttacking = false
					if not isDestroyed and humanoid.Health > 0 then
						updateMovement()
					end
				end)

			elseif comboIndex == 2 then
				-- Combo 2: Sky-Cleaving Overhead Chop
				overheadTrack:Play(0.06, 1, 1.2)
				createSound(rootPart, "rbxassetid://9114223170", 0.85, 0.95)

				task.delay(0.28, function()
					if not isDestroyed and humanoid.Health > 0 then
						onStrike("Overhead")
					end
				end)

				task.delay(0.55, function()
					isAttacking = false
					if not isDestroyed and humanoid.Health > 0 then
						updateMovement()
					end
				end)

			else
				-- Combo 3: Whirlwind Double Cross-Slash (NO LUNGE!)
				crossSlashTrack:Play(0.06, 1, 1.25)
				createSound(rootPart, "rbxassetid://9114223170", 0.8, 1.25)

				-- Hit 1: Upward diagonal
				task.delay(0.18, function()
					if not isDestroyed and humanoid.Health > 0 then
						onStrike("CrossSlash_1")
					end
				end)

				-- Hit 2: Downward cross-cut
				task.delay(0.40, function()
					if not isDestroyed and humanoid.Health > 0 then
						createSound(rootPart, "rbxassetid://9114223170", 0.85, 1.35)
						onStrike("CrossSlash_2")
					end
				end)

				task.delay(0.68, function()
					isAttacking = false
					if not isDestroyed and humanoid.Health > 0 then
						updateMovement()
					end
				end)
			end
		end,

		triggerJump = function()
			if isDestroyed then return end
			jumpTrack:Play(0.08, 1, 1.1)
		end,

		stopAll = function()
			isDestroyed = true
			conn1:Disconnect()
			conn2:Disconnect()
			pcall(function()
				idleTrack:Stop(0.1)
				walkTrack:Stop(0.1)
			end)
		end,

		setAttacking = function(val: boolean)
			isAttacking = val
			if val then walkTrack:Stop(0.08) end
		end,

		isAttacking = function()
			return isAttacking
		end,
	}

	return controller
end

-- ============================================================================
-- UNIQUE PILLAR & BOSS SKILLS
-- ============================================================================
local function executeShadowStep(model: Model, hrp: BasePart, targetHrp: BasePart, targetHum: Humanoid, anim: EnemyAnimController)
	anim.setAttacking(true)

	-- 1. Dark smoke puff at departure
	local smoke = Instance.new("Part")
	smoke.Size = Vector3.new(3, 5, 3)
	smoke.CFrame = hrp.CFrame
	smoke.Transparency = 1
	smoke.Anchored = true
	smoke.CanCollide = false
	smoke.Parent = Workspace
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(Color3.fromRGB(30, 15, 45), Color3.fromRGB(80, 20, 100))
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 0) })
	pe.Rate = 60
	pe.Speed = NumberRange.new(2, 6)
	pe.Lifetime = NumberRange.new(0.4, 0.6)
	pe.Parent = smoke
	Debris:AddItem(smoke, 0.8)
	createSound(hrp, "rbxassetid://12222200", 0.9, 1.2)

	task.wait(0.25)
	if not model.Parent or not targetHrp.Parent then anim.setAttacking(false) return end

	-- 2. Teleport behind target
	local behindCF = targetHrp.CFrame * CFrame.new(0, 0, 3.5)
	hrp.CFrame = CFrame.new(behindCF.Position, targetHrp.Position)

	-- 3. Double Shadow Cross-Slash
	createSound(hrp, "rbxassetid://9114223170", 1.0, 1.3)
	task.wait(0.18)
	if targetHum and targetHum.Health > 0 and (targetHrp.Position - hrp.Position).Magnitude <= 8 then
		dealDamage(targetHum, 35, "Shadow Step Decapitation")
		-- Brief slow effect
		local origSpeed = targetHum.WalkSpeed
		targetHum.WalkSpeed = math.max(6, origSpeed - 6)
		task.delay(1.5, function()
			if targetHum and targetHum.Parent then
				targetHum.WalkSpeed = origSpeed
			end
		end)
	end

	task.wait(0.3)
	anim.setAttacking(false)
end

local function executeCrimsonWhirlwind(model: Model, hrp: BasePart, anim: EnemyAnimController)
	anim.setAttacking(true)

	-- Flame flare windup
	local fireRing = Instance.new("Part")
	fireRing.Shape = Enum.PartType.Cylinder
	fireRing.Size = Vector3.new(0.4, 6, 6)
	fireRing.CFrame = hrp.CFrame * CFrame.Angles(0, 0, math.rad(90))
	fireRing.Material = Enum.Material.Neon
	fireRing.Color = Color3.fromRGB(255, 60, 20)
	fireRing.Transparency = 0.3
	fireRing.Anchored = true
	fireRing.CanCollide = false
	fireRing.Parent = Workspace
	createSound(hrp, "rbxassetid://2801263", 0.8, 1.1)

	task.wait(0.3)
	-- 360 Whirlwind spin & advance
	for step = 1, 12 do
		if not model.Parent then break end
		hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(30), 0) + (hrp.CFrame.LookVector * 0.65)

		-- Hit check around spinner
		for _, p in ipairs(Players:GetPlayers()) do
			local c = p.Character
			local pHum = c and c:FindFirstChildOfClass("Humanoid")
			local pRoot = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
			if pHum and pRoot and pHum.Health > 0 then
				if (pRoot.Position - hrp.Position).Magnitude <= 7.5 then
					dealDamage(pHum, 3.5, "Crimson Whirlwind")
				end
			end
		end
		task.wait(0.04)
	end

	Debris:AddItem(fireRing, 0.2)
	task.wait(0.2)
	anim.setAttacking(false)
end

local function executeIronQuake(model: Model, hrp: BasePart, anim: EnemyAnimController)
	anim.setAttacking(true)

	-- Overhead metallic windup
	createSound(hrp, "rbxassetid://9114223170", 1.0, 0.7)
	task.wait(0.4)

	if not model.Parent then anim.setAttacking(false) return end

	-- Ground slam impact
	createSound(hrp, "rbxassetid://2801263", 1.2, 0.85)

	-- Ground fissure shockwave line
	local forward = hrp.CFrame.LookVector
	for i = 1, 4 do
		local fissurePos = hrp.Position + (forward * (i * 4)) + Vector3.new(0, -1.8, 0)
		local rock = Instance.new("Part")
		rock.Size = Vector3.new(2.5, 1.2, 2.5)
		rock.Position = fissurePos
		rock.Anchored = true
		rock.CanCollide = false
		rock.Material = Enum.Material.Slate
		rock.Color = Color3.fromRGB(75, 78, 82)
		rock.Parent = Workspace
		Debris:AddItem(rock, 1.2)

		-- Check players in fissure path
		for _, p in ipairs(Players:GetPlayers()) do
			local c = p.Character
			local pHum = c and c:FindFirstChildOfClass("Humanoid")
			local pRoot = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
			if pHum and pRoot and pHum.Health > 0 then
				if (pRoot.Position - fissurePos).Magnitude <= 5.5 then
					dealDamage(pHum, 40, "Iron Mountain Quake")
					pRoot.AssemblyLinearVelocity = pRoot.AssemblyLinearVelocity + Vector3.new(0, 20, 0) + (forward * 25)
				end
			end
		end
		task.wait(0.06)
	end

	task.wait(0.3)
	anim.setAttacking(false)
end

local function executeAzureWindGale(model: Model, hrp: BasePart, anim: EnemyAnimController)
	anim.setAttacking(true)

	-- Fencing thrust windup
	createSound(hrp, "rbxassetid://9114222513", 0.9, 1.3)
	task.wait(0.3)

	if not model.Parent then anim.setAttacking(false) return end

	-- Fire 3 crescent wind projectiles
	for i = 1, 3 do
		if not model.Parent then break end
		local spreadAngle = (i - 2) * math.rad(15)
		local dir = (hrp.CFrame * CFrame.Angles(0, spreadAngle, 0)).LookVector

		local gale = Instance.new("Part")
		gale.Size = Vector3.new(3, 0.2, 1.5)
		gale.CFrame = CFrame.new(hrp.Position + (dir * 2) + Vector3.new(0, 0.5, 0), hrp.Position + (dir * 10))
		gale.Material = Enum.Material.Neon
		gale.Color = Color3.fromRGB(120, 240, 255)
		gale.Transparency = 0.2
		gale.Anchored = true
		gale.CanCollide = false
		gale.Parent = Workspace

		task.spawn(function()
			local travelDist = 0
			while travelDist < 35 and gale.Parent do
				gale.CFrame = gale.CFrame + (dir * 2.2)
				travelDist = travelDist + 2.2

				for _, p in ipairs(Players:GetPlayers()) do
					local c = p.Character
					local pHum = c and c:FindFirstChildOfClass("Humanoid")
					local pRoot = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
					if pHum and pRoot and pHum.Health > 0 then
						if (pRoot.Position - gale.Position).Magnitude <= 3.5 then
							dealDamage(pHum, 18, "Azure Wind Gale")
							gale:Destroy()
							break
						end
					end
				end
				task.wait(0.03)
			end
			if gale.Parent then gale:Destroy() end
		end)

		createSound(hrp, "rbxassetid://9114223170", 0.7, 1.4)
		task.wait(0.12)
	end

	task.wait(0.2)
	anim.setAttacking(false)
end

local function executeGhostFlameBurst(model: Model, hrp: BasePart, anim: EnemyAnimController)
	anim.setAttacking(true)

	-- Charge spiritual teal flames
	local flameSphere = Instance.new("Part")
	flameSphere.Shape = Enum.PartType.Ball
	flameSphere.Size = Vector3.new(2, 2, 2)
	flameSphere.Position = hrp.Position
	flameSphere.Material = Enum.Material.Neon
	flameSphere.Color = Color3.fromRGB(90, 255, 210)
	flameSphere.Transparency = 0.4
	flameSphere.Anchored = true
	flameSphere.CanCollide = false
	flameSphere.Parent = Workspace
	createSound(hrp, "rbxassetid://12222200", 0.8, 1.4)

	task.wait(0.4)
	if not model.Parent then
		flameSphere:Destroy()
		anim.setAttacking(false)
		return
	end

	-- Radial Detonation
	createSound(hrp, "rbxassetid://2801263", 1.0, 1.2)
	local tween = TweenService:Create(flameSphere, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(22, 22, 22),
		Transparency = 1,
	})
	tween:Play()
	Debris:AddItem(flameSphere, 0.4)

	-- Radial damage & slow
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local pHum = c and c:FindFirstChildOfClass("Humanoid")
		local pRoot = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
		if pHum and pRoot and pHum.Health > 0 then
			local dist = (pRoot.Position - hrp.Position).Magnitude
			if dist <= 14 then
				dealDamage(pHum, 38, "Ghost Flame Burst")
				local origSpeed = pHum.WalkSpeed
				pHum.WalkSpeed = math.max(6, origSpeed - 5)
				task.delay(2.0, function()
					if pHum and pHum.Parent then
						pHum.WalkSpeed = origSpeed
					end
				end)
			end
		end
	end

	task.wait(0.3)
	anim.setAttacking(false)
end

-- ============================================================================
-- GRANDMASTER SWORDMASTER BOSS UNIQUE SKILLS
-- ============================================================================
local function executeBossSwordDomain(model: Model, hrp: BasePart, anim: EnemyAnimController)
	anim.setAttacking(true)

	-- 1. Celestial Sword Domain: Golden ground circle
	local domain = Instance.new("Part")
	domain.Shape = Enum.PartType.Cylinder
	domain.Size = Vector3.new(0.4, 40, 40)
	domain.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	domain.Material = Enum.Material.Neon
	domain.Color = Color3.fromRGB(255, 215, 80)
	domain.Transparency = 0.5
	domain.Anchored = true
	domain.CanCollide = false
	domain.Parent = Workspace
	Debris:AddItem(domain, 3.5)

	createSound(hrp, "rbxassetid://9114222513", 1.2, 0.9)

	-- 2. Conjure 8 Orbiting Golden Spirit Swords
	local swords = {}
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		local sword = Instance.new("Part")
		sword.Size = Vector3.new(0.3, 0.6, 4.5)
		sword.Material = Enum.Material.Neon
		sword.Color = Color3.fromRGB(255, 230, 110)
		sword.Anchored = true
		sword.CanCollide = false
		sword.Parent = Workspace
		local tip = Instance.new("WedgePart")
		tip.Size = Vector3.new(0.3, 0.6, 1.2)
		tip.Color = Color3.fromRGB(255, 245, 180)
		tip.Material = Enum.Material.Neon
		tip.Anchored = true
		tip.CanCollide = false
		tip.Parent = Workspace

		table.insert(swords, { sword = sword, tip = tip, angle = angle })
	end

	-- Orbit for 1.2s
	local orbitTime = 0
	while orbitTime < 1.2 and model.Parent do
		orbitTime = orbitTime + 0.04
		for _, item in ipairs(swords) do
			item.angle = item.angle + 0.08
			local sPos = hrp.Position + Vector3.new(math.cos(item.angle) * 7, 3 + math.sin(orbitTime * 4) * 0.5, math.sin(item.angle) * 7)
			local lookAt = sPos + Vector3.new(math.cos(item.angle), 0, math.sin(item.angle))
			item.sword.CFrame = CFrame.lookAt(sPos, lookAt)
			item.tip.CFrame = item.sword.CFrame * CFrame.new(0, 0, -2.85) * CFrame.Angles(0, math.rad(180), 0)
		end
		task.wait(0.04)
	end

	-- 3. Starburst eruption outward
	createSound(hrp, "rbxassetid://2801263", 1.4, 1.0)
	for _, item in ipairs(swords) do
		local dir = (item.sword.Position - hrp.Position).Unit
		task.spawn(function()
			local travel = 0
			while travel < 40 and item.sword.Parent do
				item.sword.CFrame = item.sword.CFrame + (dir * 2.5)
				item.tip.CFrame = item.sword.CFrame * CFrame.new(0, 0, -2.85) * CFrame.Angles(0, math.rad(180), 0)
				travel = travel + 2.5

				for _, p in ipairs(Players:GetPlayers()) do
					local c = p.Character
					local pHum = c and c:FindFirstChildOfClass("Humanoid")
					local pRoot = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
					if pHum and pRoot and pHum.Health > 0 then
						if (pRoot.Position - item.sword.Position).Magnitude <= 5 then
							dealDamage(pHum, 48, "Celestial Sword Domain")
							break
						end
					end
				end
				task.wait(0.03)
			end
			item.sword:Destroy()
			item.tip:Destroy()
		end)
	end

	task.wait(0.4)
	anim.setAttacking(false)
end

local function executeBossDragonCleave(model: Model, hrp: BasePart, targetRoot: BasePart, anim: EnemyAnimController)
	anim.setAttacking(true)

	-- Airborne leap windup
	anim.triggerJump()
	hrp.AssemblyLinearVelocity = Vector3.new(0, 38, 0)
	createSound(hrp, "rbxassetid://9114222513", 1.2, 0.75)

	task.wait(0.45)
	if not model.Parent or not targetRoot.Parent then anim.setAttacking(false) return end

	-- Mid-air dash toward target
	local slamTarget = targetRoot.Position
	hrp.CFrame = CFrame.new(slamTarget + Vector3.new(0, 8, 0), slamTarget)
	hrp.AssemblyLinearVelocity = Vector3.new(0, -60, 0)

	task.wait(0.18)
	-- Ground crater shockwave blast
	createSound(hrp, "rbxassetid://2801263", 1.5, 0.7)
	local blastRing = Instance.new("Part")
	blastRing.Shape = Enum.PartType.Cylinder
	blastRing.Size = Vector3.new(0.6, 20, 20)
	blastRing.CFrame = CFrame.new(slamTarget - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	blastRing.Material = Enum.Material.Neon
	blastRing.Color = Color3.fromRGB(255, 180, 50)
	blastRing.Transparency = 0.2
	blastRing.Anchored = true
	blastRing.CanCollide = false
	blastRing.Parent = Workspace

	local tw = TweenService:Create(blastRing, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.6, 36, 36),
		Transparency = 1,
	})
	tw:Play()
	Debris:AddItem(blastRing, 0.5)

	-- Area damage & heavy knockback
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local pHum = c and c:FindFirstChildOfClass("Humanoid")
		local pRoot = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
		if pHum and pRoot and pHum.Health > 0 then
			local dist = (pRoot.Position - slamTarget).Magnitude
			if dist <= 18 then
				dealDamage(pHum, 55, "Heavenly Dragon Cleave")
				local pushDir = (pRoot.Position - slamTarget).Unit
				pRoot.AssemblyLinearVelocity = Vector3.new(pushDir.X * 35, 25, pushDir.Z * 35)
			end
		end
	end

	task.wait(0.35)
	anim.setAttacking(false)
end

-- ============================================================================
-- LIVE HEALTH BILLBOARD GUI BINDING
-- ============================================================================
local function setupHealthBar(model: Model, humanoid: Humanoid, variantName: string)
	local bbg = model:FindFirstChild("EnemyHealthGui") :: BillboardGui?
	if not bbg then
		bbg = Instance.new("BillboardGui")
		bbg.Name = "EnemyHealthGui"
		bbg.Size = UDim2.new(0, 160, 0, 42)
		bbg.StudsOffset = Vector3.new(0, 3.2, 0)
		bbg.AlwaysOnTop = true
		bbg.Parent = model
	end

	local nameLabel = bbg:FindFirstChild("NameLabel") :: TextLabel?
	if nameLabel then
		-- Clean any Unicode emojis
		nameLabel.Text = variantName
	end

	local hpBar = bbg:FindFirstChild("HpBar") :: Frame?
	if hpBar then
		local fill = hpBar:FindFirstChild("Fill") :: Frame?
		local valueLabel = hpBar:FindFirstChild("Value") :: TextLabel?

		local function updateHp()
			local current = math.clamp(humanoid.Health, 0, humanoid.MaxHealth)
			local ratio = humanoid.MaxHealth > 0 and (current / humanoid.MaxHealth) or 0
			if fill then
				fill.Size = UDim2.new(ratio, 0, 1, 0)
			end
			if valueLabel then
				valueLabel.Text = string.format("%d / %d", math.floor(current), math.floor(humanoid.MaxHealth))
			end
		end

		humanoid.HealthChanged:Connect(updateHp)
		updateHp()
	end
end

-- ============================================================================
-- CORE AI BINDING & COMBAT LOOP
-- ============================================================================
local function bindEnemyAI(model: Model, spawnCFrame: CFrame, isBoss: boolean, enemyVariantName: string)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not hrp then return end

	-- Ensure custom sword is attached with proper hand grip
	attachCustomSword(model, enemyVariantName)

	-- Base stats
	local baseDamage = isBoss and 35 or 18
	humanoid.MaxHealth = isBoss and 880 or (enemyVariantName:find("Iron") and 135 or (enemyVariantName:find("Crimson") and 110 or 100))
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = isBoss and 18.5 or 14

	setupHealthBar(model, humanoid, enemyVariantName)

	local anim = setupEnemyAnimations(model, humanoid, hrp)

	local CHASE_RANGE = isBoss and 50 or 40
	local ATTACK_RANGE = 6.5
	local LEASH_RANGE = isBoss and 65 or 45
	local comboIndex = 0
	local lastSkillTime = os.clock()
	local skillCooldown = isBoss and 9.0 or 7.0
	local isDead = false

	humanoid.Died:Connect(function()
		if isDead then return end
		isDead = true
		anim.stopAll()

		local killer = nil
		local creatorTag = humanoid:FindFirstChild("creator") :: ObjectValue?
		if creatorTag and creatorTag.Value and creatorTag.Value:IsA("Player") then
			killer = creatorTag.Value :: Player
		else
			-- Nearest player
			local minDist = 40
			for _, p in ipairs(Players:GetPlayers()) do
				local c = p.Character
				local r = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
				if r then
					local d = (r.Position - hrp.Position).Magnitude
					if d < minDist then
						minDist = d
						killer = p
					end
				end
			end
		end

		awardKillRewards(killer, isBoss)

		task.delay(2.5, function()
			if model.Parent then
				local enemiesFolder = model.Parent
				local modelName = model.Name
				model:Destroy()

				-- Clean respawn
				local respawnDelay = isBoss and 30 or 15
				task.wait(respawnDelay)

				local existingEnemies = Workspace:FindFirstChild("DestroyedVillage_Enemies")
				if existingEnemies then
					-- Spawn fresh model clone
					local newModel = Instance.new("Model")
					newModel.Name = modelName
					newModel.Parent = existingEnemies

					-- Standard R6 construction
					local function makeLimb(name: string, size: Vector3, color: Color3, cf: CFrame): Part
						local p = Instance.new("Part")
						p.Name = name
						p.Size = size
						p.Color = color
						p.Material = Enum.Material.SmoothPlastic
						p.CFrame = cf
						p.CanCollide = (name == "Torso" or name == "HumanoidRootPart")
						p.Parent = newModel
						return p
					end

					local sPos = spawnCFrame.Position
					local sHrp = makeLimb("HumanoidRootPart", Vector3.new(2, 2, 1), Color3.fromRGB(160, 160, 160), spawnCFrame)
					sHrp.Transparency = 1
					newModel.PrimaryPart = sHrp

					local sTorso = makeLimb("Torso", Vector3.new(2, 2, 1), Color3.fromRGB(30, 30, 35), spawnCFrame)
					local sHead = makeLimb("Head", Vector3.new(2, 1, 1), Color3.fromRGB(225, 190, 160), spawnCFrame * CFrame.new(0, 1.5, 0))
					local sLA = makeLimb("Left Arm", Vector3.new(1, 2, 1), Color3.fromRGB(35, 35, 40), spawnCFrame * CFrame.new(-1.5, 0, 0))
					local sRA = makeLimb("Right Arm", Vector3.new(1, 2, 1), Color3.fromRGB(35, 35, 40), spawnCFrame * CFrame.new(1.5, 0, 0))
					local sLL = makeLimb("Left Leg", Vector3.new(1, 2, 1), Color3.fromRGB(20, 20, 25), spawnCFrame * CFrame.new(-0.5, -2, 0))
					local sRL = makeLimb("Right Leg", Vector3.new(1, 2, 1), Color3.fromRGB(20, 20, 25), spawnCFrame * CFrame.new(0.5, -2, 0))

					local function makeMotor(p0: BasePart, p1: BasePart, name: string, c0: CFrame, c1: CFrame): Motor6D
						local m = Instance.new("Motor6D")
						m.Name = name
						m.Part0 = p0
						m.Part1 = p1
						m.C0 = c0
						m.C1 = c1
						m.Parent = p0
						return m
					end

					makeMotor(sHrp, sTorso, "RootJoint", CFrame.new(), CFrame.new())
					makeMotor(sTorso, sHead, "Neck", CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))
					makeMotor(sTorso, sRA, "Right Shoulder", CFrame.new(1, 0.5, 0) * CFrame.Angles(0, math.rad(90), 0), CFrame.new(-0.5, 0.5, 0) * CFrame.Angles(0, math.rad(90), 0))
					makeMotor(sTorso, sLA, "Left Shoulder", CFrame.new(-1, 0.5, 0) * CFrame.Angles(0, math.rad(-90), 0), CFrame.new(0.5, 0.5, 0) * CFrame.Angles(0, math.rad(-90), 0))
					makeMotor(sTorso, sRL, "Right Hip", CFrame.new(1, -1, 0) * CFrame.Angles(0, math.rad(90), 0), CFrame.new(0.5, 1, 0) * CFrame.Angles(0, math.rad(90), 0))
					makeMotor(sTorso, sLL, "Left Hip", CFrame.new(-1, -1, 0) * CFrame.Angles(0, math.rad(-90), 0), CFrame.new(-0.5, 1, 0) * CFrame.Angles(0, math.rad(-90), 0))

					local newHum = Instance.new("Humanoid")
					newHum.MaxHealth = humanoid.MaxHealth
					newHum.Health = humanoid.MaxHealth
					newHum.Parent = newModel

					bindEnemyAI(newModel, spawnCFrame, isBoss, enemyVariantName)
				end
			end
		end)
	end)

	-- Active Combat AI Loop
	task.spawn(function()
		while not isDead and model.Parent and humanoid.Health > 0 do
			local nearestPlayerHum: Humanoid? = nil
			local nearestPlayerRoot: BasePart? = nil
			local minDist = CHASE_RANGE

			for _, p in ipairs(Players:GetPlayers()) do
				local c = p.Character
				local pHum = c and c:FindFirstChildOfClass("Humanoid")
				local pRoot = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
				if pHum and pRoot and pHum.Health > 0 then
					local dist = (pRoot.Position - hrp.Position).Magnitude
					if dist < minDist then
						minDist = dist
						nearestPlayerHum = pHum
						nearestPlayerRoot = pRoot
					end
				end
			end

			if nearestPlayerHum and nearestPlayerRoot then
				local dist = (nearestPlayerRoot.Position - hrp.Position).Magnitude
				local distFromSpawn = (hrp.Position - spawnCFrame.Position).Magnitude

				if distFromSpawn > LEASH_RANGE then
					-- Exceeded leash: return to spawn
					humanoid:MoveTo(spawnCFrame.Position)
				elseif dist <= ATTACK_RANGE then
					-- Smart Melee Distancing: halt movement and face target
					humanoid:MoveTo(hrp.Position)
					local targetLook = Vector3.new(nearestPlayerRoot.Position.X, hrp.Position.Y, nearestPlayerRoot.Position.Z)
					hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position, targetLook), 0.3)

					-- Decide between Unique Skill and Melee Combo
					local now = os.clock()
					if now - lastSkillTime >= skillCooldown and not anim.isAttacking() then
						lastSkillTime = now
						if isBoss then
							if math.random() > 0.5 then
								executeBossSwordDomain(model, hrp, anim)
							else
								executeBossDragonCleave(model, hrp, nearestPlayerRoot, anim)
							end
						elseif string.find(enemyVariantName, "Shadow") then
							executeShadowStep(model, hrp, nearestPlayerRoot, nearestPlayerHum, anim)
						elseif string.find(enemyVariantName, "Crimson") then
							executeCrimsonWhirlwind(model, hrp, anim)
						elseif string.find(enemyVariantName, "Iron") then
							executeIronQuake(model, hrp, anim)
						elseif string.find(enemyVariantName, "Azure") then
							executeAzureWindGale(model, hrp, anim)
						elseif string.find(enemyVariantName, "Ghost") then
							executeGhostFlameBurst(model, hrp, anim)
						end
					elseif not anim.isAttacking() then
						comboIndex = (comboIndex % 3) + 1
						anim.playAttack(comboIndex, function(attackType)
							if not isDead and nearestPlayerHum and nearestPlayerHum.Health > 0 then
								local strikeDist = (nearestPlayerRoot.Position - hrp.Position).Magnitude
								if strikeDist <= ATTACK_RANGE + 2.5 then
									local comboDmg = baseDamage + (comboIndex * 4)
									if attackType == "CrossSlash_1" then
										dealDamage(nearestPlayerHum, math.floor(comboDmg * 0.55), enemyVariantName .. " Cross Slash 1")
									elseif attackType == "CrossSlash_2" then
										dealDamage(nearestPlayerHum, math.floor(comboDmg * 0.65), enemyVariantName .. " Cross Slash 2")
									else
										dealDamage(nearestPlayerHum, comboDmg, enemyVariantName .. " " .. attackType)
									end
								end
							end
						end)
					end
				else
					-- Advance toward player
					humanoid:MoveTo(nearestPlayerRoot.Position)
					-- Auto-jump over low obstacles if blocked
					if humanoid.MoveDirection.Magnitude > 0.1 and hrp.AssemblyLinearVelocity.Magnitude < 1.0 then
						humanoid.Jump = true
					end
				end
			else
				-- Idle / Return toward spawn if wandered
				local distFromSpawn = (hrp.Position - spawnCFrame.Position).Magnitude
				if distFromSpawn > 12 then
					humanoid:MoveTo(spawnCFrame.Position)
				end
			end

			task.wait(0.2)
		end
	end)
end

-- ============================================================================
-- MANAGER INIT: BIND TO EDIT-MODE DESTROYED VILLAGE ENEMIES
-- ============================================================================
local DestroyedVillageManager = {}

function DestroyedVillageManager.init(villageCenter: Vector3?)
	local enemiesFolder = Workspace:FindFirstChild("DestroyedVillage_Enemies")
	if not enemiesFolder then
		warn("[DestroyedVillageManager] DestroyedVillage_Enemies folder not found in Workspace!")
		return
	end

	local children = enemiesFolder:GetChildren()
	for _, child in ipairs(children) do
		if child:IsA("Model") and child.PrimaryPart then
			local isBoss = string.find(child.Name:lower(), "boss") ~= nil or string.find(child.Name:lower(), "swordmaster") ~= nil
			local healthGui = child:FindFirstChild("EnemyHealthGui", true) :: BillboardGui?
			local nameLabel = healthGui and healthGui:FindFirstChild("NameLabel", true) :: TextLabel?
			local variantName = nameLabel and nameLabel.Text or (isBoss and "Grandmaster Swordmaster" or "Swordsman")

			bindEnemyAI(child, child.PrimaryPart.CFrame, isBoss, variantName)
			print(string.format("[DestroyedVillageManager] Initialized %s (%s) with custom martial arts animations & Xianxia sword.", child.Name, variantName))
		end
	end

	print("[DestroyedVillageManager] Successfully initialized all Destroyed Village Pillar Swordsmen & Boss!")
end

return DestroyedVillageManager
