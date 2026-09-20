local results = {}
local function scan(container, name)
    for _, desc in ipairs(container:GetDescendants()) do
        if desc:IsA("SpecialMesh") and (desc.MeshId ~= "" or desc.TextureId ~= "") then
            table.insert(results, {Container = name, Parent = desc.Parent.Name, MeshId = desc.MeshId, TextureId = desc.TextureId})
        elseif desc:IsA("MeshPart") then
            table.insert(results, {Container = name, Name = desc.Name, MeshId = desc.MeshId, TextureId = desc.TextureID})
        elseif desc:IsA("Tool") then
            table.insert(results, {Container = name, Tool = desc.Name})
        end
    end
end

scan(game:GetService("ReplicatedStorage"), "ReplicatedStorage")
scan(game:GetService("ServerStorage"), "ServerStorage")
scan(game:GetService("StarterPack"), "StarterPack")
scan(game:GetService("Workspace"), "Workspace")

return game:GetService("HttpService"):JSONEncode(results)
