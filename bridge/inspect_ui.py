import urllib.request
import json
import time

PORT = 34875

def exec_code(code: str):
    url = f"http://127.0.0.1:{PORT}/exec"
    payload = json.dumps({"code": code}).encode("utf-8")
    req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode("utf-8"))
        cmd_id = data.get("id")
        
    start = time.time()
    while time.time() - start < 15:
        try:
            with urllib.request.urlopen(f"http://127.0.0.1:{PORT}/result?id={cmd_id}") as r:
                res = json.loads(r.read().decode("utf-8"))
                return res.get("success"), res.get("output") or res.get("error")
        except Exception:
            time.sleep(0.2)
    return False, "Timeout"

if __name__ == "__main__":
    code = r"""
    local StarterGui = game:GetService("StarterGui")
    local lines = {}
    for _, ch in ipairs(StarterGui:GetChildren()) do
        table.insert(lines, ch.Name .. " [" .. ch.ClassName .. "]")
        for _, sub in ipairs(ch:GetChildren()) do
            table.insert(lines, "  - " .. sub.Name .. " [" .. sub.ClassName .. "]")
        end
    end
    return table.concat(lines, "\n")
    """
    ok, out = exec_code(code)
    print("SUCCESS" if ok else "FAILED")
    print(out)
