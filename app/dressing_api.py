#!/usr/bin/env python3
"""Minimal Dressing backend. GET /health runs SELECT 1 on the database VM.
Listens on 127.0.0.1:8080 only; nginx is the public entrance."""
import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer

import psycopg


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != "/health":
            return self.reply(404, {"error": "not found"})
        try:
            with psycopg.connect(os.environ["DATABASE_URL"], connect_timeout=3) as conn:
                conn.execute("SELECT 1")
            self.reply(200, {"status": "ok", "db": "ok"})
        except psycopg.Error:
            self.reply(503, {"status": "ok", "db": "unreachable"})

    def reply(self, status, body):
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(data)


HTTPServer(("127.0.0.1", 8080), Handler).serve_forever()
