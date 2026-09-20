import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def test_popups():
    print("=== Testing Cultivation & Inventory Modal Popups in Studio ===")

    lua_test = """
    local StarterGui = game:GetService("StarterGui")
    local ui = StarterGui:FindFirstChild("CultivationUI")
    if not ui then return "CultivationUI missing" end

    local cultModal = ui:FindFirstChild("CultivationScrollModal")
    local invModal = ui:FindFirstChild("InventoryScrollModal")
    local hud = ui:FindFirstChild("GuofengHUD")
    local navRow = hud and hud:FindFirstChild("NavRow")
    local cultBtn = navRow and navRow:FindFirstChild("CultNavBtn")
    local invBtn = navRow and navRow:FindFirstChild("InvNavBtn")

    local report = {}

    table.insert(report, "cultModal exists: " .. tostring(cultModal ~= nil))
    table.insert(report, "invModal exists: " .. tostring(invModal ~= nil))
    table.insert(report, "cultNavBtn exists: " .. tostring(cultBtn ~= nil))
    table.insert(report, "invNavBtn exists: " .. tostring(invBtn ~= nil))

    -- Check CloseBtn on both modals
    local cultClose = cultModal:FindFirstChild("CloseBtn", true)
    local invClose = invModal:FindFirstChild("CloseBtn", true)
    table.insert(report, "cultModal CloseBtn: " .. (cultClose and "OK" or "MISSING"))
    table.insert(report, "invModal CloseBtn: " .. (invClose and "OK" or "MISSING"))

    -- Test Cultivation toggle simulation
    cultModal.Visible = false
    invModal.Visible = false

    -- 1. Open Cultivation modal
    cultModal.Visible = true
    table.insert(report, "1. Cultivation Modal Opened: Visible=" .. tostring(cultModal.Visible))
    cultModal.Visible = false
    table.insert(report, "2. Cultivation Modal Closed: Visible=" .. tostring(cultModal.Visible))

    -- 2. Open Inventory modal
    invModal.Visible = true
    table.insert(report, "3. Inventory Modal Opened: Visible=" .. tostring(invModal.Visible))

    -- Check inner grid and inspect panel
    local mainBody = invModal:FindFirstChild("MainBody")
    local gridContainer = mainBody and mainBody:FindFirstChild("GridContainer")
    local itemList = gridContainer and gridContainer:FindFirstChild("ItemList")
    local inspectPanel = mainBody and mainBody:FindFirstChild("InspectPanel")
    table.insert(report, "4. Inventory Inner Hierarchy: Grid=" .. tostring(itemList ~= nil) .. ", Inspect=" .. tostring(inspectPanel ~= nil))

    invModal.Visible = false
    table.insert(report, "5. Inventory Modal Closed: Visible=" .. tostring(invModal.Visible))

    return table.concat(report, "\\n")
    """

    ok, res = exec_code(lua_test)
    print("Test Results:\n" + str(res))
    assert ok, f"Test failed: {res}"

if __name__ == '__main__':
    test_popups()
