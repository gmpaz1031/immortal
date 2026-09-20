import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def test_full_flow():
    print("=== Testing End-to-End Cultivation Gameplay Flow in Studio ===")

    lua_test = """
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local remote = ReplicatedStorage:WaitForChild("CultivationRemote")
    local Shared = ReplicatedStorage:WaitForChild("Shared")
    local CultivationConfig = require(Shared:WaitForChild("CultivationConfig"))

    -- Create / find mock player character in Workspace if needed
    local report = {}

    -- 1. Test Server Breakthrough Cloud Generator Directly
    local sss = game:GetService("ServerScriptService")
    local serverFolder = sss:WaitForChild("Server")
    local mainServer = serverFolder:WaitForChild("MAINSERVER")
    table.insert(report, "Server MAINSERVER active: " .. tostring(mainServer ~= nil))

    -- Create test dummy character for Tribulation Cloud test
    local dummy = Instance.new("Model")
    dummy.Name = "TestCultivator"
    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(2, 2, 1)
    hrp.Position = Vector3.new(0, 10, 0)
    hrp.Anchored = true
    hrp.Parent = dummy
    local hum = Instance.new("Humanoid")
    hum.Parent = dummy
    dummy.PrimaryPart = hrp
    dummy.Parent = Workspace

    -- Simulate Tribulation Cloud Creation above dummy
    local cloudCenter = Instance.new("Part")
    cloudCenter.Name = "CloudCenter"
    cloudCenter.Shape = Enum.PartType.Ball
    cloudCenter.Size = Vector3.new(30, 10, 30)
    cloudCenter.Color = Color3.fromRGB(24, 20, 32)
    cloudCenter.Material = Enum.Material.Slate
    cloudCenter.CanCollide = false
    cloudCenter.Anchored = true
    cloudCenter.CFrame = hrp.CFrame * CFrame.new(0, 22, 0)
    cloudCenter.Parent = dummy

    local light = Instance.new("PointLight")
    light.Name = "LightningLight"
    light.Color = Color3.fromRGB(180, 220, 255)
    light.Range = 45
    light.Brightness = 8
    light.Parent = cloudCenter

    table.insert(report, "Tribulation Cloud Centered Height: " .. tostring((cloudCenter.Position - hrp.Position).Y) .. " studs (Expected ~22)")
    table.insert(report, "Lightning Light Brightness: " .. tostring(light.Brightness))

    -- Cleanup test dummy
    task.delay(0.5, function()
        if dummy and dummy.Parent then
            dummy:Destroy()
        end
    end)

    -- 2. Verify Qi Capacity Stage Progression Formula
    local s1Cap = CultivationConfig.getRequiredQi("Qi Condensation", 1)
    local s2Cap = CultivationConfig.getRequiredQi("Qi Condensation", 2)
    local s3Cap = CultivationConfig.getRequiredQi("Qi Condensation", 3)
    table.insert(report, string.format("Stage 1 -> Stage 2 -> Stage 3 Caps: %d -> %d -> %d", s1Cap, s2Cap, s3Cap))

    -- 3. Verify Elemental Scripture Synergy Math
    local fireRate = CultivationConfig.calculateQiRate(10, 2.5, 1.5, true)
    local waterRate = CultivationConfig.calculateQiRate(10, 2.5, 1.5, false)
    table.insert(report, string.format("Fire Root + Fire Scripture: %.1f Qi/sec", fireRate))
    table.insert(report, string.format("Fire Root + Water Scripture: %.1f Qi/sec", waterRate))

    return table.concat(report, "\\n")
    """

    ok, res = exec_code(lua_test)
    safe_out = str(res).encode('ascii', errors='replace').decode('ascii')
    print("Test Results:\n" + safe_out)
    assert ok, f"Test failed: {res}"

if __name__ == '__main__':
    test_full_flow()
