"""
scratch/test_screenshot_native.py
Tests capturing a screenshot from inside Roblox Studio using CaptureService + EditableImage
and sending the pixel buffer to Python via HTTP.
"""
import sys
import json
import time
from pathlib import Path
from http.server import HTTPServer, BaseHTTPRequestHandler
import threading
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from bridge.exec import exec_code

received_image = None

class ScreenshotReceiver(BaseHTTPRequestHandler):
    def log_message(self, *args): pass
    def do_POST(self):
        global received_image
        w = int(self.headers.get("X-Width", 0))
        h = int(self.headers.get("X-Height", 0))
        length = int(self.headers.get("Content-Length", 0))
        raw_bytes = self.rfile.read(length)
        print(f"[Python] Received {len(raw_bytes)} bytes for image {w}x{h}")
        try:
            received_image = Image.frombytes("RGBA", (w, h), raw_bytes)
        except Exception as e:
            print(f"[Python] Image decode failed: {e}")
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"OK")

server = HTTPServer(("127.0.0.1", 34878), ScreenshotReceiver)
th = threading.Thread(target=server.handle_request, daemon=True)
th.start()

# Lua code to capture and send
lua_code = """
local cs = game:GetService("CaptureService")
local assetService = game:GetService("AssetService")
local HttpService = game:GetService("HttpService")

local contentId = nil
cs:CaptureScreenshot(function(cid)
    contentId = cid
end)

local start = os.clock()
while not contentId and (os.clock() - start < 4) do
    task.wait(0.1)
end

if not contentId then
    return "Failed: No contentId"
end

local img = assetService:CreateEditableImageAsync(Content.fromUri(contentId))
local size = img.Size
local buf = img:ReadPixelsBuffer(Vector2.zero, size)
local raw = buffer.tostring(buf)

local ok, res = pcall(function()
    return HttpService:RequestAsync({
        Url = "http://127.0.0.1:34878/upload",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/octet-stream",
            ["X-Width"] = tostring(size.X),
            ["X-Height"] = tostring(size.Y)
        },
        Body = raw
    })
end)

return "Upload: ok=" .. tostring(ok) .. " status=" .. tostring(res and res.StatusCode) .. " size=" .. tostring(size)
"""

print("[Python] Triggering Studio capture...")
ok, out = exec_code(lua_code, timeout=15.0)
print(f"[Studio Response] {ok} | {out}")

th.join(timeout=5.0)
server.server_close()

if received_image:
    out_path = Path("assets/screenshots/native_capture_test.png")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    received_image.save(out_path)
    print(f"[SUCCESS] Native Studio screenshot saved to {out_path} ({received_image.size})")
else:
    print("[FAIL] Did not receive image")
