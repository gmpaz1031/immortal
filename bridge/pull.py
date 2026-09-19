"""
bridge/pull.py
Synchronizes and extracts the entire instance tree and scripts from the connected
Roblox Studio place into local files, formatted according to Rojo conventions.
"""

import os
import sys
import json
import time
import urllib.request
from pathlib import Path

PORT = 34875
BASE_URL = f"http://127.0.0.1:{PORT}"

def exec_code(code: str, timeout: float = 15.0):
    url = f"{BASE_URL}/exec"
    payload = json.dumps({"code": code}).encode("utf-8")
    req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
    
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            cmd_id = data.get("id")
    except Exception as e:
        return False, f"Failed to send request to bridge: {e}"
        
    start_time = time.time()
    while time.time() - start_time < timeout:
        res_url = f"{BASE_URL}/result?id={cmd_id}"
        try:
            with urllib.request.urlopen(res_url) as resp:
                res_data = json.loads(resp.read().decode("utf-8"))
                return res_data.get("success", False), res_data.get("output") or res_data.get("error")
        except urllib.error.HTTPError as e:
            if e.code == 404:
                time.sleep(0.15)
                continue
            return False, f"HTTP Error {e.code}"
        except Exception:
            time.sleep(0.15)
            continue
            
    return False, "Timed out waiting for Roblox Studio."

def check_connection():
    try:
        with urllib.request.urlopen(f"{BASE_URL}/status") as resp:
            data = json.loads(resp.read().decode("utf-8"))
            if not data.get("server_running"):
                return False, "Bridge server is not running."
            if not data.get("studio_connected"):
                return False, "Roblox Studio is not connected. Make sure Roblox Studio is open and AIBridgePlugin is running."
            return True, "Connected"
    except Exception as e:
        return False, f"Could not reach bridge server at {BASE_URL}: {e}"

def dump_instance_tree(root_dir: Path):
    """Fetches a full hierarchical snapshot of DataModel instances."""
    print("[1/3] Generating full DataModel instance tree snapshot...")
    luau_code = """
    local HttpService = game:GetService("HttpService")
    
    local function serializeInstance(inst, depth)
        if depth > 8 then return { name = inst.Name, class = inst.ClassName, truncated = true } end
        local node = {
            name = inst.Name,
            class = inst.ClassName,
        }
        
        -- Add specific useful metadata
        if inst:IsA("LuaSourceContainer") then
            node.hasSource = true
            node.sourceLength = #inst.Source
        end
        
        local children = inst:GetChildren()
        if #children > 0 then
            node.children = {}
            for _, child in ipairs(children) do
                -- Skip internal Studio/Rojo temporary markers
                if child.Name ~= "__Rojo_SessionLock" and child.Name ~= "RBX_ANIMSAVES" then
                    table.insert(node.children, serializeInstance(child, depth + 1))
                end
            end
        end
        return node
    end
    
    local services = {
        "Workspace",
        "ReplicatedStorage",
        "ServerScriptService",
        "ServerStorage",
        "StarterGui",
        "StarterPlayer",
        "Lighting",
        "SoundService"
    }
    
    local tree = {}
    for _, svcName in ipairs(services) do
        local ok, svc = pcall(function() return game:GetService(svcName) end)
        if ok and svc then
            tree[svcName] = serializeInstance(svc, 0)
        end
    end
    
    return HttpService:JSONEncode(tree)
    """
    
    success, output = exec_code(luau_code, timeout=20.0)
    if not success:
        print(f"[-] Failed to fetch instance tree: {output}")
        return False
        
    try:
        tree_data = json.loads(output)
        tree_file = root_dir / "instance_tree.json"
        with open(tree_file, "w", encoding="utf-8") as f:
            json.dump(tree_data, f, indent=2, ensure_ascii=False)
        print(f"[+] Saved instance tree snapshot to: {tree_file.name}")
        return True
    except Exception as e:
        print(f"[-] Error writing instance tree: {e}")
        return False

