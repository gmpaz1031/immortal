local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s1 = enemies and enemies:FindFirstChild("Swordsman_1")
local hum = s1 and s1:FindFirstChildOfClass("Humanoid")
local animator = hum and hum:FindFirstChildOfClass("Animator")

-- Create custom Slash 1
local kfs = Instance.new("KeyframeSequence")
kfs.Name = "CustomSlash1"
kfs.Loop = false

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

-- Horizontal Slash:
-- 0.0s: Start
kfs:AddKeyframe(makeKf(0.0,
    CFrame.Angles(0, 0, 0),
    CFrame.Angles(0, 0, 0)
))
-- 0.15s: Windup back right
kfs:AddKeyframe(makeKf(0.15,
    CFrame.Angles(0, math.rad(-35), 0),
    CFrame.Angles(math.rad(75), math.rad(-45), math.rad(40)),
    CFrame.Angles(math.rad(20), math.rad(30), 0)
))
-- 0.30s: Full Horizontal Slash Sweep across the front
kfs:AddKeyframe(makeKf(0.30,
    CFrame.Angles(0, math.rad(40), 0),
    CFrame.Angles(math.rad(80), math.rad(55), math.rad(-35)),
    CFrame.Angles(math.rad(-15), math.rad(-20), 0)
))
-- 0.50s: Recovery
kfs:AddKeyframe(makeKf(0.50,
    CFrame.Angles(0, 0, 0),
    CFrame.Angles(0, 0, 0)
))

local animId = KeyframeSequenceProvider:RegisterKeyframeSequence(kfs)
local anim = Instance.new("Animation")
anim.AnimationId = animId
local track = animator:LoadAnimation(anim)
track.Priority = Enum.AnimationPriority.Action4

-- Position camera to see full front of Swordsman_1
local root = s1:FindFirstChild("HumanoidRootPart")
local cam = workspace.CurrentCamera
if cam and root then
    cam.CFrame = root.CFrame * CFrame.new(0, 0.5, -7) * CFrame.Angles(0, math.rad(180), 0)
end

-- Play animation and pause at peak strike (0.30s) so we can inspect the strike pose!
track:Play(0)
track.TimePosition = 0.30
track:AdjustSpeed(0)

return game:GetService("HttpService"):JSONEncode({
    success = true,
    animId = animId,
    timePos = track.TimePosition
})
