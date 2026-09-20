local enemiesFolder = workspace:FindFirstChild("DestroyedVillage_Enemies")
local result = {}
for _, model in ipairs(enemiesFolder:GetChildren()) do
    if model:IsA("Model") then
        local weapon = model:FindFirstChild("EquippedWeapon")
        local emitters = {}
        if weapon then
            for _, d in ipairs(weapon:GetDescendants()) do
                if d:IsA("ParticleEmitter") then
                    table.insert(emitters, d.Name)
                end
            end
        end
        result[model.Name] = emitters
    end
end
return game:GetService("HttpService"):JSONEncode(result)
