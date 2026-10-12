#!/usr/bin/env python3
"""Minimal Dressing backend: enough to prove the app VM -> DB VM path works.

GET /health          -> {"status": "ok", "db": "ok"}   (runs SELECT 1 against PostgreSQL)
GET /designs/public  -> latest public designs from app.designs

Only the Python standard library plus Debian's python3-psycopg package.
Listens on 127.0.0.1; nginx is the only thing exposed to the internet.
"""
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import psycopg

DATABASE_URL = os.environ["DATABASE_URL"]
PORT = int(os.environ.get("PORT", "8080"))


def query(sql, params=()):
    with psycopg.connect(DATABASE_URL, connect_timeout=3) as conn:
        return conn.execute(sql, params).fetchall()


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            if self.path == "/health":
                query("SELECT 1")
                self.reply(200, {"status": "ok", "db": "ok"})
            elif self.path == "/designs/public":
                rows = query(
                    "SELECT id, title, created_at::text FROM app.designs "
                    "WHERE visibility = 'public' ORDER BY created_at DESC LIMIT 50"
                )
                self.reply(200, [{"id": r[0], "title": r[1], "created_at": r[2]} for r in rows])
            else:
                self.reply(404, {"error": "not found"})
        except psycopg.Error as error:
            self.log_error("database error: %s", error)
            self.reply(503, {"status": "degraded", "db": "unreachable"})

    def reply(self, status, body):
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
