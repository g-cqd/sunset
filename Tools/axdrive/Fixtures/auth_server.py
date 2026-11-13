#!/usr/bin/env python3
"""A page behind HTTP Basic (name "tide", password "low"), for on-screen checks: python3 auth_server.py [port, default 8767]."""
import base64
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer

EXPECTED = "Basic " + base64.b64encode(b"tide:low").decode()


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass

    def do_GET(self):
        if self.headers.get("Authorization") != EXPECTED:
            self.send_response(401)
            self.send_header("WWW-Authenticate", 'Basic realm="Harbour office"')
            self.end_headers()
            return
        body = b"<!doctype html><title>Signed in</title><h1>Signed in as tide</h1>"
        self.send_response(200)
        self.send_header("Content-Type", "text/html")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


HTTPServer(("127.0.0.1", int(sys.argv[1]) if len(sys.argv) > 1 else 8767), Handler).serve_forever()
