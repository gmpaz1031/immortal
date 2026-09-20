import os
from pathlib import Path

def install():
    plugin_lua = Path(__file__).resolve().parent.parent / "AIBridgePlugin.lua"
    if not plugin_lua.exists():
        print(f"Error: {plugin_lua} not found")
        return False
        
    code = plugin_lua.read_text(encoding="utf-8")
    
    xml = (
        '<roblox version="4">\n'
        '  <Item class="Script" referent="RBX_AI_BRIDGE">\n'
        '    <Properties>\n'
        '      <string name="Name">AIBridgePlugin</string>\n'
        '      <ProtectedString name="Source"><![CDATA[' + code + ']]></ProtectedString>\n'
        '    </Properties>\n'
        '  </Item>\n'
        '</roblox>\n'
    )
    
    plugins_dir = Path(os.path.expandvars(r"%LOCALAPPDATA%\Roblox\Plugins"))
    plugins_dir.mkdir(parents=True, exist_ok=True)
    
    # Write .rbxmx
    rbxmx_path = plugins_dir / "AIBridgePlugin.rbxmx"
    rbxmx_path.write_text(xml, encoding="utf-8")
    print(f"[+] Installed plugin: {rbxmx_path}")
    
    # Also write .lua
    lua_path = plugins_dir / "AIBridgePlugin.lua"
    lua_path.write_text(code, encoding="utf-8")
    print(f"[+] Installed plugin: {lua_path}")
    
    return True

if __name__ == "__main__":
    install()
