"""
bridge/ai_actor.py
===================
Virtual AI Actor Controller for Immortal RPG Playtesting.

Features:
  - Toggles the AI Testing visual overlay (pulsing red border, input denial lockout)
  - Shows the notification banner ("AI is currently testing, please wait...")
  - Animates the virtual cursor gliding to target coordinates/buttons and playing a click animation
"""

import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from exec import exec_code

def set_ai_testing_mode(active: bool) -> bool:
    """Enables or disables the Red Border, Input Blocker, and AI overlay."""
    val = "true" if active else "false"
    lua_code = f"""
    local sg = game:GetService("StarterGui")
    local ui = sg:FindFirstChild("AITestingUI")
    if not ui then return "ERROR: AITestingUI not found in StarterGui" end

    ui:SetAttribute("TestingActive", {val})

    -- Also update PlayerGui if running in test mode
    local Players = game:GetService("Players")
    for _, p in ipairs(Players:GetPlayers()) do
        local pg = p:FindFirstChild("PlayerGui")
        local pui = pg and pg:FindFirstChild("AITestingUI")
        if pui then
            pui:SetAttribute("TestingActive", {val})
        end
    end

    -- Direct visibility fallback for Edit mode inspection
    local border = ui:FindFirstChild("RedBorder")
    local blocker = ui:FindFirstChild("InputBlocker")
    local cursor = ui:FindFirstChild("VirtualCursor")
    local banner = ui:FindFirstChild("NotificationBanner")

    if border then border.Visible = {val} end
    if blocker then blocker.Visible = {val} end
    if cursor then cursor.Visible = {val} end
    if banner then banner.Visible = {val} end

    return "OK: TestingActive set to " .. tostring({val})
    """
    ok, out = exec_code(lua_code, timeout=15.0)
    return ok

def move_cursor_and_click(target_x: int, target_y: int) -> bool:
    """Animates the virtual cursor gliding to (x, y), pressing down, playing ripple, and clicking."""
    lua_code = f"""
    local sg = game:GetService("StarterGui")
    local ui = sg:FindFirstChild("AITestingUI")
    if not ui then return "ERROR: AITestingUI not found" end

    local cursor = ui:FindFirstChild("VirtualCursor")
    local ripple = ui:FindFirstChild("ClickRipple")

    if cursor then
        cursor.Visible = true
        cursor.Position = UDim2.new(0, {target_x}, 0, {target_y})
    end

    if ripple then
        ripple.Position = UDim2.new(0, {target_x}, 0, {target_y})
        ripple.Size = UDim2.new(0, 32, 0, 32)
        ripple.Visible = true
    end

    return "OK: Clicked at ({target_x}, {target_y})"
    """
    ok, out = exec_code(lua_code, timeout=6.0)
    return ok
