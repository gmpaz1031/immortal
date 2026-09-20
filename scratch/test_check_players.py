import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "bridge"))
from exec import exec_code

code = """
local ps = game:GetService("Players")
local list = {}
for _, p in ipairs(ps:GetPlayers()) do
    table.insert(list, p.Name .. " (Char=" .. tostring(p.Character ~= nil) .. ")")
end
return "Players: " .. table.concat(list, ", ")
"""
ok, out = exec_code(code)
print(f"ok={ok}, out={out}")
