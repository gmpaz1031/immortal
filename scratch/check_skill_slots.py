import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "bridge"))
from exec import exec_code

code = """
local sg = game:GetService("StarterGui")
local sk = sg:FindFirstChild("SkillUI")
if not sk then return "No SkillUI in StarterGui" end
local res = {}
for _, d in ipairs(sk:GetDescendants()) do
    if d.Name:match("Slot") or d.Name == "IconImage" or d.Name == "Icon" then
        table.insert(res, d:GetFullName() .. " (" .. d.ClassName .. ")")
    end
end
return table.concat(res, "\n")
"""

ok, out = exec_code(code)
print(out)
