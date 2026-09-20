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
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- 1. Test Swordmaster & Four Shrine Pillars position retention
local smBefore = Workspace:FindFirstChild("DestroyedVillage_Enemies") and Workspace.DestroyedVillage_Enemies:FindFirstChild("Swordmaster_Boss")
local posBefore = smBefore and smBefore.PrimaryPart and smBefore.PrimaryPart.Position or Vector3.zero

local mgrModule = ServerScriptService:FindFirstChild("Server") and ServerScriptService.Server:FindFirstChild("DestroyedVillageManager")
if mgrModule then
    local mgr = require(mgrModule)
    mgr.init()
end

local smAfter = Workspace:FindFirstChild("DestroyedVillage_Enemies") and Workspace.DestroyedVillage_Enemies:FindFirstChild("Swordmaster_Boss")
local posAfter = smAfter and smAfter.PrimaryPart and smAfter.PrimaryPart.Position or Vector3.zero
local smDisplaced = (posAfter - posBefore).Magnitude > 0.01

-- Check pillars
local cas = Workspace:FindFirstChild("DestroyedVillage") and Workspace.DestroyedVillage:FindFirstChild("CentralAncientShrine")
local p1 = cas and cas:FindFirstChild("ShrinePillar_1")
local p2 = cas and cas:FindFirstChild("ShrinePillar_2")
local p3 = cas and cas:FindFirstChild("ShrinePillar_3")
local p4 = cas and cas:FindFirstChild("ShrinePillar_4")
local pillarsPresent = (p1 ~= nil and p2 ~= nil and p3 ~= nil and p4 ~= nil)

-- 2. Test Qi Gathering Logic & Limit Hard Cap
local CultivationConfig = require(ReplicatedStorage.Shared.CultivationConfig)
local DestinyConfig = require(ReplicatedStorage.Shared.DestinyConfig)

local realm = "Qi Condensation"
local level = 0
local reqQi = CultivationConfig.getRequiredQi(realm, level) -- 100
local limit = reqQi

local baseSpeed = 5
local talentMult = DestinyConfig.GetTalentMultiplier("Mortal") -- 1.0
local rootMult = DestinyConfig.GetRootMultiplier("None") -- 1.0
local destinyMult = talentMult * rootMult

-- Test Idle: gain MUST be 0
local isCult = false
local idleGain = if isCult then math.max(1, math.floor(baseSpeed * destinyMult * 2)) else 0

-- Test Meditating: gain > 0
isCult = true
local cultGain = if isCult then math.max(1, math.floor(baseSpeed * destinyMult * 2)) else 0

-- Test Cap: simulating accumulating Qi up to and beyond limit
local simQi = 95
simQi = math.clamp(simQi + cultGain, 0, limit)
local cappedQi = simQi -- should be 100

-- Try adding more Qi while meditating when already at limit:
local addedQi = if cappedQi < limit then cultGain else 0
local finalQi = math.clamp(cappedQi + addedQi, 0, limit)

-- Test Breakthrough: deduct reqQi and level up
local newLevel = level + 1
local remainingQi = math.max(0, finalQi - reqQi)
local newReqQi = CultivationConfig.getRequiredQi(realm, newLevel)

return string.format(
    "SM Before: %s | SM After: %s | Displaced: %s | PillarsOK: %s | IdleGain: %d | CultGain: %d | CappedAtLimit: %d/%d | AddedBeyondLimit: %d | PostBreakthrough: %d/%d",
    tostring(posBefore),
    tostring(posAfter),
    tostring(smDisplaced),
    tostring(pillarsPresent),
    idleGain,
    cultGain,
    cappedQi,
    limit,
    addedQi,
    remainingQi,
    newReqQi
)
"""

ok, res = exec_code(lua_code)
print(f"Success: {ok}\nOutput: {res}")
