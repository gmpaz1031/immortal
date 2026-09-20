local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local kfs = Instance.new("KeyframeSequence")
kfs.Name = "RightArmCrossSlash"
kfs.Loop = false

local function makeArmKf(timeVal, armCF)
    local kf = Instance.new("Keyframe")
    kf.Time = timeVal
    
    local hrpPose = Instance.new("Pose")
    hrpPose.Name = "HumanoidRootPart"
    
    local torsoPose = Instance.new("Pose")
    torsoPose.Name = "Torso"
    -- Torso CFrame is CFrame.new() so it doesn't rotate torso
    torsoPose.CFrame = CFrame.new()
    hrpPose:AddSubPose(torsoPose)
    
    local armPose = Instance.new("Pose")
    armPose.Name = "Right Arm"
    armPose.CFrame = armCF
    torsoPose:AddSubPose(armPose)
    
    kf:AddPose(hrpPose)
    return kf
end

-- Double slash with Right Arm only:
-- 0.0s: Start
kfs:AddKeyframe(makeArmKf(0.0, CFrame.Angles(0, 0, 0)))
-- 0.15s: Swing back high
kfs:AddKeyframe(makeArmKf(0.15, CFrame.Angles(math.rad(110), math.rad(-30), math.rad(25))))
-- 0.30s: Diagonal downward cut across
kfs:AddKeyframe(makeArmKf(0.30, CFrame.Angles(math.rad(25), math.rad(50), math.rad(-30))))
-- 0.45s: Reverse up-cut
kfs:AddKeyframe(makeArmKf(0.45, CFrame.Angles(math.rad(95), math.rad(30), math.rad(-15))))
-- 0.60s: Reset
kfs:AddKeyframe(makeArmKf(0.60, CFrame.Angles(0, 0, 0)))

local animId = KeyframeSequenceProvider:RegisterKeyframeSequence(kfs)

local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s4 = enemies and enemies:FindFirstChild("Swordsman_4")
local hum = s4 and s4:FindFirstChildOfClass("Humanoid")
local animator = hum and hum:FindFirstChildOfClass("Animator")

local anim = Instance.new("Animation")
anim.AnimationId = animId
local track = animator:LoadAnimation(anim)
track.Priority = Enum.AnimationPriority.Action

return game:GetService("HttpService"):JSONEncode({
    success = true,
    animId = animId,
    trackLength = track.Length
})
