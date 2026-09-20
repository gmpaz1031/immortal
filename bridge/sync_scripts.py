"""
bridge/sync_scripts.py
Pushes local scripts from src/ directly into Roblox Studio DataModel safely using 100-byte arrays.
"""

import json
import urllib.request
import time
from pathlib import Path

PORT = 34875

def exec_code(code: str, timeout: float = 15.0):
    url = f"http://127.0.0.1:{PORT}/exec"
    payload = json.dumps({"code": code}).encode("utf-8")
    req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode("utf-8"))
        cmd_id = data.get("id")
        
    start = time.time()
    while time.time() - start < timeout:
        try:
            with urllib.request.urlopen(f"http://127.0.0.1:{PORT}/result?id={cmd_id}") as r:
                res = json.loads(r.read().decode("utf-8"))
                return res.get("success"), res.get("output") or res.get("error")
        except Exception:
            time.sleep(0.2)
    return False, "Timeout"

def push_script(service_name: str, path_parts: list, file_path: Path):
    source_bytes = file_path.read_bytes()
    # Chunk into 100-byte segments to stay well below the 255 Lua register limit
    chunks = [source_bytes[i:i + 100] for i in range(0, len(source_bytes), 100)]
    lua_chunks = ["string.char(" + ", ".join(str(b) for b in chunk) + ")" for chunk in chunks]
    source_expr = "table.concat({" + ", ".join(lua_chunks) + "})"
    
    folder_names = "{" + ", ".join(f'"{p}"' for p in path_parts[:-1]) + "}"
    script_name = path_parts[-1]
    is_local = ".client." in file_path.name
    is_module = file_path.name.endswith(".luau") and not (".server." in file_path.name or ".client." in file_path.name)
    
    lua_code = f"""
    local service = game:GetService({json.dumps(service_name)})
    local cur = service
    local path = {folder_names}
    for _, name in ipairs(path) do
        local child = cur:FindFirstChild(name)
        if not child then
            child = Instance.new("Folder")
            child.Name = name
            child.Parent = cur
        end
        cur = child
    end
    local scriptName = {json.dumps(script_name)}
    local scr = cur:FindFirstChild(scriptName)
    local isLocal = {str(is_local).lower()}
    local isModule = {str(is_module).lower()}
    
    local targetClass = if isModule then "ModuleScript" elseif isLocal then "LocalScript" else "Script"
    if scr and not scr:IsA(targetClass) then
        scr:Destroy()
        scr = nil
    end
    if not scr then
        scr = Instance.new(targetClass)
        scr.Name = scriptName
        scr.Parent = cur
    end
    scr.Source = {source_expr}
    return "Updated " .. scr:GetFullName()
    """
    ok, res = exec_code(lua_code)
    print(f"[{'OK' if ok else 'FAIL'}] {file_path.name} -> {res}")

if __name__ == "__main__":
    root = Path(__file__).resolve().parent.parent
    
    # Push server scripts
    for f in (root / "src" / "server").glob("*.luau"):
        name = f.name.replace(".server.luau", "").replace(".luau", "")
        push_script("ServerScriptService", ["Server", name], f)
        
    # Push shared scripts
    for f in (root / "src" / "shared").glob("*.luau"):
        name = f.name.replace(".luau", "")
        push_script("ReplicatedStorage", ["Shared", name], f)
        
    # Push gui scripts
    for f in (root / "src" / "gui").rglob("*.luau"):
        if "CultivationUI" in str(f):
            push_script("StarterGui", ["CultivationUI", "CultivationClient"], f)
        elif "SkillUI" in str(f):
            push_script("StarterGui", ["SkillUI", "SkillClient"], f)

    # Push client scripts
    for f in (root / "src" / "client").glob("*.luau"):
        name = f.name.replace(".client.luau", "").replace(".luau", "")
        push_script("StarterPlayer", ["StarterPlayerScripts", name], f)

    print("All scripts synced to Studio successfully.")
