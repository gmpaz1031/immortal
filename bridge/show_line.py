with open('bridge/verify_full_cultivation_system.py', 'r', encoding='utf-8') as f:
    content = f.read()

start = content.find('lua_test = """') + len('lua_test = """')
end = content.find('"""', start)
lua_code = content[start:end]

wrapped = """
    local success, result = xpcall(function()
""" + lua_code

for i, line in enumerate(wrapped.splitlines(), 1):
    if 20 <= i <= 35:
        print(f"{i}: {line}")
