local function getNames(folder)
    local names = {}
    for _, c in ipairs(folder:GetChildren()) do
        table.insert(names, c.Name)
    end
    return table.concat(names, ", ")
end

local res = {}
table.insert(res, "Workspace: " .. getNames(workspace))
table.insert(res, "ServerStorage: " .. getNames(game:GetService("ServerStorage")))
if workspace:FindFirstChild("SAMPLEENEMYMODEL") then
    table.insert(res, "Found SAMPLEENEMYMODEL")
end
return table.concat(res, "\n")
