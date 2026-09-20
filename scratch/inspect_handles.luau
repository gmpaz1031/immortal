local results = {}
for _, desc in ipairs(workspace:GetDescendants()) do
    if desc.Name == "Handle" then
        local toolOrModel = desc.Parent
        local mesh = desc:FindFirstChildOfClass("SpecialMesh")
        table.insert(results, {
            Parent = toolOrModel.Name,
            ParentClass = toolOrModel.ClassName,
            FullPath = desc:GetFullName(),
            MeshId = mesh and mesh.MeshId or "",
            TextureId = mesh and mesh.TextureId or "",
            Size = tostring(desc.Size)
        })
    end
end
return game:GetService("HttpService"):JSONEncode(results)
