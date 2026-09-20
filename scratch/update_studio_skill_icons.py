import sys
import json
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "bridge"))
from exec import exec_code

icons_json_path = Path(__file__).resolve().parent.parent / "assets" / "resolved_icons.json"
with open(icons_json_path, "r", encoding="utf-8") as f:
    data = json.load(f)

skills = data.get("Skills", {})
skills_json = json.dumps(skills)

code = f"""
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local skills = HttpService:JSONDecode([==[{skills_json}]==])

local defaultSlotSkills = {{
    [1] = "Sword Slash",
    [2] = "Flame Ball",
    [3] = "Palm Art",
    [4] = "Thunder Strike",
}}

local log = {{}}

local function updateUI(root)
    if not root then return end
    for _, desc in ipairs(root:GetDescendants()) do
        if desc:IsA("ImageLabel") then
            local p = desc.Parent
            local slotNum = nil
            if p then
                slotNum = p.Name:match("Slot[_-]?(%d+)") or desc.Name:match("Slot[_-]?(%d+)")
            end
            if slotNum then
                local idx = tonumber(slotNum)
                local skillName = defaultSlotSkills[idx]
                if skillName and skills[skillName] then
                    desc.Image = skills[skillName]
                    desc.BackgroundTransparency = 1
                    table.insert(log, "Updated " .. desc:GetFullName() .. " -> " .. skillName .. " (" .. skills[skillName] .. ")")
                end
            end
        end
    end
end

updateUI(StarterGui)
for _, pl in ipairs(Players:GetPlayers()) do
    local pg = pl:FindFirstChild("PlayerGui")
    if pg then updateUI(pg) end
end

return table.concat(log, string.char(10))
"""

ok, out = exec_code(code)
print("Execution OK:", ok)
print("Output:\n", out)
