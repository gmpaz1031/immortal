local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s4 = enemies and enemies:FindFirstChild("Swordsman_4")
local hum = s4 and s4:FindFirstChildOfClass("Humanoid")
local animator = hum and hum:FindFirstChildOfClass("Animator")

local a = Instance.new("Animation")
a.AnimationId = "rbxassetid://243827693"
local track = animator:LoadAnimation(a)
track.Priority = Enum.AnimationPriority.Action
track:Play()

return game:GetService("HttpService"):JSONEncode({
    playing = track.IsPlaying,
    length = track.Length,
})
