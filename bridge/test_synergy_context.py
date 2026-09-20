import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

code = """
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local CultivationConfig = loadstring(Shared:WaitForChild("CultivationConfig").Source)()
local ItemConfig = loadstring(Shared:WaitForChild("ItemConfig").Source)()

local fireItem = ItemConfig.getItem("Fire Scripture")
local out = {}
table.insert(out, "type(CultivationConfig): " .. type(CultivationConfig))
table.insert(out, "type(isManualSynergy): " .. type(CultivationConfig.isManualSynergy))
table.insert(out, "fireItem is nil: " .. tostring(fireItem == nil))
if fireItem then
    table.insert(out, "fireItem.Element: " .. tostring(fireItem.Element))
end

local ok, res = pcall(function()
    return CultivationConfig.isManualSynergy(fireItem and fireItem.Element, "Fire Root")
end)
table.insert(out, "call ok: " .. tostring(ok) .. ", res: " .. tostring(res))

return table.concat(out, "\\n")
"""

ok, res = exec_code(code)
print(res)
