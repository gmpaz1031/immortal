local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s4 = enemies and enemies:FindFirstChild("Swordsman_4")
local weapon = s4 and s4:FindFirstChild("EquippedWeapon")

local result = {}
for _, desc in ipairs(s4:GetDescendants()) do
    if desc:IsA("JointInstance") or desc:IsA("WeldConstraint") then
        local p0In = desc.Part0 and desc.Part0:IsDescendantOf(weapon)
        local p1In = desc.Part1 and desc.Part1:IsDescendantOf(weapon)
        if p0In or p1In then
            table.insert(result, {
                Class = desc.ClassName,
                Name = desc.Name,
                Parent = desc.Parent:GetFullName(),
                Part0 = desc.Part0 and desc.Part0:GetFullName() or "nil",
                Part1 = desc.Part1 and desc.Part1:GetFullName() or "nil",
                C0 = desc:IsA("Weld") and tostring(desc.C0) or nil,
                C1 = desc:IsA("Weld") and tostring(desc.C1) or nil,
            })
        end
    end
end
return game:GetService("HttpService"):JSONEncode(result)
