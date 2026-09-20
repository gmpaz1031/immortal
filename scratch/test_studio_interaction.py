import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "bridge"))
from exec import exec_code

code = """
local r = game:GetService("RunService")
return "IsRunning=" .. tostring(r:IsRunning()) .. " IsEdit=" .. tostring(r:IsEdit())
"""
ok, out = exec_code(code)
print(f"ok={ok}, out={out}")
