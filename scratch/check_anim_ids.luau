local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s4 = enemies and enemies:FindFirstChild("Swordsman_4")
local hum = s4 and s4:FindFirstChildOfClass("Humanoid")
local animator = hum and hum:FindFirstChildOfClass("Animator")

local candidateIds = {
    "129967390", -- Slash
    "125750867", -- Overhead
    "129967478", -- Lunge
    "204062532",
    "204062580",
    "243827693",
    "522635533",
    "74894680",
    "74897796",
    "45914612",
    "48420072",
    "48496246",
    "204328711",
    "180436334",
    "180436148",
    "180435792",
    "180435571",
    "180426354",
    "125750702",
    "522625527",
    "522638767",
}

local valid = {}
for _, id in ipairs(candidateIds) do
    local a = Instance.new("Animation")
    a.AnimationId = "rbxassetid://" .. id
    local track = nil
    local s, e = pcall(function()
        track = animator:LoadAnimation(a)
    end)
    if s and track and track.Length > 0 then
        valid[id] = { Length = track.Length }
    end
end

return game:GetService("HttpService"):JSONEncode(valid)
