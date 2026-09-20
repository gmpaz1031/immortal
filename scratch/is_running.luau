local rs = game:GetService("RunService")
return game:GetService("HttpService"):JSONEncode({
    isRunning = rs:IsRunning(),
    isStudio = rs:IsStudio(),
    isClient = rs:IsClient(),
    isServer = rs:IsServer(),
})
