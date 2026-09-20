local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
if not enemies then return "No DestroyedVillage_Enemies" end
local s4 = enemies:FindFirstChild("Swordsman_4")
if not s4 then return "No Swordsman_4" end

local ra = s4:FindFirstChild("Right Arm")
local weapon = s4:FindFirstChild("EquippedWeapon")
if not weapon or not ra then return "No weapon or Right Arm" end

local result = {
    Parts = {},
    Welds = {},
}

for _, p in ipairs(weapon:GetChildren()) do
    if p:IsA("BasePart") then
        local relArm = ra.CFrame:Inverse() * p.CFrame
        table.insert(result.Parts, {
            Name = p.Name,
            Size = tostring(p.Size),
            CFrame = tostring(p.CFrame),
            RelArmCFrame = tostring(relArm),
            RelArmPos = tostring(relArm.Position),
            RelArmRot = tostring(Vector3.new(relArm:ToOrientation())),
        })
    end
end

for _, d in ipairs(s4:GetDescendants()) do
    if d:IsA("Weld") or d:IsA("WeldConstraint") or d:IsA("Motor6D") then
        if (d.Part0 and d.Part0:IsDescendantOf(weapon)) or (d.Part1 and d.Part1:IsDescendantOf(weapon)) or d.Part0 == ra or d.Part1 == ra then
            table.insert(result.Welds, {
                Class = d.ClassName,
                Name = d.Name,
                Parent = d.Parent.Name,
                Part0 = d.Part0 and d.Part0.Name or "nil",
                Part1 = d.Part1 and d.Part1.Name or "nil",
                C0 = d:IsA("Weld") and tostring(d.C0) or nil,
                C1 = d:IsA("Weld") and tostring(d.C1) or nil,
            })
        end
    end
end

return game:GetService("HttpService"):JSONEncode(result)
