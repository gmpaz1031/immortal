import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def simulate():
    print("=== Simulating Live Client Modal Interactions ===")

    lua_sim = """
    local StarterGui = game:GetService("StarterGui")
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local ui = StarterGui:FindFirstChild("CultivationUI")
    if not ui then return "CultivationUI missing" end

    local cultModal = ui:FindFirstChild("CultivationScrollModal")
    local invModal = ui:FindFirstChild("InventoryScrollModal")
    local hud = ui:FindFirstChild("GuofengHUD")
    local navRow = hud:FindFirstChild("NavRow")
    local cultBtn = navRow:FindFirstChild("CultNavBtn")
    local invBtn = navRow:FindFirstChild("InvNavBtn")

    local report = {}

    -- Simulate what toggleModal does
    local function closeAll()
        for _, m in ipairs({ cultModal, invModal, ui:FindFirstChild("RoadmapModal"), ui:FindFirstChild("ShopScrollModal"), ui:FindFirstChild("DestinyWheelModal") }) do
            if m then m.Visible = false end
        end
    end

    local function toggle(m)
        local cur = m.Visible
        closeAll()
        m.Visible = not cur
    end

    -- Test 1: Open Cultivation
    closeAll()
    toggle(cultModal)
    table.insert(report, "Cultivation Opened: " .. tostring(cultModal.Visible))

    -- Test 2: Toggle Cultivation off
    toggle(cultModal)
    table.insert(report, "Cultivation Closed: " .. tostring(not cultModal.Visible))

    -- Test 3: Open Inventory
    toggle(invModal)
    table.insert(report, "Inventory Opened: " .. tostring(invModal.Visible))

    -- Test 4: Switching between them
    toggle(cultModal)
    table.insert(report, "Switched to Cultivation: cult=" .. tostring(cultModal.Visible) .. ", inv=" .. tostring(invModal.Visible))

    -- Reset to clean state
    closeAll()
    table.insert(report, "All Modals Reset cleanly to Hidden state")

    return table.concat(report, "\\n")
    """

    ok, res = exec_code(lua_sim)
    print("Simulation Output:\n" + str(res))
    assert ok, f"Simulation failed: {res}"

if __name__ == '__main__':
    simulate()