def pull_scripts(root_dir: Path):
    """Finds all scripts in the DataModel and writes them to src/ using Rojo conventions."""
    print("[2/3] Extracting scripts from Roblox Studio...")
    
    # 1. Discover all scripts
    discover_code = """
    local HttpService = game:GetService("HttpService")
    local scripts = {}
    
    local function scan(inst, path)
        for _, child in ipairs(inst:GetChildren()) do
            local childPath = (path == "" and child.Name or (path .. "/" .. child.Name))
            local isScript = child:IsA("LuaSourceContainer")
            local hasChildScripts = false
            for _, sub in ipairs(child:GetChildren()) do
                if sub:IsA("LuaSourceContainer") then
                    hasChildScripts = true
                    break
                end
            end
            
            if isScript then
                table.insert(scripts, {
                    path = childPath,
                    name = child.Name,
                    className = child.ClassName,
                    hasChildren = (#child:GetChildren() > 0)
                })
            end
            scan(child, childPath)
        end
    end
    
    local services = {"ServerScriptService", "ReplicatedStorage", "StarterPlayer", "StarterGui", "Workspace", "ServerStorage"}
    for _, svc in ipairs(services) do
        local ok, s = pcall(function() return game:GetService(svc) end)
        if ok and s then
            scan(s, svc)
        end
    end
    
    return HttpService:JSONEncode(scripts)
    """
    
    success, output = exec_code(discover_code, timeout=15.0)
    if not success:
        print(f"[-] Failed to discover scripts: {output}")
        return False
        
    scripts = json.loads(output)
    print(f"[+] Found {len(scripts)} scripts in Studio.")
    
    # Mapping services to src/ paths
    # ServerScriptService -> src/server
    # ReplicatedStorage -> src/shared
    # StarterPlayer/StarterPlayerScripts -> src/client
    # StarterPlayer/StarterCharacterScripts -> src/client/character
    # StarterGui -> src/gui
    # Workspace -> src/workspace
    # ServerStorage -> src/serverstorage
    
    pulled_count = 0
    src_dir = root_dir / "src"
    src_dir.mkdir(exist_ok=True)
    
    for s_info in scripts:
        path_str = s_info["path"]
        class_name = s_info["className"]
        name = s_info["name"]
        has_children = s_info.get("hasChildren", False)
        
        # Determine destination relative to src/
        parts = path_str.split("/")
        service = parts[0]
        subparts = parts[1:]
        
        if service == "ServerScriptService":
            base_dir = src_dir / "server"
            rel_parts = subparts
        elif service == "ReplicatedStorage":
            base_dir = src_dir / "shared"
            rel_parts = subparts
        elif service == "StarterPlayer":
            if len(subparts) > 0 and subparts[0] == "StarterPlayerScripts":
                base_dir = src_dir / "client"
                rel_parts = subparts[1:]
            elif len(subparts) > 0 and subparts[0] == "StarterCharacterScripts":
                base_dir = src_dir / "client" / "character"
                rel_parts = subparts[1:]
            else:
                base_dir = src_dir / "starterplayer"
                rel_parts = subparts
        elif service == "StarterGui":
            base_dir = src_dir / "gui"
            rel_parts = subparts
        elif service == "Workspace":
            base_dir = src_dir / "workspace"
            rel_parts = subparts
        elif service == "ServerStorage":
            base_dir = src_dir / "serverstorage"
            rel_parts = subparts
        else:
            base_dir = src_dir / service.lower()
            rel_parts = subparts

        # Decide extension & filename
        # Rojo conventions:
        # Script -> .server.luau
        # LocalScript -> .client.luau
        # ModuleScript -> .luau
        # If script has child scripts, it becomes a folder with init.server.luau / init.client.luau / init.luau
        if class_name == "Script":
            ext = ".server.luau"
            init_name = "init.server.luau"
        elif class_name == "LocalScript":
            ext = ".client.luau"
            init_name = "init.client.luau"
        else:
            ext = ".luau"
            init_name = "init.luau"
            
        # Target file path
        if len(rel_parts) == 0:
            target_file = base_dir / (name + ext)
        else:
            parent_dir = base_dir.joinpath(*rel_parts[:-1])
            if has_children:
                target_file = parent_dir / name / init_name
            else:
                target_file = parent_dir / (name + ext)
                
        # Fetch the script source
        fetch_code = f"""
        local function getByPath(path)
            local parts = string.split(path, "/")
            local current = game:GetService(parts[1])
            for i = 2, #parts do
                current = current:FindFirstChild(parts[i])
                if not current then return nil end
            end
            return current
        end
        local inst = getByPath({json.dumps(path_str)})
        if inst and inst:IsA("LuaSourceContainer") then
            return inst.Source
        else
            return ""
        end
        """
        
        ok, source = exec_code(fetch_code, timeout=10.0)
        if not ok:
            print(f"  [-] Failed to read source for {path_str}: {source}")
            continue
            
        target_file.parent.mkdir(parents=True, exist_ok=True)
        with open(target_file, "w", encoding="utf-8") as f:
            f.write(source)
            
        pulled_count += 1
        print(f"  [+] {path_str} -> {target_file.relative_to(root_dir)}")
        
    print(f"[+] Successfully pulled {pulled_count} scripts.")
    return True

