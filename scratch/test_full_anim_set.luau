-- scratch/test_full_anim_set.luau
-- Registers and verifies all 5 custom Swordsman animations in Studio

local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local function createR6KFS(name: string, loop: boolean, keyframes: { { time: number, torso: CFrame?, rightArm: CFrame?, leftArm: CFrame?, head: CFrame?, rightLeg: CFrame?, leftLeg: CFrame? } }): string
    local kfs = Instance.new("KeyframeSequence")
    kfs.Name = name
    kfs.Loop = loop

    for _, data in ipairs(keyframes) do
        local kf = Instance.new("Keyframe")
        kf.Time = data.time
        
        local hrpPose = Instance.new("Pose")
        hrpPose.Name = "HumanoidRootPart"
        
        local torsoPose = Instance.new("Pose")
        torsoPose.Name = "Torso"
        torsoPose.CFrame = data.torso or CFrame.new()
        hrpPose:AddSubPose(torsoPose)
        
        if data.rightArm then
            local p = Instance.new("Pose")
            p.Name = "Right Arm"
            p.CFrame = data.rightArm
            torsoPose:AddSubPose(p)
        end
        if data.leftArm then
            local p = Instance.new("Pose")
            p.Name = "Left Arm"
            p.CFrame = data.leftArm
            torsoPose:AddSubPose(p)
        end
        if data.head then
            local p = Instance.new("Pose")
            p.Name = "Head"
            p.CFrame = data.head
            torsoPose:AddSubPose(p)
        end
        if data.rightLeg then
            local p = Instance.new("Pose")
            p.Name = "Right Leg"
            p.CFrame = data.rightLeg
            torsoPose:AddSubPose(p)
        end
        if data.leftLeg then
            local p = Instance.new("Pose")
            p.Name = "Left Leg"
            p.CFrame = data.leftLeg
            torsoPose:AddSubPose(p)
        end
        
        kf:AddPose(hrpPose)
        kfs:AddKeyframe(kf)
    end

    return KeyframeSequenceProvider:RegisterKeyframeSequence(kfs)
end

-- 1. Combat Idle (Ready Guard Stance)
local idleAnimId = createR6KFS("SwordsmanCombatIdle", true, {
    { time = 0.0,
      torso = CFrame.Angles(0, math.rad(-15), 0),
      rightArm = CFrame.Angles(math.rad(65), math.rad(-25), math.rad(15)),
      leftArm = CFrame.Angles(math.rad(30), math.rad(25), math.rad(-10)),
      head = CFrame.Angles(0, math.rad(15), 0),
    },
    { time = 1.0,
      torso = CFrame.new(0, -0.04, 0) * CFrame.Angles(math.rad(-2), math.rad(-15), 0),
      rightArm = CFrame.Angles(math.rad(62), math.rad(-23), math.rad(13)),
      leftArm = CFrame.Angles(math.rad(28), math.rad(23), math.rad(-8)),
      head = CFrame.Angles(math.rad(2), math.rad(15), 0),
    },
    { time = 2.0,
      torso = CFrame.Angles(0, math.rad(-15), 0),
      rightArm = CFrame.Angles(math.rad(65), math.rad(-25), math.rad(15)),
      leftArm = CFrame.Angles(math.rad(30), math.rad(25), math.rad(-10)),
      head = CFrame.Angles(0, math.rad(15), 0),
    },
})

-- 2. Combat Walk (Velocity Stride)
local walkAnimId = createR6KFS("SwordsmanCombatWalk", true, {
    { time = 0.0,
      torso = CFrame.Angles(0, math.rad(-10), 0),
      rightArm = CFrame.Angles(math.rad(60), math.rad(-20), math.rad(10)),
      leftArm = CFrame.Angles(math.rad(20), math.rad(15), math.rad(-10)),
      rightLeg = CFrame.Angles(math.rad(28), 0, 0),
      leftLeg = CFrame.Angles(math.rad(-28), 0, 0),
    },
    { time = 0.35,
      torso = CFrame.new(0, 0.05, 0) * CFrame.Angles(0, math.rad(10), 0),
      rightArm = CFrame.Angles(math.rad(55), math.rad(-25), math.rad(15)),
      leftArm = CFrame.Angles(math.rad(25), math.rad(20), math.rad(-5)),
      rightLeg = CFrame.Angles(math.rad(-28), 0, 0),
      leftLeg = CFrame.Angles(math.rad(28), 0, 0),
    },
    { time = 0.70,
      torso = CFrame.Angles(0, math.rad(-10), 0),
      rightArm = CFrame.Angles(math.rad(60), math.rad(-20), math.rad(10)),
      leftArm = CFrame.Angles(math.rad(20), math.rad(15), math.rad(-10)),
      rightLeg = CFrame.Angles(math.rad(28), 0, 0),
      leftLeg = CFrame.Angles(math.rad(-28), 0, 0),
    },
})

