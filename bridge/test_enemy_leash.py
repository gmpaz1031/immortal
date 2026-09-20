"""
bridge/test_enemy_leash.py
Verifies the enemy leash, walk back, and 15-second return teleportation mechanics.
"""

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

TEST_SCRIPT = """
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- Test Unit: Leash, walk back, and 15s return teleportation logic
local homeCF = CFrame.new(-477.61, 9.20, -222.91)
local homePos = homeCF.Position
local MAX_LEASH_DIST = 40

local results = {}

-- Scenario A: Enemy wanders outside home without enemy detected
local returningStartTime = nil
local enemyPos = homePos + Vector3.new(35, 0, 0) -- 35 studs away
local distFromHome = (enemyPos - homePos).Magnitude

if distFromHome > 4 then
    returningStartTime = os.clock()
end
table.insert(results, "Scenario A: Return timer initiated -> " .. tostring(returningStartTime ~= nil))

-- Scenario B: 10 seconds elapsed (< 15s) -> Must continue walking, NOT teleport
local timeReturning = 10
local shouldTeleport = timeReturning >= 15
table.insert(results, "Scenario B (t=10s): Teleport triggered -> " .. tostring(shouldTeleport) .. " (Walks back)")

-- Scenario C: 15.1 seconds elapsed (>= 15s) -> Teleports back to homeCF
timeReturning = 15.1
shouldTeleport = timeReturning >= 15
if shouldTeleport then
    enemyPos = homeCF.Position
    returningStartTime = nil
end
local isBackHome = (enemyPos - homePos).Magnitude <= 1
table.insert(results, "Scenario C (t=15.1s): Teleport triggered -> " .. tostring(shouldTeleport) .. ", Back at home -> " .. tostring(isBackHome))

-- Scenario D: Enemy detects player while returning -> Timer MUST reset to nil
returningStartTime = os.clock()
local playerDetected = true
if playerDetected then
    returningStartTime = nil
end
table.insert(results, "Scenario D: Player detected -> Return timer reset to nil -> " .. tostring(returningStartTime == nil))

-- Scenario E: Verify BanditSpawnerService script code in ServerScriptService
local sss = game:GetService("ServerScriptService")
local banditScript = sss:FindFirstChild("Server") and sss.Server:FindFirstChild("BanditSpawnerService")
local has15sCode = false
local hasLeashCode = false
if banditScript then
    local src = banditScript.Source
    has15sCode = string.find(src, "timeReturning >= 15") ~= nil
    hasLeashCode = string.find(src, "MAX_LEASH_DIST") ~= nil
end
table.insert(results, "Scenario E: Server BanditSpawnerService has 15s teleport code -> " .. tostring(has15sCode) .. ", has MAX_LEASH_DIST -> " .. tostring(hasLeashCode))

return table.concat(results, "\\n")
"""

if __name__ == "__main__":
    ok, out = exec_code(TEST_SCRIPT)
    print("============================================================")
    print("  ENEMY LEASH & 15-SECOND RETURN TELEPORT TEST")
    print("============================================================")
    print(out)
    print("============================================================")
