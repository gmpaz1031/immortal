"""
bridge/upgrade_village_enemies.py
Replaces Destroyed Village enemies with enhanced SAMPLEENEMYMODEL rigs.
Features:
- Preserves exact positions of all 6 enemies
- Custom cultivation aesthetic for each enemy based on their titles:
  1. Swordsman_1: Shadow Blade Swordsman (Kasa hat, shadow scarf, katana, shadow mist)
  2. Swordsman_2: Crimson Dao Vanguard (headband, crimson dao broadsword, fiery sparks)
  3. Swordsman_3: Iron Gale Swordsman (iron helm, iron pauldrons, iron cleaver greatsword)
  4. Swordsman_4: Azure Wind Swordsman (topknot, jade hairpin, azure jian, wind qi)
  5. Swordsman_5: Ghost Flame Swordsman (ghost mask, ghost flame dao, violet spirit flames)
  6. Swordmaster_Boss: Grandmaster Swordmaster [BOSS] (1.32x scale, dragon crown, dragon pauldrons, cape, Master Odachi, celestial aura)
- Full R6 Walk, Jump, and Sword Slash animation controller
- Health Bar BillboardGui
"""

import sys
from exec import exec_code

UPGRADE_LUA = r'''
local ContentProvider = game:GetService("ContentProvider")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ServerStorage = game:GetService("ServerStorage")

local sampleRig = Workspace:FindFirstChild("SAMPLEENEMYMODEL")
if not sampleRig then
    return "ERROR: SAMPLEENEMYMODEL not found in Workspace!"
end

local enemiesFolder = Workspace:FindFirstChild("DestroyedVillage_Enemies")
if not enemiesFolder then
    enemiesFolder = Instance.new("Folder")
    enemiesFolder.Name = "DestroyedVillage_Enemies"
    enemiesFolder.Parent = Workspace
end

-- Exact recorded CFrames
local TARGET_CFRAMES = {
    ["Swordsman_1"] = CFrame.new(-679, 6.88988304, 195.000076, -0.529919326, 0, 0.848048031, 0, 1, 0, -0.848048031, 0, -0.529919326),
    ["Swordsman_2"] = CFrame.new(-614, 6.88988304, 190.000076, -0.601815104, 0, 0.798635483, 0, 1, 0, -0.798635483, 0, -0.601815104),
    ["Swordsman_3"] = CFrame.new(-674, 6.88988304, 245.000092, -0.999390841, 0, -0.0348993875, 0, 1, 0, 0.0348993875, 0, -0.999390841),
    ["Swordsman_4"] = CFrame.new(-621, 6.88988304, 250.000092, -0.754709542, 0, -0.656059086, 0, 1, 0, 0.656059086, 0, -0.754709542),
    ["Swordsman_5"] = CFrame.new(-649, 6.88988304, 260.000092, -0.754709661, 0, 0.656058967, 0, 1, 0, -0.656058967, 0, -0.754709661),
    ["Swordmaster_Boss"] = CFrame.new(-647.729919, 14.1833973, 226.042786, -1, 0, 0, 0, 1, 0, 0, 0, -1)
}

-- Helpers
local function createPart(name, size, color, material, parent)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.CanCollide = false
    p.Massless = true
    p.Anchored = false
    p.CastShadow = false
    p.Parent = parent
    return p
end

local function weldParts(p0, p1, c0)
    p1.CFrame = p0.CFrame * (c0 or CFrame.new())
    local w = Instance.new("WeldConstraint")
    w.Part0 = p0
    w.Part1 = p1
    w.Parent = p1
    return w
end

-- Health Bar Billboard UI
local function attachHealthBar(model, adorneePart, title, maxHp, isBoss, titleColor, barColor)
    local bbg = Instance.new("BillboardGui")
    bbg.Name = "EnemyHealthGui"
    bbg.AlwaysOnTop = false
    bbg.MaxDistance = isBoss and 58 or 44
    bbg.Size = isBoss and UDim2.new(5.6, 0, 1.15, 0) or UDim2.new(4.2, 0, 0.88, 0)
    bbg.StudsOffset = Vector3.new(0, isBoss and 3.8 or 2.7, 0)
    bbg.Adornee = adorneePart
    bbg.Parent = model

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Name = "NameLabel"
    nameLbl.BackgroundTransparency = 1
    nameLbl.Size = UDim2.new(1, 0, 0.48, 0)
    nameLbl.Position = UDim2.new(0, 0, 0, 0)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.Text = title
    nameLbl.TextColor3 = titleColor or (isBoss and Color3.fromRGB(255, 215, 90) or Color3.fromRGB(255, 230, 160))
    nameLbl.TextScaled = true
    nameLbl.Parent = bbg

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(15, 10, 12)
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
    hpFill.BackgroundColor3 = barColor or (isBoss and Color3.fromRGB(235, 45, 55) or Color3.fromRGB(220, 70, 50))
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

-- Create Server AI & Animation Controller Script for NPCs
local function createControllerScript(isBoss, maxHp, damage, enemyTitle)
    local s = Instance.new("Script")
    s.Name = "EnemyController"
    
    local header = string.format([==[
local model = script.Parent
local humanoid = model:WaitForChild("Humanoid")
local hrp = model:WaitForChild("HumanoidRootPart")
local head = model:WaitForChild("Head")

local isBoss = %s
local baseDamage = %d
local enemyTitle = "%s"
]==], tostring(isBoss), damage, enemyTitle)

    local body = [==[
local spawnCFrame = hrp.CFrame
local isDead = false

-- 1. Setup Animator & Animations
local animator = humanoid:FindFirstChildOfClass("Animator")
if not animator then
    animator = Instance.new("Animator")
    animator.Parent = humanoid
end

local function makeAnim(id, priority, looped)
    local a = Instance.new("Animation")
    a.AnimationId = id
    local track = animator:LoadAnimation(a)
    track.Priority = priority
    track.Looped = looped
    return track
end

local idleTrack = makeAnim("rbxassetid://180435571", Enum.AnimationPriority.Idle, true)
local walkTrack = makeAnim("rbxassetid://180426354", Enum.AnimationPriority.Movement, true)
local jumpTrack = makeAnim("rbxassetid://125750702", Enum.AnimationPriority.Action, false)
local slashTrack = makeAnim("rbxassetid://129967390", Enum.AnimationPriority.Action, false)

idleTrack:Play()

-- Movement & Jump listeners
humanoid.Running:Connect(function(speed)
    if isDead then return end
    if speed > 0.8 then
        if not walkTrack.IsPlaying then
            walkTrack:Play(0.2)
        end
    else
        if walkTrack.IsPlaying then
            walkTrack:Stop(0.2)
        end
    end
end)

humanoid.StateChanged:Connect(function(oldState, newState)
    if isDead then return end
    if newState == Enum.HumanoidStateType.Jumping then
        jumpTrack:Play(0.08)
    end
end)

-- Find weapon trail
local trail = nil
for _, d in ipairs(model:GetDescendants()) do
    if d:IsA("Trail") then
        trail = d
        break
    end
end

-- Damage application helper
local DamageService = nil
pcall(function()
    local sss = game:GetService("ServerScriptService")
    local ds = sss:FindFirstChild("DamageService", true)
    if ds and ds:IsA("ModuleScript") then
        DamageService = require(ds)
    end
end)

local function dealDamage(targetHum, dmg, name)
    if DamageService and DamageService.applyDamage then
        DamageService.applyDamage(targetHum, dmg, nil, name)
    else
        targetHum:TakeDamage(dmg)
    end
end

-- STANDBY BOSS LOGIC
if isBoss then
    -- Swordmaster Boss stays in majestic standby on the shrine dais
    while not isDead and model.Parent and humanoid.Health > 0 do
        local nearestPlayer = nil
        local minDist = 25
        for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
            local char = player.Character
            local pHrp = char and char:FindFirstChild("HumanoidRootPart")
            local pHum = char and char:FindFirstChildOfClass("Humanoid")
            if pHrp and pHum and pHum.Health > 0 then
                local d = (pHrp.Position - hrp.Position).Magnitude
                if d < minDist then
                    minDist = d
                    nearestPlayer = pHrp
                end
            end
        end

        if nearestPlayer then
            local targetPos = Vector3.new(nearestPlayer.Position.X, hrp.Position.Y, nearestPlayer.Position.Z)
            local lookCF = CFrame.new(hrp.Position, targetPos)
            hrp.CFrame = hrp.CFrame:Lerp(lookCF, 0.1)
        end
        task.wait(0.25)
    end
    return
end

-- COMBAT & PATROL AI FOR SWORDSMEN
local CHASE_RANGE = 35
local ATTACK_RANGE = 6.5
local ATTACK_COOLDOWN = 1.85
local lastAttack = 0

humanoid.Died:Connect(function()
    if isDead then return end
    isDead = true
    pcall(function()
        idleTrack:Stop()
        walkTrack:Stop()
        jumpTrack:Stop()
        slashTrack:Stop()
    end)
    task.delay(2.5, function()
        if model.Parent then model:Destroy() end
    end)
end)

task.spawn(function()
    while not isDead and model.Parent and humanoid.Health > 0 do
        local targetHum = nil
        local targetRoot = nil
        local minDist = CHASE_RANGE

        for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
            local char = player.Character
            local pHrp = char and char:FindFirstChild("HumanoidRootPart")
            local pHum = char and char:FindFirstChildOfClass("Humanoid")
            if pHrp and pHum and pHum.Health > 0 then
                local d = (pHrp.Position - hrp.Position).Magnitude
                if d < minDist then
                    minDist = d
                    targetHum = pHum
                    targetRoot = pHrp
                end
            end
        end

        if targetHum and targetRoot then
            local dist = (targetRoot.Position - hrp.Position).Magnitude
            if dist <= ATTACK_RANGE and (tick() - lastAttack) >= ATTACK_COOLDOWN then
                lastAttack = tick()
                -- Face target
                hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetRoot.Position.X, hrp.Position.Y, targetRoot.Position.Z))
                
                -- Play slash animation
                slashTrack:Play(0.05, 1, 1.35)
                if trail then trail.Enabled = true end

                -- Hit timing at swing apex
                task.delay(0.22, function()
                    if trail then trail.Enabled = false end
                    if not isDead and targetHum and targetHum.Health > 0 and (targetRoot.Position - hrp.Position).Magnitude <= ATTACK_RANGE + 2.5 then
                        dealDamage(targetHum, baseDamage, enemyTitle)
                    end
                end)
            else
                -- Move towards target
                humanoid:MoveTo(targetRoot.Position)
                -- Auto-jump over obstacles
                if humanoid.MoveDirection.Magnitude > 0.1 and hrp.AssemblyLinearVelocity.Magnitude < 1.0 then
                    humanoid.Jump = true
                end
            end
        else
            -- Return towards spawn if wandered far
            if (hrp.Position - spawnCFrame.Position).Magnitude > 22 then
                humanoid:MoveTo(spawnCFrame.Position)
            end
        end

        task.wait(0.25)
    end
end)
]==]

    s.Source = header .. body
    s.Parent = model
    return s
end

-- Clear out any previous models in DestroyedVillage_Enemies
local existingEnemies = {}
for _, m in ipairs(enemiesFolder:GetChildren()) do
    existingEnemies[m.Name] = m
end

local results = {}

for name, targetCF in pairs(TARGET_CFRAMES) do
    local oldModel = existingEnemies[name]

    -- Clone from SAMPLEENEMYMODEL
    local newModel = sampleRig:Clone()
    newModel.Name = name

    -- Clean out sample LocalScript
    local oldAnim = newModel:FindFirstChild("Animate")
    if oldAnim then oldAnim:Destroy() end

    local hrp = newModel:FindFirstChild("HumanoidRootPart")
    local torso = newModel:FindFirstChild("Torso")
    local head = newModel:FindFirstChild("Head")
    local rArm = newModel:FindFirstChild("Right Arm")
    local lArm = newModel:FindFirstChild("Left Arm")
    local rLeg = newModel:FindFirstChild("Right Leg")
    local lLeg = newModel:FindFirstChild("Left Leg")
    local hum = newModel:FindFirstChildOfClass("Humanoid")
    local bodyColors = newModel:FindFirstChildOfClass("BodyColors")

    if not bodyColors then
        bodyColors = Instance.new("BodyColors")
        bodyColors.Parent = newModel
    end

    -- Set PrimaryPart strictly to HumanoidRootPart
    newModel.PrimaryPart = hrp

    ----------------------------------------------------------------------------
    -- 1. SWORDSMAN_1: SHADOW BLADE SWORDSMAN
    ----------------------------------------------------------------------------
    if name == "Swordsman_1" then
        hum.MaxHealth = 95
        hum.Health = 95
        hum.WalkSpeed = 14

        bodyColors.HeadColor3 = Color3.fromRGB(215, 185, 155)
        bodyColors.TorsoColor3 = Color3.fromRGB(24, 24, 28)
        bodyColors.LeftArmColor3 = Color3.fromRGB(35, 36, 42)
        bodyColors.RightArmColor3 = Color3.fromRGB(35, 36, 42)
        bodyColors.LeftLegColor3 = Color3.fromRGB(20, 20, 24)
        bodyColors.RightLegColor3 = Color3.fromRGB(20, 20, 24)

        -- Conical Bamboo Kasa Hat
        local hat = createPart("KasaHat", Vector3.new(2.8, 0.45, 2.8), Color3.fromRGB(38, 36, 33), Enum.Material.Wood, newModel)
        local hatMesh = Instance.new("SpecialMesh")
        hatMesh.MeshType = Enum.MeshType.Cylinder
        hatMesh.Parent = hat
        weldParts(head, hat, CFrame.new(0, 0.65, 0) * CFrame.Angles(math.rad(8), 0, 0))

        local hatKnob = createPart("KasaKnob", Vector3.new(0.4, 0.35, 0.4), Color3.fromRGB(30, 28, 26), Enum.Material.Wood, newModel)
        weldParts(hat, hatKnob, CFrame.new(0, 0.3, 0))

        -- Shadow Scarf
        local scarf = createPart("ShadowScarf", Vector3.new(1.4, 0.4, 1.4), Color3.fromRGB(18, 18, 22), Enum.Material.Fabric, newModel)
        weldParts(head, scarf, CFrame.new(0, -0.45, 0))

        -- Shadow Katana: Hilt + Tsuba + Blade
        local hilt = createPart("KatanaHilt", Vector3.new(0.2, 0.9, 0.2), Color3.fromRGB(20, 20, 25), Enum.Material.Fabric, newModel)
        weldParts(rArm, hilt, CFrame.new(0, -1.0, -0.2) * CFrame.Angles(math.rad(65), 0, 0))

        local tsuba = createPart("KatanaTsuba", Vector3.new(0.55, 0.08, 0.55), Color3.fromRGB(85, 75, 60), Enum.Material.Metal, newModel)
        weldParts(hilt, tsuba, CFrame.new(0, 0.45, 0))

        local blade = createPart("WeaponBlade", Vector3.new(0.15, 3.2, 0.35), Color3.fromRGB(45, 45, 55), Enum.Material.Metal, newModel)
        weldParts(tsuba, blade, CFrame.new(0, 1.6, 0))

        local att0 = Instance.new("Attachment", blade)
        att0.Position = Vector3.new(0, -1.5, 0)
        local att1 = Instance.new("Attachment", blade)
        att1.Position = Vector3.new(0, 1.5, 0)

        local trail = Instance.new("Trail")
        trail.Attachment0 = att0
        trail.Attachment1 = att1
        trail.Color = ColorSequence.new(Color3.fromRGB(70, 25, 95), Color3.fromRGB(15, 15, 25))
        trail.Lifetime = 0.25
        trail.Enabled = false
        trail.Parent = blade

        -- Torso Shadow Mist
        local mist = Instance.new("ParticleEmitter")
        mist.Name = "ShadowMist"
        mist.Color = ColorSequence.new(Color3.fromRGB(35, 25, 45), Color3.fromRGB(12, 12, 18))
        mist.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1.3) })
        mist.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
        mist.Lifetime = NumberRange.new(0.8, 1.4)
        mist.Rate = 10
        mist.Speed = NumberRange.new(0.5, 1.5)
        mist.Parent = torso

        attachHealthBar(newModel, head, "Shadow Blade Swordsman", 95, false, Color3.fromRGB(200, 180, 230), Color3.fromRGB(160, 40, 60))
        createControllerScript(false, 95, 15, "Shadow Blade Swordsman").Parent = newModel

    ----------------------------------------------------------------------------
    -- 2. SWORDSMAN_2: CRIMSON DAO VANGUARD
    ----------------------------------------------------------------------------
    elseif name == "Swordsman_2" then
        hum.MaxHealth = 110
        hum.Health = 110
        hum.WalkSpeed = 14

        bodyColors.HeadColor3 = Color3.fromRGB(205, 165, 130)
        bodyColors.TorsoColor3 = Color3.fromRGB(150, 28, 32)
        bodyColors.LeftArmColor3 = Color3.fromRGB(120, 25, 30)
        bodyColors.RightArmColor3 = Color3.fromRGB(120, 25, 30)
        bodyColors.LeftLegColor3 = Color3.fromRGB(32, 26, 26)
        bodyColors.RightLegColor3 = Color3.fromRGB(32, 26, 26)

        -- Crimson Warrior Headband
        local headband = createPart("CrimsonHeadband", Vector3.new(1.35, 0.35, 1.35), Color3.fromRGB(180, 25, 30), Enum.Material.Fabric, newModel)
        weldParts(head, headband, CFrame.new(0, 0.2, 0))

        local ribbon = createPart("RibbonTail", Vector3.new(0.3, 1.3, 0.08), Color3.fromRGB(180, 25, 30), Enum.Material.Fabric, newModel)
        weldParts(head, ribbon, CFrame.new(0, -0.2, 0.7) * CFrame.Angles(math.rad(-15), 0, 0))

        -- Gold Buckle Sash
        local sash = createPart("GoldSash", Vector3.new(2.1, 0.35, 1.1), Color3.fromRGB(200, 155, 45), Enum.Material.Metal, newModel)
        weldParts(torso, sash, CFrame.new(0, -0.6, 0))

        -- Crimson Dao Broadsword: Hilt + Brass Guard + Flared Curved Blade
        local hilt = createPart("DaoHilt", Vector3.new(0.22, 0.9, 0.22), Color3.fromRGB(160, 25, 30), Enum.Material.Fabric, newModel)
        weldParts(rArm, hilt, CFrame.new(0, -1.0, -0.25) * CFrame.Angles(math.rad(65), 0, 0))

        local guard = createPart("DaoGuard", Vector3.new(0.6, 0.1, 0.5), Color3.fromRGB(215, 170, 50), Enum.Material.Metal, newModel)
        weldParts(hilt, guard, CFrame.new(0, 0.45, 0))

        local blade = createPart("WeaponBlade", Vector3.new(0.2, 3.4, 0.6), Color3.fromRGB(225, 55, 55), Enum.Material.Metal, newModel)
        weldParts(guard, blade, CFrame.new(0, 1.7, 0))

        local att0 = Instance.new("Attachment", blade)
        att0.Position = Vector3.new(0, -1.7, 0)
        local att1 = Instance.new("Attachment", blade)
        att1.Position = Vector3.new(0, 1.7, 0)

        local trail = Instance.new("Trail")
        trail.Attachment0 = att0
        trail.Attachment1 = att1
        trail.Color = ColorSequence.new(Color3.fromRGB(255, 45, 45), Color3.fromRGB(190, 20, 20))
        trail.Lifetime = 0.28
        trail.Enabled = false
        trail.Parent = blade

        -- Blade Crimson Sparks
        local sparks = Instance.new("ParticleEmitter")
        sparks.Name = "CrimsonQi"
        sparks.Color = ColorSequence.new(Color3.fromRGB(255, 70, 60), Color3.fromRGB(200, 20, 20))
        sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
        sparks.Lifetime = NumberRange.new(0.4, 0.8)
        sparks.Rate = 12
        sparks.Speed = NumberRange.new(1, 3)
        sparks.Parent = blade

        attachHealthBar(newModel, head, "Crimson Dao Vanguard", 110, false, Color3.fromRGB(255, 140, 140), Color3.fromRGB(230, 45, 45))
        createControllerScript(false, 110, 18, "Crimson Dao Vanguard").Parent = newModel

    ----------------------------------------------------------------------------
    -- 3. SWORDSMAN_3: IRON GALE SWORDSMAN
    ----------------------------------------------------------------------------
    elseif name == "Swordsman_3" then
        hum.MaxHealth = 135
        hum.Health = 135
        hum.WalkSpeed = 12.5

        bodyColors.HeadColor3 = Color3.fromRGB(190, 155, 125)
        bodyColors.TorsoColor3 = Color3.fromRGB(68, 72, 82)
        bodyColors.LeftArmColor3 = Color3.fromRGB(60, 65, 75)
        bodyColors.RightArmColor3 = Color3.fromRGB(60, 65, 75)
        bodyColors.LeftLegColor3 = Color3.fromRGB(45, 50, 58)
        bodyColors.RightLegColor3 = Color3.fromRGB(45, 50, 58)

        -- Armored Iron Helm
        local helm = createPart("IronHelm", Vector3.new(1.35, 0.6, 1.35), Color3.fromRGB(75, 80, 90), Enum.Material.Metal, newModel)
        weldParts(head, helm, CFrame.new(0, 0.45, 0))

        -- Heavy Iron Pauldrons
        local lPauldron = createPart("LeftIronPauldron", Vector3.new(1.2, 0.5, 1.2), Color3.fromRGB(80, 85, 95), Enum.Material.Metal, newModel)
        weldParts(lArm, lPauldron, CFrame.new(-0.25, 0.7, 0))

        local rPauldron = createPart("RightIronPauldron", Vector3.new(1.2, 0.5, 1.2), Color3.fromRGB(80, 85, 95), Enum.Material.Metal, newModel)
        weldParts(rArm, rPauldron, CFrame.new(0.25, 0.7, 0))

        -- Iron Cleaver Greatsword
        local hilt = createPart("CleaverHilt", Vector3.new(0.25, 1.0, 0.25), Color3.fromRGB(40, 42, 48), Enum.Material.Metal, newModel)
        weldParts(rArm, hilt, CFrame.new(0, -1.0, -0.25) * CFrame.Angles(math.rad(60), 0, 0))

        local guard = createPart("CleaverGuard", Vector3.new(0.8, 0.15, 0.4), Color3.fromRGB(90, 95, 105), Enum.Material.Metal, newModel)
        weldParts(hilt, guard, CFrame.new(0, 0.5, 0))

        local blade = createPart("WeaponBlade", Vector3.new(0.25, 3.6, 0.8), Color3.fromRGB(160, 170, 180), Enum.Material.Metal, newModel)
        weldParts(guard, blade, CFrame.new(0, 1.8, 0))

        local att0 = Instance.new("Attachment", blade)
        att0.Position = Vector3.new(0, -1.8, 0)
        local att1 = Instance.new("Attachment", blade)
        att1.Position = Vector3.new(0, 1.8, 0)

        local trail = Instance.new("Trail")
        trail.Attachment0 = att0
        trail.Attachment1 = att1
        trail.Color = ColorSequence.new(Color3.fromRGB(220, 230, 240), Color3.fromRGB(120, 130, 140))
        trail.Lifetime = 0.3
        trail.Enabled = false
        trail.Parent = blade

        attachHealthBar(newModel, head, "Iron Gale Swordsman", 135, false, Color3.fromRGB(210, 220, 230), Color3.fromRGB(180, 110, 45))
        createControllerScript(false, 135, 22, "Iron Gale Swordsman").Parent = newModel

    ----------------------------------------------------------------------------
    -- 4. SWORDSMAN_4: AZURE WIND SWORDSMAN
    ----------------------------------------------------------------------------
    elseif name == "Swordsman_4" then
        hum.MaxHealth = 100
        hum.Health = 100
        hum.WalkSpeed = 15

        bodyColors.HeadColor3 = Color3.fromRGB(225, 195, 165)
        bodyColors.TorsoColor3 = Color3.fromRGB(38, 115, 135)
        bodyColors.LeftArmColor3 = Color3.fromRGB(48, 130, 150)
        bodyColors.RightArmColor3 = Color3.fromRGB(48, 130, 150)
        bodyColors.LeftLegColor3 = Color3.fromRGB(215, 228, 235)
        bodyColors.RightLegColor3 = Color3.fromRGB(215, 228, 235)

        -- Scholar Topknot & Jade Hairpin
        local bun = createPart("TopknotBun", Vector3.new(0.7, 0.7, 0.7), Color3.fromRGB(30, 30, 32), Enum.Material.SmoothPlastic, newModel)
        weldParts(head, bun, CFrame.new(0, 0.9, -0.1))

        local pin = createPart("JadePin", Vector3.new(1.3, 0.15, 0.15), Color3.fromRGB(80, 220, 170), Enum.Material.Neon, newModel)
        weldParts(bun, pin, CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(45)))

        -- Jade Waist Sash
        local sash = createPart("JadeSash", Vector3.new(2.1, 0.35, 1.1), Color3.fromRGB(230, 240, 245), Enum.Material.Fabric, newModel)
        weldParts(torso, sash, CFrame.new(0, -0.6, 0))

        -- Azure Jian: Hilt + Silver Crossguard + Slender Blade
        local hilt = createPart("JianHilt", Vector3.new(0.2, 0.85, 0.2), Color3.fromRGB(220, 230, 235), Enum.Material.Fabric, newModel)
        weldParts(rArm, hilt, CFrame.new(0, -1.0, -0.2) * CFrame.Angles(math.rad(65), 0, 0))

        local guard = createPart("JianGuard", Vector3.new(0.7, 0.1, 0.3), Color3.fromRGB(190, 200, 210), Enum.Material.Metal, newModel)
        weldParts(hilt, guard, CFrame.new(0, 0.42, 0))

        local blade = createPart("WeaponBlade", Vector3.new(0.15, 3.4, 0.35), Color3.fromRGB(190, 235, 245), Enum.Material.Metal, newModel)
        weldParts(guard, blade, CFrame.new(0, 1.7, 0))

        local att0 = Instance.new("Attachment", blade)
        att0.Position = Vector3.new(0, -1.7, 0)
        local att1 = Instance.new("Attachment", blade)
        att1.Position = Vector3.new(0, 1.7, 0)

        local trail = Instance.new("Trail")
        trail.Attachment0 = att0
        trail.Attachment1 = att1
        trail.Color = ColorSequence.new(Color3.fromRGB(90, 230, 255), Color3.fromRGB(40, 160, 200))
        trail.Lifetime = 0.28
        trail.Enabled = false
        trail.Parent = blade

        -- Swirling Wind Qi
        local wind = Instance.new("ParticleEmitter")
        wind.Name = "WindQi"
        wind.Color = ColorSequence.new(Color3.fromRGB(150, 240, 255), Color3.fromRGB(70, 190, 220))
        wind.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0.1) })
        wind.Lifetime = NumberRange.new(0.5, 1.0)
        wind.Rate = 12
        wind.Speed = NumberRange.new(1.5, 3.5)
        wind.Parent = torso

        attachHealthBar(newModel, head, "Azure Wind Swordsman", 100, false, Color3.fromRGB(140, 235, 255), Color3.fromRGB(40, 175, 215))
        createControllerScript(false, 100, 16, "Azure Wind Swordsman").Parent = newModel

    ----------------------------------------------------------------------------
    -- 5. SWORDSMAN_5: GHOST FLAME SWORDSMAN
    ----------------------------------------------------------------------------
    elseif name == "Swordsman_5" then
        hum.MaxHealth = 105
        hum.Health = 105
        hum.WalkSpeed = 14

        bodyColors.HeadColor3 = Color3.fromRGB(195, 175, 205)
        bodyColors.TorsoColor3 = Color3.fromRGB(50, 26, 78)
        bodyColors.LeftArmColor3 = Color3.fromRGB(42, 22, 65)
        bodyColors.RightArmColor3 = Color3.fromRGB(42, 22, 65)
        bodyColors.LeftLegColor3 = Color3.fromRGB(22, 18, 32)
        bodyColors.RightLegColor3 = Color3.fromRGB(22, 18, 32)

        -- Ghost Spirit Half-Mask
        local mask = createPart("GhostMask", Vector3.new(1.25, 0.5, 1.25), Color3.fromRGB(35, 20, 50), Enum.Material.Fabric, newModel)
        weldParts(head, mask, CFrame.new(0, -0.25, 0.05))

        -- Ghost Flame Dao: Bone Hilt + Demon Guard + Violet Serrated Blade
        local hilt = createPart("GhostHilt", Vector3.new(0.2, 0.85, 0.2), Color3.fromRGB(60, 50, 70), Enum.Material.SmoothPlastic, newModel)
        weldParts(rArm, hilt, CFrame.new(0, -1.0, -0.2) * CFrame.Angles(math.rad(65), 0, 0))

        local guard = createPart("GhostGuard", Vector3.new(0.6, 0.12, 0.45), Color3.fromRGB(120, 60, 180), Enum.Material.Metal, newModel)
        weldParts(hilt, guard, CFrame.new(0, 0.42, 0))

        local blade = createPart("WeaponBlade", Vector3.new(0.2, 3.4, 0.5), Color3.fromRGB(180, 80, 255), Enum.Material.Neon, newModel)
        weldParts(guard, blade, CFrame.new(0, 1.7, 0))

        local att0 = Instance.new("Attachment", blade)
        att0.Position = Vector3.new(0, -1.7, 0)
        local att1 = Instance.new("Attachment", blade)
        att1.Position = Vector3.new(0, 1.7, 0)

        local trail = Instance.new("Trail")
        trail.Attachment0 = att0
        trail.Attachment1 = att1
        trail.Color = ColorSequence.new(Color3.fromRGB(210, 90, 255), Color3.fromRGB(80, 20, 140))
        trail.Lifetime = 0.3
        trail.Enabled = false
        trail.Parent = blade

        -- Violet Flame Emitter
        local flames = Instance.new("ParticleEmitter")
        flames.Name = "GhostFlames"
        flames.Color = ColorSequence.new(Color3.fromRGB(210, 80, 255), Color3.fromRGB(90, 20, 150))
        flames.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
        flames.Lifetime = NumberRange.new(0.4, 0.8)
        flames.Rate = 16
        flames.Speed = NumberRange.new(1.5, 3.0)
        flames.Parent = blade

        attachHealthBar(newModel, head, "Ghost Flame Swordsman", 105, false, Color3.fromRGB(220, 150, 255), Color3.fromRGB(150, 45, 205))
        createControllerScript(false, 105, 19, "Ghost Flame Swordsman").Parent = newModel

    ----------------------------------------------------------------------------
    -- 6. SWORDMASTER_BOSS: GRANDMASTER (STANDBY MODE)
    ----------------------------------------------------------------------------
    elseif name == "Swordmaster_Boss" then
        hum.MaxHealth = 880
        hum.Health = 880
        hum.WalkSpeed = 14

        bodyColors.HeadColor3 = Color3.fromRGB(222, 192, 162)
        bodyColors.TorsoColor3 = Color3.fromRGB(16, 22, 44)
        bodyColors.LeftArmColor3 = Color3.fromRGB(22, 28, 52)
        bodyColors.RightArmColor3 = Color3.fromRGB(22, 28, 52)
        bodyColors.LeftLegColor3 = Color3.fromRGB(12, 16, 32)
        bodyColors.RightLegColor3 = Color3.fromRGB(12, 16, 32)

        -- Grandmaster Dragon Crest Crown
        local crown = createPart("DragonCrown", Vector3.new(1.4, 0.5, 1.4), Color3.fromRGB(240, 195, 60), Enum.Material.Metal, newModel)
        weldParts(head, crown, CFrame.new(0, 0.6, 0))

        local hornL = createPart("HornLeft", Vector3.new(0.2, 0.8, 0.2), Color3.fromRGB(255, 215, 80), Enum.Material.Metal, newModel)
        weldParts(crown, hornL, CFrame.new(-0.6, 0.4, -0.2) * CFrame.Angles(0, 0, math.rad(25)))

        local hornR = createPart("HornRight", Vector3.new(0.2, 0.8, 0.2), Color3.fromRGB(255, 215, 80), Enum.Material.Metal, newModel)
        weldParts(crown, hornR, CFrame.new(0.6, 0.4, -0.2) * CFrame.Angles(0, 0, math.rad(-25)))

        -- Golden Dragon Pauldrons
        local pL = createPart("LeftDragonPauldron", Vector3.new(1.3, 0.6, 1.3), Color3.fromRGB(240, 195, 60), Enum.Material.Metal, newModel)
        weldParts(lArm, pL, CFrame.new(-0.25, 0.75, 0))

        local pR = createPart("RightDragonPauldron", Vector3.new(1.3, 0.6, 1.3), Color3.fromRGB(240, 195, 60), Enum.Material.Metal, newModel)
        weldParts(rArm, pR, CFrame.new(0.25, 0.75, 0))

        -- Grandmaster Velvet Cape
        local cape = createPart("GrandmasterCape", Vector3.new(2.4, 3.8, 0.2), Color3.fromRGB(20, 24, 48), Enum.Material.Fabric, newModel)
        weldParts(torso, cape, CFrame.new(0, -0.6, 0.65) * CFrame.Angles(math.rad(8), 0, 0))

        -- Golden Dragon Belt
        local belt = createPart("DragonBelt", Vector3.new(2.1, 0.45, 1.15), Color3.fromRGB(240, 195, 60), Enum.Material.Metal, newModel)
        weldParts(torso, belt, CFrame.new(0, -0.6, 0))

        -- Giant Master Celestial Odachi: 2-Handed Hilt + Dragon Tsuba + Massive Blade
        local hilt = createPart("MasterHilt", Vector3.new(0.25, 1.4, 0.25), Color3.fromRGB(230, 185, 55), Enum.Material.Metal, newModel)
        weldParts(rArm, hilt, CFrame.new(0, -1.3, -0.3) * CFrame.Angles(math.rad(65), 0, 0))

        local guard = createPart("MasterGuard", Vector3.new(0.85, 0.15, 0.7), Color3.fromRGB(255, 215, 75), Enum.Material.Metal, newModel)
        weldParts(hilt, guard, CFrame.new(0, 0.7, 0))

        local blade = createPart("WeaponBlade", Vector3.new(0.25, 4.6, 0.65), Color3.fromRGB(255, 245, 220), Enum.Material.Metal, newModel)
        weldParts(guard, blade, CFrame.new(0, 2.3, 0))

        local att0 = Instance.new("Attachment", blade)
        att0.Position = Vector3.new(0, -2.3, 0)
        local att1 = Instance.new("Attachment", blade)
        att1.Position = Vector3.new(0, 2.3, 0)

        local trail = Instance.new("Trail")
        trail.Attachment0 = att0
        trail.Attachment1 = att1
        trail.Color = ColorSequence.new(Color3.fromRGB(255, 220, 100), Color3.fromRGB(255, 180, 40))
        trail.Lifetime = 0.35
        trail.Enabled = false
        trail.Parent = blade

        -- Radiant Celestial Aura
        local aura = Instance.new("ParticleEmitter")
        aura.Name = "CelestialAura"
        aura.Color = ColorSequence.new(Color3.fromRGB(255, 225, 110), Color3.fromRGB(255, 170, 40))
        aura.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) })
        aura.Lifetime = NumberRange.new(0.8, 1.5)
        aura.Rate = 16
        aura.Speed = NumberRange.new(0.8, 2.2)
        aura.SpreadAngle = Vector2.new(180, 180)
        aura.Parent = torso

        -- Scale Boss up to 1.32x for grandmaster stature
        newModel:ScaleTo(1.32)

        attachHealthBar(newModel, head, "⚔️ Grandmaster Swordmaster [BOSS]", 880, true, Color3.fromRGB(255, 215, 70), Color3.fromRGB(235, 45, 55))
        createControllerScript(true, 880, 35, "Grandmaster Swordmaster").Parent = newModel
    end

    ----------------------------------------------------------------------------
    -- MOVE TO EXACT POSITION AND PARENT
    ----------------------------------------------------------------------------
    newModel.PrimaryPart = hrp
    newModel:PivotTo(targetCF)

    -- In Edit mode, also start Idle animation preview on Animator
    local humAnim = hum:FindFirstChildOfClass("Animator")
    if humAnim then
        local aIdle = Instance.new("Animation")
        aIdle.AnimationId = "rbxassetid://180435571"
        pcall(function()
            local t = humAnim:LoadAnimation(aIdle)
            t.Looped = true
            t:Play()
        end)
    end

    -- Replace old model cleanly
    if oldModel then
        oldModel:Destroy()
    end

    newModel.Parent = enemiesFolder

    local finalPos = hrp.Position
    table.insert(results, string.format("%s positioned at (%0.1f, %0.1f, %0.1f)", name, finalPos.X, finalPos.Y, finalPos.Z))
end

-- Backup new models to ServerStorage
local templateFolder = ServerStorage:FindFirstChild("DestroyedVillage_EnemyTemplates")
if templateFolder then templateFolder:Destroy() end

templateFolder = Instance.new("Folder")
templateFolder.Name = "DestroyedVillage_EnemyTemplates"
templateFolder.Parent = ServerStorage

for _, enemy in ipairs(enemiesFolder:GetChildren()) do
    local clone = enemy:Clone()
    clone.Parent = templateFolder
end

return "SUCCESS:\n" .. table.concat(results, "\n")
'''

def upgrade_enemies():
    print("Sending updated enemy upgrade payload to Roblox Studio...")
    success, output = exec_code(UPGRADE_LUA, timeout=30.0)
    print(f"Success: {success}")
    print(f"Output:\n{output}")
    return success

if __name__ == "__main__":
    ok = upgrade_enemies()
    sys.exit(0 if ok else 1)
