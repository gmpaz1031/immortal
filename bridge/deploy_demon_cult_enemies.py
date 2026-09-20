import sys
import os
import time

sys.path.append(os.path.dirname(__file__))
from exec import exec_code

ENEMIES_LUA = """
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

local enemiesFolder = Workspace:FindFirstChild("DemonCult_Enemies")
if enemiesFolder then
    enemiesFolder:Destroy()
end
enemiesFolder = Instance.new("Folder")
enemiesFolder.Name = "DemonCult_Enemies"
enemiesFolder.Parent = Workspace

local sampleRig = Workspace:FindFirstChild("SAMPLEENEMYMODEL")
if not sampleRig then
    return "Error: Workspace.SAMPLEENEMYMODEL not found."
end

local templateFolder = ServerStorage:FindFirstChild("DemonCult_EnemyTemplates")
if templateFolder then
    templateFolder:Destroy()
end
templateFolder = Instance.new("Folder")
templateFolder.Name = "DemonCult_EnemyTemplates"
templateFolder.Parent = ServerStorage

local function createPart(name, size, color, material, parent)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Color = color
    p.Material = material
    p.CanCollide = false
    p.Massless = true
    p.Parent = parent
    return p
end

local function weldParts(p0, p1, c0)
    local w = Instance.new("WeldConstraint")
    w.Part0 = p0
    w.Part1 = p1
    p1.CFrame = p0.CFrame * (c0 or CFrame.new())
    w.Parent = p1
    return w
end

local function attachHealthBar(model, head, name, maxHealth, isBoss)
    local bg = Instance.new("BillboardGui")
    bg.Name = "HealthBarGui"
    bg.Adornee = head
    bg.Size = UDim2.new(4.2, 0, 0.88, 0)
    bg.StudsOffset = Vector3.new(0, 3, 0)
    bg.AlwaysOnTop = false
    if isBoss then
        bg.Size = UDim2.new(6.5, 0, 1.2, 0)
        bg.StudsOffset = Vector3.new(0, 4.5, 0)
        bg.MaxDistance = 58
    else
        bg.MaxDistance = 44
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

-- CONTROLLER GENERATOR
local function createControllerScript(enemyType, maxHp, damage)
    local s = Instance.new("Script")
    s.Name = "EnemyController"
    
    local header = string.format([==[
local model = script.Parent
local humanoid = model:WaitForChild("Humanoid")
local hrp = model:WaitForChild("HumanoidRootPart")
local enemyType = "%s"
local baseDamage = %d
]==], enemyType, damage)

    local body = [==[
local isDead = false
local spawnCFrame = hrp.CFrame

local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
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

humanoid.Running:Connect(function(speed)
    if isDead then return end
    if speed > 0.8 then
        if not walkTrack.IsPlaying then walkTrack:Play(0.2) end
    else
        if walkTrack.IsPlaying then walkTrack:Stop(0.2) end
    end
end)

humanoid.StateChanged:Connect(function(oldState, newState)
    if isDead and newState == Enum.HumanoidStateType.Jumping then jumpTrack:Play(0.08) end
end)

local trail = nil
for _, d in ipairs(model:GetDescendants()) do if d:IsA("Trail") then trail = d break end end

local DamageService = nil
pcall(function()
    local sss = game:GetService("ServerScriptService")
    local ds = sss:FindFirstChild("DamageService", true)
    if ds then DamageService = require(ds) end
end)

local function dealDamage(targetHum, dmg, name)
    if DamageService and DamageService.applyDamage then
        DamageService.applyDamage(targetHum, dmg, nil, name)
    else
        targetHum:TakeDamage(dmg)
    end
end

humanoid.Died:Connect(function()
    isDead = true
    pcall(function() idleTrack:Stop() walkTrack:Stop() slashTrack:Stop() end)
    task.delay(2.5, function() if model.Parent then model:Destroy() end end)
end)

local CHASE_RANGE = 45
local ATTACK_RANGE = 7
local ATTACK_COOLDOWN = 1.8
local lastAttack = 0
local lastSkill = 0

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

            if enemyType == "Elder" then
                -- Demonic Elder Skills
                -- Near skill: Pull + Damage
                if dist <= 20 and (tick() - lastSkill) >= 6 then
                    lastSkill = tick()
                    -- Create Giant Hand
                    local hand = Instance.new("Part")
                    hand.Size = Vector3.new(4, 4, 4)
                    hand.Color = Color3.fromRGB(200, 30, 30)
                    hand.Material = Enum.Material.Neon
                    hand.Anchored = true
                    hand.CanCollide = false
                    hand.CFrame = targetRoot.CFrame * CFrame.new(0, -3, 0)
                    hand.Parent = workspace
                    game.Debris:AddItem(hand, 1)

                    -- Pull player
                    targetRoot.CFrame = targetRoot.CFrame:Lerp(hrp.CFrame, 0.5)
                    dealDamage(targetHum, baseDamage * 1.5, "Demonic Pull")

                -- Far skill: Shoot Flame Hands
                elseif dist > 20 and dist < 60 and (tick() - lastSkill) >= 3 then
                    lastSkill = tick()
                    hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetRoot.Position.X, hrp.Position.Y, targetRoot.Position.Z))
                    
                    local proj = Instance.new("Part")
                    proj.Size = Vector3.new(2, 2, 2)
                    proj.Color = Color3.fromRGB(255, 80, 40)
                    proj.Material = Enum.Material.Neon
                    proj.CFrame = hrp.CFrame * CFrame.new(0, 1, -3)
                    proj.Parent = workspace
                    
                    local bv = Instance.new("BodyVelocity")
                    bv.Velocity = (targetRoot.Position - proj.Position).Unit * 40
                    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                    bv.Parent = proj

                    game.Debris:AddItem(proj, 3)

                    proj.Touched:Connect(function(hit)
                        if hit.Parent and hit.Parent:FindFirstChild("Humanoid") and hit.Parent ~= model then
                            dealDamage(hit.Parent.Humanoid, baseDamage, "Flame Hand")
                            proj:Destroy()
                        end
                    end)
                else
                    humanoid:MoveTo(targetRoot.Position)
                end

            else
                -- Normal / Senior Cultist Combat
                if dist <= ATTACK_RANGE and (tick() - lastAttack) >= ATTACK_COOLDOWN then
                    lastAttack = tick()
                    hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetRoot.Position.X, hrp.Position.Y, targetRoot.Position.Z))
                    slashTrack:Play(0.05, 1, 1.2)
                    if trail then trail.Enabled = true end

                    task.delay(0.22, function()
                        if trail then trail.Enabled = false end
                        if not isDead and targetHum and targetHum.Health > 0 and (targetRoot.Position - hrp.Position).Magnitude <= ATTACK_RANGE + 3 then
                            dealDamage(targetHum, baseDamage, enemyType)
                        end
                    end)
                else
                    humanoid:MoveTo(targetRoot.Position)
                    if humanoid.MoveDirection.Magnitude > 0.1 and hrp.AssemblyLinearVelocity.Magnitude < 1.0 then
                        humanoid.Jump = true
                    end
                end
            end
        else
            if (hrp.Position - spawnCFrame.Position).Magnitude > 30 then
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

-- 1. Demon Cultist
local cultist = sampleRig:Clone()
cultist.Name = "DemonCultist"
local bodyColors = cultist:FindFirstChildOfClass("BodyColors") or Instance.new("BodyColors", cultist)
bodyColors.HeadColor3 = Color3.fromRGB(200, 170, 140)
bodyColors.TorsoColor3 = Color3.fromRGB(20, 5, 5)
bodyColors.LeftArmColor3 = Color3.fromRGB(20, 5, 5)
bodyColors.RightArmColor3 = Color3.fromRGB(20, 5, 5)
bodyColors.LeftLegColor3 = Color3.fromRGB(15, 10, 10)
bodyColors.RightLegColor3 = Color3.fromRGB(15, 10, 10)

local rArm = cultist:FindFirstChild("Right Arm")
if rArm then
    local hilt = createPart("Hilt", Vector3.new(0.2, 1, 0.2), Color3.fromRGB(30, 30, 30), Enum.Material.Wood, cultist)
    weldParts(rArm, hilt, CFrame.new(0, -1, -0.2) * CFrame.Angles(math.rad(65), 0, 0))
    local blade = createPart("Blade", Vector3.new(0.1, 3.5, 0.4), Color3.fromRGB(200, 30, 30), Enum.Material.Neon, cultist)
    weldParts(hilt, blade, CFrame.new(0, 2.2, 0))

    local att0 = Instance.new("Attachment", blade)
    att0.Position = Vector3.new(0, -1.7, 0)
    local att1 = Instance.new("Attachment", blade)
    att1.Position = Vector3.new(0, 1.7, 0)
    local tr = Instance.new("Trail", blade)
    tr.Attachment0 = att0
    tr.Attachment1 = att1
    tr.Color = ColorSequence.new(Color3.fromRGB(255, 50, 50), Color3.fromRGB(100, 0, 0))
    tr.Lifetime = 0.3
    tr.Enabled = false
end

local cHead = cultist:FindFirstChild("Head")
if cHead then
    attachHealthBar(cultist, cHead, "Demon Cultist", 120, false)
end
local cHum = cultist:FindFirstChild("Humanoid")
if cHum then
    cHum.MaxHealth = 120
    cHum.Health = 120
end
createControllerScript("Demon Cultist", 120, 15).Parent = cultist
cultist.PrimaryPart = cultist:FindFirstChild("HumanoidRootPart")
cultist.Parent = templateFolder

-- 2. Senior Demon Cultist
local senior = cultist:Clone()
senior.Name = "SeniorDemonCultist"
local sBodyColors = senior:FindFirstChildOfClass("BodyColors")
if sBodyColors then sBodyColors.TorsoColor3 = Color3.fromRGB(50, 10, 10) end
local blade2 = senior:FindFirstChild("Blade", true)
if blade2 then
    local fire = Instance.new("ParticleEmitter", blade2)
    fire.Color = ColorSequence.new(Color3.fromRGB(255, 80, 20), Color3.fromRGB(255, 20, 20))
    fire.Rate = 20
    fire.Size = NumberSequence.new(0.5, 0)
    fire.Lifetime = NumberRange.new(0.5, 1)
end
local sHead = senior:FindFirstChild("Head")
if sHead then
    attachHealthBar(senior, sHead, "Senior Demon Cultist", 250, false)
end
local sHum = senior:FindFirstChild("Humanoid")
if sHum then
    sHum.MaxHealth = 250
    sHum.Health = 250
end
local sc = senior:FindFirstChild("EnemyController")
if sc then sc:Destroy() end
createControllerScript("Senior Demon Cultist", 250, 25).Parent = senior
senior.Parent = templateFolder

-- 3. Demonic Elder
local elder = sampleRig:Clone()
elder.Name = "DemonicElder"
elder:ScaleTo(1.1)
local bColors2 = elder:FindFirstChildOfClass("BodyColors") or Instance.new("BodyColors", elder)
bColors2.HeadColor3 = Color3.fromRGB(220, 200, 200)
bColors2.TorsoColor3 = Color3.fromRGB(80, 0, 0)
bColors2.LeftArmColor3 = Color3.fromRGB(80, 0, 0)
bColors2.RightArmColor3 = Color3.fromRGB(80, 0, 0)
bColors2.LeftLegColor3 = Color3.fromRGB(30, 0, 0)
bColors2.RightLegColor3 = Color3.fromRGB(30, 0, 0)

local eTorso = elder:FindFirstChild("Torso")
if eTorso then
    local aura = Instance.new("ParticleEmitter", eTorso)
    aura.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0), Color3.fromRGB(50, 0, 0))
    aura.Rate = 15
    aura.Size = NumberSequence.new(1.5, 0)
    aura.Lifetime = NumberRange.new(1, 2)
end

local eHead = elder:FindFirstChild("Head")
if eHead then
    attachHealthBar(elder, eHead, "Demonic Elder [BOSS]", 800, true)
end
local eHum = elder:FindFirstChild("Humanoid")
if eHum then
    eHum.MaxHealth = 800
    eHum.Health = 800
end
createControllerScript("Elder", 800, 45).Parent = elder
elder.PrimaryPart = elder:FindFirstChild("HumanoidRootPart")
elder.Parent = templateFolder

-- Spawning Phase
local spawnLocations = {
    {temp="DemonCultist", pos=Vector3.new(1020, 5, 1020)},
    {temp="DemonCultist", pos=Vector3.new(1030, 5, 980)},
    {temp="DemonCultist", pos=Vector3.new(970, 5, 1020)},
    {temp="DemonCultist", pos=Vector3.new(980, 5, 980)},
    {temp="DemonCultist", pos=Vector3.new(1000, 5, 950)},
    {temp="SeniorDemonCultist", pos=Vector3.new(1015, 5, 1000)},
    {temp="SeniorDemonCultist", pos=Vector3.new(985, 5, 1000)},
    {temp="DemonicElder", pos=Vector3.new(1000, 5, 1010)}
}

for _, cfg in ipairs(spawnLocations) do
    local t = templateFolder:FindFirstChild(cfg.temp)
    if t then
        local clone = t:Clone()
        local h = clone:FindFirstChild("HumanoidRootPart")
        if h then
            clone:PivotTo(CFrame.new(cfg.pos))
            clone.Parent = enemiesFolder
        end
    end
end

return "Successfully created and spawned Demon Cult enemies."
"""

def generate_enemies():
    print("Sending Demon Cult Enemies payload to Roblox Studio...")
    success, output = exec_code(ENEMIES_LUA, timeout=20.0)
    print(f"Success: {success}")
    print(f"Output:\n{output}")
    return success

if __name__ == "__main__":
    generate_enemies()
