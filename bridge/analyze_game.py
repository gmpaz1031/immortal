import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

cult_path = Path("src/gui/CultivationUI/CultivationClient.client.luau")
with open(cult_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "SHOP_CATALOG" in line:
        print("".join(lines[i:i+60]))
        break

skill_path = Path("src/gui/SkillUI/SkillClient.client.luau")
with open(skill_path, "r", encoding="utf-8") as f:
    s_lines = f.readlines()

print("\n--- SkillClient line count:", len(s_lines))
for i, line in enumerate(s_lines[:150]):
    if any(k in line for k in ["SKILL", "Skill", "Config", "Data", "remote"]):
        print(f"L{i+1}: {line.strip()}")
