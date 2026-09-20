import sys
import os

sys.path.append(os.path.dirname(__file__))
from exec import exec_code

BOSSES_LUA = """
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

local enemiesFolder = Workspace:FindFirstChild("DemonCult_Bosses")
if enemiesFolder then enemiesFolder:Destroy() end
enemiesFolder = Instance.new("Folder")
enemiesFolder.Name = "DemonCult_Bosses"
enemiesFolder.Parent = Workspace

local sampleRig = Workspace:FindFirstChild("SAMPLEENEMYMODEL")
if not sampleRig then return "Error: SAMPLEENEMYMODEL not found." end

local templateFolder = ServerStorage:FindFirstChild("DemonCult_BossTemplates")
if templateFolder then templateFolder:Destroy() end
templateFolder = Instance.new("Folder")
templateFolder.Name = "DemonCult_BossTemplates"
templateFolder.Parent = ServerStorage

local function attachHealthBar(model, head, name, maxHealth)
    local bg = Instance.new("BillboardGui")
    bg.Name = "HealthBarGui"
    bg.Adornee = head
    bg.Size = UDim2.new(6.5, 0, 1.2, 0)
    bg.StudsOffset = Vector3.new(0, 4.5, 0)
    bg.AlwaysOnTop = false
    bg.MaxDistance = 60

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

-- HUGE CONTROLLER SCRIPT FOR BOSSES
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
local function makeAnim(id, priority)
    local a = Instance.new("Animation")
    a.AnimationId = id
    local track = animator:LoadAnimation(a)
    track.Priority = priority
    return track
end

local idleTrack = makeAnim("rbxassetid://180435571", Enum.AnimationPriority.Idle)
idleTrack.Looped = true
local walkTrack = makeAnim("rbxassetid://180426354", Enum.AnimationPriority.Movement)
walkTrack.Looped = true
local slashTrack = makeAnim("rbxassetid://129967390", Enum.AnimationPriority.Action)

idleTrack:Play()

humanoid.Running:Connect(function(speed)
    if isDead then return end
    if speed > 0.8 then
        if not walkTrack.IsPlaying then walkTrack:Play(0.2) end
    else
        if walkTrack.IsPlaying then walkTrack:Stop(0.2) end
    end
end)

local function dealDamage(targetHum, dmg, name)
    targetHum:TakeDamage(dmg)
end

humanoid.Died:Connect(function()
    isDead = true
    pcall(function() idleTrack:Stop() walkTrack:Stop() slashTrack:Stop() end)
    task.delay(3, function() if model.Parent then model:Destroy() end end)
end)

local CHASE_RANGE = 50
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
            if bossType == "FlameDemoness" then
                if dist > 10 and (tick() - lastSkill) >= 5 then
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
                elseif dist <= 20 and (tick() - lastSkill) >= 4 then
                    lastSkill = tick()
                    -- Dash Attack
                    hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetRoot.Position.X, hrp.Position.Y, targetRoot.Position.Z))
                    local bp = Instance.new("BodyPosition")
                    bp.Position = targetRoot.Position
                    bp.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                    bp.P = 50000
                    bp.Parent = hrp
                    Debris:AddItem(bp, 0.3)
                    task.wait(0.3)
                    if (targetRoot.Position - hrp.Position).Magnitude <= 5 then
                        dealDamage(targetHum, 20, "Poison Dash")
                    end
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
                    -- Heavy Punches
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
                    -- Teleport Strike
                    hrp.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
                    task.wait(0.2)
                    slashTrack:Play()
                    dealDamage(targetHum, 35, "Teleport Strike")
                elseif dist > 10 and (tick() - lastSkill) >= 4 then
                    lastSkill = tick()
                    -- Fire Slash (Energy Wave)
                    hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetRoot.Position.X, hrp.Position.Y, targetRoot.Position.Z))
                    local wave = Instance.new("Part")
                    wave.Size = Vector3.new(10, 2, 1)
                    wave.Color = Color3.fromRGB(50, 100, 255)
                    wave.Material = Enum.Material.Neon
                    wave.CFrame = hrp.CFrame * CFrame.new(0, 0, -2)
                    local bv = Instance.new("BodyVelocity")
                    bv.Velocity = hrp.CFrame.LookVector * 40
                    bv.Parent = wave
                    wave.Parent = workspace
                    Debris:AddItem(wave, 1)
                    wave.Touched:Connect(function(hit)
                        if hit.Parent and hit.Parent:FindFirstChild("Humanoid") and hit.Parent ~= model then
                            dealDamage(hit.Parent.Humanoid, 30, "Sword Wave")
                            wave:Destroy()
                        end
                    end)
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
                if not minionsSpawned and humanoid.Health < humanoid.MaxHealth * 0.7 then
                    minionsSpawned = true
                    lastSkill = tick()
                    -- Summon (we'll just spawn a small cultist manually or skip if complex)
                    -- To avoid dependency on template folder inside script, we'll emit a purple ring
                    local ring = Instance.new("Part")
                    ring.Size = Vector3.new(20,2,20)
                    ring.Color = Color3.fromRGB(150, 0, 200)
                    ring.Material = Enum.Material.Neon
                    ring.CFrame = hrp.CFrame
                    ring.Anchored = true
                    ring.CanCollide = false
                    ring.Parent = workspace
                    Debris:AddItem(ring, 1)
                elseif dist <= 20 and (tick() - lastSkill) >= 10 then
                    lastSkill = tick()
                    -- AoE Explosion 2s charge
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
                elseif dist > 15 and (tick() - lastSkill) >= 6 then
                    lastSkill = tick()
                    -- Teleport Strike Above
                    hrp.CFrame = targetRoot.CFrame * CFrame.new(0, 10, 0)
                    task.wait(0.3)
                    hrp.CFrame = targetRoot.CFrame
                    slashTrack:Play(0.05, 1, 1)
                    dealDamage(targetHum, 40, "Supreme Slam")
                else
                    humanoid:MoveTo(targetRoot.Position)
                end

            elseif bossType == "BloodDemon" then
                if dist > 15 and (tick() - lastSkill) >= 5 then
                    lastSkill = tick()
                    -- Blood Slash
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
                elseif dist <= 12 and (tick() - lastSkill) >= 8 then
                    lastSkill = tick()
                    -- Blood Pool AoE
                    local pool = Instance.new("Part")
                    pool.Size = Vector3.new(20, 0.5, 20)
                    pool.Shape = Enum.PartType.Cylinder
                    pool.Color = Color3.fromRGB(150, 10, 10)
                    pool.Material = Enum.Material.Neon
                    pool.CFrame = hrp.CFrame * CFrame.Angles(0,0,math.rad(90))
                    pool.Anchored = true
                    pool.CanCollide = false
                    pool.Parent = workspace
                    Debris:AddItem(pool, 5)
                    task.spawn(function()
                        for i=1,5 do
                            if targetHum and (targetRoot.Position - pool.Position).Magnitude <= 10 then
                                dealDamage(targetHum, 8, "Blood Tick")
                                targetHum.WalkSpeed = 8
                                humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 8)
                            end
                            task.wait(1)
                        end
                        if targetHum then targetHum.WalkSpeed = 16 end
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

local function applyVisuals(model, title, maxHp, hColor, tColor, aColor, aLegs)
    model.Name = title
    local bc = model:FindFirstChildOfClass("BodyColors") or Instance.new("BodyColors", model)
    bc.HeadColor3 = hColor
    bc.TorsoColor3 = tColor
    bc.LeftArmColor3 = tColor
    bc.RightArmColor3 = tColor
    bc.LeftLegColor3 = aLegs
    bc.RightLegColor3 = aLegs

    local torso = model:FindFirstChild("Torso")
    if torso and aColor then
        local aura = Instance.new("ParticleEmitter", torso)
        aura.Color = ColorSequence.new(aColor, aColor)
        aura.Rate = 20
        aura.Size = NumberSequence.new(1.5, 0)
        aura.Lifetime = NumberRange.new(0.5, 1)
    end

    local head = model:FindFirstChild("Head")
    if head then
        attachHealthBar(model, head, title, maxHp)
    end

    local hum = model:FindFirstChild("Humanoid")
    if hum then
        hum.MaxHealth = maxHp
        hum.Health = maxHp
    end
    
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if hrp then model.PrimaryPart = hrp end
    
    return model
end

-- 1. Flame Demoness
local fDem = applyVisuals(sampleRig:Clone(), "FlameDemoness", 800, Color3.fromRGB(220,150,150), Color3.fromRGB(150,20,20), Color3.fromRGB(255,100,50), Color3.fromRGB(100,20,20))
createBossController("FlameDemoness", 800, 20).Parent = fDem
fDem.Parent = templateFolder

-- 2. Poison Demoness
local pDem = applyVisuals(sampleRig:Clone(), "PoisonDemoness", 800, Color3.fromRGB(200,220,200), Color3.fromRGB(60,20,80), Color3.fromRGB(50,200,50), Color3.fromRGB(20,50,20))
createBossController("PoisonDemoness", 800, 20).Parent = pDem
pDem.Parent = templateFolder

-- 3. Fist Demon
local fist = applyVisuals(sampleRig:Clone(), "FistDemon", 1000, Color3.fromRGB(200,150,150), Color3.fromRGB(180,50,50), Color3.fromRGB(255,150,50), Color3.fromRGB(100,20,20))
fist:ScaleTo(1.2)
createBossController("FistDemon", 1000, 30).Parent = fist
fist.Parent = templateFolder

-- 4. Sword Demon
local sw = applyVisuals(sampleRig:Clone(), "SwordDemon", 850, Color3.fromRGB(150,150,200), Color3.fromRGB(20,20,80), Color3.fromRGB(50,100,255), Color3.fromRGB(10,10,40))
createBossController("SwordDemon", 850, 35).Parent = sw
sw.Parent = templateFolder

-- 5. Supreme Demon
local sup = applyVisuals(sampleRig:Clone(), "SupremeDemon", 1200, Color3.fromRGB(150,100,200), Color3.fromRGB(10,10,10), Color3.fromRGB(150,50,255), Color3.fromRGB(10,10,10))
sup:ScaleTo(1.3)
createBossController("SupremeDemon", 1200, 50).Parent = sup
sup.Parent = templateFolder

-- 6. Blood Demon
local bd = applyVisuals(sampleRig:Clone(), "BloodDemon", 900, Color3.fromRGB(255,150,150), Color3.fromRGB(80,10,10), Color3.fromRGB(255,0,0), Color3.fromRGB(40,10,10))
createBossController("BloodDemon", 900, 25).Parent = bd
bd.Parent = templateFolder

-- Spawning at Demon Cult Tower
local tCenter = Vector3.new(1000, 5, 1500)
local spawns = {
    {t="FlameDemoness", p=tCenter + Vector3.new(50, 0, 50)},
    {t="PoisonDemoness", p=tCenter + Vector3.new(-50, 0, 50)},
    {t="FistDemon", p=tCenter + Vector3.new(50, 0, -50)},
    {t="SwordDemon", p=tCenter + Vector3.new(-50, 0, -50)},
    {t="SupremeDemon", p=tCenter + Vector3.new(0, 0, 70)},
    {t="BloodDemon", p=tCenter + Vector3.new(0, 0, -70)}
}

for _, cfg in ipairs(spawns) do
    local temp = templateFolder:FindFirstChild(cfg.t)
    if temp then
        local c = temp:Clone()
        local h = c:FindFirstChild("HumanoidRootPart")
        if h then
            c:PivotTo(CFrame.new(cfg.p))
            c.Parent = enemiesFolder
        end
    end
end

return "Successfully spawned Demon Cult Bosses!"
"""

def generate_bosses():
    print("Sending Bosses payload...")
    success, output = exec_code(BOSSES_LUA, timeout=20.0)
    print(f"Success: {success}")
    print(f"Output:\n{output}")
    return success

if __name__ == "__main__":
    generate_bosses()
