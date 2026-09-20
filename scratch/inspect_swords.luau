local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
if not enemies then return "No DestroyedVillage_Enemies" end
local result = {}
for _, model in ipairs(enemies:GetChildren()) do
    if model:IsA("Model") then
        local parts = {}
        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("BasePart") then
                local lname = desc.Name:lower()
                if lname:find("sword") or lname:find("blade") or lname:find("weapon") or lname:find("katana") or lname:find("dao") or lname:find("scabbard") or lname:find("sheath") or desc.Parent:IsA("Tool") or desc.Parent.Name:lower():find("weapon") or desc.Parent.Name:lower():find("sword") then
                    local weld = desc:FindFirstChildOfClass("Weld") or desc:FindFirstChildOfClass("Motor6D") or desc:FindFirstChildOfClass("WeldConstraint")
                    local mesh = desc:FindFirstChildOfClass("SpecialMesh")
                    table.insert(parts, {
                        Name = desc.Name,
                        Parent = desc.Parent.Name,
                        ClassName = desc.ClassName,
                        Size = tostring(desc.Size),
                        Color = tostring(desc.Color),
                        Material = desc.Material.Name,
                        MeshType = mesh and mesh.MeshType.Name or nil,
                        MeshId = mesh and mesh.MeshId or nil,
                        WeldClass = weld and weld.ClassName or nil,
                        Part0 = weld and weld.Part0 and weld.Part0.Name or nil,
                        Part1 = weld and weld.Part1 and weld.Part1.Name or nil,
                        C0 = weld and (weld:IsA("Weld") or weld:IsA("Motor6D")) and tostring(weld.C0) or nil,
                        C1 = weld and (weld:IsA("Weld") or weld:IsA("Motor6D")) and tostring(weld.C1) or nil,
                    })
                end
            end
        end
        result[model.Name] = parts
    end
end
return game:GetService("HttpService"):JSONEncode(result)
