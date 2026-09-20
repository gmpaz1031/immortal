import sys
import json
import urllib.request
import time
from pathlib import Path

PORT = 34875
BASE_URL = f"http://127.0.0.1:{PORT}"

def exec_code(code: str, timeout: float = 15.0):
    url = f"{BASE_URL}/exec"
    payload = json.dumps({"code": code}).encode("utf-8")
    req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
    
    try:
        with urllib.request.urlopen(req) as resp:
            cmd_id = json.loads(resp.read().decode("utf-8")).get("id")
    except Exception as e:
        return False, f"Bridge error: {e}"
        
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
    return False, "Timed out"

def main():
    root = Path(r"c:\GMGAME\immortal")
    src_dir = root / "src"
    
    # 1. Fetch ServerScriptService.Server children
    code = """
    local HttpService = game:GetService("HttpService")
    local sss = game:GetService("ServerScriptService"):FindFirstChild("Server")
    local res = {}
    if sss then
        for _, c in ipairs(sss:GetChildren()) do
            if c:IsA("LuaSourceContainer") then
                table.insert(res, {
                    name = c.Name,
                    className = c.ClassName,
                    source = c.Source
                })
            end
        end
    end
    return HttpService:JSONEncode(res)
    """
    ok, out = exec_code(code)
    if not ok:
        print("Failed to fetch server scripts:", out)
        return
    server_scripts = json.loads(out)
    server_dir = src_dir / "server"
    server_dir.mkdir(parents=True, exist_ok=True)
    
    for s in server_scripts:
        name = s["name"]
        cls = s["className"]
        src = s["source"]
        # Skip Rojo template placeholders
        if name in ["init", "Server"] and "Hello world" in src:
            print(f"Skipping placeholder {name}")
            continue
        ext = ".server.luau" if cls == "Script" else ".luau"
        target = server_dir / (name + ext)
        target.write_text(src, encoding="utf-8")
        print(f"Pulled Server: {target.name} ({len(src)} chars)")

    # 2. Fetch ReplicatedStorage.Shared children
    code = """
    local HttpService = game:GetService("HttpService")
    local rs = game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
    local res = {}
    if rs then
        for _, c in ipairs(rs:GetChildren()) do
            if c:IsA("LuaSourceContainer") then
                table.insert(res, {
                    name = c.Name,
                    className = c.ClassName,
                    source = c.Source
                })
            end
        end
    end
    return HttpService:JSONEncode(res)
    """
    ok, out = exec_code(code)
    if not ok:
        print("Failed to fetch shared scripts:", out)
        return
    shared_scripts = json.loads(out)
    shared_dir = src_dir / "shared"
    shared_dir.mkdir(parents=True, exist_ok=True)
    
    for s in shared_scripts:
        name = s["name"]
        src = s["source"]
        if name == "Hello" and "Hello, world!" in src:
            print("Skipping placeholder Hello")
            continue
        target = shared_dir / (name + ".luau")
        target.write_text(src, encoding="utf-8")
        print(f"Pulled Shared: {target.name} ({len(src)} chars)")

    # 3. Fetch CultivationClient
    code = """
    local cui = game:GetService("StarterGui"):FindFirstChild("CultivationUI")
    local cc = cui and cui:FindFirstChild("CultivationClient")
    return cc and cc.Source or ""
    """
    ok, src = exec_code(code)
    if ok and len(src) > 0:
        target = src_dir / "gui" / "CultivationUI" / "CultivationClient.client.luau"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(src, encoding="utf-8")
        print(f"Pulled CultivationClient ({len(src)} chars)")

    # 4. Fetch SkillClient
    code = """
    local sui = game:GetService("StarterGui"):FindFirstChild("SkillUI")
    local sc = sui and sui:FindFirstChild("SkillClient")
    return sc and sc.Source or ""
    """
    ok, src = exec_code(code)
    if ok and len(src) > 0:
        target = src_dir / "gui" / "SkillUI" / "SkillClient.client.luau"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(src, encoding="utf-8")
        print(f"Pulled SkillClient ({len(src)} chars)")

    # 5. Fetch MovementController
    code = """
    local sp = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
    local mc = sp and sp:FindFirstChild("MovementController")
    return mc and mc.Source or ""
    """
    ok, src = exec_code(code)
    if ok and len(src) > 0:
        target = src_dir / "client" / "MovementController.client.luau"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(src, encoding="utf-8")
        print(f"Pulled MovementController ({len(src)} chars)")

if __name__ == "__main__":
    main()
