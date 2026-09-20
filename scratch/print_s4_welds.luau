local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s4 = enemies and enemies:FindFirstChild("Swordsman_4")
local weapon = s4 and s4:FindFirstChild("EquippedWeapon")
if not weapon then return "No weapon" end

local result = {}
for _, p in ipairs(weapon:GetChildren()) do
    if p:IsA("BasePart") then
        for _, c in ipairs(p:GetChildren()) do
            if c:IsA("Weld") or c:IsA("WeldConstraint") or c:IsA("Motor6D") then
                table.insert(result, {
                    Class = c.ClassName,
                    Parent = p.Name,
                    Part0 = c.Part0 and c.Part0.Name or "nil",
                    Part1 = c.Part1 and c.Part1.Name or "nil",
                    C0 = c:IsA("Weld") and tostring(c.C0) or nil,
                    C1 = c:IsA("Weld") and tostring(c.C1) or nil,
                })
            end
        end
    end
end
return game:GetService("HttpService"):JSONEncode(result)
