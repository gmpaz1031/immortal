import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "bridge"))
from exec import exec_code

code = """
local sss = game:GetService("ServerScriptService")
sss.LoadStringEnabled = true
return "LoadStringEnabled=" .. tostring(sss.LoadStringEnabled)
"""
ok, out = exec_code(code)
print(f"ok={ok}, out={out}")
