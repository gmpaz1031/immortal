import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def deploy():
    print("=== Deploying Pro Inventory UI & Client to Studio ===")

    with open('src/shared/ItemConfig.luau', 'r', encoding='utf-8') as f:
        item_config_src = f.read()

    with open('src/gui/CultivationClient.client.luau', 'r', encoding='utf-8') as f:
        client_src = f.read()

    lua_deploy = f"""
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local StarterGui = game:GetService("StarterGui")

    local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
    local itemConfig = sharedFolder:WaitForChild("ItemConfig")
    itemConfig.Source = [====[{item_config_src}]====]

    local ui = StarterGui:WaitForChild("CultivationUI")
    local clientScript = ui:WaitForChild("CultivationClient")
    clientScript.Source = [====[{client_src}]====]

    return "Successfully updated ItemConfig and CultivationClient in Studio!"
    """

    ok, res = exec_code(lua_deploy)
    print("Deploy Result:", ok, res)
    assert ok, f"Failed deploying: {res}"

if __name__ == '__main__':
    deploy()
