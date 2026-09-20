local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local kfs = Instance.new("KeyframeSequence")
kfs.Name = "R6Slash"

local function makeKf(timeVal, torsoCF, rightArmCF)
    local kf = Instance.new("Keyframe")
    kf.Time = timeVal
    
    local hrpPose = Instance.new("Pose")
    hrpPose.Name = "HumanoidRootPart"
    
    local torsoPose = Instance.new("Pose")
    torsoPose.Name = "Torso"
    torsoPose.CFrame = torsoCF or CFrame.new()
    hrpPose:AddSubPose(torsoPose)
    
    local ra = Instance.new("Pose")
    ra.Name = "Right Arm"
    ra.CFrame = rightArmCF or CFrame.new()
    torsoPose:AddSubPose(ra)
    
    kf:AddPose(hrpPose)
    return kf
end

kfs:AddKeyframe(makeKf(0.0, CFrame.Angles(0, 0, 0), CFrame.Angles(0, 0, 0)))
kfs:AddKeyframe(makeKf(0.5, CFrame.Angles(0, math.rad(-30), 0), CFrame.Angles(math.rad(90), 0, 0)))

local animId = KeyframeSequenceProvider:RegisterKeyframeSequence(kfs)
local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s1 = enemies:FindFirstChild("Swordsman_1")
local hum = s1:FindFirstChildOfClass("Humanoid")
local animator = hum:FindFirstChildOfClass("Animator")

local anim = Instance.new("Animation")
anim.AnimationId = animId
local track = animator:LoadAnimation(anim)
track:Play()

task.wait(0.2)

return game:GetService("HttpService"):JSONEncode({
    animId = animId,
    isPlaying = track.IsPlaying,
    length = track.Length,
    timePosition = track.TimePosition
})
