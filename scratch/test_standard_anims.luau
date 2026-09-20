local InsertService = game:GetService("InsertService")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s4 = enemies and enemies:FindFirstChild("Swordsman_4")
local hum = s4 and s4:FindFirstChildOfClass("Humanoid")
local animator = hum and hum:FindFirstChildOfClass("Animator")

local animsToTest = {
    Slash = "rbxassetid://129967390",
    Overhead = "rbxassetid://125750867",
    Lunge = "rbxassetid://129967478",
    Walk = "rbxassetid://180426354",
    Idle = "rbxassetid://180435571",
}

local results = {}
for name, id in pairs(animsToTest) do
    local a = Instance.new("Animation")
    a.AnimationId = id
    local track = animator:LoadAnimation(a)
    results[name] = {
        Length = track.Length,
        Valid = track.Length > 0
    }
end

return game:GetService("HttpService"):JSONEncode(results)
