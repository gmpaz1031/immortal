import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def deploy():
    print("=== Deploying PlantHarvestService & CultivationClient to Studio ===")
    
    with open('src/server/PlantHarvestService.server.luau', 'r', encoding='utf-8') as f:
        plant_service_src = f.read()

    with open('src/gui/CultivationClient.client.luau', 'r', encoding='utf-8') as f:
        client_src = f.read()

    # 1. Update PlantHarvestService
    lua_server = f"""
    local SSS = game:GetService("ServerScriptService")
    local serverFolder = SSS:WaitForChild("Server")
    local phs = serverFolder:WaitForChild("PlantHarvestService")
    phs.Source = [====[{plant_service_src}]====]
    return "Updated " .. phs:GetFullName()
    """
    ok1, res1 = exec_code(lua_server)
    print("PlantHarvestService Deploy:", ok1, res1)
    assert ok1, f"Failed deploying PlantHarvestService: {res1}"

    # 2. Update CultivationClient in StarterGui
    lua_client = f"""
    local StarterGui = game:GetService("StarterGui")
    local ui = StarterGui:WaitForChild("CultivationUI")
    local clientScript = ui:WaitForChild("CultivationClient")
    clientScript.Source = [====[{client_src}]====]
    return "Updated " .. clientScript:GetFullName()
    """
    ok2, res2 = exec_code(lua_client)
    print("CultivationClient Deploy:", ok2, res2)
    assert ok2, f"Failed deploying CultivationClient: {res2}"

    print("All services successfully deployed to Studio!")

if __name__ == '__main__':
    deploy()
