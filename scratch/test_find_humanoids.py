import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "bridge"))
from exec import exec_code

code = """
local list = {}
for _, c in ipairs(workspace:GetChildren()) do
    local h = c:FindFirstChildOfClass("Humanoid")
    if h then
        table.insert(list, c.Name .. " (HP=" .. tostring(h.Health) .. "/" .. tostring(h.MaxHealth) .. ", Pos=" .. tostring(c:GetPivot().Position) .. ")")
    end
end
return "Humanoids in Workspace: " .. table.concat(list, " | ")
"""
ok, out = exec_code(code)
print(out)
