"""
bridge/screenshot_server.py
============================
Background Visual Playtesting Screenshot Server for Immortal RPG.

CAPTURE METHOD: Windows PrintWindow API (fully non-invasive)
  - Captures Roblox Studio WITHOUT bringing it to focus
  - Does NOT move your cursor
  - Does NOT switch your active tab or window
  - Works while you are browsing, in another game, or on another monitor
  - Keystrokes (F5, Shift+F5) sent via PostMessage directly into Studio's
    message queue -- no focus steal whatsoever

IMPORTANT: You must launch this server yourself in a real desktop terminal.
  Double-click: start_screenshot_server.bat
  Then the AI calls it at http://127.0.0.1:34876/

Endpoints:
  GET  /status                       Server health + Studio detection
  GET  /windows                      List all visible window titles
  GET  /screenshot                   Studio window capture (background)
  GET  /screenshot?region=hotbar     Skill hotbar crop
  GET  /screenshot?region=viewport   3D game viewport crop
  GET  /screenshot?region=hud        Top HUD strip
  GET  /screenshot_b64               Same, plus base64 PNG for AI analysis
  POST /playtest/start               Send F5 to Studio (no focus steal)
  POST /playtest/stop                Send Shift+F5 to Studio (no focus steal)
"""

import sys
import json
import time
import base64
import io
import ctypes
from pathlib import Path
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

try:
    import win32gui
    import win32ui
    import win32con
    import win32api
except ImportError:
    print("[ERROR] pywin32 not installed. Run:  pip install pywin32")
    sys.exit(1)

try:
    from PIL import Image
except ImportError:
    print("[ERROR] Pillow not installed. Run:  pip install Pillow")
    sys.exit(1)

# ---------------------------------------------------------------------------
PORT            = 34876
SCREENSHOTS_DIR = Path(__file__).resolve().parent.parent / "assets" / "screenshots"
SCREENSHOTS_DIR.mkdir(parents=True, exist_ok=True)

# PW_RENDERFULLCONTENT -- captures hardware-accelerated / GPU-composited windows
PW_RENDERFULLCONTENT = 0x00000002

# Crop presets (fraction of window: left, top, right, bottom)
REGIONS = {
    "hotbar":   (0.20, 0.87, 0.80, 1.00),  # Bottom-center skill hotbar
    "viewport": (0.00, 0.04, 1.00, 0.87),  # Main 3D game view
    "hud":      (0.00, 0.00, 1.00, 0.10),  # Top HUD row
    "full":     (0.00, 0.00, 1.00, 1.00),  # Entire Studio window
}


# ---------------------------------------------------------------------------
# Window discovery
# ---------------------------------------------------------------------------

def find_studio_hwnd():
    """Find Roblox Studio's window handle (must run in user desktop session)."""
    results = []

    def _cb(hwnd, _):
        if win32gui.IsWindow(hwnd) and win32gui.IsWindowVisible(hwnd):
            title = win32gui.GetWindowText(hwnd)
            if "Roblox Studio" in title:
                results.append((hwnd, title))

    win32gui.EnumWindows(_cb, None)
    # Prefer windows that contain the project name
    results.sort(key=lambda x: "immortal" in x[1].lower(), reverse=True)
    return results[0] if results else None


def list_windows():
    wins = []

    def _cb(hwnd, _):
        if win32gui.IsWindowVisible(hwnd):
            t = win32gui.GetWindowText(hwnd)
            if t.strip():
                wins.append(t)

    win32gui.EnumWindows(_cb, None)
    return sorted(wins)


# ---------------------------------------------------------------------------
# Background capture via PrintWindow
# ---------------------------------------------------------------------------

