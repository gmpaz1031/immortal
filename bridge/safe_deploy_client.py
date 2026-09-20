import sys
import os
import json
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def safe_deploy():
    print("=== Safely Deploying Full CultivationClient via JSONDecode ===")

    with open('src/gui/CultivationClient.client.luau', 'r', encoding='utf-8') as f:
        src = f.read()

    # Pack into a JSON object string
    packed_json = json.dumps({"source": src})
    # Double serialize so it becomes a valid Lua string literal in the code payload
    lua_json_literal = json.dumps(packed_json)

    lua_deploy = f"""
    local HttpService = game:GetService("HttpService")
    local StarterGui = game:GetService("StarterGui")

    local jsonStr = {lua_json_literal}
    local data = HttpService:JSONDecode(jsonStr)

    local ui = StarterGui:WaitForChild("CultivationUI")
    local clientScript = ui:WaitForChild("CultivationClient")
    clientScript.Source = data.source

    return string.format("Deployed successfully! Length: %d chars, Lines: %d", #clientScript.Source, #string.split(clientScript.Source, "\\n"))
    """

    ok, res = exec_code(lua_deploy)
    print("Safe Deploy Result:", ok, res)
    assert ok, f"Deploy failed: {res}"

if __name__ == '__main__':
    safe_deploy()
