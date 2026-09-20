"""
bridge/deploy_village_and_enemies.py
Deploys the Destroyed Village, Central Shrine, Swordsmen, Swordmaster Boss (Standby),
and the complete Cave Enemy Template Collection into Roblox Studio in real-time.
"""

import sys
import json
import time
from pathlib import Path
from exec import exec_code

def deploy():
    print("=" * 60)
    print("  Deploying Destroyed Village & Cave Enemy Generation System")
    print("=" * 60)

    # Load Lua modules from src/
    root_dir = Path(__file__).resolve().parent.parent
    src_dir = root_dir / "src"

    config_code = (src_dir / "shared" / "CaveEnemyConfig.luau").read_text(encoding="utf-8")
    damage_code = (src_dir / "server" / "DamageService.luau").read_text(encoding="utf-8")
    factory_code = (src_dir / "server" / "CaveEnemyFactory.luau").read_text(encoding="utf-8")
    ai_code = (src_dir / "server" / "CaveEnemyAI.luau").read_text(encoding="utf-8")
    gen_code = (src_dir / "server" / "DestroyedVillageGenerator.luau").read_text(encoding="utf-8")
    mgr_code = (src_dir / "server" / "DestroyedVillageManager.luau").read_text(encoding="utf-8")

    # Composite script to execute in Roblox Studio
    studio_script = f"""
    local HttpService = game:GetService("HttpService")
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerScriptService = game:GetService("ServerScriptService")
    local ServerStorage = game:GetService("ServerStorage")

    -- 1. Install / Update Shared Configuration
    local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
    if not sharedFolder then
        sharedFolder = Instance.new("Folder")
        sharedFolder.Name = "Shared"
        sharedFolder.Parent = ReplicatedStorage
    end

    local oldCfg = sharedFolder:FindFirstChild("CaveEnemyConfig")
    if oldCfg then oldCfg:Destroy() end
    local configMod = Instance.new("ModuleScript")
    configMod.Name = "CaveEnemyConfig"
    configMod.Source = [===[{config_code}]===]
    configMod.Parent = sharedFolder

    -- 2. Install / Update Server Modules (destroying previous clears require error cache)
    local serverFolder = ServerScriptService:FindFirstChild("Server") or ServerScriptService
    local function putModule(name, source)
        local old = serverFolder:FindFirstChild(name)
        if old then old:Destroy() end
        local mod = Instance.new("ModuleScript")
        mod.Name = name
        mod.Source = source
        mod.Parent = serverFolder
        return mod
    end

    putModule("DamageService", [===[{damage_code}]===])
    local factoryMod = putModule("CaveEnemyFactory", [===[{factory_code}]===])
    local aiMod = putModule("CaveEnemyAI", [===[{ai_code}]===])
    local genMod = putModule("DestroyedVillageGenerator", [===[{gen_code}]===])
    local mgrMod = putModule("DestroyedVillageManager", [===[{mgr_code}]===])

    -- 3. Execute Village Generation
    local okGen, villageGen = pcall(require, genMod)
    if okGen and villageGen and villageGen.generate then
        villageGen.generate(Vector3.new(240, 0, -180))
    else
        warn("Failed to require DestroyedVillageGenerator:", villageGen)
    end

    -- 4. Spawn Swordsmen & Swordmaster Boss
    local okMgr, villageMgr = pcall(require, mgrMod)
    if okMgr and villageMgr and villageMgr.init then
        villageMgr.init(Vector3.new(240, 0, -180))
    else
        warn("Failed to require DestroyedVillageManager:", villageMgr)
    end

    -- 5. Generate Cave Enemies Template Collection for Manual Placement
    -- Location: Workspace.CaveEnemies_Templates & ServerStorage.CaveEnemies_Templates
    local oldTemplates = Workspace:FindFirstChild("CaveEnemies_Templates")
    if oldTemplates then oldTemplates:Destroy() end

    local templatesFolder = Instance.new("Folder")
    templatesFolder.Name = "CaveEnemies_Templates"
    templatesFolder.Parent = Workspace

    local Factory = require(factoryMod)
    local AI = require(aiMod)

    -- Template base offset (placed side by side cleanly for easy manual selection)
    local templateBase = Vector3.new(180, 2, -100)

    -- List of all 6 cave enemy types
    local enemyEntries = {{
        {{ type = "CaveSpider", isSpider = true, isMother = false, offset = Vector3.new(-25, 0, 0) }},
        {{ type = "SpiderMother", isSpider = true, isMother = true, offset = Vector3.new(-12, 0, 0) }},
        {{ type = "Assassin", isSpider = false, offset = Vector3.new(2, 0, 0) }},
        {{ type = "SeniorAssassin", isSpider = false, offset = Vector3.new(16, 0, 0) }},
        {{ type = "FourPillarAssassin", isSpider = false, offset = Vector3.new(30, 0, 0) }},
        {{ type = "SupremeAssassin", isSpider = false, offset = Vector3.new(46, 0, 0) }},
    }}

    local spawnedCount = 0
    for _, entry in ipairs(enemyEntries) do
        local enemyModel
        if entry.isSpider then
            enemyModel = Factory.createSpider(entry.isMother)
        else
            enemyModel = Factory.createHumanoidEnemy(entry.type)
        end

        local pos = templateBase + entry.offset
        local spawnCF = CFrame.new(pos)
        if enemyModel.PrimaryPart then
            enemyModel.PrimaryPart.CFrame = spawnCF
        end
        enemyModel.Parent = templatesFolder

        -- Attach AI Controller
        AI.attach(enemyModel, entry.type, spawnCF)
        spawnedCount = spawnedCount + 1
    end

    -- Also clone templates into ServerStorage for persistent backup
    local ssTemplates = ServerStorage:FindFirstChild("CaveEnemies_Templates")
    if ssTemplates then ssTemplates:Destroy() end
    local ssClone = templatesFolder:Clone()
    ssClone.Parent = ServerStorage

    return string.format("DEPLOY_SUCCESS: Destroyed Village created at (240, 0, -180) with 5 Swordsmen & Swordmaster Boss (Standby). %d Cave Enemy Templates ready in Workspace.CaveEnemies_Templates & ServerStorage!", spawnedCount)
    """

    print("[1/2] Sending deployment payload to Roblox Studio...")
    success, output = exec_code(studio_script, timeout=25.0)

    if success:
        print("[2/2] Deployment successful!")
        print(f"Output: {output}")
        return True
    else:
        print(f"[-] Deployment failed: {output}")
        return False

if __name__ == "__main__":
    ok = deploy()
    sys.exit(0 if ok else 1)
