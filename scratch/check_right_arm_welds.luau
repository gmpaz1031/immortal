local enemiesFolder = workspace:FindFirstChild("DestroyedVillage_Enemies")
local results = {}

for _, enemy in ipairs(enemiesFolder:GetChildren()) do
    if enemy:IsA("Model") then
        local ra = enemy:FindFirstChild("Right Arm")
        local welds = {}
        if ra then
            for _, child in ipairs(ra:GetChildren()) do
                if child:IsA("Weld") or child:IsA("Motor6D") then
                    table.insert(welds, {
                        class = child.ClassName,
                        name = child.Name,
                        part0 = child.Part0 and child.Part0.Name,
                        part1 = child.Part1 and child.Part1.Name,
                        c0_pos = { child.C0.Position.X, child.C0.Position.Y, child.C0.Position.Z },
                    })
                end
            end
        end
        results[enemy.Name] = welds
    end
end

return game:GetService("HttpService"):JSONEncode(results)
