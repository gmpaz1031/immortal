local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s4 = enemies and enemies:FindFirstChild("Swordsman_4")
local hum = s4 and s4:FindFirstChildOfClass("Humanoid")
local animator = hum and hum:FindFirstChildOfClass("Animator")

local ids = {
    "129967390", -- Slash
    "125750867", -- Overhead
    "129967478", -- Lunge
    "180426354", -- Walk
    "180435571", -- Idle
    "243827693",
    "522635533",
    "74894680",
    "74897796",
}

local res = {}
for _, id in ipairs(ids) do
    local a = Instance.new("Animation")
    a.AnimationId = "rbxassetid://" .. id
    local success, track = pcall(function() return animator:LoadAnimation(a) end)
    if success and track then
        res[id] = true
    else
        res[id] = false
    end
end

return game:GetService("HttpService"):JSONEncode(res)
