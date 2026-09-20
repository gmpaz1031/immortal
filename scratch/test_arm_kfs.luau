local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s4 = enemies and enemies:FindFirstChild("Swordsman_4")
local hum = s4 and s4:FindFirstChildOfClass("Humanoid")
local animator = hum and hum:FindFirstChildOfClass("Animator")

-- Create an arm-only KeyframeSequence
local function createArmOnlyAttackKFS(): string
	local kfs = Instance.new("KeyframeSequence")
	kfs.Name = "SwordsmanDoubleSlash"
	kfs.Loop = false

	local kf0 = Instance.new("Keyframe")
	kf0.Time = 0.0
	local hrp0 = Instance.new("Pose"); hrp0.Name = "HumanoidRootPart"
	local torso0 = Instance.new("Pose"); torso0.Name = "Torso"
	-- Keep torso CFrame identity so RootJoint is NEVER rotated!
	local arm0 = Instance.new("Pose"); arm0.Name = "Right Arm"
	arm0.CFrame = CFrame.Angles(math.rad(60), math.rad(-20), math.rad(10))
	torso0:AddSubPose(arm0)
	hrp0:AddSubPose(torso0)
	kf0:AddPose(hrp0)
	kfs:AddKeyframe(kf0)

	-- Hit 1: Upward-diagonal slash
	local kf1 = Instance.new("Keyframe")
	kf1.Time = 0.18
	local hrp1 = Instance.new("Pose"); hrp1.Name = "HumanoidRootPart"
	local torso1 = Instance.new("Pose"); torso1.Name = "Torso"
	local arm1 = Instance.new("Pose"); arm1.Name = "Right Arm"
	arm1.CFrame = CFrame.Angles(math.rad(25), math.rad(-45), math.rad(45))
	torso1:AddSubPose(arm1)
	hrp1:AddSubPose(torso1)
	kf1:AddPose(hrp1)
	kfs:AddKeyframe(kf1)

	local kf2 = Instance.new("Keyframe")
	kf2.Time = 0.32
	local hrp2 = Instance.new("Pose"); hrp2.Name = "HumanoidRootPart"
	local torso2 = Instance.new("Pose"); torso2.Name = "Torso"
	local arm2 = Instance.new("Pose"); arm2.Name = "Right Arm"
	arm2.CFrame = CFrame.Angles(math.rad(115), math.rad(35), math.rad(-30))
	torso2:AddSubPose(arm2)
	hrp2:AddSubPose(torso2)
	kf2:AddPose(hrp2)
	kfs:AddKeyframe(kf2)

	-- Hit 2: Downward diagonal cross-cut
	local kf3 = Instance.new("Keyframe")
	kf3.Time = 0.48
	local hrp3 = Instance.new("Pose"); hrp3.Name = "HumanoidRootPart"
	local torso3 = Instance.new("Pose"); torso3.Name = "Torso"
	local arm3 = Instance.new("Pose"); arm3.Name = "Right Arm"
	arm3.CFrame = CFrame.Angles(math.rad(130), math.rad(40), math.rad(-10))
	torso3:AddSubPose(arm3)
	hrp3:AddSubPose(torso3)
	kf3:AddPose(hrp3)
	kfs:AddKeyframe(kf3)

	local kf4 = Instance.new("Keyframe")
	kf4.Time = 0.65
	local hrp4 = Instance.new("Pose"); hrp4.Name = "HumanoidRootPart"
	local torso4 = Instance.new("Pose"); torso4.Name = "Torso"
	local arm4 = Instance.new("Pose"); arm4.Name = "Right Arm"
	arm4.CFrame = CFrame.Angles(math.rad(20), math.rad(-30), math.rad(20))
	torso4:AddSubPose(arm4)
	hrp4:AddSubPose(torso4)
	kf4:AddPose(hrp4)
	kfs:AddKeyframe(kf4)

	-- Recovery
	local kf5 = Instance.new("Keyframe")
	kf5.Time = 0.80
	local hrp5 = Instance.new("Pose"); hrp5.Name = "HumanoidRootPart"
	local torso5 = Instance.new("Pose"); torso5.Name = "Torso"
	local arm5 = Instance.new("Pose"); arm5.Name = "Right Arm"
	arm5.CFrame = CFrame.Angles(0, 0, 0)
	torso5:AddSubPose(arm5)
	hrp5:AddSubPose(torso5)
	kf5:AddPose(hrp5)
	kfs:AddKeyframe(kf5)

	return KeyframeSequenceProvider:RegisterKeyframeSequence(kfs)
end

local animId = createArmOnlyAttackKFS()
local a = Instance.new("Animation")
a.AnimationId = animId
local track = animator:LoadAnimation(a)
track.Priority = Enum.AnimationPriority.Action

return game:GetService("HttpService"):JSONEncode({
    success = true,
    animId = animId,
    length = track.Length,
})
