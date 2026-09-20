import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "bridge"))
from exec import exec_code

code = """
local StarterGui = game:GetService("StarterGui")
local hotbar = StarterGui:FindFirstChild("SkillUI") and StarterGui.SkillUI:FindFirstChild("GuofengSkillHotbar")
if not hotbar then return "No GuofengSkillHotbar found" end

local res = {}
for i = 1, 4 do
    local slot = hotbar:FindFirstChild("SkillSlot_" .. i)
    if slot then
        local img = slot:FindFirstChild("IconImage")
        local imgVal = img and img.Image or "nil"
        local transVal = img and img.BackgroundTransparency or -1
        table.insert(res, "Slot " .. i .. ": Image=" .. imgVal .. ", BgTransparency=" .. tostring(transVal))
    end
end
return table.concat(res, string.char(10))
"""

ok, out = exec_code(code)
print("Studio Query:")
print(out)
