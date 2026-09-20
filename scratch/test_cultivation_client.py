import json
import urllib.request
import time

PORT = 34875

def exec_code(code: str, timeout: float = 20.0):
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
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ui = StarterGui:FindFirstChild("CultivationUI")
if not ui then return "CultivationUI not found in StarterGui" end

local cultModal = ui:FindFirstChild("CultivationScrollModal")
local scrollQiBar = cultModal and cultModal:FindFirstChild("ScrollQiBar")
local scrollQiFill = scrollQiBar and scrollQiBar:FindFirstChild("Fill")
local breakProgText = cultModal and cultModal:FindFirstChild("BreakProgressText")
local qiBar = ui:FindFirstChild("QiBar")
local qiFill = qiBar and qiBar:FindFirstChild("Fill")

-- Test 1: Verify Initial bar state
local initialScrollSize = scrollQiFill.Size
local initialQiBarSize = qiFill.Size

-- Test 2: Test popup creation
local popup = Instance.new("TextLabel")
popup.Name = "TestQiGainPopup"
popup.BackgroundTransparency = 1
popup.AnchorPoint = Vector2.new(0.5, 0.5)
popup.Position = UDim2.new(0.5, 0, 0.5, 0)
popup.Size = UDim2.new(0, 180, 0, 40)
popup.Font = Enum.Font.GothamBlack
popup.Text = "+25 QI"
popup.TextColor3 = Color3.fromRGB(80, 255, 215)
popup.TextSize = 22
popup.ZIndex = 85
popup.Parent = ui

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(12, 45, 38)
stroke.Thickness = 2.0
stroke.Parent = popup

local popupCreated = popup.Parent == ui

task.delay(0.2, function()
    if popup and popup.Parent then
        popup:Destroy()
    end
end)

-- Test 3: Test Dynamic updateStatsDisplay math
local CultivationConfig = require(ReplicatedStorage.Shared.CultivationConfig)
local reqQi = CultivationConfig.getRequiredQi("Qi Condensation", 0) -- should be 100
local currentQi = 45
local qiRatio = math.clamp(currentQi / reqQi, 0, 1)

scrollQiFill.Size = UDim2.new(qiRatio, 0, 1, 0)
qiFill.Size = UDim2.new(qiRatio, 0, 1, 0)
breakProgText.Text = string.format("BREAKTHROUGH REQUIREMENT: %d / %d QI", currentQi, reqQi)

local updatedScrollSize = scrollQiFill.Size
local updatedText = breakProgText.Text

-- Reset back to 0 for clean studio state
scrollQiFill.Size = UDim2.new(0, 0, 1, 0)
qiFill.Size = UDim2.new(0, 0, 1, 0)
breakProgText.Text = "BREAKTHROUGH REQUIREMENT: 0 / 100 QI"

return string.format(
    "ReqQi: %d | PopupCreated: %s | DynamicSize: %s | DynamicText: %s | Reset: %s",
    reqQi,
    tostring(popupCreated),
    tostring(updatedScrollSize),
    updatedText,
    tostring(scrollQiFill.Size)
)
"""

ok, res = exec_code(lua_code)
print(f"Success: {ok}\nOutput: {res}")
