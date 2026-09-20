import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def deploy_mining_system():
    print("=== Deploying Mining System to Roblox Studio ===")

    with open('src/shared/OreConfig.luau', 'r', encoding='utf-8') as f:
        ore_config_src = f.read()

    with open('src/shared/ItemConfig.luau', 'r', encoding='utf-8') as f:
        item_config_src = f.read()

    with open('src/server/MiningService.server.luau', 'r', encoding='utf-8') as f:
        mining_service_src = f.read()

    lua_deploy = f"""
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local SSS = game:GetService("ServerScriptService")

    local sharedFolder = ReplicatedStorage:WaitForChild("Shared")

    -- 1. Deploy OreConfig
    local oreConfig = sharedFolder:FindFirstChild("OreConfig")
    if not oreConfig then
        oreConfig = Instance.new("ModuleScript")
        oreConfig.Name = "OreConfig"
        oreConfig.Parent = sharedFolder
    end
    oreConfig.Source = [====[{ore_config_src}]====]

    -- 2. Deploy ItemConfig
    local itemConfig = sharedFolder:WaitForChild("ItemConfig")
    itemConfig.Source = [====[{item_config_src}]====]

    -- 3. Deploy MiningService
    local serverFolder = SSS:WaitForChild("Server")
    local miningService = serverFolder:FindFirstChild("MiningService")
    if not miningService then
        miningService = Instance.new("Script")
        miningService.Name = "MiningService"
        miningService.Parent = serverFolder
    end
    miningService.Source = [====[{mining_service_src}]====]

    return "Successfully deployed OreConfig, ItemConfig, and MiningService!"
    """

    ok, res = exec_code(lua_deploy)
    print("Deploy Mining System Result:", ok, res)
    assert ok, f"Failed deploying mining system: {res}"

if __name__ == '__main__':
    deploy_mining_system()