def capture_hwnd(hwnd: int) -> Image.Image:
    """
    Render the window into a bitmap without ever touching focus or cursor.

    PrintWindow asks the window to paint itself into our DC -- it works
    regardless of whether the window is behind other windows, minimised to
    taskbar, or even on a different virtual desktop.
    """
    left, top, right, bottom = win32gui.GetWindowRect(hwnd)
    w = right  - left
    h = bottom - top

    if w <= 0 or h <= 0:
        raise ValueError(f"Window has no area ({w}x{h})")

    hwnd_dc = win32gui.GetWindowDC(hwnd)
    mfc_dc  = win32ui.CreateDCFromHandle(hwnd_dc)
    mem_dc  = mfc_dc.CreateCompatibleDC()

    bmp = win32ui.CreateBitmap()
    bmp.CreateCompatibleBitmap(mfc_dc, w, h)
    mem_dc.SelectObject(bmp)

    # Render window content -> mem_dc without focusing the window
    ctypes.windll.user32.PrintWindow(hwnd, mem_dc.GetSafeHdc(), PW_RENDERFULLCONTENT)

    info = bmp.GetInfo()
    bits = bmp.GetBitmapBits(True)
    img  = Image.frombuffer("RGB", (info["bmWidth"], info["bmHeight"]),
                            bits, "raw", "BGRX", 0, 1)

    # Release GDI resources
    win32gui.DeleteObject(bmp.GetHandle())
    mem_dc.DeleteDC()
    mfc_dc.DeleteDC()
    win32gui.ReleaseDC(hwnd, hwnd_dc)

    return img


def capture_studio(region: str = "full"):
    """Capture Studio window cropped to region. Returns (img, meta) or (None, err)."""
    found = find_studio_hwnd()
    if not found:
        return None, {"error": "Roblox Studio window not found. Make sure it is open."}

    hwnd, title = found

    try:
        full = capture_hwnd(hwnd)
    except Exception as e:
        return None, {"error": f"PrintWindow failed: {e}"}

    pct  = REGIONS.get(region, REGIONS["full"])
    x1   = int(full.width  * pct[0])
    y1   = int(full.height * pct[1])
    x2   = int(full.width  * pct[2])
    y2   = int(full.height * pct[3])
    crop = full.crop((x1, y1, x2, y2))

    meta = {
        "window_title":  title,
        "window_hwnd":   hwnd,
        "full_size":     [full.width, full.height],
        "region":        region,
        "crop_px":       [x1, y1, x2, y2],
        "captured_size": [crop.width, crop.height],
        "capture_method": "PrintWindow (background, no focus steal)",
    }
    return crop, meta


# ---------------------------------------------------------------------------
# Non-invasive keystroke injection
# ---------------------------------------------------------------------------

def post_key(hwnd: int, vk: int, shift: bool = False):
    """
    Inject a keypress directly into a window's message queue.
    The window does not need focus. The user's cursor is not moved.
    This is the same mechanism used by automation testing tools.
    """
    sc     = win32api.MapVirtualKey(vk, 0)
    lp_dn  = (1) | (sc << 16)
    lp_up  = (1) | (sc << 16) | (1 << 30) | (1 << 31)

    if shift:
        sc_sh    = win32api.MapVirtualKey(win32con.VK_SHIFT, 0)
        lp_sh_dn = (1) | (sc_sh << 16)
        lp_sh_up = (1) | (sc_sh << 16) | (1 << 30) | (1 << 31)
        win32api.PostMessage(hwnd, win32con.WM_KEYDOWN, win32con.VK_SHIFT, lp_sh_dn)

    win32api.PostMessage(hwnd, win32con.WM_KEYDOWN, vk, lp_dn)
    time.sleep(0.06)
    win32api.PostMessage(hwnd, win32con.WM_KEYUP,   vk, lp_up)

    if shift:
        time.sleep(0.06)
        win32api.PostMessage(hwnd, win32con.WM_KEYUP, win32con.VK_SHIFT, lp_sh_up)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def save_png(img: Image.Image, label: str = "") -> Path:
    ts    = int(time.time())
    name  = f"screenshot_{label}_{ts}.png" if label else f"screenshot_{ts}.png"
    path  = SCREENSHOTS_DIR / name
    img.save(path, format="PNG")
    return path


