"""
bridge/upload_all_icons.py
Uploads all remaining generated Xianxia icons to Roblox via Open Cloud,
resolves their live image texture IDs using Roblox Studio bridge,
and updates src/shared/IconAssets.luau.
"""

import os
import sys
import json
import time
from pathlib import Path

# Add bridge dir to sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent))
from roblox_asset_uploader import upload_asset
from exec import exec_code

ICONS_DIR = Path(__file__).resolve().parent.parent / "assets" / "icons"
REGISTRY_FILE = Path(__file__).resolve().parent.parent / "assets" / "asset_registry.json"

ICON_DEFS = [
    # Skills
    {"name": "Sword Slash", "display": "Xianxia_Sword_Slash", "file": "icon_sword_slash_1789806428893.jpg", "category": "Skills"},
    {"name": "Flame Ball", "display": "Xianxia_Flame_Ball", "file": "icon_flame_ball_1789806441112.jpg", "category": "Skills"},
    {"name": "Palm Art", "display": "Xianxia_Palm_Art", "file": "icon_palm_art_1789806453847.jpg", "category": "Skills"},
    {"name": "Thunder Strike", "display": "Xianxia_Thunder_Strike", "file": "icon_thunder_strike_1789806466519.jpg", "category": "Skills"},
    {"name": "Multiple Swords", "display": "Xianxia_Multiple_Swords", "file": "icon_multiple_swords_1789806495300.jpg", "category": "Skills"},
    {"name": "Flame Spear", "display": "Xianxia_Flame_Spear", "file": "icon_flame_spear_1789806509375.jpg", "category": "Skills"},
    # Items
    {"name": "Qi Condensation Pill", "display": "Xianxia_Qi_Condensation_Pill", "file": "icon_condensation_pill_1789806584245.jpg", "category": "Items"},
    {"name": "Lesser Qi Pill", "display": "Xianxia_Lesser_Qi_Pill", "file": "icon_qi_pill_1789806572601.jpg", "category": "Items"},
    {"name": "Spirit Spring Elixir", "display": "Xianxia_Spirit_Spring_Elixir", "file": "icon_elixir_1789806634391.jpg", "category": "Items"},
    {"name": "Iron Sword", "display": "Xianxia_Iron_Sword", "file": "icon_iron_sword_1789806659172.jpg", "category": "Items"},
    {"name": "Dragon Spear", "display": "Xianxia_Dragon_Spear", "file": "icon_dragon_spear_1789806671813.jpg", "category": "Items"},
    {"name": "Mountain Axe", "display": "Xianxia_Mountain_Axe", "file": "icon_mountain_axe_1789806707361.jpg", "category": "Items"},
    {"name": "Cloud Silk Robe", "display": "Xianxia_Cloud_Silk_Robe", "file": "icon_cloud_robe_1789807358279.jpg", "category": "Items"},
    {"name": "Iron Scale Armor", "display": "Xianxia_Iron_Scale_Armor", "file": "icon_iron_armor_1789807374478.jpg", "category": "Items"},
]

