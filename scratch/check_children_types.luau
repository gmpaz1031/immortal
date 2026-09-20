local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s4 = enemies and enemies:FindFirstChild("Swordsman_4")
local weapon = s4 and s4:FindFirstChild("EquippedWeapon")
if not weapon then return "No weapon" end

local result = {}
for _, p in ipairs(weapon:GetChildren()) do
    if p:IsA("BasePart") then
        local childNames = {}
        for _, c in ipairs(p:GetChildren()) do
            table.insert(childNames, c.ClassName .. ":" .. c.Name)
        end
        result[p.Name] = childNames
    end
end
return game:GetService("HttpService"):JSONEncode(result)
