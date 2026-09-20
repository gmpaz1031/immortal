import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def debug_verify():
    with open('bridge/verify_full_cultivation_system.py', 'r', encoding='utf-8') as f:
        content = f.read()

    start = content.find('lua_test = """') + len('lua_test = """')
    end = content.find('"""', start)
    lua_code = content[start:end]

    wrapped_lua = f"""
    local success, result = xpcall(function()
        {lua_code}
    end, function(err)
        return debug.traceback(err)
    end)
    return "SUCCESS=" .. tostring(success) .. "\\nRESULT=" .. tostring(result)
    """

    ok, res = exec_code(wrapped_lua)
    safe = str(res).encode('ascii', errors='replace').decode('ascii')
    print("Debug result:\n" + safe)

if __name__ == '__main__':
    debug_verify()
