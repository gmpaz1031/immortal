local model = script.Parent
local humanoid = model:WaitForChild("Humanoid")
local hrp = model:WaitForChild("HumanoidRootPart")
local head = model:WaitForChild("Head")

local isBoss = false
local baseDamage = 16
local enemyTitle = "Azure Wind Swordsman"
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
