import sys
import os
sys.path.append(os.path.dirname(__file__))
from exec import exec_code

# Phase B deployment:
# 1. Wipe old DemonCult content
# 2. Build DemonCultConfig in RS.Shared
# 3. Build DemonCultFactory, DemonCultAI, DemonCultVillageGenerator, DemonCultManager in SSS.Server
# 4. Call DemonCultManager.init() to spawn everything

WIPE_LUA = """
-- Clear all previous DemonCult artifacts
local function d(parent, name)
    local c = parent:FindFirstChild(name)
    if c then c:Destroy() end
end
-- Workspace
d(workspace, "DemonCultVillage")
d(workspace, "DemonCultTower")
d(workspace, "DemonCultCave")
d(workspace, "DemonCult_Enemies")
d(workspace, "DemonCult_Bosses")
d(workspace, "Map")
-- ServerStorage
d(game.ServerStorage, "DemonCult_BossTemplates")
d(game.ServerStorage, "DemonCult_EnemyTemplates")
-- Stale Player model from previous run
for _, c in ipairs(workspace:GetChildren()) do
    if c.Name == "Player" and c:IsA("Model") then c:Destroy() end
end
return "Wiped all DemonCult artifacts."
"""

INJECT_LUA = r"""
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

local shared = RS:WaitForChild("Shared")
local server = SSS:WaitForChild("Server")

--------------------------------------------------------------------------------
-- Helper: create or replace a ModuleScript
--------------------------------------------------------------------------------
local function injectModule(parent, name, source)
    local existing = parent:FindFirstChild(name)
    if existing then existing:Destroy() end
    local m = Instance.new("ModuleScript")
    m.Name = name
    m.Source = source
    m.Parent = parent
    return m
end

--------------------------------------------------------------------------------
-- 1. DemonCultConfig (goes into ReplicatedStorage.Shared)
--------------------------------------------------------------------------------
local DEMON_CULT_CONFIG_SRC = [==[
--!strict
local DemonCultConfig = {
    DemonCultist = {
        MaxHealth=120, WalkSpeed=14, Scale=1.0, BaseDamage=18,
        AttackRange=5.5, AttackCooldown=1.2, ChaseRange=55,
        IsBoss=false, IsStandby=false, Title="Demon Cultist",
    },
    SeniorDemonCultist = {
        MaxHealth=280, WalkSpeed=15, Scale=1.1, BaseDamage=26,
        AttackRange=6.0, AttackCooldown=1.1, ChaseRange=60,
        IsBoss=false, IsStandby=false, Title="Senior Demon Cultist",
    },
    DemonicElder = {
        MaxHealth=750, WalkSpeed=13, Scale=1.2, BaseDamage=30,
        AttackRange=6.5, AttackCooldown=1.4, ChaseRange=75,
        SpecialCooldowns={ NearPull=4.0, FarFlame=3.0 },
        IsBoss=true, IsStandby=false, Title="Demonic Elder · Cult Guardian",
    },
    FlameDemoness = {
        MaxHealth=900, WalkSpeed=14, Scale=1.15, BaseDamage=32,
        AttackRange=6.0, AttackCooldown=1.3, ChaseRange=80,
        SpecialCooldowns={ FlameShockwave=6.0, FlamePull=4.0 },
        IsBoss=true, IsStandby=false, Title="Flame Demoness · Pillar of Fire",
    },
    PoisonDemoness = {
        MaxHealth=850, WalkSpeed=15, Scale=1.15, BaseDamage=28,
        AttackRange=6.0, AttackCooldown=1.2, ChaseRange=80,
        SpecialCooldowns={ PoisonOrb=5.0, PoisonPool=8.0 },
        IsBoss=true, IsStandby=false, Title="Poison Demoness · Pillar of Venom",
    },
    FistDemon = {
        MaxHealth=1050, WalkSpeed=13, Scale=1.3, BaseDamage=38,
        AttackRange=7.0, AttackCooldown=1.5, ChaseRange=75,
        SpecialCooldowns={ GroundSmash=7.0, DemonicDash=5.0 },
        IsBoss=true, IsStandby=false, Title="Fist Demon · Pillar of Destruction",
    },
    SwordDemon = {
        MaxHealth=920, WalkSpeed=16, Scale=1.2, BaseDamage=35,
        AttackRange=6.5, AttackCooldown=1.0, ChaseRange=80,
        SpecialCooldowns={ CrossSlash=6.0, SwordWave=4.0, ShadowStep=5.0 },
        IsBoss=true, IsStandby=false, Title="Sword Demon · Pillar of Blades",
    },
    SupremeDemon = {
        MaxHealth=2800, WalkSpeed=14, Scale=1.45, BaseDamage=55,
        AttackRange=8.0, AttackCooldown=1.6, ChaseRange=90,
        IsBoss=true, IsStandby=true, Title="Supreme Demon · Heavenly Demon Sovereign",
    },
    BloodDemon = {
        MaxHealth=2400, WalkSpeed=15, Scale=1.35, BaseDamage=48,
        AttackRange=7.5, AttackCooldown=1.4, ChaseRange=85,
        IsBoss=true, IsStandby=true, Title="Blood Demon · Crimson Patriarch",
    },
}
return DemonCultConfig
]==]

injectModule(shared, "DemonCultConfig", DEMON_CULT_CONFIG_SRC)
return "Step 1 done: DemonCultConfig injected"
"""

