local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local kfs = Instance.new("KeyframeSequence")
kfs.Name = "CustomSwordSlash"

local kf1 = Instance.new("Keyframe")
kf1.Time = 0

local rootPose = Instance.new("Pose")
rootPose.Name = "Torso"

local rightArmPose = Instance.new("Pose")
rightArmPose.Name = "Right Arm"
rightArmPose.CFrame = CFrame.Angles(0, 0, 0)
rootPose:AddSubPose(rightArmPose)
kf1:AddPose(rootPose)
kfs:AddKeyframe(kf1)

local kf2 = Instance.new("Keyframe")
kf2.Time = 0.3
local rootPose2 = Instance.new("Pose")
rootPose2.Name = "Torso"
local rightArmPose2 = Instance.new("Pose")
rightArmPose2.Name = "Right Arm"
rightArmPose2.CFrame = CFrame.Angles(math.rad(90), math.rad(45), 0)
rootPose2:AddSubPose(rightArmPose2)
kf2:AddPose(rootPose2)
kfs:AddKeyframe(kf2)

local success, animId = pcall(function()
    return KeyframeSequenceProvider:RegisterKeyframeSequence(kfs)
end)

return game:GetService("HttpService"):JSONEncode({
    success = success,
    animId = animId
})
