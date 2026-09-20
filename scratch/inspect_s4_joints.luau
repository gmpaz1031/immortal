local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s4 = enemies and enemies:FindFirstChild("Swordsman_4")
local weapon = s4 and s4:FindFirstChild("EquippedWeapon")

local result = {}
if weapon then
    for _, desc in ipairs(weapon:GetDescendants()) do
        if desc:IsA("JointInstance") or desc:IsA("WeldConstraint") then
            table.insert(result, {
                Class = desc.ClassName,
                Name = desc.Name,
                Parent = desc.Parent.Name,
                Part0 = desc.Part0 and desc.Part0.Name or "nil",
                Part1 = desc.Part1 and desc.Part1.Name or "nil",
            })
        end
    end
end
local ra = s4 and s4:FindFirstChild("Right Arm")
if ra then
    for _, desc in ipairs(ra:GetDescendants()) do
        if desc:IsA("JointInstance") or desc:IsA("WeldConstraint") then
            table.insert(result, {
                Class = desc.ClassName,
                Name = desc.Name,
                Parent = desc.Parent.Name,
                Part0 = desc.Part0 and desc.Part0.Name or "nil",
                Part1 = desc.Part1 and desc.Part1.Name or "nil",
            })
        end
    end
end

return game:GetService("HttpService"):JSONEncode(result)
