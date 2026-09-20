import sys
import os
import json
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def deploy_item_config():
    with open('src/shared/ItemConfig.luau', 'r', encoding='utf-8') as f:
        src = f.read()

    packed_json = json.dumps({"source": src})
    lua_json_literal = json.dumps(packed_json)

    lua = f"""
    local HttpService = game:GetService("HttpService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local shared = ReplicatedStorage:WaitForChild("Shared")
    local ic = shared:WaitForChild("ItemConfig")
    local data = HttpService:JSONDecode({lua_json_literal})
    ic.Source = data.source
    return "ItemConfig deployed! Length: " .. #ic.Source
    """
    ok, res = exec_code(lua)
    print("ItemConfig deploy:", ok, res)

if __name__ == '__main__':
    deploy_item_config()
