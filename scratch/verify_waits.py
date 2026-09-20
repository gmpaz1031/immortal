import json
import urllib.request
import time

PORT = 34875

def exec_code(code: str, timeout: float = 15.0):
    url = f"http://127.0.0.1:{PORT}/exec"
    payload = json.dumps({"code": code}).encode("utf-8")
    req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode("utf-8"))
        cmd_id = data.get("id")
        
    start = time.time()
    while time.time() - start < timeout:
        try:
            with urllib.request.urlopen(f"http://127.0.0.1:{PORT}/result?id={cmd_id}") as r:
                res = json.loads(r.read().decode("utf-8"))
                return res.get("success"), res.get("output") or res.get("error")
        except Exception:
            time.sleep(0.2)
    return False, "Timeout"

lua_code = """
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local ui = StarterGui:FindFirstChild("CultivationUI")
if not ui then return "CultivationUI missing" end

local function testWait(parent, childName)
    local ok, res = pcall(function()
        return parent:WaitForChild(childName, 0.5)
    end)
    if not ok or not res then
        return false, parent:GetFullName() .. " failed WaitForChild('" .. childName .. "')"
    end
    return true, res
end

local checks = {
    {ReplicatedStorage, "Shared"},
    {ReplicatedStorage:FindFirstChild("Shared"), "CultivationConfig"},
    {ReplicatedStorage:FindFirstChild("Shared"), "ItemConfig"},
    {ReplicatedStorage:FindFirstChild("Shared"), "GuofengTheme"},
    {ReplicatedStorage:FindFirstChild("Shared"), "IconAssets"},
    {ReplicatedStorage:FindFirstChild("Shared"), "DestinyConfig"},
    {ReplicatedStorage, "CultivationRemote"},
    {ui, "RoadmapModal"},
    {ui, "CultivationScrollModal"},
    {ui, "InventoryScrollModal"},
    {ui, "ShopScrollModal"},
    {ui, "DestinyWheelModal"},
    {ui, "NavRow"},
    {ui:FindFirstChild("NavRow"), "RoadmapNavBtn"},
    {ui:FindFirstChild("NavRow"), "CultNavBtn"},
    {ui:FindFirstChild("NavRow"), "InvNavBtn"},
    {ui:FindFirstChild("NavRow"), "ShopNavBtn"},
    {ui, "HPBar"},
    {ui:FindFirstChild("HPBar"), "Fill"},
    {ui:FindFirstChild("HPBar"), "Text"},
    {ui, "QiBar"},
    {ui:FindFirstChild("QiBar"), "Fill"},
    {ui:FindFirstChild("QiBar"), "Text"},
    {ui, "GoldLabel"},
    {ui, "RealmLabel"},
    {ui:FindFirstChild("RoadmapModal"), "CenterCanvas"},
    {ui:FindFirstChild("RoadmapModal") and ui.RoadmapModal.CenterCanvas, "LineBanner"},
    {ui:FindFirstChild("CultivationScrollModal"), "StatNodes"},
    {ui:FindFirstChild("CultivationScrollModal"), "BreakProgressText"},
    {ui:FindFirstChild("CultivationScrollModal"), "ScrollQiBar"},
    {ui:FindFirstChild("CultivationScrollModal") and ui.CultivationScrollModal.ScrollQiBar, "Fill"},
    {ui:FindFirstChild("CultivationScrollModal"), "CinnabarActionBtn"},
    {ui:FindFirstChild("CultivationScrollModal"), "DestinyWheelBtn"},
    {ui:FindFirstChild("CultivationScrollModal"), "TalentCrest"},
    {ui:FindFirstChild("CultivationScrollModal"), "RootCrest"},
    {ui:FindFirstChild("DestinyWheelModal"), "HeaderBanner"},
    {ui:FindFirstChild("DestinyWheelModal") and ui.DestinyWheelModal.HeaderBanner, "CloseBtn"},
    {ui:FindFirstChild("DestinyWheelModal"), "TabRow"},
    {ui:FindFirstChild("DestinyWheelModal") and ui.DestinyWheelModal.TabRow, "TalentTab"},
    {ui:FindFirstChild("DestinyWheelModal") and ui.DestinyWheelModal.TabRow, "RootTab"},
    {ui:FindFirstChild("DestinyWheelModal"), "LeftColumn"},
    {ui:FindFirstChild("DestinyWheelModal") and ui.DestinyWheelModal.LeftColumn, "WheelRim"},
    {ui:FindFirstChild("DestinyWheelModal") and ui.DestinyWheelModal.LeftColumn and ui.DestinyWheelModal.LeftColumn.WheelRim, "WheelDisc"},
    {ui:FindFirstChild("DestinyWheelModal") and ui.DestinyWheelModal.LeftColumn and ui.DestinyWheelModal.LeftColumn.WheelRim, "Pointer"},
    {ui:FindFirstChild("DestinyWheelModal") and ui.DestinyWheelModal.LeftColumn, "CurrentStatus"},
    {ui:FindFirstChild("DestinyWheelModal") and ui.DestinyWheelModal.LeftColumn, "CostInfo"},
    {ui:FindFirstChild("DestinyWheelModal") and ui.DestinyWheelModal.LeftColumn, "SpinActionBtn"},
    {ui:FindFirstChild("DestinyWheelModal"), "RightColumn"},
    {ui:FindFirstChild("DestinyWheelModal") and ui.DestinyWheelModal.RightColumn, "TierScroll"},
    {ui, "DestinyAwardPopup"},
    {ui:FindFirstChild("DestinyAwardPopup"), "Card"},
    {ui:FindFirstChild("InventoryScrollModal"), "HeaderBar"},
    {ui:FindFirstChild("InventoryScrollModal") and ui.InventoryScrollModal.HeaderBar, "SearchFrame"},
    {ui:FindFirstChild("InventoryScrollModal") and ui.InventoryScrollModal.HeaderBar, "CapacityLabel"},
    {ui:FindFirstChild("InventoryScrollModal"), "CategoryTabs"},
    {ui:FindFirstChild("InventoryScrollModal"), "MainBody"},
    {ui:FindFirstChild("InventoryScrollModal") and ui.InventoryScrollModal.MainBody, "GridContainer"},
    {ui:FindFirstChild("InventoryScrollModal") and ui.InventoryScrollModal.MainBody and ui.InventoryScrollModal.MainBody.GridContainer, "ItemList"},
    {ui:FindFirstChild("InventoryScrollModal") and ui.InventoryScrollModal.MainBody, "InspectPanel"},
    {ui:FindFirstChild("ShopScrollModal"), "ShopItemList"},
    {ui:FindFirstChild("ShopScrollModal"), "ShopList"},
}

local fails = {}
for _, chk in ipairs(checks) do
    local parent = chk[1]
    local name = chk[2]
    if parent then
        local ok, msg = testWait(parent, name)
        if not ok then
            table.insert(fails, msg)
        end
    else
        table.insert(fails, "Parent was nil for child: " .. name)
    end
end

if #fails > 0 then
    return "FAILURES:\\n" .. table.concat(fails, "\\n")
else
    return "ALL WAITS PASSED!"
end
"""

ok, out = exec_code(lua_code)
print(f"Result: {out}")
