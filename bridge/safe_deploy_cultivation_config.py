import sys
import os
import json
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def deploy_cultivation_config():
    with open('src/shared/CultivationConfig.luau', 'r', encoding='utf-8') as f:
        src = f.read()

    packed_json = json.dumps({"source": src})
    lua_json_literal = json.dumps(packed_json)

    lua = f"""
    local HttpService = game:GetService("HttpService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local shared = ReplicatedStorage:WaitForChild("Shared")
    local cc = shared:WaitForChild("CultivationConfig")
    local data = HttpService:JSONDecode({lua_json_literal})
    cc.Source = data.source
    return "CultivationConfig deployed! Length: " .. #cc.Source
    """
    ok, res = exec_code(lua)
    print("CultivationConfig deploy:", ok, res)

if __name__ == '__main__':
    deploy_cultivation_config()
