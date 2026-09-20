local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s4 = enemies and enemies:FindFirstChild("Swordsman_4")
local hum = s4 and s4:FindFirstChildOfClass("Humanoid")
local animator = hum and hum:FindFirstChildOfClass("Animator")

local idleA = Instance.new("Animation")
idleA.AnimationId = "rbxassetid://180435571"
local idleTrack = animator:LoadAnimation(idleA)
idleTrack.Priority = Enum.AnimationPriority.Idle
idleTrack:Play()

local walkA = Instance.new("Animation")
walkA.AnimationId = "rbxassetid://180426354"
local walkTrack = animator:LoadAnimation(walkA)
walkTrack.Priority = Enum.AnimationPriority.Movement

return game:GetService("HttpService"):JSONEncode({
    idlePlaying = idleTrack.IsPlaying,
    idleLength = idleTrack.Length,
    walkLength = walkTrack.Length,
    torsoCFrame = s4.Torso.CFrame:GetComponents(),
})