def to_b64(img: Image.Image) -> str:
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return base64.b64encode(buf.getvalue()).decode()


# ---------------------------------------------------------------------------
# HTTP server
# ---------------------------------------------------------------------------

class Handler(BaseHTTPRequestHandler):

    def log_message(self, fmt, *args):
        print(f"  [{time.strftime('%H:%M:%S')}] {args[0]} {args[1]} {args[2]}")

    def json(self, data: dict, code: int = 200):
        body = json.dumps(data, indent=2).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    # ---- GET ----------------------------------------------------------------

    def do_GET(self):
        p   = urlparse(self.path)
        qs  = parse_qs(p.query)
        ep  = p.path

        if ep == "/status":
            studio = find_studio_hwnd()
            self.json({
                "server_running":   True,
                "capture_method":   "PrintWindow (background, no focus steal)",
                "studio_found":     studio is not None,
                "studio_title":     studio[1] if studio else None,
                "screenshots_dir":  str(SCREENSHOTS_DIR),
            })

        elif ep == "/windows":
            self.json({"windows": list_windows()})

        elif ep in ("/screenshot", "/screenshot_b64"):
            region   = qs.get("region", ["full"])[0]
            want_b64 = ep == "/screenshot_b64" or \
                       qs.get("b64", ["false"])[0].lower() == "true"

            img, meta = capture_studio(region)
            if img is None:
                self.json(meta, code=404)
                return

            path = save_png(img, f"studio_{region}")
            resp = {"success": True, "path": str(path),
                    "filename": path.name, "size": list(img.size), **meta}
            if want_b64:
                resp["b64"] = to_b64(img)
            self.json(resp)

        else:
            self.json({"error": f"Unknown endpoint: {ep}"}, code=404)

    # ---- POST ---------------------------------------------------------------

    def do_POST(self):
        ep = urlparse(self.path).path

        if ep == "/playtest/start":
            found = find_studio_hwnd()
            if not found:
                self.json({"success": False, "error": "Studio not found"})
                return
            hwnd, title = found
            post_key(hwnd, win32con.VK_F5)
            time.sleep(3.5)
            img, meta = capture_studio("full")
            saved = save_png(img, "after_playtest_start") if img else None
            self.json({"success": True, "action": "playtest_start",
                       "key": "F5 (PostMessage, no focus steal)",
                       "screenshot": str(saved) if saved else None, **meta})

        elif ep == "/playtest/stop":
            found = find_studio_hwnd()
            if not found:
                self.json({"success": False, "error": "Studio not found"})
                return
            hwnd, _ = found
            post_key(hwnd, win32con.VK_F5, shift=True)
            self.json({"success": True, "action": "playtest_stop",
                       "key": "Shift+F5 (PostMessage, no focus steal)"})

        else:
            self.json({"error": f"Unknown endpoint: {ep}"}, code=404)


def main():
    SCREENSHOTS_DIR.mkdir(parents=True, exist_ok=True)
    server = HTTPServer(("127.0.0.1", PORT), Handler)
    print(f"""
+----------------------------------------------------------+
|  Immortal Playtest Screenshot Server   port {PORT}        |
|  Capture: PrintWindow (fully background, no focus steal) |
+----------------------------------------------------------+
|  GET  /status                  Health + Studio check     |
|  GET  /windows                 List open windows         |
|  GET  /screenshot              Studio capture            |
|  GET  /screenshot?region=hotbar     Skill hotbar crop    |
|  GET  /screenshot?region=viewport   3D viewport crop     |
|  GET  /screenshot?region=hud        HUD strip            |
|  GET  /screenshot_b64          Capture + base64 JSON     |
|  POST /playtest/start          F5  (no focus steal)      |
|  POST /playtest/stop           Shift+F5 (no focus steal) |
+----------------------------------------------------------+
Screenshots -> {SCREENSHOTS_DIR}

Waiting for requests...
""")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[INFO] Server stopped.")
        server.server_close()


if __name__ == "__main__":
    main()
