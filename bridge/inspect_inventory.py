import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def inspect():
    lua = """
    local ui = game:GetService("StarterGui"):FindFirstChild("CultivationUI")
    if not ui then return "No CultivationUI" end
    local inv = ui:FindFirstChild("InventoryScrollModal")
    if not inv then return "No InventoryScrollModal" end
    local lines = { inv.Name .. " - Size: " .. tostring(inv.Size) }
    for _, c in ipairs(inv:GetChildren()) do
        table.insert(lines, "  " .. c.Name .. " [" .. c.ClassName .. "]")
    end
    return table.concat(lines, "\\n")
    """
    ok, res = exec_code(lua)
    print("Result:\n" + str(res))

if __name__ == '__main__':
    inspect()
