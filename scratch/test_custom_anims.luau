local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

-- Helper to construct R6 KeyframeSequence
local function createR6KFS(name: string, keyframes: { { time: number, torso: CFrame?, rightArm: CFrame?, leftArm: CFrame?, head: CFrame?, rightLeg: CFrame?, leftLeg: CFrame? } }): string
    local kfs = Instance.new("KeyframeSequence")
    kfs.Name = name
    kfs.Loop = false

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

-- 1. Swordsman Combat Idle (Ready Guard stance)
local idleAnimId = createR6KFS("SwordsmanCombatIdle", {
    { time = 0.0,
      torso = CFrame.Angles(0, math.rad(-15), 0),
      rightArm = CFrame.Angles(math.rad(65), math.rad(-25), math.rad(15)),
      leftArm = CFrame.Angles(math.rad(30), math.rad(25), math.rad(-10)),
      head = CFrame.Angles(0, math.rad(15), 0),
      rightLeg = CFrame.Angles(0, 0, math.rad(5)),
      leftLeg = CFrame.Angles(0, 0, math.rad(-5)),
    },
    { time = 1.0,
      torso = CFrame.new(0, -0.05, 0) * CFrame.Angles(math.rad(-2), math.rad(-15), 0),
      rightArm = CFrame.Angles(math.rad(63), math.rad(-23), math.rad(13)),
      leftArm = CFrame.Angles(math.rad(28), math.rad(23), math.rad(-8)),
      head = CFrame.Angles(math.rad(2), math.rad(15), 0),
      rightLeg = CFrame.Angles(0, 0, math.rad(5)),
      leftLeg = CFrame.Angles(0, 0, math.rad(-5)),
    },
    { time = 2.0,
      torso = CFrame.Angles(0, math.rad(-15), 0),
      rightArm = CFrame.Angles(math.rad(65), math.rad(-25), math.rad(15)),
      leftArm = CFrame.Angles(math.rad(30), math.rad(25), math.rad(-10)),
      head = CFrame.Angles(0, math.rad(15), 0),
      rightLeg = CFrame.Angles(0, 0, math.rad(5)),
      leftLeg = CFrame.Angles(0, 0, math.rad(-5)),
    },
})

-- 2. Attack 1: Horizontal Crescent Slash
local slash1Id = createR6KFS("SwordsmanSlash1", {
    { time = 0.0,
      torso = CFrame.Angles(0, math.rad(-15), 0),
      rightArm = CFrame.Angles(math.rad(65), math.rad(-25), math.rad(15)),
    },
    -- Windup back
    { time = 0.15,
      torso = CFrame.Angles(0, math.rad(-45), 0),
      rightArm = CFrame.Angles(math.rad(100), math.rad(-40), math.rad(30)),
      leftArm = CFrame.Angles(math.rad(20), math.rad(40), 0),
      head = CFrame.Angles(0, math.rad(30), 0),
    },
    -- Forward strike
    { time = 0.35,
      torso = CFrame.Angles(0, math.rad(45), 0),
      rightArm = CFrame.Angles(math.rad(70), math.rad(50), math.rad(-30)),
      leftArm = CFrame.Angles(math.rad(-20), math.rad(-20), 0),
      head = CFrame.Angles(0, math.rad(-25), 0),
    },
    -- Follow-through
    { time = 0.50,
      torso = CFrame.Angles(0, math.rad(30), 0),
      rightArm = CFrame.Angles(math.rad(50), math.rad(40), math.rad(-20)),
    },
    -- Recover
    { time = 0.65,
      torso = CFrame.Angles(0, math.rad(-15), 0),
      rightArm = CFrame.Angles(math.rad(65), math.rad(-25), math.rad(15)),
    }
})

-- 3. Attack 2: Heavy Overhead Cleave
local slash2Id = createR6KFS("SwordsmanSlash2", {
    { time = 0.0,
      torso = CFrame.Angles(0, math.rad(-15), 0),
      rightArm = CFrame.Angles(math.rad(65), math.rad(-25), math.rad(15)),
    },
    -- Windup high overhead
    { time = 0.20,
      torso = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-10), 0, 0),
      rightArm = CFrame.Angles(math.rad(160), math.rad(-10), math.rad(10)),
      leftArm = CFrame.Angles(math.rad(140), math.rad(20), math.rad(-10)),
      head = CFrame.Angles(math.rad(-15), 0, 0),
    },
    -- Downward slam
    { time = 0.40,
      torso = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(25), 0, 0),
      rightArm = CFrame.Angles(math.rad(20), 0, 0),
      leftArm = CFrame.Angles(math.rad(10), math.rad(-20), 0),
      head = CFrame.Angles(math.rad(15), 0, 0),
    },
    -- Impact hold
    { time = 0.55,
      torso = CFrame.new(0, -0.15, 0) * CFrame.Angles(math.rad(18), 0, 0),
      rightArm = CFrame.Angles(math.rad(30), 0, 0),
    },
    -- Recover
    { time = 0.70,
      torso = CFrame.Angles(0, math.rad(-15), 0),
      rightArm = CFrame.Angles(math.rad(65), math.rad(-25), math.rad(15)),
    }
})

-- 4. Attack 3: Dynamic Double Cross-Slash (Replacing the goofy lunge!)
local slash3Id = createR6KFS("SwordsmanSlash3", {
    { time = 0.0,
      torso = CFrame.Angles(0, math.rad(-15), 0),
      rightArm = CFrame.Angles(math.rad(65), math.rad(-25), math.rad(15)),
    },
    -- Slash 1 windup low-left
    { time = 0.12,
      torso = CFrame.Angles(0, math.rad(-30), 0),
      rightArm = CFrame.Angles(math.rad(20), math.rad(-30), math.rad(40)),
    },
    -- Slash 1 strike upward-right
    { time = 0.28,
      torso = CFrame.Angles(0, math.rad(35), 0),
      rightArm = CFrame.Angles(math.rad(120), math.rad(30), math.rad(-30)),
    },
    -- Slash 2 windup high-right
    { time = 0.42,
      torso = CFrame.Angles(0, math.rad(40), 0),
      rightArm = CFrame.Angles(math.rad(130), math.rad(40), math.rad(-10)),
    },
    -- Slash 2 strike downward-left (finishing the X cross-cut)
    { time = 0.58,
      torso = CFrame.Angles(0, math.rad(-25), 0),
      rightArm = CFrame.Angles(math.rad(15), math.rad(-35), math.rad(25)),
    },
    -- Recover
    { time = 0.75,
      torso = CFrame.Angles(0, math.rad(-15), 0),
      rightArm = CFrame.Angles(math.rad(65), math.rad(-25), math.rad(15)),
    }
})

return game:GetService("HttpService"):JSONEncode({
    idleAnimId = idleAnimId,
    slash1Id = slash1Id,
    slash2Id = slash2Id,
    slash3Id = slash3Id,
})
