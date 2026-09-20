local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
if not enemies then return "No DestroyedVillage_Enemies" end
local result = {}

for _, model in ipairs(enemies:GetChildren()) do
    if model:IsA("Model") then
        local rightArm = model:FindFirstChild("Right Arm")
        local torso = model:FindFirstChild("Torso")
        local weaponParts = {}
        for _, p in ipairs(model:GetChildren()) do
            local n = p.Name:lower()
            if p:IsA("BasePart") and (n:find("hilt") or n:find("blade") or n:find("guard") or n:find("tsuba") or n:find("sheath") or n:find("scabbard") or n:find("weapon") or n:find("sword") or n:find("katana") or n:find("dao") or n:find("cleaver") or n:find("jian")) then
                local relArm = rightArm and (rightArm.CFrame:Inverse() * p.CFrame) or nil
                local relTorso = torso and (torso.CFrame:Inverse() * p.CFrame) or nil
                local weld = p:FindFirstChildOfClass("WeldConstraint") or p:FindFirstChildOfClass("Weld") or p:FindFirstChildOfClass("Motor6D")
                table.insert(weaponParts, {
                    Name = p.Name,
                    Size = tostring(p.Size),
                    CFrame = tostring(p.CFrame),
                    RelArmPos = relArm and tostring(relArm.Position) or nil,
                    RelArmRot = relArm and tostring(Vector3.new(relArm:ToOrientation())) or nil,
                    RelTorsoPos = relTorso and tostring(relTorso.Position) or nil,
                    WeldInfo = weld and (weld.ClassName .. " | Part0=" .. tostring(weld.Part0 and weld.Part0.Name) .. " | Part1=" .. tostring(weld.Part1 and weld.Part1.Name)) or "None",
                    Color = tostring(p.Color),
                    Material = p.Material.Name,
                    Mesh = p:FindFirstChildOfClass("SpecialMesh") and p:FindFirstChildOfClass("SpecialMesh").MeshType.Name or "NoMesh",
                })
            end
        end
        result[model.Name] = weaponParts
    end
end
return game:GetService("HttpService"):JSONEncode(result)
