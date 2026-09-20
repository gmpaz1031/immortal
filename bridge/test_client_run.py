import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def test_client_run():
    lua = """
    local StarterGui = game:GetService("StarterGui")
    local ui = StarterGui:FindFirstChild("CultivationUI")
    if not ui then return "No CultivationUI" end

    local clientScript = ui:FindFirstChild("CultivationClient")
    if not clientScript then return "No CultivationClient" end

    -- Test loadstring of CultivationClient to catch syntax errors or compile errors
    local fn, err = loadstring(clientScript.Source)
    if not fn then
        return "COMPILE ERROR: " .. tostring(err)
    end

    -- Check all WaitForChild calls on StarterGui hierarchy
    local errors = {}
    local function safeWait(parent, name, timeout)
        local child = parent:WaitForChild(name, timeout or 2)
        if not child then
            table.insert(errors, "FAILED: " .. parent:GetFullName() .. ":WaitForChild('" .. name .. "') TIMED OUT")
        end
        return child
    end

    local hud = safeWait(ui, "GuofengHUD")
    local roadmapModal = safeWait(ui, "RoadmapModal")
    local cultModal = safeWait(ui, "CultivationScrollModal")
    local invModal = safeWait(ui, "InventoryScrollModal")
    local shopModal = safeWait(ui, "ShopScrollModal")
    local wheelModal = safeWait(ui, "DestinyWheelModal")

    if invModal then
        local hb = safeWait(invModal, "HeaderBar")
        if hb then
            local sf = safeWait(hb, "SearchFrame")
            if sf then safeWait(sf, "SearchBox") end
            safeWait(hb, "CapacityLabel")
            local cb = hb:FindFirstChild("CloseBtn") or invModal:FindFirstChild("CloseBtn")
            if not cb then table.insert(errors, "FAILED: CloseBtn not found in HeaderBar or invModal") end
        end
        local tabs = safeWait(invModal, "CategoryTabs")
        local mb = safeWait(invModal, "MainBody")
        if mb then
            local gc = safeWait(mb, "GridContainer")
            if gc then safeWait(gc, "ItemList") end
            local ip = safeWait(mb, "InspectPanel")
            if ip then
                safeWait(ip, "IconBox")
                safeWait(ip, "ItemName")
                safeWait(ip, "ItemTier")
                safeWait(ip, "DescFrame")
                safeWait(ip, "StatLabel")
                safeWait(ip, "ValueLabel")
                safeWait(ip, "ActionBtn")
                safeWait(ip, "DiscardBtn")
            end
        end
    end

    if #errors > 0 then
        return "ERRORS FOUND:\\n" .. table.concat(errors, "\\n")
    else
        return "ALL UI HIERARCHY WAITFORCHILD CHECKS PASSED!"
    end
    """
    ok, res = exec_code(lua)
    print("Test Output:\n" + str(res))

if __name__ == '__main__':
    test_client_run()