def load_registry():
    if REGISTRY_FILE.exists():
        try:
            with open(REGISTRY_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return {}
    return {}

def resolve_texture(decal_id: str) -> str:
    code = f"""
    local ok, objs = pcall(function() return game:GetObjects("rbxassetid://{decal_id}") end)
    if ok and objs and #objs > 0 and objs[1]:IsA("Decal") then
        return objs[1].Texture
    else
        return "rbxassetid://{decal_id}"
    end
    """
    ok, out = exec_code(code, timeout=8.0)
    if ok and out and out.startswith("rbxassetid://"):
        return out
    return f"rbxassetid://{decal_id}"

def main():
    registry = load_registry()
    resolved_skills = {}
    resolved_items = {}

    print(f"Starting upload and resolution for {len(ICON_DEFS)} icons...\n")

    for item in ICON_DEFS:
        name = item["name"]
        display = item["display"]
        file_path = ICONS_DIR / item["file"]
        cat = item["category"]

        if not file_path.exists():
            print(f"[ERROR] File not found: {file_path}")
            continue

        # Check if already uploaded
        asset_id = None
        if display in registry and "assetId" in registry[display]:
            asset_id = registry[display]["assetId"]
            print(f"[CACHE] {name} already uploaded: Asset ID {asset_id}")
        else:
            print(f"[UPLOAD] Uploading {name} ({file_path.name})...")
            try:
                res = upload_asset(str(file_path), display, f"{name} icon for Xianxia RPG", "Decal")
                asset_id = res["asset_id"]
                registry = load_registry()  # Reload after upload
            except Exception as e:
                print(f"[ERROR] Upload failed for {name}: {e}")
                continue
            time.sleep(1.0)

        # Resolve texture ID
        print(f"[RESOLVE] Resolving texture for {name} (Decal: {asset_id})...")
        texture_url = resolve_texture(asset_id)
        print(f"  -> {name}: {texture_url}\n")

        if cat == "Skills":
            resolved_skills[name] = texture_url
        else:
            resolved_items[name] = texture_url

    # Also include GoldCoin / SpiritStone
    gold_coin_texture = "rbxassetid://77328888231754"

    # Save to JSON
    out_json = {
        "Skills": resolved_skills,
        "Items": resolved_items,
        "UI": {"SpiritStone": gold_coin_texture}
    }
    with open(Path(__file__).resolve().parent.parent / "assets" / "resolved_icons.json", "w", encoding="utf-8") as f:
        json.dump(out_json, f, indent=2)
    print("Saved assets/resolved_icons.json")

    # Generate Luau file
    luau_code = generate_luau(resolved_skills, resolved_items, gold_coin_texture)
    icon_assets_path = Path(__file__).resolve().parent.parent / "src" / "shared" / "IconAssets.luau"
    with open(icon_assets_path, "w", encoding="utf-8") as f:
        f.write(luau_code)
    print("Updated src/shared/IconAssets.luau")

def generate_luau(skills: dict, items: dict, gold_coin: str) -> str:
    lines = [
        "--!strict",
        "-- src/shared/IconAssets.luau",
        "-- Centralized Icon Asset ID Registry for Xianxia RPG",
        "-- Auto-generated by bridge/upload_all_icons.py with live resolved Roblox texture IDs",
        "",
        "local IconAssets = {}",
        "",
        "-- ============================================================================",
        "-- SKILL ICONS (Used in hotbar slots and technique book)",
        "-- ============================================================================",
        "IconAssets.Skills = {"
    ]
    for k, v in skills.items():
        lines.append(f'\t["{k}"] = "{v}",')
    lines.extend([
        "}",
        "",
        "-- ============================================================================",
        "-- ITEM ICONS (Used in shop and inventory)",
        "-- ============================================================================",
        "IconAssets.Items = {"
    ])
    for k, v in items.items():
        lines.append(f'\t["{k}"] = "{v}",')
    lines.extend([
        "}",
        "",
        "-- ============================================================================",
        "-- UI ICONS (Used in HUD and labels)",
        "-- ============================================================================",
        "IconAssets.UI = {",
        f'\tSpiritStone = "{gold_coin}",',
        "}",
        "",
        "function IconAssets.getSkillIcon(skillName: string): string",
        '\treturn IconAssets.Skills[skillName] or "rbxassetid://0"',
        "end",
        "",
        "function IconAssets.getItemIcon(itemName: string): string",
        '\treturn IconAssets.Items[itemName] or "rbxassetid://0"',
        "end",
        "",
        "--- Returns true if the asset ID is a real uploaded asset (not the 0 placeholder)",
        "function IconAssets.isUploaded(assetId: string): boolean",
        '\treturn assetId ~= nil and assetId ~= "rbxassetid://0" and assetId ~= ""',
        "end",
        "",
        "return IconAssets",
        ""
    ])
    return "\n".join(lines)

if __name__ == "__main__":
    main()
