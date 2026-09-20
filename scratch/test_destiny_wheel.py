import json
import urllib.request
import time

PORT = 34875

def exec_code(code: str, timeout: float = 25.0):
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
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- 1. Check MAINSERVER has SpinWheel handler
local mainServer = ServerScriptService:FindFirstChild("Server") and ServerScriptService.Server:FindFirstChild("MAINSERVER")
local msSrc = mainServer and mainServer.Source or ""
local hasSpinWheelAction = string.find(msSrc, 'action == "SpinWheel"', 1, true) ~= nil
local hasSpinResultFire = string.find(msSrc, '"SpinResult"', 1, true) ~= nil

-- 2. Test rolling functionality from DestinyConfig
local DestinyConfig = require(ReplicatedStorage.Shared.DestinyConfig)
local talent, tIdx = DestinyConfig.RollTalent()
local root, rIdx = DestinyConfig.RollSpiritualRoot()

-- 3. Check DestinyAwardPopup hierarchy and text updates
local ui = StarterGui:FindFirstChild("CultivationUI")
local popup = ui and ui:FindFirstChild("DestinyAwardPopup")
local card = popup and popup:FindFirstChild("Card")
local headerPill = card and card:FindFirstChild("HeaderPill")
local headerLbl = headerPill and headerPill:FindFirstChild("HeaderLabel")
local nameLbl = card and card:FindFirstChild("NameLabel")
local multBanner = card and card:FindFirstChild("MultBanner")
local multLbl = multBanner and multBanner:FindFirstChild("MultLabel")
local chanceLbl = card and card:FindFirstChild("ChanceLabel")
local descBox = card and card:FindFirstChild("DescBox")
local claimBtn = card and card:FindFirstChild("ClaimBtn")

local allPopupElementsPresent = (
    popup ~= nil and
    card ~= nil and
    headerLbl ~= nil and
    nameLbl ~= nil and
    multLbl ~= nil and
    chanceLbl ~= nil and
    descBox ~= nil and
    claimBtn ~= nil
)

-- Test populating popup with the rolled talent
if allPopupElementsPresent then
    headerLbl.Text = "DESTINY TALENT AWAKENED"
    nameLbl.Text = talent.Name
    nameLbl.TextColor3 = talent.Color
    chanceLbl.Text = string.format("Rarity: %s | Probability: %.2f%%", talent.TierName, talent.Chance)
    descBox.Text = talent.Description
    multLbl.Text = string.format("Qi Gathering Speed: x%.2f Multiplier", talent.Multiplier)
    popup.Visible = true
end

local popupVisibleAfterSet = popup and popup.Visible
local popupNameText = nameLbl and nameLbl.Text

-- Hide it again for clean state
if popup then
    popup.Visible = false
end

return string.format(
    "SpinWheelServerHandler: %s | SpinResultFire: %s | RolledTalent: %s (#%d, x%.2f) | RolledRoot: %s (#%d, x%.2f) | PopupElementsOK: %s | PopupTestedVisible: %s | PopupName: %s",
    tostring(hasSpinWheelAction),
    tostring(hasSpinResultFire),
    talent.Name,
    tIdx,
    talent.Multiplier,
    root.Name,
    rIdx,
    root.Multiplier,
    tostring(allPopupElementsPresent),
    tostring(popupVisibleAfterSet),
    tostring(popupNameText)
)
"""

ok, res = exec_code(lua_code)
print(f"Success: {ok}\nOutput: {res}")
