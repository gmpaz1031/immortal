import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def debug_all():
    print("=== Deep Diagnostic of All Systems in Roblox Studio ===")

    lua_diag = """
    local StarterGui = game:GetService("StarterGui")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local SSS = game:GetService("ServerScriptService")

    local report = {}

    -- 1. Check RemoteEvent
    local remote = ReplicatedStorage:FindFirstChild("CultivationRemote")
    table.insert(report, "CultivationRemote: " .. (remote and "OK" or "MISSING"))

    -- 2. Check CultivationUI in StarterGui
    local ui = StarterGui:FindFirstChild("CultivationUI")
    if not ui then
        return "FATAL: StarterGui.CultivationUI is missing!"
    end
    table.insert(report, "CultivationUI: OK")

    -- Check all modals under CultivationUI
    local modals = {
        "GuofengHUD",
        "CultivationScrollModal",
        "InventoryScrollModal",
        "DestinyWheelModal",
        "DestinyAwardPopup",
        "ShopScrollModal",
        "RoadmapModal",
    }
    for _, mName in ipairs(modals) do
        local m = ui:FindFirstChild(mName)
        table.insert(report, string.format("Modal %s: %s (Visible=%s)", mName, m and "OK" or "MISSING", tostring(m and m.Visible)))
    end

    -- 3. Check DestinyWheelModal hierarchy
    local wheel = ui:FindFirstChild("DestinyWheelModal")
    if wheel then
        local header = wheel:FindFirstChild("HeaderBanner")
        local leftCol = wheel:FindFirstChild("LeftColumn")
        local rightCol = wheel:FindFirstChild("RightColumn")
        local tabRow = wheel:FindFirstChild("TabRow")
        table.insert(report, string.format("DestinyWheel: Header=%s, LeftCol=%s, RightCol=%s, TabRow=%s",
            tostring(header ~= nil), tostring(leftCol ~= nil), tostring(rightCol ~= nil), tostring(tabRow ~= nil)))
        if leftCol then
            local rim = leftCol:FindFirstChild("WheelRim")
            local disc = rim and rim:FindFirstChild("WheelDisc")
            local ptr = rim and rim:FindFirstChild("Pointer")
            local spinBtn = leftCol:FindFirstChild("SpinActionBtn")
            table.insert(report, string.format("Wheel Elements: Rim=%s, Disc=%s, Pointer=%s, SpinBtn=%s",
                tostring(rim ~= nil), tostring(disc ~= nil), tostring(ptr ~= nil), tostring(spinBtn ~= nil)))
        end
    end

    -- 4. Check CultivationScrollModal hierarchy
    local cult = ui:FindFirstChild("CultivationScrollModal")
    if cult then
        local dBtn = cult:FindFirstChild("DestinyWheelBtn")
        local cBtn = cult:FindFirstChild("CinnabarActionBtn")
        local sn = cult:FindFirstChild("StatNodes")
        local tc = cult:FindFirstChild("TalentCrest")
        local rc = cult:FindFirstChild("RootCrest")
        table.insert(report, string.format("CultModal: DestinyWheelBtn=%s, CinnabarBtn=%s, StatNodes=%s, TalentCrest=%s, RootCrest=%s",
            tostring(dBtn ~= nil), tostring(cBtn ~= nil), tostring(sn ~= nil), tostring(tc ~= nil), tostring(rc ~= nil)))
    end

    -- 5. Check InventoryScrollModal hierarchy
    local inv = ui:FindFirstChild("InventoryScrollModal")
    if inv then
        local header = inv:FindFirstChild("HeaderBar")
        local tabs = inv:FindFirstChild("CategoryTabs")
        local main = inv:FindFirstChild("MainBody")
        table.insert(report, string.format("InventoryModal: Header=%s, CategoryTabs=%s, MainBody=%s",
            tostring(header ~= nil), tostring(tabs ~= nil), tostring(main ~= nil)))
        if tabs then
            local tabNames = {}
            for _, c in ipairs(tabs:GetChildren()) do
                if c:IsA("TextButton") then table.insert(tabNames, c.Name) end
            end
            table.insert(report, "Inventory Tabs found: " .. table.concat(tabNames, ", "))
        end
        if main then
            local grid = main:FindFirstChild("GridContainer")
            local inspect = main:FindFirstChild("InspectPanel")
            table.insert(report, string.format("Inventory Main: GridContainer=%s, InspectPanel=%s",
                tostring(grid ~= nil), tostring(inspect ~= nil)))
        end
    end

    -- 6. Check CultivationClient script
    local cs = ui:FindFirstChild("CultivationClient")
    table.insert(report, "CultivationClient script: " .. (cs and ("OK (" .. tostring(#cs.Source) .. " chars)") or "MISSING"))
    if cs then
        local fn, err = loadstring(cs.Source)
        table.insert(report, "CultivationClient compiles: " .. (fn and "YES" or ("NO: " .. tostring(err))))
    end

    -- 7. Check Server Scripts
    local serverFolder = SSS:FindFirstChild("Server")
    if serverFolder then
        local ds = serverFolder:FindFirstChild("DATA")
        local ms = serverFolder:FindFirstChild("MAINSERVER")
        local ps = serverFolder:FindFirstChild("PlantHarvestService")
        local minS = serverFolder:FindFirstChild("MiningService")
        table.insert(report, string.format("Server Scripts: DATA=%s, MAINSERVER=%s, PlantHarvest=%s, MiningService=%s",
            tostring(ds ~= nil), tostring(ms ~= nil), tostring(ps ~= nil), tostring(minS ~= nil)))
    end

    return table.concat(report, "\\n")
    """

    ok, res = exec_code(lua_diag)
    print("Diagnostic Output:\n" + str(res))

if __name__ == '__main__':
    debug_all()
