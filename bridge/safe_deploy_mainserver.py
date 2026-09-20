import sys
import os
import json
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def deploy_mainserver():
    print("=== Deploying MAINSERVER to ServerScriptService.Server.MAINSERVER ===")
    with open('src/server/MAINSERVER.server.luau', 'r', encoding='utf-8') as f:
        src = f.read()

    packed_json = json.dumps({"source": src})
    lua_json_literal = json.dumps(packed_json)

    lua = f"""
    local HttpService = game:GetService("HttpService")
    local sss = game:GetService("ServerScriptService")
    local serverFolder = sss:WaitForChild("Server")
    local main = serverFolder:WaitForChild("MAINSERVER")
    local data = HttpService:JSONDecode({lua_json_literal})
    main.Source = data.source
    return "MAINSERVER deployed! Length: " .. #main.Source
    """
    ok, res = exec_code(lua)
    print("MAINSERVER deploy result:", ok, res)
    assert ok, f"Deploy failed: {res}"

if __name__ == '__main__':
    deploy_mainserver()
