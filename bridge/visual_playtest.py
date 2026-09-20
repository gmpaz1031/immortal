"""
bridge/visual_playtest.py
==========================
AI-Driven Visual & Logic Playtest Suite for Immortal RPG.

Combines:
  - Native in-engine screenshot capture (Roblox Studio CaptureService + EditableImage)
  - Bridge DataModel execution (Luau code inside Studio)
  - Zero mouse/keyboard interference, zero focus stealing, 100% background

Usage:
    python bridge/visual_playtest.py
"""

import sys
import json
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from capture import capture, is_studio_connected
from exec import exec_code
from ai_actor import set_ai_testing_mode, move_cursor_and_click

REPORT_DIR = Path(__file__).resolve().parent.parent / "assets" / "screenshots"
REPORT_DIR.mkdir(parents=True, exist_ok=True)


def run_visual_captures() -> list:
    print("\n[Visual] Capturing in-engine screenshots...")
    captures = []
    for reg, label in [("full", "Full Viewport"), ("hotbar", "Skill Hotbar"), ("hud", "Cultivation HUD")]:
        print(f"  Capturing {label} ({reg})...")
        try:
            path = capture(region=reg, label=reg)
            print(f"  -> Saved: {path.name}")
            captures.append({"region": reg, "label": label, "path": str(path), "success": True})
        except Exception as e:
            print(f"  -> FAILED: {e}")
            captures.append({"region": reg, "label": label, "success": False, "error": str(e)})
        time.sleep(0.3)
    return captures


def run_logic_checks() -> dict:
    print("\n[Logic] Running programmatic Studio checks...")
    code = """
    local sg = game:GetService("StarterGui")
    local rs = game:GetService("ReplicatedStorage")
    local ws = game:GetService("Workspace")
    local logService = game:GetService("LogService")
    local checks = {}

    -- Check SkillUI & Hotbar
    local skillUI = sg:FindFirstChild("SkillUI")
    table.insert(checks, "SkillUI exists: " .. tostring(skillUI ~= nil))

    local hotbar = skillUI and skillUI:FindFirstChild("GuofengSkillHotbar")
    for i = 1, 4 do
        local slot = hotbar and hotbar:FindFirstChild("SkillSlot_" .. i)
        local img = slot and slot:FindFirstChild("IconImage")
        local hasImg = img and img.Image ~= "" and img.Image ~= "rbxassetid://0"
        local assetId = img and img.Image or "none"
        table.insert(checks, "Slot " .. i .. " Icon: " .. assetId)
    end

    -- Check CultivationUI
    local cultUI = sg:FindFirstChild("CultivationUI")
    table.insert(checks, "CultivationUI exists: " .. tostring(cultUI ~= nil))

    -- Check Enemies in Workspace
    local village = ws:FindFirstChild("BanditVillage") or ws:FindFirstChild("Enemies")
    local enemyCount = 0
    if village then
        for _, c in ipairs(village:GetChildren()) do
            if c:FindFirstChildOfClass("Humanoid") then
                enemyCount = enemyCount + 1
            end
        end
    end
    table.insert(checks, "Active Enemies Count: " .. tostring(enemyCount))

    -- Check Console Errors
    local logs = logService:GetLogHistory()
    local errors = 0
    for _, l in ipairs(logs) do
        if l.messageType == Enum.MessageType.MessageError then
            if not string.find(l.message, "Rojo") and not string.find(l.message, "Live Scripting") then
                errors = errors + 1
            end
        end
    end
    table.insert(checks, "Console Script Errors: " .. tostring(errors))

    return table.concat(checks, string.char(10))
    """
    ok, out = exec_code(code)
    results = {}
    if ok and out:
        for line in out.strip().splitlines():
            if ": " in line:
                k, v = line.split(": ", 1)
                results[k.strip()] = v.strip()
    return results


def main():
    print("=" * 60)
    print("  IMMORTAL RPG - BACKGROUND PLAYTEST & VISUAL SUITE")
    print("=" * 60)

    if not is_studio_connected():
        print("[ERROR] Roblox Studio is not connected to the bridge!")
        print("  Ensure Roblox Studio is open with AIBridgePlugin active.")
        sys.exit(1)

    print("[OK] Roblox Studio is connected via Live Bridge.")
    print("[AI] Activating AI Testing Mode (Red Border, Input Lockout, Virtual Cursor)...")
    set_ai_testing_mode(True)
    time.sleep(0.4)

    try:
        report = {
            "timestamp": int(time.time()),
            "visual_captures": run_visual_captures(),
            "logic_checks": run_logic_checks()
        }
    finally:
        print("[AI] Deactivating AI Testing Mode...")
        set_ai_testing_mode(False)

    report_path = REPORT_DIR / f"report_{report['timestamp']}.json"
    with open(report_path, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)

    print("\n" + "=" * 60)
    print("  PLAYTEST REPORT SUMMARY")
    print("=" * 60)
    for k, v in report["logic_checks"].items():
        print(f"  * {k}: {v}")

    print("\nVisual Captures:")
    for cap in report["visual_captures"]:
        status = "SAVED" if cap["success"] else "FAILED"
        print(f"  [{status}] {cap['label']} -> {cap.get('path', cap.get('error'))}")
    print("=" * 60)


if __name__ == "__main__":
    main()
