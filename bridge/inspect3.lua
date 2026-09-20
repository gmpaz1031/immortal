local res = {}
for _, name in ipairs({"ChineseFantasyVillage", "ChineseCultivationVillage", "BanditVillage", "DestroyedVillage"}) do
    local v = workspace:FindFirstChild(name)
    if v then
        local pos = "N/A"
        if v:IsA("Folder") then
            -- Find first part
            for _, child in ipairs(v:GetDescendants()) do
                if child:IsA("BasePart") then
                    pos = tostring(child.Position)
                    break
                end
            end
        end
        table.insert(res, name .. " is " .. v.ClassName .. " pos: " .. pos)
    end
end
return table.concat(res, "\n")