def update_project_json(root_dir: Path):
    """Updates default.project.json to include all mapped services (gui, workspace, serverstorage)."""
    print("[3/3] Updating default.project.json configuration...")
    proj_path = root_dir / "default.project.json"
    if not proj_path.exists():
        print("[-] default.project.json not found.")
        return
        
    with open(proj_path, "r", encoding="utf-8") as f:
        proj = json.load(f)
        
    tree = proj.setdefault("tree", {})
    
    # Ensure ReplicatedStorage.Shared
    rs = tree.setdefault("ReplicatedStorage", {})
    rs.setdefault("Shared", {"$path": "src/shared"})
    
    # Ensure ServerScriptService.Server
    sss = tree.setdefault("ServerScriptService", {})
    sss.setdefault("Server", {"$path": "src/server"})
    
    # Ensure StarterPlayer.StarterPlayerScripts.Client
    sp = tree.setdefault("StarterPlayer", {})
    sps = sp.setdefault("StarterPlayerScripts", {})
    sps.setdefault("Client", {"$path": "src/client"})
    
    # If src/gui exists, map StarterGui
    gui_dir = root_dir / "src" / "gui"
    if gui_dir.exists() and any(gui_dir.iterdir()):
        sg = tree.setdefault("StarterGui", {})
        sg.setdefault("UI", {"$path": "src/gui"})
        
    # If src/serverstorage exists, map ServerStorage
    ss_dir = root_dir / "src" / "serverstorage"
    if ss_dir.exists() and any(ss_dir.iterdir()):
        ss = tree.setdefault("ServerStorage", {})
        ss.setdefault("Storage", {"$path": "src/serverstorage"})
        
    with open(proj_path, "w", encoding="utf-8") as f:
        json.dump(proj, f, indent=2)
        
    print("[+] default.project.json updated with active service paths.")

def main():
    root_dir = Path(__file__).resolve().parent.parent
    print("=" * 60)
    print("  Roblox Studio -> Filesystem Instance Tree Synchronizer")
    print("=" * 60)
    
    connected, msg = check_connection()
    if not connected:
        print(f"Error: {msg}")
        print("Please ensure:")
        print("  1. 'python bridge\\server.py' is running.")
        print("  2. Roblox Studio is open with the place loaded.")
        print("  3. AIBridgePlugin is enabled in Studio.")
        sys.exit(1)
        
    dump_instance_tree(root_dir)
    pull_scripts(root_dir)
    update_project_json(root_dir)
    
    print("=" * 60)
    print("Sync complete! All scripts & instance trees are now updated.")
    print("=" * 60)

if __name__ == "__main__":
    main()
