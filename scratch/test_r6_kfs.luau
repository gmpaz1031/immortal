local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local kfs = Instance.new("KeyframeSequence")
kfs.Name = "R6Slash"

local function makeKf(timeVal, torsoCF, rightArmCF, leftArmCF, headCF)
    local kf = Instance.new("Keyframe")
    kf.Time = timeVal
    
    local hrpPose = Instance.new("Pose")
    hrpPose.Name = "HumanoidRootPart"
    
    local torsoPose = Instance.new("Pose")
    torsoPose.Name = "Torso"
    torsoPose.CFrame = torsoCF or CFrame.new()
    hrpPose:AddSubPose(torsoPose)
    
    if rightArmPose or rightArmCF then
        local ra = Instance.new("Pose")
        ra.Name = "Right Arm"
        ra.CFrame = rightArmCF or CFrame.new()
        torsoPose:AddSubPose(ra)
    end
    if leftArmCF then
        local la = Instance.new("Pose")
        la.Name = "Left Arm"
        la.CFrame = leftArmCF or CFrame.new()
        torsoPose:AddSubPose(la)
    end
    if headCF then
        local h = Instance.new("Pose")
        h.Name = "Head"
        h.CFrame = headCF or CFrame.new()
        torsoPose:AddSubPose(h)
    end
    
    kf:AddPose(hrpPose)
    return kf
end

kfs:AddKeyframe(makeKf(0.0, CFrame.Angles(0, 0, 0), CFrame.Angles(0, 0, 0)))
kfs:AddKeyframe(makeKf(0.3, CFrame.Angles(0, math.rad(-30), 0), CFrame.Angles(math.rad(110), math.rad(-20), math.rad(30))))
kfs:AddKeyframe(makeKf(0.6, CFrame.Angles(0, math.rad(40), 0), CFrame.Angles(math.rad(10), math.rad(40), math.rad(-20))))

local animId = KeyframeSequenceProvider:RegisterKeyframeSequence(kfs)

local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s1 = enemies and enemies:FindFirstChild("Swordsman_1")
local hum = s1 and s1:FindFirstChildOfClass("Humanoid")
local animator = hum:FindFirstChildOfClass("Animator")

local anim = Instance.new("Animation")
anim.AnimationId = animId
local track = animator:LoadAnimation(anim)
track:Play()

return game:GetService("HttpService"):JSONEncode({
    animId = animId,
    isPlaying = track.IsPlaying,
    length = track.Length
})
