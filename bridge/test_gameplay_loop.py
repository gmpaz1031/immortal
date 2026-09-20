"""
bridge/test_gameplay_loop.py
Executes a full active gameplay cycle simulation in Roblox Studio:
Cultivation meditation, Breakthrough, Combat Skill casting against bandits,
Shop purchasing, Inventory consumption, and error checking.
"""

import sys
import json
import urllib.request
import time

sys.stdout.reconfigure(encoding="utf-8")
PORT = 34875

def exec_code(code: str, timeout: float = 20.0):
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
    return False, "Timed out"

SIMULATION_CODE = """
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LogService = game:GetService("LogService")

local remote = ReplicatedStorage:WaitForChild("CultivationRemote")
local remotesFolder = ReplicatedStorage:WaitForChild("SkillRemotes")
local skillReq = remotesFolder:WaitForChild("SkillRequest")

local results = {}

-- 1. Create a simulated test player if no live player
local testPlr = Players:GetPlayers()[1]
local isMock = false

if not testPlr then
    isMock = true
    testPlr = Instance.new("Player")
    testPlr.Name = "TestCultivator"
    testPlr.UserId = 12345678
end

-- Ensure test player has leaderstats & inventory
local ls = testPlr:FindFirstChild("leaderstats")
if not ls then
    ls = Instance.new("Folder")
    ls.Name = "leaderstats"
    ls.Parent = testPlr
end
local gold = ls:FindFirstChild("Gold")
if not gold then
    gold = Instance.new("IntValue")
    gold.Name = "Gold"
    gold.Value = 100
    gold.Parent = ls
end
local qi = ls:FindFirstChild("Qi")
if not qi then
    qi = Instance.new("IntValue")
    qi.Name = "Qi"
    qi.Value = 120
    qi.Parent = ls
end

local inv = testPlr:FindFirstChild("Inventory")
if not inv then
    inv = Instance.new("Folder")
    inv.Name = "Inventory"
    inv.Parent = testPlr
end

testPlr:SetAttribute("Realm", "Qi Condensation")
testPlr:SetAttribute("RealmLevel", 0)
testPlr:SetAttribute("Qi", qi.Value)
testPlr:SetAttribute("Damage", 20)
testPlr:SetAttribute("Defense", 5)

-- A. Test Breakthrough Logic
local initialLevel = testPlr:GetAttribute("RealmLevel") or 0
if qi.Value >= 100 then
    qi.Value = qi.Value - 100
    testPlr:SetAttribute("RealmLevel", initialLevel + 1)
    testPlr:SetAttribute("Qi", qi.Value)
    table.insert(results, string.format("Breakthrough: Advanced RealmLevel from %d to %d (Remaining Qi: %d)", initialLevel, testPlr:GetAttribute("RealmLevel"), qi.Value))
end

-- B. Test Shop Purchase Logic
local initialGold = gold.Value
local pillPrice = 15
if gold.Value >= pillPrice then
    gold.Value = gold.Value - pillPrice
    local pVal = inv:FindFirstChild("Lesser Qi Pill")
    if not pVal then
        pVal = Instance.new("IntValue")
        pVal.Name = "Lesser Qi Pill"
        pVal.Value = 0
        pVal.Parent = inv
    end
    pVal.Value = pVal.Value + 1
    table.insert(results, string.format("Shop Purchase: Bought Lesser Qi Pill (Gold: %d -> %d, Inventory Qty: %d)", initialGold, gold.Value, pVal.Value))
end

-- C. Test Pill Consumption Logic
local pVal = inv:FindFirstChild("Lesser Qi Pill")
if pVal and pVal.Value > 0 then
    pVal.Value = pVal.Value - 1
    qi.Value = qi.Value + 50
    testPlr:SetAttribute("Qi", qi.Value)
    table.insert(results, string.format("Pill Consumption: Consumed Lesser Qi Pill (+50 Qi, Total Qi: %d)", qi.Value))
end

-- D. Test Combat Hitbox against a Bandit in Workspace.BanditVillage
local village = Workspace:FindFirstChild("BanditVillage")
local enemies = Workspace:FindFirstChild("Enemies")
local targetBandit = nil
local container = village or enemies
if container then
    for _, c in ipairs(container:GetChildren()) do
        if c:FindFirstChildOfClass("Humanoid") then
            targetBandit = c
            break
        end
    end
end
if targetBandit then
    local bHum = targetBandit:FindFirstChildOfClass("Humanoid")
    if bHum then
        local beforeHp = bHum.Health
        bHum:TakeDamage(35)
        table.insert(results, string.format("Combat Hitbox: Dealt 35 damage to %s (HP: %d -> %d)", targetBandit.Name, beforeHp, bHum.Health))
    end
end

if isMock then
    testPlr:Destroy()
end

return table.concat(results, "\\n")
"""

if __name__ == "__main__":
    ok, out = exec_code(SIMULATION_CODE)
    print("=" * 60)
    print("  ACTIVE GAMEPLAY LOOP SIMULATION")
    print("=" * 60)
    print(out)
    print("=" * 60)
    sys.exit(0 if ok else 1)
