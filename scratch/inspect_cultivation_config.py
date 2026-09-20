import json
import urllib.request
import time

PORT = 34875

def exec_code(code: str, timeout: float = 15.0):
    url = f"http://127.0.0.1:{PORT}/exec"
    payload = json.dumps({"code": code}).encode("utf-8")
    req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode("utf-8"))
        cmd_id = data.get("id")
        
    start = time.time()
    while time.time() - start < timeout:
        try:
            with urllib.request.urlopen(f"http://127.0.0.1:{PORT}/result?id={cmd_id}") as r:
                res = json.loads(r.read().decode("utf-8"))
                return res.get("success"), res.get("output") or res.get("error")
        except Exception:
            time.sleep(0.2)
    return False, "Timeout"

lua_code = """
local c = game:GetService("ReplicatedStorage"):FindFirstChild("Shared"):FindFirstChild("CultivationConfig")
if not c then return "CultivationConfig not found" end
local src = c.Source
local hasImmortalSovereign = string.find(src, "Immortal Sovereign", 1, true) ~= nil

-- Also search for any other CultivationConfig in the whole game
local otherConfigs = {}
for _, desc in ipairs(game:GetDescendants()) do
    if desc.Name == "CultivationConfig" and desc:IsA("ModuleScript") then
        table.insert(otherConfigs, desc:GetFullName())
    end
end

-- Test cloning to bypass require cache
local clone = c:Clone()
clone.Parent = game:GetService("ReplicatedStorage")
local required = require(clone)
local countOrder = #required.RealmOrder
clone:Destroy()

return string.format("RS.Shared Source len: %d | hasImmortalSovereign: %s | Fresh Require RealmOrder Count: %d | Found modules: %s", 
    #src, tostring(hasImmortalSovereign), countOrder, table.concat(otherConfigs, ", "))
"""

ok, res = exec_code(lua_code)
print(f"Success: {ok}\nOutput: {res}")
