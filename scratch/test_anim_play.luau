local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local kfs = Instance.new("KeyframeSequence")
kfs.Name = "TestAnim"

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
kf2.Time = 0.5
local rootPose2 = Instance.new("Pose")
rootPose2.Name = "Torso"
local rightArmPose2 = Instance.new("Pose")
rightArmPose2.Name = "Right Arm"
rightArmPose2.CFrame = CFrame.Angles(math.rad(90), 0, 0)
rootPose2:AddSubPose(rightArmPose2)
kf2:AddPose(rootPose2)
kfs:AddKeyframe(kf2)

local animId = KeyframeSequenceProvider:RegisterKeyframeSequence(kfs)

local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s1 = enemies and enemies:FindFirstChild("Swordsman_1")
local hum = s1 and s1:FindFirstChildOfClass("Humanoid")
local animator = hum and (hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum))

local anim = Instance.new("Animation")
anim.AnimationId = animId
local track = animator:LoadAnimation(anim)
track:Play()

return game:GetService("HttpService"):JSONEncode({
    animId = animId,
    isPlaying = track.IsPlaying,
    length = track.Length
})
