import sys
import os
import json
import urllib.request
from pathlib import Path

PORT = 34875
BASE_URL = f"http://127.0.0.1:{PORT}"

def exec_code(code: str, timeout: float = 15.0):
    url = f"{BASE_URL}/exec"
    payload = json.dumps({"code": code}).encode("utf-8")
    req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode("utf-8"))
        cmd_id = data.get("id")
    
    import time
    start_time = time.time()
    while time.time() - start_time < timeout:
        res_url = f"{BASE_URL}/result?id={cmd_id}"
        try:
            with urllib.request.urlopen(res_url) as resp:
                res_data = json.loads(resp.read().decode("utf-8"))
                return res_data.get("success", False), res_data.get("output") or res_data.get("error")
        except urllib.error.HTTPError as e:
            if e.code == 404:
                time.sleep(0.1)
                continue
            return False, f"HTTP Error {e.code}"
        except Exception:
            time.sleep(0.1)
            continue
    return False, "Timeout"

scripts_to_pull = [
    ("StarterGui.CultivationUI.CultivationClient", "src/gui/CultivationClient_Studio.client.luau"),
    ("ServerScriptService.Server.MAINSERVER", "src/server/MAINSERVER_Studio.server.luau"),
    ("ReplicatedStorage.Shared.CultivationConfig", "src/shared/CultivationConfig.luau"),
    ("ReplicatedStorage.Shared.ItemConfig", "src/shared/ItemConfig.luau"),
]

for inst_path, local_rel in scripts_to_pull:
    lua = f"""
    local inst = game
    for _, part in ipairs(string.split('{inst_path}', '.')) do
        inst = inst:FindFirstChild(part)
        if not inst then return 'NOT_FOUND' end
    end
    if inst:IsA('LuaSourceContainer') then
        return inst.Source
    end
    return 'NOT_SCRIPT'
    """
    ok, src = exec_code(lua)
    if ok and src not in ('NOT_FOUND', 'NOT_SCRIPT'):
        dest = Path(local_rel)
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(src, encoding='utf-8')
        print(f"Successfully pulled {inst_path} -> {local_rel} ({len(src)} bytes)")
    else:
        print(f"Failed to pull {inst_path}: {src}")
