import sys
import json
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "bridge"))
from exec import exec_code

def main():
    reg_path = Path(__file__).resolve().parent.parent / "assets" / "asset_registry.json"
    with open(reg_path, "r", encoding="utf-8") as f:
        reg = json.load(f)

    resolved_textures = {}
    pending = []

    for name, data in reg.items():
        aid = data["assetId"]
        code = f"""
        local ok, o = pcall(function() return game:GetObjects("rbxassetid://{aid}") end)
        if ok and o and #o > 0 and o[1]:IsA("Decal") then
            return o[1].Texture
        else
            return "pending"
        end
        """
        ok, out = exec_code(code, timeout=6.0)
        if ok and out and out.startswith("rbxassetid://"):
            resolved_textures[name] = out
            print(f"[RESOLVED] {name} ({aid}) -> {out}")
        else:
            pending.append(name)
            resolved_textures[name] = f"rbxassetid://{aid}"
            print(f"[PENDING] {name} ({aid}) -> still propagating, using decal fallback: rbxassetid://{aid}")
        time.sleep(0.1)

    print(f"\nTotal: {len(resolved_textures)}, Resolved textures: {len(resolved_textures) - len(pending)}, Pending: {len(pending)}")

    # Update resolved_icons.json and IconAssets.luau if any resolved
    icons_json_path = Path(__file__).resolve().parent.parent / "assets" / "resolved_icons.json"
    if icons_json_path.exists():
        with open(icons_json_path, "r", encoding="utf-8") as f:
            icons_data = json.load(f)
    else:
        icons_data = {"Skills": {}, "Items": {}, "UI": {}}

    mapping = {
        "Xianxia_Sword_Slash": ("Skills", "Sword Slash"),
        "Xianxia_Flame_Ball": ("Skills", "Flame Ball"),
        "Xianxia_Palm_Art": ("Skills", "Palm Art"),
        "Xianxia_Thunder_Strike": ("Skills", "Thunder Strike"),
        "Xianxia_Multiple_Swords": ("Skills", "Multiple Swords"),
        "Xianxia_Flame_Spear": ("Skills", "Flame Spear"),
        "Xianxia_Qi_Condensation_Pill": ("Items", "Qi Condensation Pill"),
        "Xianxia_Lesser_Qi_Pill": ("Items", "Lesser Qi Pill"),
        "Xianxia_Spirit_Spring_Elixir": ("Items", "Spirit Spring Elixir"),
        "Xianxia_Iron_Sword": ("Items", "Iron Sword"),
        "Xianxia_Dragon_Spear": ("Items", "Dragon Spear"),
        "Xianxia_Mountain_Axe": ("Items", "Mountain Axe"),
        "Xianxia_Cloud_Silk_Robe": ("Items", "Cloud Silk Robe"),
        "Xianxia_Iron_Scale_Armor": ("Items", "Iron Scale Armor"),
    }

    for disp, (cat, actual_name) in mapping.items():
        if disp in resolved_textures:
            icons_data[cat][actual_name] = resolved_textures[disp]

    icons_data["UI"]["SpiritStone"] = "rbxassetid://77328888231754"

    with open(icons_json_path, "w", encoding="utf-8") as f:
        json.dump(icons_data, f, indent=2)

    # Re-generate IconAssets.luau
    from upload_all_icons import generate_luau
    luau_code = generate_luau(icons_data["Skills"], icons_data["Items"], icons_data["UI"]["SpiritStone"])
    icon_assets_path = Path(__file__).resolve().parent.parent / "src" / "shared" / "IconAssets.luau"
    with open(icon_assets_path, "w", encoding="utf-8") as f:
        f.write(luau_code)
    print("[SUCCESS] Updated IconAssets.luau with current resolved textures!")

if __name__ == "__main__":
    main()
