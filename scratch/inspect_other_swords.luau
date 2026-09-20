local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
if not enemies then return "No DestroyedVillage_Enemies" end

local info = {}
for _, name in ipairs({"Swordsman_2", "Swordsman_3", "Swordsman_5"}) do
    local model = enemies:FindFirstChild(name)
    if model then
        local children = {}
        for _, c in ipairs(model:GetChildren()) do
            if c:IsA("BasePart") then
                local n = c.Name:lower()
                if n:find("hilt") or n:find("blade") or n:find("guard") or n:find("weapon") or n:find("sword") or n:find("dao") or n:find("cleaver") then
                    table.insert(children, {
                        Name = c.Name,
                        Size = tostring(c.Size),
                        Color = tostring(c.Color),
                        Material = c.Material.Name,
                    })
                end
            end
        end
        info[name] = children
    end
end
return game:GetService("HttpService"):JSONEncode(info)
