import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def sanitize_ui():
    print("=== Sanitizing All Non-ASCII Glyphs in CultivationUI ===")

    lua = """
    local StarterGui = game:GetService("StarterGui")
    local ui = StarterGui:FindFirstChild("CultivationUI")
    if not ui then return "CultivationUI missing" end

    local count = 0
    for _, desc in ipairs(ui:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextButton") then
            local text = desc.Text
            if text and text ~= "" then
                -- Replace specific unicode glyphs
                local cleaned = text
                cleaned = string.gsub(cleaned, "\\226\\156\\166", "") -- ✦
                cleaned = string.gsub(cleaned, "\\226\\156\\149", "X") -- ✕
                cleaned = string.gsub(cleaned, "\\226\\128\\148", "-") -- —
                cleaned = string.gsub(cleaned, "\\226\\128\\162", "·") -- •
                cleaned = string.gsub(cleaned, "\\226\\151\\134", "*") -- ◈
                cleaned = string.gsub(cleaned, "\\226\\151\\135", "*") -- ◇
                cleaned = string.gsub(cleaned, "[%z\\1-\\31\\128-\\255]", "") -- strip any remaining non-ascii except newline

                -- Trim extra whitespace
                cleaned = string.gsub(cleaned, "^%s+", "")
                cleaned = string.gsub(cleaned, "%s+$", "")

                if cleaned ~= text then
                    desc.Text = cleaned
                    count = count + 1
                end
            end
        end
    end

    -- Explicitly format Cultivation title and close button
    local cultModal = ui:FindFirstChild("CultivationScrollModal")
    if cultModal then
        local header = cultModal:FindFirstChild("HeaderBanner")
        if header then
            for _, child in ipairs(header:GetChildren()) do
                if child:IsA("TextLabel") and string.find(child.Text, "XIANXIA") then
                    child.Text = "XIANXIA RPG - CULTIVATION & TECHNIQUES"
                elseif child:IsA("TextLabel") and string.find(child.Text, "PROGRESSION") then
                    child.Text = "PROGRESSION PATHWAY - ACTIVE MEDITATION FOCUS"
                end
            end
        end
        local closeBtn = cultModal:FindFirstChild("CloseBtn", true)
        if closeBtn then
            closeBtn.Text = "X"
            closeBtn.TextSize = 14
        end
    end

    return "Cleaned " .. count .. " UI text elements to pure clean ASCII."
    """

    ok, res = exec_code(lua)
    print("Sanitize result:", ok, res)

if __name__ == '__main__':
    sanitize_ui()
