#!/usr/bin/env python3
"""The web tester's server, on localhost only (a secure context, as https is).

    /...            the tester's files
    /isolated/...   the same files, cross-origin isolated (COOP and COEP): SharedArrayBuffer, precise timers
    /echo           the request's headers, as JSON: what this browser says it is
    /events         three server-sent events, then the end
    /beacon         takes a beacon
    POST /results/<label>   keeps a browser's results (in RESULTS, default .build/web-tester/results)
    GET  /results/          every result kept, as a JSON list
    /wpt/...        web-platform-tests, when fetched (Scripts/web-tester.sh wpt): served at the root so that their
                    /resources/ paths resolve (see README)

Usage: server.py [port] [results folder] [wpt folder]
"""
import json
import re
import socket
import sys
import threading
import time
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8767
RESULTS = Path(sys.argv[2] if len(sys.argv) > 2 else ROOT.parents[1] / ".build/web-tester/results")
WPT = Path(sys.argv[3]) if len(sys.argv) > 3 else ROOT.parents[1] / ".build/web-tester/wpt"
RESULTS.mkdir(parents=True, exist_ok=True)


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def log_message(self, format, *args):
        sys.stderr.write("%s %s\n" % (self.command, self.path))

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        if self.path.startswith("/isolated/"):
            self.send_header("Cross-Origin-Opener-Policy", "same-origin")
            self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()

    def translate_path(self, path):
        clean = path.split("?", 1)[0]
        if clean.startswith("/isolated/"):
            return super().translate_path(clean[len("/isolated"):])
        # web-platform-tests: their own paths (/resources/testharness.js, /mediacapture-streams/...) from the checkout.
        first = clean.strip("/").split("/", 1)[0]
        if first and WPT.is_dir() and (WPT / first).exists() and not (ROOT / first).exists():
            return str(WPT / clean.lstrip("/"))
        if clean.startswith("/wpt/") and WPT.is_dir():
            return str(WPT / clean[len("/wpt/"):])
        return super().translate_path(path)

    def json(self, value, status=200):
        body = json.dumps(value, indent=2).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = self.path.split("?", 1)[0]
        if path == "/echo":
            return self.json({k.lower(): v for k, v in self.headers.items()})
        if path == "/events":
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.end_headers()
            for n in range(1, 4):
                self.wfile.write(f"data: event {n}\n\n".encode())
                self.wfile.flush()
                time.sleep(0.1)
            return
        if path in ("/results", "/results/"):
            kept = []
            for file in sorted(RESULTS.glob("*.json")):
                try:
                    kept.append(json.loads(file.read_text()))
                except ValueError:
                    pass
            return self.json(kept)
        if path == "/" and (ROOT / "index.html").exists():
            self.path = "/index.html"
        return super().do_GET()

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(min(length, 5_000_000))
        path = self.path.split("?", 1)[0]
        if path == "/beacon":
            self.send_response(204)
            self.end_headers()
            return
        match = re.fullmatch(r"/results/([A-Za-z0-9._-]{1,60})", path)
        if not match:
            return self.json({"error": "not here"}, 404)
        try:
            report = json.loads(body)
        except ValueError:
            return self.json({"error": "not JSON"}, 400)
        report["label"] = match.group(1)
        (RESULTS / f"{match.group(1)}.json").write_text(json.dumps(report, indent=2))
        return self.json({"saved": match.group(1)})


class IPv6Server(ThreadingHTTPServer):
    address_family = socket.AF_INET6


if __name__ == "__main__":
    # Both loopbacks, never the network: browsers try "localhost" as ::1, 127.0.0.1, or both.
    servers = [ThreadingHTTPServer(("127.0.0.1", PORT), Handler)]
    try:
        servers.append(IPv6Server(("::1", PORT), Handler))
    except OSError:
        pass
    for extra in servers[1:]:
        threading.Thread(target=extra.serve_forever, daemon=True).start()
    print(f"Web tester: http://localhost:{PORT}/   results in {RESULTS}", flush=True)
    servers[0].serve_forever()
