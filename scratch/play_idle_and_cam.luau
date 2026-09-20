local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s1 = enemies and enemies:FindFirstChild("Swordsman_1")
local hum = s1 and s1:FindFirstChildOfClass("Humanoid")
local root = s1 and s1:FindFirstChild("HumanoidRootPart")
local animator = hum and (hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum))

-- Stop existing tracks
for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
    t:Stop(0)
end

-- Create SwordsmanCombatIdle
local kfs = Instance.new("KeyframeSequence")
kfs.Name = "SwordsmanCombatIdle"
kfs.Loop = true

local function makeKf(timeVal, torsoCF, rightArmCF, leftArmCF, headCF)
    local kf = Instance.new("Keyframe")
    kf.Time = timeVal
    
    local hrpPose = Instance.new("Pose")
    hrpPose.Name = "HumanoidRootPart"
    
    local torsoPose = Instance.new("Pose")
    torsoPose.Name = "Torso"
    torsoPose.CFrame = torsoCF or CFrame.new()
    hrpPose:AddSubPose(torsoPose)
    
    if rightArmCF then
        local p = Instance.new("Pose")
        p.Name = "Right Arm"
        p.CFrame = rightArmCF
        torsoPose:AddSubPose(p)
    end
    if leftArmCF then
        local p = Instance.new("Pose")
        p.Name = "Left Arm"
        p.CFrame = leftArmCF
        torsoPose:AddSubPose(p)
    end
    if headCF then
        local p = Instance.new("Pose")
        p.Name = "Head"
        p.CFrame = headCF
        torsoPose:AddSubPose(p)
    end
    
    kf:AddPose(hrpPose)
    return kf
end

-- Ready combat stance: Torso turned slightly, sword held in front in ready guard, left arm balanced
kfs:AddKeyframe(makeKf(0.0,
    CFrame.Angles(0, math.rad(-15), 0),
    CFrame.Angles(math.rad(60), math.rad(-25), math.rad(15)),
    CFrame.Angles(math.rad(25), math.rad(20), math.rad(-10)),
    CFrame.Angles(0, math.rad(15), 0)
))
kfs:AddKeyframe(makeKf(1.0,
    CFrame.new(0, -0.05, 0) * CFrame.Angles(math.rad(-2), math.rad(-15), 0),
    CFrame.Angles(math.rad(58), math.rad(-23), math.rad(13)),
    CFrame.Angles(math.rad(23), math.rad(18), math.rad(-8)),
    CFrame.Angles(math.rad(2), math.rad(15), 0)
))
kfs:AddKeyframe(makeKf(2.0,
    CFrame.Angles(0, math.rad(-15), 0),
    CFrame.Angles(math.rad(60), math.rad(-25), math.rad(15)),
    CFrame.Angles(math.rad(25), math.rad(20), math.rad(-10)),
    CFrame.Angles(0, math.rad(15), 0)
))

local animId = KeyframeSequenceProvider:RegisterKeyframeSequence(kfs)
local anim = Instance.new("Animation")
anim.AnimationId = animId
local track = animator:LoadAnimation(anim)
track.Priority = Enum.AnimationPriority.Action
track.Looped = true
track:Play(0.1)

-- Position camera to look right at Swordsman_1
local cam = workspace.CurrentCamera
if cam and root then
    local targetPos = root.Position + Vector3.new(0, 0.5, 0)
    local camPos = targetPos + root.CFrame.LookVector * 7 + Vector3.new(2, 1, 0)
    cam.CFrame = CFrame.lookAt(camPos, targetPos)
end

return game:GetService("HttpService"):JSONEncode({
    success = true,
    animId = animId,
    isPlaying = track.IsPlaying,
    rootPos = tostring(root and root.Position),
})
