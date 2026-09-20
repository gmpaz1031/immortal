import sys
import json
import time
import urllib.request

PORT = 34875

def exec_code(code: str, timeout: float = 30.0):
    url = f"http://127.0.0.1:{PORT}/exec"
    payload = json.dumps({"code": code}).encode("utf-8")
    req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
    
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            cmd_id = data.get("id")
    except Exception as e:
        print(f"[Error] Failed to send command to bridge server: {e}")
        return False, str(e)
    
    # Poll for result
    start_time = time.time()
    while time.time() - start_time < timeout:
        res_url = f"http://127.0.0.1:{PORT}/result?id={cmd_id}"
        try:
            with urllib.request.urlopen(res_url) as resp:
                res_data = json.loads(resp.read().decode("utf-8"))
                return res_data.get("success", False), res_data.get("output") or res_data.get("error")
        except urllib.error.HTTPError as e:
            if e.code == 404:
                time.sleep(0.15)
                continue
            else:
                return False, f"HTTP Error {e.code}"
        except Exception as e:
            time.sleep(0.15)
            continue
            
    return False, "Timed out waiting for Roblox Studio execution."

if __name__ == "__main__":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
    if len(sys.argv) < 2:
        print("Usage: python exec.py <luau_code_or_filepath>")
        sys.exit(1)
        
    arg = sys.argv[1]
    code = arg
    if arg.endswith(".luau") or arg.endswith(".lua"):
        with open(arg, "r", encoding="utf-8") as f:
            code = f.read()
            
    success, msg = exec_code(code)
    try:
        print(f"Success: {success}\nOutput: {msg}")
    except Exception:
        print(f"Success: {success}\nOutput: {str(msg).encode('ascii', errors='replace').decode('ascii')}")
    sys.exit(0 if success else 1)
