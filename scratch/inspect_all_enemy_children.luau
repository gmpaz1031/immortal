local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
if not enemies then return "No DestroyedVillage_Enemies" end

local info = {}
for _, model in ipairs(enemies:GetChildren()) do
    if model:IsA("Model") then
        local children = {}
        for _, c in ipairs(model:GetChildren()) do
            local item = {
                Name = c.Name,
                Class = c.ClassName,
            }
            if c:IsA("BasePart") then
                item.Size = tostring(c.Size)
                item.Color = tostring(c.Color)
                item.Material = c.Material.Name
                local welds = {}
                for _, w in ipairs(c:GetChildren()) do
                    if w:IsA("WeldConstraint") or w:IsA("Weld") or w:IsA("Motor6D") then
                        table.insert(welds, {
                            Class = w.ClassName,
                            Part0 = w.Part0 and w.Part0.Name or "nil",
                            Part1 = w.Part1 and w.Part1.Name or "nil",
                        })
                    end
                end
                item.Welds = welds
            end
            table.insert(children, item)
        end
        info[model.Name] = children
    end
end
return game:GetService("HttpService"):JSONEncode(info)
