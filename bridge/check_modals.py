import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def check():
    lua = """
    local StarterGui = game:GetService("StarterGui")
    local ui = StarterGui:FindFirstChild("CultivationUI")
    if not ui then return "No CultivationUI" end

    local invModal = ui:FindFirstChild("InventoryScrollModal")
    local cultModal = ui:FindFirstChild("CultivationScrollModal")

    local report = {}
    table.insert(report, "invModal exists: " .. tostring(invModal ~= nil))
    if invModal then
        table.insert(report, "invModal Visible: " .. tostring(invModal.Visible))
        table.insert(report, "invModal Children:")
        for _, c in ipairs(invModal:GetChildren()) do
            table.insert(report, "  " .. c.Name .. " (" .. c.ClassName .. ")")
        end
    end

    table.insert(report, "cultModal exists: " .. tostring(cultModal ~= nil))
    if cultModal then
        table.insert(report, "cultModal Visible: " .. tostring(cultModal.Visible))
        table.insert(report, "cultModal Children:")
        for _, c in ipairs(cultModal:GetChildren()) do
            table.insert(report, "  " .. c.Name .. " (" .. c.ClassName .. ")")
        end
    end

    -- Check Nav Buttons
    local hud = ui:FindFirstChild("GuofengHUD")
    if hud then
        local navRow = hud:FindFirstChild("NavRow")
        if navRow then
            table.insert(report, "NavRow Buttons:")
            for _, b in ipairs(navRow:GetChildren()) do
                table.insert(report, "  " .. b.Name .. " (" .. b.ClassName .. ")")
            end
        else
            table.insert(report, "NavRow missing")
        end
    else
        table.insert(report, "GuofengHUD missing")
    end

    return table.concat(report, "\\n")
    """
    ok, res = exec_code(lua)
    print("Check Output:\n" + str(res))

if __name__ == '__main__':
    check()
