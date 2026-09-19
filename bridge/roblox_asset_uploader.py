"""
bridge/roblox_asset_uploader.py
Automated Open Cloud asset uploader for decals, icons, and textures directly into Roblox.
Reads API key and User ID from .env.
"""

import os
import sys
import json
import time
import argparse
from pathlib import Path

try:
    import requests
except ImportError:
    print("Error: 'requests' package not found. Run 'pip install requests'.", file=sys.stderr)
    sys.exit(1)


def load_env(env_path: Path):
    """Load key-value pairs from .env into os.environ if not already set."""
    if not env_path.exists():
        return
    with open(env_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                key, val = line.split("=", 1)
                key = key.strip()
                val = val.strip()
                if key and key not in os.environ:
                    os.environ[key] = val


def upload_asset(
    file_path: str,
    display_name: str,
    description: str = "Automated game icon upload",
    asset_type: str = "Decal",
    timeout_sec: int = 30
) -> dict:
    """
    Uploads a local image file to Roblox Open Cloud Assets API v1.
    Returns a dict with success, asset_id, rbx_url, and full response.
    """
    project_root = Path(__file__).resolve().parent.parent
    load_env(project_root / ".env")

    api_key = os.environ.get("ROBLOX_API_KEY")
    user_id = os.environ.get("ROBLOX_USER_ID")
    group_id = os.environ.get("ROBLOX_GROUP_ID")

    if not api_key:
        raise ValueError("Missing ROBLOX_API_KEY in .env or environment variables.")

    creator_context = {}
    if group_id:
        creator_context["groupId"] = str(group_id)
    elif user_id:
        creator_context["userId"] = str(user_id)
    else:
        raise ValueError("Must specify either ROBLOX_USER_ID or ROBLOX_GROUP_ID in .env.")

    file_p = Path(file_path).resolve()
    if not file_p.exists():
        raise FileNotFoundError(f"File not found: {file_p}")

    ext = file_p.suffix.lower()
    mime_types = {
        ".png": "image/png",
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".bmp": "image/bmp",
        ".tga": "image/tga",
    }
    content_type = mime_types.get(ext, "image/png")

    metadata = {
        "assetType": asset_type,
        "displayName": display_name[:50],  # Max 50 chars
        "description": description[:500],  # Max 500 chars
        "creationContext": {
            "creator": creator_context
        }
    }

    with open(file_p, "rb") as f:
        file_bytes = f.read()

    files = {
        "request": (None, json.dumps(metadata), "application/json"),
        "fileContent": (file_p.name, file_bytes, content_type)
    }

    headers = {
        "x-api-key": api_key
    }

    print(f"[OpenCloud] Uploading {file_p.name} as '{display_name}' ({asset_type})...")
    resp = requests.post(
        "https://apis.roblox.com/assets/v1/assets",
        headers=headers,
        files=files,
        timeout=15
    )

    if resp.status_code != 200:
        raise RuntimeError(f"Upload failed with status {resp.status_code}: {resp.text}")

    data = resp.json()
    operation_path = data.get("path")
    if not operation_path:
        raise RuntimeError(f"Unexpected response: {data}")

    # Check if already done
    if data.get("done") and "response" in data:
        asset_id = data["response"].get("assetId")
        rbx_url = f"rbxassetid://{asset_id}"
        print(f"[OpenCloud] Uploaded immediately! Asset ID: {asset_id} ({rbx_url})")
        return {"success": True, "asset_id": asset_id, "rbx_url": rbx_url, "details": data["response"]}

    # Poll operation status
    op_url = f"https://apis.roblox.com/assets/v1/{operation_path}"
    start_time = time.time()
    print(f"[OpenCloud] Polling operation: {operation_path}...")

    while time.time() - start_time < timeout_sec:
        time.sleep(1.0)
        op_resp = requests.get(op_url, headers=headers, timeout=10)
        if op_resp.status_code != 200:
            print(f"[OpenCloud] Polling warning ({op_resp.status_code}): {op_resp.text}")
            continue

        op_data = op_resp.json()
        if op_data.get("done"):
            if "error" in op_data:
                raise RuntimeError(f"Operation failed: {op_data['error']}")
            
            asset_info = op_data.get("response", {})
            asset_id = asset_info.get("assetId")
            rbx_url = f"rbxassetid://{asset_id}"
            moderation = asset_info.get("moderationResult", {}).get("moderationState", "Unknown")
            print(f"[OpenCloud] Success! Asset ID: {asset_id} ({rbx_url}) | Moderation: {moderation}")

            # Update registry
            registry_file = project_root / "assets" / "asset_registry.json"
            registry_file.parent.mkdir(parents=True, exist_ok=True)
            registry = {}
            if registry_file.exists():
                try:
                    with open(registry_file, "r", encoding="utf-8") as rf:
                        registry = json.load(rf)
                except Exception:
                    registry = {}

            registry[display_name] = {
                "assetId": asset_id,
                "rbxUrl": rbx_url,
                "localPath": str(file_p),
                "assetType": asset_type,
                "moderation": moderation,
                "uploadedAt": time.strftime("%Y-%m-%d %H:%M:%S")
            }

            with open(registry_file, "w", encoding="utf-8") as rf:
                json.dump(registry, rf, indent=2)

            return {
                "success": True,
                "asset_id": asset_id,
                "rbx_url": rbx_url,
                "details": asset_info
            }

    raise TimeoutError(f"Upload operation timed out after {timeout_sec} seconds.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Upload asset to Roblox Open Cloud.")
    parser.add_argument("--file", required=True, help="Path to the image/asset file.")
    parser.add_argument("--name", required=True, help="Display name for the asset in Roblox.")
    parser.add_argument("--desc", default="Game icon", help="Description for the asset.")
    parser.add_argument("--type", default="Decal", help="Asset type (Decal, Model, Audio).")

    args = parser.parse_args()
    try:
        res = upload_asset(args.file, args.name, args.desc, args.type)
        print(f"RESULT_ASSET_ID={res['asset_id']}")
        print(f"RESULT_RBX_URL={res['rbx_url']}")
    except Exception as err:
        print(f"ERROR: {err}", file=sys.stderr)
        sys.exit(1)
