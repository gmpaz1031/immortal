import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

verify_script = """
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local SG = game:GetService("StarterGui")

local report = {}

local dConfig = RS.Shared:FindFirstChild("DestinyConfig")
table.insert(report, "1. DestinyConfig: " .. (dConfig and "PRESENT" or "MISSING"))

local dataScript = SSS.Server:FindFirstChild("DATA")
local dataOk = dataScript and loadstring(dataScript.Source) ~= nil
table.insert(report, "2. Server.DATA: " .. (dataScript and "PRESENT" or "MISSING") .. " (Compiles: " .. tostring(dataOk) .. ")")

local mainScript = SSS.Server:FindFirstChild("MAINSERVER")
local mainOk = mainScript and loadstring(mainScript.Source) ~= nil
local hasSpinWheel = mainScript and (mainScript.Source:find("SpinWheel") ~= nil)
local hasAutoReplenish = mainScript and (mainScript.Source:find("goldVal.Value %+ 1000") ~= nil)
table.insert(report, string.format("3. Server.MAINSERVER: %s (Compiles: %s, SpinWheel: %s, StudioReplenish: %s)", 
    mainScript and "PRESENT" or "MISSING", tostring(mainOk), tostring(hasSpinWheel), tostring(hasAutoReplenish)))

local cultUI = SG:FindFirstChild("CultivationUI")
local clientScript = cultUI and cultUI:FindFirstChild("CultivationClient")
local clientOk = clientScript and loadstring(clientScript.Source) ~= nil
local hasRunService = clientScript and (clientScript.Source:find("RunService") ~= nil)
local has4sSpin = clientScript and (clientScript.Source:find("4.0") ~= nil)
table.insert(report, string.format("4. CultivationClient: %s (Compiles: %s, RunService defined: %s, 4s Tween: %s)",
    clientScript and "PRESENT" or "MISSING", tostring(clientOk), tostring(hasRunService), tostring(has4sSpin)))

local cultModal = cultUI and cultUI:FindFirstChild("CultivationScrollModal")
local destinyBtn = cultModal and cultModal:FindFirstChild("DestinyWheelBtn")
table.insert(report, "5. DestinyWheelBtn: " .. (destinyBtn and "PRESENT" or "MISSING"))

local wheelModal = cultUI and cultUI:FindFirstChild("DestinyWheelModal")
table.insert(report, "6. DestinyWheelModal: " .. (wheelModal and "PRESENT" or "MISSING"))

if wheelModal then
    local disc = wheelModal:FindFirstChild("WheelDisc", true)
    local pointer = wheelModal:FindFirstChild("Pointer", true)
    local spinBtn = wheelModal:FindFirstChild("SpinActionBtn", true)
    local winnerOverlay = wheelModal:FindFirstChild("WinnerOverlay", true)
    local dismissBtn = winnerOverlay and winnerOverlay:FindFirstChild("DismissBtn", true)
    table.insert(report, string.format("   - WheelDisc: %s, Pointer: %s, SpinActionBtn: %s", disc and "OK" or "MISSING", pointer and "OK" or "MISSING", spinBtn and "OK" or "MISSING"))
    table.insert(report, string.format("   - WinnerOverlay: %s, DismissBtn: %s", winnerOverlay and "OK" or "MISSING", dismissBtn and "OK" or "MISSING"))
end

return table.concat(report, "\\n")
"""

ok, res = exec_code(verify_script)
print("Execution success:", ok)
print(res)
