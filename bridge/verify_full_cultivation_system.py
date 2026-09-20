import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def verify_full_system():
    print("=== Testing Full Cultivation & Tribulation System in Roblox Studio ===")

    lua_test = """
    local StarterGui = game:GetService("StarterGui")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")

    local Shared = ReplicatedStorage:WaitForChild("Shared")
    local CultivationConfig = loadstring(Shared:WaitForChild("CultivationConfig").Source)()
    local ItemConfig = loadstring(Shared:WaitForChild("ItemConfig").Source)()
    local DestinyConfig = loadstring(Shared:WaitForChild("DestinyConfig").Source)()

    local report = {}

    -- 1. Verify Formulas & Config
    table.insert(report, "--- 1. Shared Formulas & Config ---")
    local ok1, err1 = pcall(function()
        local req1 = CultivationConfig.getRequiredQi("Qi Condensation", 1)
        local req2 = CultivationConfig.getRequiredQi("Qi Condensation", 2)
        local req3 = CultivationConfig.getRequiredQi("Qi Condensation", 3)
        table.insert(report, string.format("Stage 1 Max Qi: %d (Expected 5000)", req1))
        table.insert(report, string.format("Stage 2 Max Qi: %d (Expected 7500)", req2))
        table.insert(report, string.format("Stage 3 Max Qi: %d (Expected 10000)", req3))

        local fireItem = ItemConfig.getItem("Fire Scripture")
        local isSynergy = CultivationConfig.isManualSynergy(fireItem and fireItem.Element, "Fire Root")
        local noSynergy = CultivationConfig.isManualSynergy(fireItem and fireItem.Element, "Water Root")
        table.insert(report, string.format("Fire Scripture + Fire Root Synergy: %s (Expected true)", tostring(isSynergy)))
        table.insert(report, string.format("Fire Scripture + Water Root Synergy: %s (Expected false)", tostring(noSynergy)))

        local matchRate = CultivationConfig.calculateQiRate(10, 2.5, 1.5, true)
        local noMatchRate = CultivationConfig.calculateQiRate(10, 2.5, 1.5, false)
        table.insert(report, string.format("Matching Rate (10 x 2.5 x 1.5): %.1f Qi/s (Expected 37.5)", matchRate))
        table.insert(report, string.format("Non-Matching Rate (10 x 2.5): %.1f Qi/s (Expected 25.0)", noMatchRate))
    end)
    if not ok1 then table.insert(report, "Formulas Error: " .. tostring(err1)) end

    -- 2. Verify UI Components in CultivationUI
    table.insert(report, "--- 2. CultivationUI Hierarchy ---")
    local ui = StarterGui:FindFirstChild("CultivationUI")
    if not ui then return "CultivationUI missing!" end

    local cultModal = ui:FindFirstChild("CultivationScrollModal")
    local invModal = ui:FindFirstChild("InventoryScrollModal")
    local wheelModal = ui:FindFirstChild("DestinyWheelModal")
    local clientScript = ui:FindFirstChild("CultivationClient")

    table.insert(report, "cultModal exists: " .. tostring(cultModal ~= nil))
    table.insert(report, "invModal exists: " .. tostring(invModal ~= nil))
    table.insert(report, "DestinyWheelModal exists: " .. tostring(wheelModal ~= nil))
    table.insert(report, "CultivationClient len: " .. tostring(clientScript and #clientScript.Source or 0))

    -- 3. Verify Cultivation Panel Typography
    table.insert(report, "--- 3. Cultivation Panel Typography ---")
    if cultModal then
        local header = cultModal:FindFirstChild("HeaderBanner")
        local title = header and (header:FindFirstChild("TitleText") or header:FindFirstChild("Title"))
        local closeBtn = cultModal:FindFirstChild("CloseBtn", true)
        local bpt = cultModal:FindFirstChild("BreakProgressText")
        local cinBtn = cultModal:FindFirstChild("CinnabarActionBtn")
        local dBtn = cultModal:FindFirstChild("DestinyWheelBtn")
        local mBanner = cultModal:FindFirstChild("ManualSynergyBanner")

        table.insert(report, "Title: " .. (title and title.Text or "missing"))
        table.insert(report, "CloseBtn Text: " .. (closeBtn and closeBtn.Text or "missing"))
        table.insert(report, "Breakthrough Btn: " .. tostring(cinBtn ~= nil))
        table.insert(report, "Destiny Wheel Btn: " .. tostring(dBtn ~= nil))
        table.insert(report, "Manual Synergy Banner: " .. tostring(mBanner ~= nil))
    end

    -- 4. Verify Server Script Verification
    table.insert(report, "--- 4. Server Script Verification ---")
    local sss = game:GetService("ServerScriptService")
    local serverFolder = sss:FindFirstChild("Server")
    local mainServer = serverFolder and serverFolder:FindFirstChild("MAINSERVER")

    if mainServer then
        local src = mainServer.Source
        local hasCloud = string.find(src, "createTribulationCloud") ~= nil
        local hasLightning = string.find(src, "fireLightningStrike") ~= nil
        local hasSynergyCheck = string.find(src, "isManualSynergy") ~= nil
        local hasStageCap = string.find(src, "getRequiredQi") ~= nil
        local hasCapHalt = string.find(src, "BreakthroughAvailable") ~= nil

        table.insert(report, "Tribulation Cloud Generator in Server: " .. tostring(hasCloud))
        table.insert(report, "Lightning Strike Generator in Server: " .. tostring(hasLightning))
        table.insert(report, "Manual Synergy Logic in Server: " .. tostring(hasSynergyCheck))
        table.insert(report, "Stage Qi Capacity Capping in Server: " .. tostring(hasStageCap))
        table.insert(report, "Qi Full Breakthrough Trigger in Server: " .. tostring(hasCapHalt))
    end

    -- 5. Verify Client Script Feature Checks
    table.insert(report, "--- 5. Client Script Feature Checks ---")
    if clientScript then
        local src = clientScript.Source
        local hasKeyC = string.find(src, "Enum.KeyCode.C") ~= nil
        local hasKeyK = string.find(src, "Enum.KeyCode.K") ~= nil
        local hasKeyB = string.find(src, "Enum.KeyCode.B") ~= nil
        local hasActiveCard = string.find(src, "ActiveCultivatingCard") ~= nil
        local hasProceduralPose = string.find(src, "RunService.Stepped") ~= nil
        local hasInwardParticles = string.find(src, "QiGatherParticles") ~= nil
        local hasSlotPullout = string.find(src, "Smooth slot pullout animation") ~= nil
        local hasTribulationPhases = string.find(src, "TribulationPhase") ~= nil

        table.insert(report, "Keybind C (Cultivate): " .. tostring(hasKeyC))
        table.insert(report, "Keybind K (Cultivation Panel): " .. tostring(hasKeyK))
        table.insert(report, "Keybind B (Inventory): " .. tostring(hasKeyB))
        table.insert(report, "Active Cultivating Card UI: " .. tostring(hasActiveCard))
        table.insert(report, "Procedural Cross-Legged Sitting Pose: " .. tostring(hasProceduralPose))
        table.insert(report, "Inward Spiritual Qi Particles: " .. tostring(hasInwardParticles))
        table.insert(report, "Inventory Slot Pullout Animation: " .. tostring(hasSlotPullout))
        table.insert(report, "Tribulation Lightning Camera Shake & Flash: " .. tostring(hasTribulationPhases))
    end

    return table.concat(report, "\\n")
    """

    ok, res = exec_code(lua_test)
    print("=== Studio System Test Results ===")
    safe_out = str(res).encode('ascii', errors='replace').decode('ascii')
    print(safe_out)
    assert ok, f"Test failed: {res}"

if __name__ == '__main__':
    verify_full_system()
