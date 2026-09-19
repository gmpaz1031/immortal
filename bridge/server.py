import sys
import json
import time
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import threading
import queue

PORT = 34875

# Command queue for Studio to consume
command_queue = queue.Queue()

# Store execution results: id -> result dict
results = {}

# Last ping from Studio plugin
last_studio_ping = 0

class BridgeHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Suppress noisy polling logs
        pass

    def _send_json(self, status_code, data):
        body = json.dumps(data).encode('utf-8')
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.end_headers()

    def do_GET(self):
        global last_studio_ping
        parsed = urlparse(self.path)
        params = parse_qs(parsed.query)

        if parsed.path == "/poll":
            # Studio plugin polling for new work
            last_studio_ping = time.time()
            try:
                # Wait up to 1.5 seconds for a command
                cmd = command_queue.get(timeout=1.5)
                self._send_json(200, cmd)
            except queue.Empty:
                self._send_json(200, {"action": "none"})

        elif parsed.path == "/status":
            connected = (time.time() - last_studio_ping) < 5.0
            self._send_json(200, {
                "server_running": True,
                "studio_connected": connected,
                "last_seen_seconds_ago": round(time.time() - last_studio_ping, 1) if last_studio_ping else None,
                "queue_size": command_queue.qsize()
            })

        elif parsed.path == "/result":
            cmd_id = params.get("id", [None])[0]
            if cmd_id and cmd_id in results:
                self._send_json(200, results[cmd_id])
            else:
                self._send_json(404, {"error": "Result not ready or not found"})

        else:
            self._send_json(404, {"error": "Endpoint not found"})

    def do_POST(self):
        parsed = urlparse(self.path)
        content_length = int(self.headers.get('Content-Length', 0))
        raw_body = self.rfile.read(content_length).decode('utf-8')
        data = {}
        if raw_body:
            try:
                data = json.loads(raw_body)
            except Exception:
                data = {"raw": raw_body}

        if parsed.path == "/exec":
            cmd_id = f"cmd_{int(time.time()*1000)}"
            code = data.get("code", "")
            if not code:
                self._send_json(400, {"error": "No code provided"})
                return

            command = {
                "id": cmd_id,
                "action": "execute",
                "code": code
            }
            command_queue.put(command)
            self._send_json(200, {"id": cmd_id, "status": "queued"})

        elif parsed.path == "/result":
            # Studio plugin sending back execution result
            cmd_id = data.get("id")
            if cmd_id:
                results[cmd_id] = data
                print(f"[Bridge] Command {cmd_id} result: success={data.get('success')} output={data.get('output')} error={data.get('error')}", flush=True)
            self._send_json(200, {"status": "ok"})

        else:
            self._send_json(404, {"error": "Endpoint not found"})

def run_server():
    server = HTTPServer(("127.0.0.1", PORT), BridgeHandler)
    print(f"[Bridge] Live Studio Bridge server listening on http://127.0.0.1:{PORT}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()

if __name__ == "__main__":
    run_server()
