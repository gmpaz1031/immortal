import sys
import os

sys.path.append(os.path.dirname(__file__))
from exec import exec_code

LUA_CODE = """
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

local enemiesFolder = Workspace:FindFirstChild("DemonCult_Bosses")
if enemiesFolder then enemiesFolder:Destroy() end
enemiesFolder = Instance.new("Folder")
enemiesFolder.Name = "DemonCult_Bosses"
enemiesFolder.Parent = Workspace

local templateFolder = ServerStorage:FindFirstChild("DemonCult_BossTemplates")
if templateFolder then templateFolder:Destroy() end
templateFolder = Instance.new("Folder")
templateFolder.Name = "DemonCult_BossTemplates"
templateFolder.Parent = ServerStorage

local function attachHealthBar(model, head, name, maxHealth, isBoss)
    local bg = Instance.new("BillboardGui")
    bg.Name = "HealthBarGui"
    bg.Adornee = head
    bg.Size = UDim2.new(4.2, 0, 0.88, 0)
    bg.StudsOffset = Vector3.new(0, 3, 0)
    bg.AlwaysOnTop = false
    bg.MaxDistance = 50
    if isBoss then
        bg.Size = UDim2.new(6.5, 0, 1.2, 0)
        bg.StudsOffset = Vector3.new(0, 4.5, 0)
        bg.MaxDistance = 60
    end

    local bgFrame = Instance.new("Frame", bg)
    bgFrame.Size = UDim2.new(1, 0, 0.4, 0)
    bgFrame.Position = UDim2.new(0, 0, 0.6, 0)
    bgFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    bgFrame.BorderSizePixel = 0

    local hpBar = Instance.new("Frame", bgFrame)
    hpBar.Name = "HealthBar"
    hpBar.Size = UDim2.new(1, 0, 1, 0)
    hpBar.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
    hpBar.BorderSizePixel = 0

    local nameLabel = Instance.new("TextLabel", bg)
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = name
    nameLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.Oswald

    bg.Parent = model
end

local function createWeapon(model, rightHand, bladeColor)
    local hilt = Instance.new("Part")
    hilt.Name = "WeaponHilt"
    hilt.Size = Vector3.new(0.2, 1.2, 0.2)
    hilt.Color = Color3.fromRGB(30, 30, 30)
    hilt.Material = Enum.Material.Metal
    hilt.CanCollide = false
    hilt.Massless = true
    hilt.Parent = model
    
    local w1 = Instance.new("WeldConstraint", hilt)
    w1.Part0 = rightHand
    w1.Part1 = hilt
    hilt.CFrame = rightHand.CFrame * CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0)
    
    local blade = Instance.new("Part")
    blade.Name = "WeaponBlade"
    blade.Size = Vector3.new(0.1, 4, 0.4)
    blade.Color = bladeColor
    blade.Material = Enum.Material.Neon
    blade.CanCollide = false
    blade.Massless = true
    blade.Parent = model
    
    local w2 = Instance.new("WeldConstraint", blade)
    w2.Part0 = hilt
    w2.Part1 = blade
    blade.CFrame = hilt.CFrame * CFrame.new(0, 2.5, 0)
    
    local att0 = Instance.new("Attachment", blade)
    att0.Position = Vector3.new(0, -2, 0)
    local att1 = Instance.new("Attachment", blade)
    att1.Position = Vector3.new(0, 2, 0)
    
    local trail = Instance.new("Trail", blade)
    trail.Attachment0 = att0
    trail.Attachment1 = att1
    trail.Color = ColorSequence.new(bladeColor, Color3.fromRGB(20, 20, 20))
    trail.Lifetime = 0.3
    trail.Enabled = false
    
    return blade
end

-- CONTROLLER GENERATOR (Now updated for R15 logic and Animations)
local function createBossController(bossType, maxHp, damage)
    local s = Instance.new("Script")
    s.Name = "EnemyController"
    
    local header = string.format([==[
local bossType = "%s"
local baseDamage = %d
]==], bossType, damage)

    local body = [==[
local model = script.Parent
local humanoid = model:WaitForChild("Humanoid")
local hrp = model:WaitForChild("HumanoidRootPart")
local isDead = false
local spawnCFrame = hrp.CFrame
local Debris = game:GetService("Debris")

local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
local function makeAnim(id, priority, looped)
    local a = Instance.new("Animation")
    a.AnimationId = id
    local track = animator:LoadAnimation(a)
    track.Priority = priority
    track.Looped = looped
    return track
end

-- R15 Animations
local idleTrack = makeAnim("rbxassetid://507766388", Enum.AnimationPriority.Idle, true)
local walkTrack = makeAnim("rbxassetid://507777826", Enum.AnimationPriority.Movement, true)
local slashTrack = makeAnim("rbxassetid://12520999032", Enum.AnimationPriority.Action, false)

idleTrack:Play()

humanoid.Running:Connect(function(speed)
    if isDead then return end
    if speed > 0.8 then
        if not walkTrack.IsPlaying then walkTrack:Play(0.2) end
    else
        if walkTrack.IsPlaying then walkTrack:Stop(0.2) end
    end
end)

local trail = nil
for _, d in ipairs(model:GetDescendants()) do if d:IsA("Trail") then trail = d break end end

local function dealDamage(targetHum, dmg, name)
    targetHum:TakeDamage(dmg)
end

humanoid.Died:Connect(function()
    isDead = true
    pcall(function() idleTrack:Stop() walkTrack:Stop() slashTrack:Stop() end)
    task.delay(3, function() if model.Parent then model:Destroy() end end)
end)

local CHASE_RANGE = 50
local ATTACK_RANGE = 7
local lastSkill = 0
local minionsSpawned = false

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

            -- AI LOGIC PER BOSS
            if bossType == "DemonCultist" or bossType == "SeniorDemonCultist" then
                if dist <= ATTACK_RANGE and (tick() - lastSkill) >= 1.5 then
                    lastSkill = tick()
                    hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetRoot.Position.X, hrp.Position.Y, targetRoot.Position.Z))
                    slashTrack:Play(0.05, 1, 1.2)
                    if trail then trail.Enabled = true end
                    task.delay(0.25, function()
                        if trail then trail.Enabled = false end
                        if targetHum.Health > 0 and (targetRoot.Position - hrp.Position).Magnitude <= ATTACK_RANGE + 3 then
                            dealDamage(targetHum, baseDamage, bossType)
                        end
                    end)
                else
                    humanoid:MoveTo(targetRoot.Position)
                end
            elseif bossType == "FlameDemoness" then
                if dist > 10 and dist < 40 and (tick() - lastSkill) >= 5 then
                    lastSkill = tick()
                    -- Pull
                    targetRoot.CFrame = hrp.CFrame * CFrame.new(0, 0, -3)
                elseif dist <= 5 and (tick() - lastSkill) >= 2 then
                    lastSkill = tick()
                    -- Flaming Punches (3 hit combo)
                    hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetRoot.Position.X, hrp.Position.Y, targetRoot.Position.Z))
                    for i=1,3 do
                        slashTrack:Play(0.05, 1, 1.5)
                        task.wait(0.2)
                        dealDamage(targetHum, 10, "Flame Punch")
                    end
                else
                    humanoid:MoveTo(targetRoot.Position)
                end
            elseif bossType == "PoisonDemoness" then
                if dist > 15 and (tick() - lastSkill) >= 6 then
                    lastSkill = tick()
                    -- Poison Orbs
                    hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetRoot.Position.X, hrp.Position.Y, targetRoot.Position.Z))
                    for i=1,3 do
                        local orb = Instance.new("Part")
                        orb.Size = Vector3.new(2,2,2)
                        orb.Shape = Enum.PartType.Ball
                        orb.Color = Color3.fromRGB(50, 200, 50)
                        orb.Material = Enum.Material.Neon
                        orb.CFrame = hrp.CFrame * CFrame.new(0, 2, -3)
                        local bv = Instance.new("BodyVelocity")
                        bv.Velocity = (targetRoot.Position - orb.Position).Unit * 50
                        bv.Parent = orb
                        orb.Parent = workspace
                        Debris:AddItem(orb, 2)
                        orb.Touched:Connect(function(hit)
                            if hit.Parent and hit.Parent:FindFirstChild("Humanoid") and hit.Parent ~= model then
                                dealDamage(hit.Parent.Humanoid, 10, "Poison Orb")
                                orb:Destroy()
                            end
                        end)
                        task.wait(0.2)
                    end
                elseif dist <= 12 and (tick() - lastSkill) >= 8 then
                    lastSkill = tick()
                    -- Poison Ground AoE
                    local pool = Instance.new("Part")
                    pool.Size = Vector3.new(24, 0.5, 24)
                    pool.Shape = Enum.PartType.Cylinder
                    pool.Color = Color3.fromRGB(50, 150, 50)
                    pool.Material = Enum.Material.Neon
                    pool.CFrame = hrp.CFrame * CFrame.Angles(0,0,math.rad(90))
                    pool.Anchored = true
                    pool.CanCollide = false
                    pool.Parent = workspace
                    Debris:AddItem(pool, 5)
                    task.spawn(function()
                        for i=1,5 do
                            if targetHum and (targetRoot.Position - pool.Position).Magnitude <= 12 then
                                dealDamage(targetHum, 5, "Poison Tick")
                            end
                            task.wait(1)
                        end
                    end)
                else
                    humanoid:MoveTo(targetRoot.Position)
                end
            elseif bossType == "FistDemon" then
                if dist <= 15 and (tick() - lastSkill) >= 7 then
                    lastSkill = tick()
                    -- Shockwave
                    slashTrack:Play(0.05, 1, 0.8)
                    task.wait(0.5)
                    local wave = Instance.new("Part")
                    wave.Size = Vector3.new(30, 1, 30)
                    wave.Shape = Enum.PartType.Cylinder
                    wave.Color = Color3.fromRGB(200, 100, 50)
                    wave.Material = Enum.Material.Neon
                    wave.CFrame = hrp.CFrame * CFrame.new(0, -2, 0) * CFrame.Angles(0,0,math.rad(90))
                    wave.Anchored = true
                    wave.CanCollide = false
                    wave.Parent = workspace
                    Debris:AddItem(wave, 0.5)
                    if (targetRoot.Position - hrp.Position).Magnitude <= 15 then
                        dealDamage(targetHum, 25, "Shockwave")
                        targetHum.Sit = true
                    end
                elseif dist <= 6 and (tick() - lastSkill) >= 3 then
                    lastSkill = tick()
                    slashTrack:Play(0.05, 1, 1)
                    task.wait(0.3)
                    dealDamage(targetHum, 15, "Heavy Punch 1")
                    task.wait(0.3)
                    dealDamage(targetHum, 15, "Heavy Punch 2")
                else
                    humanoid:MoveTo(targetRoot.Position)
                end
            elseif bossType == "SwordDemon" then
                if dist > 15 and (tick() - lastSkill) >= 5 then
                    lastSkill = tick()
                    hrp.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
                    task.wait(0.2)
                    slashTrack:Play()
                    dealDamage(targetHum, 35, "Teleport Strike")
                elseif dist <= 6 and (tick() - lastSkill) >= 2 then
                    lastSkill = tick()
                    for i=1,3 do
                        slashTrack:Play(0.05, 1, 1.5)
                        task.wait(0.2)
                        dealDamage(targetHum, 10, "Rapid Slash")
                    end
                else
                    humanoid:MoveTo(targetRoot.Position)
                end
            elseif bossType == "SupremeDemon" then
                if dist <= 20 and (tick() - lastSkill) >= 10 then
                    lastSkill = tick()
                    local charge = Instance.new("Part")
                    charge.Shape = Enum.PartType.Ball
                    charge.Size = Vector3.new(4,4,4)
                    charge.Color = Color3.fromRGB(150, 0, 200)
                    charge.Material = Enum.Material.Neon
                    charge.CFrame = hrp.CFrame
                    charge.Anchored = true
                    charge.CanCollide = false
                    charge.Parent = workspace
                    Debris:AddItem(charge, 2.1)
                    task.wait(2)
                    charge.Size = Vector3.new(40,40,40)
                    if (targetRoot.Position - hrp.Position).Magnitude <= 20 then
                        dealDamage(targetHum, 50, "Supreme Explosion")
                    end
                else
                    humanoid:MoveTo(targetRoot.Position)
                end
            elseif bossType == "BloodDemon" then
                if dist > 15 and (tick() - lastSkill) >= 5 then
                    lastSkill = tick()
                    hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetRoot.Position.X, hrp.Position.Y, targetRoot.Position.Z))
                    local wave = Instance.new("Part")
                    wave.Size = Vector3.new(8, 2, 1)
                    wave.Color = Color3.fromRGB(200, 0, 0)
                    wave.Material = Enum.Material.Neon
                    wave.CFrame = hrp.CFrame * CFrame.new(0, 0, -2)
                    local bv = Instance.new("BodyVelocity")
                    bv.Velocity = hrp.CFrame.LookVector * 45
                    bv.Parent = wave
                    wave.Parent = workspace
                    Debris:AddItem(wave, 1)
                    wave.Touched:Connect(function(hit)
                        if hit.Parent and hit.Parent:FindFirstChild("Humanoid") and hit.Parent ~= model then
                            dealDamage(hit.Parent.Humanoid, 25, "Blood Slash")
                            wave:Destroy()
                        end
                    end)
                else
                    humanoid:MoveTo(targetRoot.Position)
                end
            end
        else
            if (hrp.Position - spawnCFrame.Position).Magnitude > 40 then
                humanoid:MoveTo(spawnCFrame.Position)
            end
        end
        task.wait(0.25)
    end
end)
]==]
    s.Source = header .. body
    return s
end

local function generateR15NPC(title, maxHp, damage, color3, accessoriesStr)
    local desc = Instance.new("HumanoidDescription")
    desc.HeadColor = color3
    desc.TorsoColor = color3
    desc.LeftArmColor = color3
    desc.RightArmColor = color3
    desc.LeftLegColor = color3
    desc.RightLegColor = color3
    
    if accessoriesStr and accessoriesStr ~= "" then
        desc.HatAccessory = accessoriesStr
    end
    
    local ok, model = pcall(function()
        return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
    end)
    if not ok or not model then
        error("Failed to generate R15: " .. tostring(model))
    end
    
    model.Name = title
    
    -- Enhance textures by tinting them based on character type
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Material = Enum.Material.Fabric
        end
    end
    
    local hrp = model:WaitForChild("HumanoidRootPart")
    local head = model:WaitForChild("Head")
    local hum = model:WaitForChild("Humanoid")
    hum.MaxHealth = maxHp
    hum.Health = maxHp
    model.PrimaryPart = hrp
    
    attachHealthBar(model, head, title, maxHp, maxHp >= 800)
    createBossController(title:gsub(" ", ""), maxHp, damage).Parent = model
    
    return model
end

--------------------------------------------------------------------------------
-- GENERATE ENEMIES
--------------------------------------------------------------------------------

-- 1. Normal Cultist (1309911 Ninja Mask)
local norm = generateR15NPC("Demon Cultist", 150, 15, Color3.fromRGB(40,10,10), "1309911")
createWeapon(norm, norm:WaitForChild("RightHand"), Color3.fromRGB(255, 30, 30))
norm.Parent = templateFolder

-- 2. Senior Cultist (1033722 Straw Hat, 1309911 Ninja Mask)
local sen = generateR15NPC("Senior Demon Cultist", 300, 25, Color3.fromRGB(20,5,5), "1033722,1309911")
local b = createWeapon(sen, sen:WaitForChild("RightHand"), Color3.fromRGB(255, 100, 30))
local fire = Instance.new("ParticleEmitter", b)
fire.Color = ColorSequence.new(Color3.fromRGB(255, 80, 20))
fire.Rate = 20
fire.Size = NumberSequence.new(0.5, 0)
sen.Parent = templateFolder

-- 3. Flame Demoness
local fDem = generateR15NPC("Flame Demoness", 800, 20, Color3.fromRGB(150,20,20), "")
local aura = Instance.new("ParticleEmitter", fDem:WaitForChild("UpperTorso"))
aura.Color = ColorSequence.new(Color3.fromRGB(255,100,50))
fDem.Parent = templateFolder

-- 4. Poison Demoness
local pDem = generateR15NPC("Poison Demoness", 800, 20, Color3.fromRGB(60,20,80), "")
local pAura = Instance.new("ParticleEmitter", pDem:WaitForChild("UpperTorso"))
pAura.Color = ColorSequence.new(Color3.fromRGB(50,200,50))
pDem.Parent = templateFolder

-- 5. Fist Demon
local fist = generateR15NPC("Fist Demon", 1000, 30, Color3.fromRGB(180,50,50), "")
fist:ScaleTo(1.2)
fist.Parent = templateFolder

-- 6. Sword Demon
local sw = generateR15NPC("Sword Demon", 850, 35, Color3.fromRGB(20,20,80), "1309911")
createWeapon(sw, sw:WaitForChild("RightHand"), Color3.fromRGB(50, 100, 255))
sw.Parent = templateFolder

-- 7. Supreme Demon
local sup = generateR15NPC("Supreme Demon", 1200, 50, Color3.fromRGB(10,10,10), "")
sup:ScaleTo(1.3)
local sAura = Instance.new("ParticleEmitter", sup:WaitForChild("UpperTorso"))
sAura.Color = ColorSequence.new(Color3.fromRGB(150,50,255))
sup.Parent = templateFolder

-- 8. Blood Demon
local bd = generateR15NPC("Blood Demon", 900, 25, Color3.fromRGB(80,10,10), "")
bd.Parent = templateFolder

--------------------------------------------------------------------------------
-- SPAWNING
--------------------------------------------------------------------------------
local vCenter = Vector3.new(1000, 10, 1000)
local tCenter = Vector3.new(1000, 10, 1500)

local spawns = {
    -- Village
    {t="Demon Cultist", p=vCenter + Vector3.new(40, 0, 40)},
    {t="Demon Cultist", p=vCenter + Vector3.new(-40, 0, 40)},
    {t="Demon Cultist", p=vCenter + Vector3.new(40, 0, -40)},
    {t="Demon Cultist", p=vCenter + Vector3.new(-40, 0, -40)},
    {t="Senior Demon Cultist", p=vCenter + Vector3.new(0, 0, 30)},
    {t="Senior Demon Cultist", p=vCenter + Vector3.new(0, 0, -30)},
    
    -- Tower Bosses
    {t="Flame Demoness", p=tCenter + Vector3.new(60, 0, 60)},
    {t="Poison Demoness", p=tCenter + Vector3.new(-60, 0, 60)},
    {t="Fist Demon", p=tCenter + Vector3.new(60, 0, -60)},
    {t="Sword Demon", p=tCenter + Vector3.new(-60, 0, -60)},
    {t="Supreme Demon", p=tCenter + Vector3.new(0, 0, 80)},
    {t="Blood Demon", p=tCenter + Vector3.new(0, 0, -80)}
}

for _, cfg in ipairs(spawns) do
    local temp = templateFolder:FindFirstChild(cfg.t)
    if temp then
        local c = temp:Clone()
        c:PivotTo(CFrame.new(cfg.p))
        c.Parent = enemiesFolder
    end
end

return "Beautiful R15 Enemies spawned!"
"""

def generate_beautiful_enemies():
    print("Sending beautiful R15 enemies payload...")
    success, output = exec_code(LUA_CODE, timeout=25.0)
    print(f"Success: {success}")
    print(f"Output:\n{output}")
    return success

if __name__ == "__main__":
    generate_beautiful_enemies()
