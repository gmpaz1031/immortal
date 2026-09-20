import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def test_full_script():
    lua = """
    local Players = game:GetService("Players")
    local StarterGui = game:GetService("StarterGui")
    local ui = StarterGui:FindFirstChild("CultivationUI")
    if not ui then return "CultivationUI missing" end

    local clientScript = ui:FindFirstChild("CultivationClient")
    if not clientScript then return "CultivationClient missing" end

    -- Check if script compiles
    local fn, err = loadstring(clientScript.Source)
    if not fn then
        return "SYNTAX ERROR: " .. tostring(err)
    end

    -- Create a fake player context environment to test execution
    local env = getfenv(fn)
    
    return "Script compiles cleanly without syntax errors (Length: " .. tostring(#clientScript.Source) .. " chars)"
    """
    ok, res = exec_code(lua)
    print("Compile test:", ok, res)

if __name__ == '__main__':
    test_full_script()
