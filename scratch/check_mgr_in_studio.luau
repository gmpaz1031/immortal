local sss = game:GetService("ServerScriptService")
local mgr = sss:FindFirstChild("DestroyedVillageManager", true)

return game:GetService("HttpService"):JSONEncode({
    found = mgr ~= nil,
    fullName = mgr and mgr:GetFullName() or "nil",
    className = mgr and mgr.ClassName or "nil",
    sourceLen = mgr and #mgr.Source or 0
})
