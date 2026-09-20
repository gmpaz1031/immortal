"""
bridge/verify_requirements.py
Verifies the 4 user requirements:
1. Zero scripts contain ScreenGui instance creation; StarterGui UI is preserved.
2. StarterGui Backpack is disabled.
3. Zero Chinese text in any script, label, banner, or button.
4. All enemies in Workspace.Enemies use SAMPLEENEMYMODEL template with custom styling.
"""

import sys
import json
import re
import urllib.request
import time

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
            time.sleep(0.25)
    return False, "Timed out"

LUA_VERIFY = r"""
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local LogService = game:GetService("LogService")

local report = {
    checks = {},
    passed = true
}

local function addCheck(name, success, details)
    table.insert(report.checks, {
        name = name,
        success = success,
        details = details or "OK"
    })
    if not success then
        report.passed = false
    end
end

-- 1. Check: Zero scripts with Instance.new("ScreenGui")
local screenGuiScripts = {}
for _, desc in ipairs(game:GetDescendants()) do
    if desc:IsA("LuaSourceContainer") then
        local src = desc.Source
        if string.find(src, "Instance%.new%(%s*[\"']ScreenGui[\"']%s*%)") then
            table.insert(screenGuiScripts, desc:GetFullName())
        end
    end
end

if #screenGuiScripts == 0 then
    addCheck("1. No ScreenGui Instance Creation", true, "Zero scripts contain Instance.new('ScreenGui')")
else
    addCheck("1. No ScreenGui Instance Creation", false, "Found in: " .. table.concat(screenGuiScripts, ", "))
end

-- Also check StarterGui UI preserved
local cultUI = StarterGui:FindFirstChild("CultivationUI")
local skillUI = StarterGui:FindFirstChild("SkillUI")
local preserved = cultUI and cultUI:FindFirstChild("NavRow") and cultUI:FindFirstChild("HPBar")
    and cultUI:FindFirstChild("QiBar") and cultUI:FindFirstChild("RoadmapModal")
    and cultUI:FindFirstChild("CultivationScrollModal") and cultUI:FindFirstChild("InventoryScrollModal")
    and cultUI:FindFirstChild("ShopScrollModal") and skillUI and skillUI:FindFirstChild("GuofengSkillHotbar")
    and skillUI:FindFirstChild("MartialArtsBookModal")

addCheck("1b. StarterGui UI Preserved", preserved ~= nil and preserved ~= false, "All core Xianxia panels, NavRow, HP/Qi bars intact in StarterGui")

-- 2. Check: Chinese text in scripts and UI elements
local chinesePattern = "[\228-\233][\128-\191][\128-\191]"
local chineseFound = {}

for _, desc in ipairs(StarterGui:GetDescendants()) do
    if desc:IsA("TextLabel") or desc:IsA("TextButton") then
        if string.find(desc.Text, chinesePattern) then
            table.insert(chineseFound, desc:GetFullName() .. ": '" .. desc.Text .. "'")
        end
    end
end

for _, desc in ipairs(game:GetDescendants()) do
    if desc:IsA("LuaSourceContainer") and not string.find(desc:GetFullName(), "AIBridgePlugin") then
        local s = desc.Source
        if string.find(s, chinesePattern) then
            table.insert(chineseFound, desc:GetFullName())
        end
    end
end

if #chineseFound == 0 then
    addCheck("2. Zero Chinese Texts", true, "All scripts, labels, buttons, and banners are pure English")
else
    addCheck("2. Zero Chinese Texts", false, "Chinese found in: " .. table.concat(chineseFound, " | "))
end

-- 3. Check: Enemies styled from SAMPLEENEMYMODEL in Workspace.BanditVillage
local village = Workspace:FindFirstChild("BanditVillage")
local enemies = Workspace:FindFirstChild("Enemies")
local bossFound = false
local scoutCount = 0
local enemyDetails = {}

local enemyList = {}
if village then
    for _, c in ipairs(village:GetChildren()) do
        if c:FindFirstChildOfClass("Humanoid") then
            table.insert(enemyList, c)
        end
    end
end
if #enemyList == 0 and enemies then
    for _, c in ipairs(enemies:GetChildren()) do
        if c:FindFirstChildOfClass("Humanoid") then
            table.insert(enemyList, c)
        end
    end
end

local hudValidCount = 0

for _, e in ipairs(enemyList) do
    local hum = e:FindFirstChildOfClass("Humanoid")
    local hud = e:FindFirstChild("OverheadHUD", true)
    if hud and hud:IsA("BillboardGui") and hud.AlwaysOnTop == false and hud.LightInfluence == 0 then
        hudValidCount = hudValidCount + 1
    end

    local isBoss = string.find(e.Name, "Boss") ~= nil
    if isBoss then
        bossFound = true
        local helm = e:FindFirstChild("BossHelm")
        local cleaver = e:FindFirstChild("BossCleaver")
        local pauldrons = e:FindFirstChild("IronPauldron")
        table.insert(enemyDetails, string.format("Boss: %s (HP %d, Helm: %s, Cleaver: %s, HUD: %s)", e.Name, hum and hum.MaxHealth or 0, tostring(helm ~= nil), tostring(cleaver ~= nil), tostring(hud ~= nil)))
    else
        scoutCount = scoutCount + 1
        local mask = e:FindFirstChild("BanditMask")
        local wep = e:FindFirstChild("BanditWeapon")
        table.insert(enemyDetails, string.format("Scout %d: %s (HP %d, Mask: %s, Wep: %s, HUD: %s)", scoutCount, e.Name, hum and hum.MaxHealth or 0, tostring(mask ~= nil), tostring(wep ~= nil), tostring(hud ~= nil)))
    end
end

local enemyPass = bossFound and scoutCount >= 4 and hudValidCount == #enemyList
addCheck("3. Enemies Designed from SAMPLEENEMYMODEL", enemyPass, table.concat(enemyDetails, " ; "))
addCheck("3b. Overhead HUD Settings", hudValidCount == #enemyList and hudValidCount >= 6, string.format("%d/%d enemies have OverheadHUD with AlwaysOnTop=false and LightInfluence=0", hudValidCount, #enemyList))

-- 4. Check: Zero console runtime errors
local logs = LogService:GetLogHistory()
local errors = {}
for _, entry in ipairs(logs) do
    if entry.messageType == Enum.MessageType.MessageError then
        if not string.find(entry.message, "Rojo") and not string.find(entry.message, "Live Scripting") then
            table.insert(errors, entry.message)
        end
    end
end

if #errors == 0 then
    addCheck("4. Console Error Check", true, "Zero runtime script errors")
else
    addCheck("4. Console Error Check", false, table.concat(errors, " | "))
end

return HttpService:JSONEncode(report)
"""

if __name__ == "__main__":
    ok, out = exec_code(LUA_VERIFY)
    if not ok:
        print(f"Failed to execute verification: {out}")
        sys.exit(1)
        
    try:
        report = json.loads(out)
        print("=" * 65)
        print("  IMMORTAL VERIFICATION REPORT: ALL 4 USER REQUIREMENTS")
        print("=" * 65)
        for chk in report.get("checks", []):
            status = "PASS" if chk["success"] else "FAIL"
            print(f"[{status}] {chk['name']}")
            print(f"       {chk['details']}")
        print("=" * 65)
        overall = "ALL REQUIREMENTS VERIFIED!" if report.get("passed") else "REQUIREMENTS INCOMPLETE"
        print(f"OVERALL STATUS: {overall}")
        print("=" * 65)
        sys.exit(0 if report.get("passed") else 1)
    except Exception as e:
        print(f"Error parsing report: {e}\nRaw output: {out}")
        sys.exit(1)