# We'll run the source files directly via the large Lua files we wrote
# The bridge will inject them as ModuleScripts inside SSS.Server
# Then call Manager.init()

import pathlib

def read_lua(filename):
    p = pathlib.Path("src") / "server" / filename
    return p.read_text(encoding="utf-8")

def read_shared(filename):
    p = pathlib.Path("src") / "shared" / filename
    return p.read_text(encoding="utf-8")

def run(lua, label, timeout=20.0):
    print(f"  >> {label}...")
    ok, out = exec_code(lua, timeout=timeout)
    status = "OK" if ok else "FAIL"
    print(f"    [{status}] {out[:200]}")
    return ok

def escape_lua_string(s):
    """Wrap Lua source in a long-string bracket that won't conflict."""
    # Use level-4 long strings [====[...]==== ] which are very unlikely to appear in source
    return "[====[" + s + "]====]"

def inject_module(parent_expr, name, source_code):
    """Generate Lua to inject a ModuleScript into parent."""
    escaped = escape_lua_string(source_code)
    return f"""
local parent = {parent_expr}
local existing = parent:FindFirstChild({repr(name)})
if existing then existing:Destroy() end
local m = Instance.new("ModuleScript")
m.Name = {repr(name)}
m.Source = {escaped}
m.Parent = parent
return "Injected: " .. {repr(name)}
"""

if __name__ == "__main__":
    cwd = pathlib.Path(__file__).parent.parent
    os.chdir(cwd)
    
    print("Phase B — Deploy Demon Cult Village\n")

    # Step 0: Wipe
    run(WIPE_LUA, "Wipe old DemonCult content")

    # Step 1: Inject DemonCultConfig into RS.Shared
    config_src = read_shared("DemonCultConfig.luau")
    run(inject_module(
        "game:GetService('ReplicatedStorage'):WaitForChild('Shared')",
        "DemonCultConfig", config_src
    ), "DemonCultConfig into RS.Shared")

    # Step 2: Inject DemonCultFactory into SSS.Server
    factory_src = read_lua("DemonCultFactory.luau")
    run(inject_module(
        "game:GetService('ServerScriptService'):WaitForChild('Server')",
        "DemonCultFactory", factory_src
    ), "DemonCultFactory into SSS.Server", timeout=25.0)

    # Step 3: Inject DemonCultAI into SSS.Server
    ai_src = read_lua("DemonCultAI.luau")
    run(inject_module(
        "game:GetService('ServerScriptService'):WaitForChild('Server')",
        "DemonCultAI", ai_src
    ), "DemonCultAI into SSS.Server", timeout=25.0)

    # Step 4: Inject DemonCultVillageGenerator into SSS.Server
    vgen_src = read_lua("DemonCultVillageGenerator.luau")
    run(inject_module(
        "game:GetService('ServerScriptService'):WaitForChild('Server')",
        "DemonCultVillageGenerator", vgen_src
    ), "DemonCultVillageGenerator into SSS.Server", timeout=25.0)

    # Step 5: Inject DemonCultManager into SSS.Server
    mgr_src = read_lua("DemonCultManager.luau")
    run(inject_module(
        "game:GetService('ServerScriptService'):WaitForChild('Server')",
        "DemonCultManager", mgr_src
    ), "DemonCultManager into SSS.Server", timeout=25.0)

    # Step 6: Execute DemonCultManager.init() directly
    INIT_LUA = """
local SSS = game:GetService("ServerScriptService")
local server = SSS:WaitForChild("Server")
local mgr = server:WaitForChild("DemonCultManager", 10)
if not mgr then return "ERROR: DemonCultManager not found" end
local ok, err = pcall(function()
    local m = require(mgr)
    m.init()
end)
if not ok then return "ERROR: " .. tostring(err) end
return "DemonCultManager.init() SUCCESS"
"""
    run(INIT_LUA, "DemonCultManager.init()", timeout=30.0)

    print("\nPhase B deployment complete.")
