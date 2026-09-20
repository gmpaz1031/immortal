"""
bridge/capture.py
==================
Native In-Engine Screenshot & Visual Playtesting Client for Immortal RPG.

Directly captures the Roblox Studio viewport via CaptureService & EditableImage.
- 100% Background Execution: NO focus stealing, NO cursor movement, NO window switching.
- Works while you are in another tab, playing another game, or minimized.
- Crops regions directly inside the engine buffer before transferring.

Usage:
    from bridge.capture import capture, capture_all_regions, is_studio_connected

    # Capture the skill hotbar
    img_path = capture(region="hotbar")

    # Capture full screen
    full_path = capture(region="full")
"""

import sys
import json
import time
import base64
import threading
from pathlib import Path
from http.server import HTTPServer, BaseHTTPRequestHandler
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from exec import exec_code

SCREENSHOTS_DIR = Path(__file__).resolve().parent.parent / "assets" / "screenshots"
SCREENSHOTS_DIR.mkdir(parents=True, exist_ok=True)

RECEIVER_PORT = 34878

def is_studio_connected() -> bool:
    import urllib.request
    try:
        with urllib.request.urlopen("http://127.0.0.1:34875/status", timeout=2) as r:
            data = json.loads(r.read().decode("utf-8"))
            return data.get("server_running", False)
    except Exception:
        return False

def capture(region: str = "full", label: str = "") -> Path:
    """
    Takes a screenshot directly inside Roblox Studio and saves it to assets/screenshots.
    Regions supported:
      - 'full': entire viewport
      - 'hotbar': bottom-center skill hotbar
      - 'hud': top-left cultivation/HP/Qi HUD
      - 'viewport': center gameplay area
    """
    captured_data = {"image": None, "width": 0, "height": 0}
    done_event = threading.Event()

    class ReceiverHandler(BaseHTTPRequestHandler):
        def log_message(self, *args): pass
        def do_POST(self):
            w = int(self.headers.get("X-Width", 0))
            h = int(self.headers.get("X-Height", 0))
            length = int(self.headers.get("Content-Length", 0))
            raw_bytes = self.rfile.read(length)
            captured_data["width"] = w
            captured_data["height"] = h
            try:
                captured_data["image"] = Image.frombytes("RGBA", (w, h), raw_bytes)
            except Exception as e:
                print(f"[Capture Receiver] Decode error: {e}")
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"OK")
            done_event.set()

    server = HTTPServer(("127.0.0.1", RECEIVER_PORT), ReceiverHandler)
    server.timeout = 10.0

    def serve():
        server.handle_request()

    th = threading.Thread(target=serve, daemon=True)
    th.start()

    lua_code = f"""
    local cs = game:GetService("CaptureService")
    local assetService = game:GetService("AssetService")
    local HttpService = game:GetService("HttpService")

    local contentId = nil
    cs:CaptureScreenshot(function(cid)
        contentId = cid
    end)

    local start = os.clock()
    while not contentId and (os.clock() - start < 5) do
        task.wait(0.05)
    end

    if not contentId then
        return "ERROR: CaptureScreenshot timed out"
    end

    local img = assetService:CreateEditableImageAsync(Content.fromUri(contentId))
    local fullSize = img.Size

    local origin = Vector2.zero
    local targetSize = fullSize

    local reg = "{region}"
    if reg == "hotbar" then
        origin = Vector2.new(math.floor(fullSize.X * 0.30), math.floor(fullSize.Y * 0.82))
        targetSize = Vector2.new(math.floor(fullSize.X * 0.40), math.floor(fullSize.Y * 0.18))
    elseif reg == "hud" then
        origin = Vector2.zero
        targetSize = Vector2.new(math.floor(fullSize.X * 0.42), math.floor(fullSize.Y * 0.22))
    elseif reg == "viewport" then
        origin = Vector2.new(math.floor(fullSize.X * 0.15), math.floor(fullSize.Y * 0.15))
        targetSize = Vector2.new(math.floor(fullSize.X * 0.70), math.floor(fullSize.Y * 0.70))
    end

    -- Clamp to valid bounds
    local ox = math.clamp(origin.X, 0, fullSize.X - 1)
    local oy = math.clamp(origin.Y, 0, fullSize.Y - 1)
    local tw = math.clamp(targetSize.X, 1, fullSize.X - ox)
    local th = math.clamp(targetSize.Y, 1, fullSize.Y - oy)

    local buf = img:ReadPixelsBuffer(Vector2.new(ox, oy), Vector2.new(tw, th))
    local raw = buffer.tostring(buf)

    local ok, res = pcall(function()
        return HttpService:RequestAsync({{
            Url = "http://127.0.0.1:{RECEIVER_PORT}/upload",
            Method = "POST",
            Headers = {{
                ["Content-Type"] = "application/octet-stream",
                ["X-Width"] = tostring(tw),
                ["X-Height"] = tostring(th)
            }},
            Body = raw
        }})
    end)

    return "OK:" .. tostring(tw) .. "x" .. tostring(th)
    """

    ok, out = exec_code(lua_code, timeout=12.0)
    if not ok:
        server.server_close()
        raise RuntimeError(f"Studio failed to capture: {out}")

    done_event.wait(timeout=5.0)
    server.server_close()

    if not captured_data["image"]:
        raise RuntimeError(f"Did not receive screenshot data from Studio (Studio out: {out})")

    ts = int(time.time())
    tag = f"_{label}" if label else ""
    filename = f"capture_{region}{tag}_{ts}.png"
    save_path = SCREENSHOTS_DIR / filename
    captured_data["image"].save(save_path, format="PNG")
    return save_path

def capture_b64(region: str = "full") -> tuple[str, Path]:
    path = capture(region)
    with open(path, "rb") as f:
        b64 = base64.b64encode(f.read()).decode("utf-8")
    return b64, path

def capture_all_regions() -> dict[str, Path]:
    results = {}
    for r in ["full", "hotbar", "hud"]:
        results[r] = capture(region=r)
        time.sleep(0.2)
    return results

if __name__ == "__main__":
    print(f"Studio Connected: {is_studio_connected()}")
    print("Testing capture('hotbar')...")
    p = capture("hotbar")
    print(f"Captured hotbar: {p}")
