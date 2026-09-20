import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
from exec import exec_code

code = """
local p = workspace:FindPartOnRay(Ray.new(Vector3.new(-2.7, 6.0, -4.0), Vector3.new(0, 0, -22)))
return string.format("Obstacle between spawn and -26: %s", p and p:GetFullName() or "NONE - COMPLETELY CLEAR!")
"""

ok, res = exec_code(code)
print(res)
