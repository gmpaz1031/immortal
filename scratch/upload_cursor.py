"""
scratch/upload_cursor.py
Uploads ai_cursor.png to Roblox Open Cloud and resolves the live texture ID.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "bridge"))
from roblox_asset_uploader import upload_asset
from exec import exec_code

cursor_file = Path("assets/icons/ai_cursor.png")
print("Uploading cursor asset to Roblox...")
res = upload_asset(str(cursor_file), "Immortal_AICursor_v1", "Custom UI pointer cursor for Immortal AI playtesting")

if not res:
    print("[ERROR] Failed to upload cursor")
    sys.exit(1)

decal_id = res["asset_id"]
print(f"Uploaded Decal ID: {decal_id}")

# Resolve Decal -> Image Texture ID
code = f"""
local ok, objs = pcall(function() return game:GetObjects("rbxassetid://{decal_id}") end)
if ok and objs and #objs > 0 and objs[1]:IsA("Decal") then
    return objs[1].Texture
else
    return "rbxassetid://{decal_id}"
end
"""
ok, out = exec_code(code, timeout=10.0)
resolved_id = out if (ok and out and out.startswith("rbxassetid://")) else f"rbxassetid://{decal_id}"
print(f"Resolved Texture ID: {resolved_id}")

# Save to scratch/cursor_id.txt
with open("scratch/cursor_id.txt", "w", encoding="utf-8") as f:
    f.write(resolved_id)
