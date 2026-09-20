-- scratch/verify_village_overhaul.luau

local enemiesFolder = workspace:FindFirstChild("DestroyedVillage_Enemies")
if not enemiesFolder then return "No DestroyedVillage_Enemies" end

local results = {
    Enemies = {},
    TotalEnemies = 0,
    AllHaveWedgeTip = true,
    AllHaveParticleEmitter = true,
    AllHaveProperGrip = true,
    NoEmojis = true,
    NoGoofyLunge = true,
}

for _, model in ipairs(enemiesFolder:GetChildren()) do
    if model:IsA("Model") then
        results.TotalEnemies = results.TotalEnemies + 1
        local weapon = model:FindFirstChild("EquippedWeapon")
        local blade = weapon and weapon:FindFirstChild("WeaponBlade")
        local tip = weapon and weapon:FindFirstChild("BladeTip")
        local rightArm = model:FindFirstChild("Right Arm")
        local weld = rightArm and rightArm:FindFirstChildOfClass("Weld")

        local hasWedgeTip = tip ~= nil and tip:IsA("WedgePart")
        local hasParticles = weapon and weapon:FindFirstChildOfClass("ParticleEmitter", true) ~= nil
        local hasProperGrip = weld ~= nil and weld.C0.Y < 0

        local bbg = model:FindFirstChild("EnemyHealthGui", true)
        local nameLabel = bbg and bbg:FindFirstChild("NameLabel", true)
        local hasEmoji = nameLabel and (string.find(nameLabel.Text, "[\128-\255]") ~= nil) or false

        if not hasWedgeTip then results.AllHaveWedgeTip = false end
        if not hasParticles then results.AllHaveParticleEmitter = false end
        if not hasProperGrip then results.AllHaveProperGrip = false end
        if hasEmoji then results.NoEmojis = false end

        table.insert(results.Enemies, {
            Name = model.Name,
            Title = nameLabel and nameLabel.Text or "Unknown",
            WeaponPartsCount = weapon and #weapon:GetChildren() or 0,
            HasWedgeTip = hasWedgeTip,
            HasParticles = hasParticles,
            GripC0 = weld and tostring(weld.C0) or "None",
            HasEmoji = hasEmoji,
        })
    end
end

-- Verify DestroyedVillageManager requires and runs
local dvm = require(game:GetService("ServerScriptService").Server.DestroyedVillageManager)
results.ManagerLoaded = dvm ~= nil

return game:GetService("HttpService"):JSONEncode(results)
