#!/usr/bin/env python3
"""Локальний mock Hub API v1 для контракт-першої розробки.

Запуск: python3 MockServer/serve.py
Base: http://127.0.0.1:8787/v1
"""

from __future__ import annotations

import json
import re
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FIXTURES = ROOT / "Fixtures"
HOST, PORT = "127.0.0.1", 8787


def load(name: str):
    path = FIXTURES / f"{name}.json"
    with path.open(encoding="utf-8") as f:
        return json.load(f)


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):  # quieter
        print(f"[mock] {self.command} {self.path} -> {fmt % args}")

    def _json(self, code: int, payload):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def _err(self, code: int, err_code: str, message: str):
        self._json(code, {"error": {"code": err_code, "message": message}})

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Authorization, Content-Type")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.end_headers()

    def do_POST(self):
        if self.path in ("/v1/auth/login", "/v1/auth/register", "/v1/auth/apple", "/v1/auth/refresh"):
            self._json(200, {
                "accessToken": "mock-access-token",
                "refreshToken": "mock-refresh",
                "expiresIn": 3600,
            })
            return
        if self.path == "/v1/devices":
            self._json(204, {})
            return
        self._err(404, "not_found", self.path)

    def do_GET(self):
        path = self.path.split("?", 1)[0]
        if path == "/v1/me":
            return self._json(200, load("me"))

        m = re.match(r"^/v1/businesses/([^/]+)/summary$", path)
        if m:
            biz = m.group(1)
            name = "summary_ecom" if biz == "biz-ecom" else "summary_resto"
            return self._json(200, load(name))

        m = re.match(r"^/v1/businesses/([^/]+)/alerts$", path)
        if m:
            biz = m.group(1)
            qs = self.path.split("?", 1)
            cursor = None
            if len(qs) == 2:
                for part in qs[1].split("&"):
                    if part.startswith("cursor="):
                        cursor = part.split("=", 1)[1]
            if cursor == "page2":
                name = "alerts_ecom_page2" if biz == "biz-ecom" else "alerts_resto_page2"
            else:
                name = "alerts_ecom" if biz == "biz-ecom" else "alerts_resto"
            return self._json(200, load(name))

        m = re.match(r"^/v1/businesses/([^/]+)/reports$", path)
        if m:
            return self._json(200, load("reports"))

        m = re.match(r"^/v1/businesses/([^/]+)/metrics/([^/]+)$", path)
        if m:
            biz, dash = m.group(1), m.group(2)
            mode = "ecom" if biz == "biz-ecom" else "resto"
            stub = {
                "foodcost", "staff", "control", "locations",
                "products", "orders", "channels",
            }
            if dash in stub:
                return self._json(501, {
                    "error": {"code": "not_implemented", "message": f"{dash} stub"}
                })
            file = f"metrics_{mode}_{dash.replace('-', '_')}"
            try:
                return self._json(200, load(file))
            except FileNotFoundError:
                return self._err(501, "not_implemented", dash)

        self._err(404, "not_found", path)


if __name__ == "__main__":
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"Metrica Mock Hub on http://{HOST}:{PORT}/v1")
    server.serve_forever()
