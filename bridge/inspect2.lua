local function getPos(model)
    if model:IsA("Model") and model.PrimaryPart then
        return tostring(model.PrimaryPart.Position)
    elseif model:IsA("Model") then
        local pos = model:GetBoundingBox().Position
        return tostring(pos)
    end
    return "N/A"
end

local res = {}
for _, name in ipairs({"ChineseFantasyVillage", "ChineseCultivationVillage", "BanditVillage", "DestroyedVillage"}) do
    local v = workspace:FindFirstChild(name)
    if v then
        table.insert(res, name .. " pos: " .. getPos(v))
    end
end
return table.concat(res, "\n")
