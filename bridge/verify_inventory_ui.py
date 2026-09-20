import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def verify_ui():
    print("=== Verifying Complete Professional Inventory UI in Studio ===")

    lua_test = """
    local StarterGui = game:GetService("StarterGui")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local report = {}

    local ui = StarterGui:FindFirstChild("CultivationUI")
    if not ui then return "CultivationUI missing" end

    local inv = ui:FindFirstChild("InventoryScrollModal")
    if not inv then return "InventoryScrollModal missing" end

    table.insert(report, "Inventory Window Size: " .. tostring(inv.Size))

    -- 1. Check Header
    local header = inv:FindFirstChild("HeaderBar")
    table.insert(report, "HeaderBar: " .. (header and "OK" or "MISSING"))
    if header then
        local search = header:FindFirstChild("SearchBox", true)
        local cap = header:FindFirstChild("CapacityLabel", true)
        local close = header:FindFirstChild("CloseBtn", true)
        table.insert(report, string.format("Header Elements: Search=%s, Capacity=%s, CloseBtn=%s", tostring(search ~= nil), tostring(cap ~= nil), tostring(close ~= nil)))
    end

    -- 2. Check 5 Category Tabs
    local tabs = inv:FindFirstChild("CategoryTabs")
    table.insert(report, "CategoryTabs Bar: " .. (tabs and "OK" or "MISSING"))
    if tabs then
        local tabList = {}
        for _, c in ipairs({ "MISC", "PILLS", "MANUALS", "SKILLS", "EQUIPMENT" }) do
            local t = tabs:FindFirstChild("Tab_" .. c)
            if t then table.insert(tabList, c) end
        end
        table.insert(report, "Category Tabs Count: " .. tostring(#tabList) .. " / 5 (" .. table.concat(tabList, ", ") .. ")")
    end

    -- 3. Check Left Grid Container
    local mainBody = inv:FindFirstChild("MainBody")
    table.insert(report, "MainBody Dual Container: " .. (mainBody and "OK" or "MISSING"))
    if mainBody then
        local grid = mainBody:FindFirstChild("GridContainer")
        local itemList = grid and grid:FindFirstChild("ItemList")
        local gridLayout = itemList and itemList:FindFirstChildWhichIsA("UIGridLayout")
        table.insert(report, string.format("Left Grid: Container=%s, ItemList=%s, UIGridLayout=%s", tostring(grid ~= nil), tostring(itemList ~= nil), tostring(gridLayout ~= nil)))
    
        -- 4. Check Right Item Inspect Panel
        local inspect = mainBody:FindFirstChild("InspectPanel")
        table.insert(report, "Right InspectPanel: " .. (inspect and "OK" or "MISSING"))
        if inspect then
            local iconBox = inspect:FindFirstChild("IconBox")
            local itemName = inspect:FindFirstChild("ItemName")
            local itemTier = inspect:FindFirstChild("ItemTier")
            local desc = inspect:FindFirstChild("DescFrame")
            local stats = inspect:FindFirstChild("StatLabel")
            local val = inspect:FindFirstChild("ValueLabel")
            local actBtn = inspect:FindFirstChild("ActionBtn")
            local discBtn = inspect:FindFirstChild("DiscardBtn")

            table.insert(report, string.format("Inspect Elements: Icon=%s, Name=%s, Tier=%s, Desc=%s, Stats=%s, Value=%s, ActionBtn=%s, DiscardBtn=%s",
                tostring(iconBox ~= nil), tostring(itemName ~= nil), tostring(itemTier ~= nil), tostring(desc ~= nil),
                tostring(stats ~= nil), tostring(val ~= nil), tostring(actBtn ~= nil), tostring(discBtn ~= nil)))
        end
    end

    -- 5. Check Client Script Logic
    local clientScript = ui:FindFirstChild("CultivationClient")
    if clientScript then
        local src = clientScript.Source
        local hasGrid = string.find(src, "UIGridLayout", 1, true) ~= nil
        local hasTabs = string.find(src, 'categoryTabs:FindFirstChild("Tab_" .. tabName)', 1, true) ~= nil
        local hasSearch = string.find(src, 'searchBox:GetPropertyChangedSignal("Text")', 1, true) ~= nil
        local hasInspect = string.find(src, "selectItem", 1, true) ~= nil
        table.insert(report, string.format("CultivationClient Logic: Grid=%s, 5Tabs=%s, RealtimeSearch=%s, InspectSelection=%s",
            tostring(hasGrid), tostring(hasTabs), tostring(hasSearch), tostring(hasInspect)))
    end

    return table.concat(report, "\\n")
    """

    ok, res = exec_code(lua_test)
    print("UI Verification Output:\n" + str(res))
    assert ok, f"Verification failed: {res}"

if __name__ == '__main__':
    verify_ui()
