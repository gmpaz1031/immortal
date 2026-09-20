local enemiesFolder = workspace:FindFirstChild("DestroyedVillage_Enemies")
local results = {}

for _, enemy in ipairs(enemiesFolder:GetChildren()) do
    if enemy:IsA("Model") then
        local hrp = enemy:FindFirstChild("HumanoidRootPart")
        local torso = enemy:FindFirstChild("Torso")
        local rootJoint = hrp and hrp:FindFirstChild("RootJoint") or (torso and torso:FindFirstChild("RootJoint"))

        local torsoTiltDeg = 0
        if torso then
            local rx, ry, rz = torso.CFrame:ToOrientation()
            torsoTiltDeg = math.deg(rx)
        end

        results[enemy.Name] = {
            hasHrp = hrp ~= nil,
            hasTorso = torso ~= nil,
            hasRootJoint = rootJoint ~= nil,
            torsoTiltDeg = torsoTiltDeg,
            isUpright = math.abs(torsoTiltDeg) < 5,
        }
    end
end

return game:GetService("HttpService"):JSONEncode(results)
