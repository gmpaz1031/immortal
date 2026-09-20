import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "bridge"))
from exec import exec_code

code = """
local list = {}
for _, c in ipairs(workspace:GetChildren()) do
    if c.Name == "Rig" then
        local parts = {}
        for _, p in ipairs(c:GetChildren()) do
            if p:IsA("BasePart") or p:IsA("Humanoid") or p:IsA("Script") or p:IsA("LocalScript") then
                table.insert(parts, p.Name .. "(" .. p.ClassName .. ")")
            end
        end
        table.insert(list, "Rig: " .. table.concat(parts, ", "))
    end
end
return table.concat(list, " || ")
"""
ok, out = exec_code(code)
print(out)
