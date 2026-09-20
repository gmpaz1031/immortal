local enemiesFolder = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s3 = enemiesFolder and enemiesFolder:FindFirstChild("Swordsman_3")
local weapon = s3 and s3:FindFirstChild("EquippedWeapon")
local blade = weapon and weapon:FindFirstChild("WeaponBlade")

if blade then
    local fx = Instance.new("ParticleEmitter")
    fx.Name = "IronGlint"
    fx.Color = ColorSequence.new(Color3.fromRGB(220, 230, 245), Color3.fromRGB(150, 160, 175))
    fx.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.05) })
    fx.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
    fx.Lifetime = NumberRange.new(0.3, 0.6)
    fx.Rate = 8
    fx.Speed = NumberRange.new(0.5, 2.0)
    fx.LightEmission = 0.4
    fx.Parent = blade
    return "Iron glint added to Swordsman_3"
end
return "Failed to find blade on Swordsman_3"
