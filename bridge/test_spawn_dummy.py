import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
from exec import exec_code

code = """
local existingRig = workspace:FindFirstChild("Rig")
if not existingRig then return "No rig found" end

local clone = existingRig:Clone()
clone.Name = "Corrupted Cultivator Dummy"
local hrp = clone:FindFirstChild("HumanoidRootPart") or clone:FindFirstChild("Torso")
if hrp then
    -- Place at (-2.7, 5.7, -26.0) facing towards spawn (-2.7, 5.8, -4.0)
    local targetCFrame = CFrame.new(Vector3.new(-2.7, 5.7, -26.0), Vector3.new(-2.7, 5.7, -4.0))
    clone:PivotTo(targetCFrame)
end

local hum = clone:FindFirstChildOfClass("Humanoid")
if hum then
    hum.MaxHealth = 1000
    hum.Health = 1000
    hum.WalkSpeed = 0
end

-- Create overhead BillboardGui
local bg = Instance.new("BillboardGui")
bg.Name = "DummyOverhead"
bg.Size = UDim2.new(0, 180, 0, 50)
bg.StudsOffset = Vector3.new(0, 3.8, 0)
bg.AlwaysOnTop = true
bg.Parent = clone:FindFirstChild("Head") or hrp

local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, 0, 1, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 24, 30)
frame.BackgroundTransparency = 0.2
frame.Parent = bg

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(220, 70, 70)
stroke.Thickness = 1.5
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 18)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "Corrupted Cultivator"
title.TextColor3 = Color3.fromRGB(255, 100, 100)
title.TextSize = 12
title.Parent = frame

local hpBg = Instance.new("Frame")
hpBg.Name = "HPBackground"
hpBg.Size = UDim2.new(0.9, 0, 0, 8)
hpBg.Position = UDim2.new(0.05, 0, 0, 20)
hpBg.BackgroundColor3 = Color3.fromRGB(40, 15, 15)
hpBg.BorderSizePixel = 0
hpBg.Parent = frame

local hpFill = Instance.new("Frame")
hpFill.Name = "HPFill"
hpFill.Size = UDim2.new(1, 0, 1, 0)
hpFill.BackgroundColor3 = Color3.fromRGB(235, 60, 60)
hpFill.BorderSizePixel = 0
hpFill.Parent = hpBg

local statusTag = Instance.new("TextLabel")
statusTag.Name = "DummyStatusTag"
statusTag.Size = UDim2.new(1, 0, 0, 16)
statusTag.Position = UDim2.new(0, 0, 0, 30)
statusTag.BackgroundTransparency = 1
statusTag.Font = Enum.Font.GothamMedium
statusTag.Text = "STATUS: ACTIVE (1000/1000)"
statusTag.TextColor3 = Color3.fromRGB(120, 255, 140)
statusTag.TextSize = 10
statusTag.Parent = frame

if hum then
    hum.HealthChanged:Connect(function(newHp)
        local pct = math.clamp(newHp / 1000, 0, 1)
        hpFill.Size = UDim2.new(pct, 0, 1, 0)
        if not string.find(statusTag.Text, "STUNNED") and not string.find(statusTag.Text, "ZAP") then
            statusTag.Text = string.format("STATUS: ACTIVE (%d/1000)", math.floor(newHp))
        end
    end)
end

clone.Parent = workspace
return "Dummy spawned at " .. tostring(hrp.Position)
"""

ok, res = exec_code(code)
print(ok, res)