-- 3. Combo 1: Horizontal Crescent Slash
local slashAnimId = createR6KFS("SwordsmanSlash", false, {
    { time = 0.0,
      torso = CFrame.Angles(0, math.rad(-15), 0),
      rightArm = CFrame.Angles(math.rad(65), math.rad(-25), math.rad(15)),
    },
    { time = 0.15,
      torso = CFrame.Angles(0, math.rad(-45), 0),
      rightArm = CFrame.Angles(math.rad(100), math.rad(-40), math.rad(30)),
      leftArm = CFrame.Angles(math.rad(20), math.rad(40), 0),
    },
    { time = 0.30,
      torso = CFrame.Angles(0, math.rad(45), 0),
      rightArm = CFrame.Angles(math.rad(70), math.rad(50), math.rad(-30)),
      leftArm = CFrame.Angles(math.rad(-20), math.rad(-20), 0),
    },
    { time = 0.48,
      torso = CFrame.Angles(0, math.rad(-15), 0),
      rightArm = CFrame.Angles(math.rad(65), math.rad(-25), math.rad(15)),
    },
})

-- 4. Combo 2: Sky-Cleaving Overhead Chop
local overheadAnimId = createR6KFS("SwordsmanOverhead", false, {
    { time = 0.0,
      torso = CFrame.Angles(0, math.rad(-15), 0),
      rightArm = CFrame.Angles(math.rad(65), math.rad(-25), math.rad(15)),
    },
    { time = 0.18,
      torso = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-12), 0, 0),
      rightArm = CFrame.Angles(math.rad(160), math.rad(-10), math.rad(10)),
      leftArm = CFrame.Angles(math.rad(140), math.rad(20), math.rad(-10)),
    },
    { time = 0.35,
      torso = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(25), 0, 0),
      rightArm = CFrame.Angles(math.rad(20), 0, 0),
      leftArm = CFrame.Angles(math.rad(10), math.rad(-20), 0),
    },
    { time = 0.55,
      torso = CFrame.Angles(0, math.rad(-15), 0),
      rightArm = CFrame.Angles(math.rad(65), math.rad(-25), math.rad(15)),
    },
})

-- 5. Combo 3: Whirlwind Double Cross-Slash (Replacing Lunge!)
local crossSlashAnimId = createR6KFS("SwordsmanCrossSlash", false, {
    { time = 0.0,
      torso = CFrame.Angles(0, math.rad(-15), 0),
      rightArm = CFrame.Angles(math.rad(65), math.rad(-25), math.rad(15)),
    },
    -- Strike 1: Upward diagonal slash
    { time = 0.12,
      torso = CFrame.Angles(0, math.rad(-30), 0),
      rightArm = CFrame.Angles(math.rad(20), math.rad(-30), math.rad(40)),
    },
    { time = 0.24,
      torso = CFrame.Angles(0, math.rad(35), 0),
      rightArm = CFrame.Angles(math.rad(120), math.rad(30), math.rad(-30)),
    },
    -- Strike 2: Downward diagonal cross-cut
    { time = 0.38,
      torso = CFrame.Angles(0, math.rad(40), 0),
      rightArm = CFrame.Angles(math.rad(130), math.rad(40), math.rad(-10)),
    },
    { time = 0.52,
      torso = CFrame.Angles(0, math.rad(-25), 0),
      rightArm = CFrame.Angles(math.rad(15), math.rad(-35), math.rad(25)),
    },
    -- Recovery
    { time = 0.68,
      torso = CFrame.Angles(0, math.rad(-15), 0),
      rightArm = CFrame.Angles(math.rad(65), math.rad(-25), math.rad(15)),
    },
})

-- Test loading on Swordsman_1
local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s1 = enemies and enemies:FindFirstChild("Swordsman_1")
local hum = s1 and s1:FindFirstChildOfClass("Humanoid")
local animator = hum and hum:FindFirstChildOfClass("Animator")

local t1 = animator:LoadAnimation((function() local a = Instance.new("Animation"); a.AnimationId = idleAnimId; return a end)())
local t2 = animator:LoadAnimation((function() local a = Instance.new("Animation"); a.AnimationId = walkAnimId; return a end)())
local t3 = animator:LoadAnimation((function() local a = Instance.new("Animation"); a.AnimationId = slashAnimId; return a end)())
local t4 = animator:LoadAnimation((function() local a = Instance.new("Animation"); a.AnimationId = overheadAnimId; return a end)())
local t5 = animator:LoadAnimation((function() local a = Instance.new("Animation"); a.AnimationId = crossSlashAnimId; return a end)())

task.wait(0.1)

return game:GetService("HttpService"):JSONEncode({
    success = true,
    idleAnimId = idleAnimId,
    walkAnimId = walkAnimId,
    slashAnimId = slashAnimId,
    overheadAnimId = overheadAnimId,
    crossSlashAnimId = crossSlashAnimId,
    tracks = {
        idle = t1.Length,
        walk = t2.Length,
        slash = t3.Length,
        overhead = t4.Length,
        crossSlash = t5.Length,
    }
})
