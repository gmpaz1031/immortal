import json
import urllib.request
import time

PORT = 34875

def exec_code(code: str, timeout: float = 25.0):
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
local ServerScriptService = game:GetService("ServerScriptService")
local StarterGui = game:GetService("StarterGui")

local dataScript = ServerScriptService:FindFirstChild("Server") and ServerScriptService.Server:FindFirstChild("DATA")
local dataSrc = dataScript and dataScript.Source or ""
local hasZeroQiVal = string.find(dataSrc, "qiVal.Value = 0", 1, true) ~= nil
local hasZeroQiAttr = string.find(dataSrc, 'player:SetAttribute("Qi", 0)', 1, true) ~= nil

local clientScript = StarterGui:FindFirstChild("CultivationUI") and StarterGui.CultivationUI:FindFirstChild("CultivationClient")
local clientSrc = clientScript and clientScript.Source or ""
local hasIdleZero = string.find(clientSrc, '"0.0/s (IDLE)"', 1, true) ~= nil

return string.format("DATA starting Qi 0 Value: %s | Attribute 0: %s | UI Idle 0.0/s: %s",
    tostring(hasZeroQiVal),
    tostring(hasZeroQiAttr),
    tostring(hasIdleZero)
)
"""

ok, res = exec_code(lua_code)
print(f"Success: {ok}\nOutput: {res}")
